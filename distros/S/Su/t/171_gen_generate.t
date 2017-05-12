use lib qw(t/test171 lib ../lib);
use Su;
use Test::More tests => 17;    #qw(no_plan);    #tests => 15;
use Carp;

BEGIN {
  $SIG{__WARN__} = sub {
    Carp::cluck(@_);
  };
  $SIG{__DIE__} = sub {
    Carp::cluck(@_);
  };
} ## end BEGIN

my $su = Su->new( base => 't/test171' );

unlink 't/test171/Pkg/FooProc.pm'   if ( -f 't/test171/Pkg/FooProc.pm' );
unlink 't/test171/Pkg/FooModel.pm'  if ( -f 't/test171/Pkg/FooModel.pm' );
unlink 't/test171/Pkg/FooProc2.pm'  if ( -f 't/test171/Pkg/FooProc2.pm' );
unlink 't/test171/Pkg/FooModel2.pm' if ( -f 't/test171/Pkg/FooModel2.pm' );
unlink 't/test171/Defs/Defs.pm'     if ( -f 't/test171/Defs/Defs.pm' );

my $ret = $su->gen_defs();

ok( -f 't/test171/Defs/Defs.pm' );

my $expect = {
  'main' => {
    'model' => 'Model',
    'proc'  => 'MainProc',
  },
  resource => {
    proc  => "Su::Procs::ResourceProc",
    model => "ResourceModel",
  },

};

ok( $ret == 1, "Generate default Defs file" );

$su->_load_defs_file();

ok( $su->{defs_href} );

is_deeply( $su->{defs_href}, $expect );

my $warn_occured = 0;
{
  local ( $SIG{__WARN__} ) = \&test_warn;

  $ret = $su->gen_defs();

  # Defs file already exists. So '0' will return and not overwrite.
  ok( $ret == 0, "Nothing generate because Defs file already exist." );
}

ok( $warn_occured,
'Warning should occur when explicitly call gen_defs and Defs file already exists.'
);

unlink 't/test171/Defs/Defs.pm';

$ret = $su->generate( 'Pkg::FooProc', 1 );

ok( $ret == 1 );

# delete $INC{'Defs/Defs.pm'};
$su->_load_defs_file( "Defs::Defs", 1 );

ok( $su->{defs_href} );

$expect = {

  # 'main' => {
  #   'model' => 'Model',
  #   'proc'  => 'MainProc',
  # },
  fooProc => {
    proc  => "Pkg::FooProc",
    model => "Pkg::FooModel",
  },

  resource => {
    proc  => "Su::Procs::ResourceProc",
    model => "ResourceModel",
  },
};

ok( -f 't/test171/Pkg/FooProc.pm' );
ok( -f 't/test171/Pkg/FooModel.pm' );

is_deeply( $su->{defs_href}, $expect,
  "Use proc name as entry id instead of the name of main." );

$su = Su->new( base => 't/test171' );

$warn_occured = 0;
{
  local ( $SIG{__WARN__} ) = \&test_warn;
  $ret = $su->generate( 'Pkg::FooProc2', 1 );
  ok( $ret == 0 );

  $expect = {

    # 'main' => {
    #   'model' => 'Pkg::FooModel',
    #   'proc'  => 'Pkg::FooProc',
    # },
    resource => {
      proc  => "Su::Procs::ResourceProc",
      model => "ResourceModel",
    },

    # Test whether the now entry is added.
    fooProc => {
      proc  => "Pkg::FooProc",
      model => "Pkg::FooModel",
    },
    fooProc2 => {
      proc  => "Pkg::FooProc2",
      model => "Pkg::FooProc2Model",
    },

  };
  ok( !$su->{defs_href} );

  # Force reload module which loaded by require.
  # delete $INC{'Defs/Defs.pm'};
  $su->_load_defs_file( "Defs::Defs", 1 );
  is_deeply( $su->{defs_href}, $expect,
    "New entry 'fooProc2' is added to existing entries." );

# Defs file already exist, and entry is added to Defs file automatically without any option.
  $ret = $su->generate('Pkg::FooProc3');
  ok( $ret == 0 );
  $expect = {
    resource => {
      proc  => "Su::Procs::ResourceProc",
      model => "ResourceModel",
    },

    # Test whether the now entry is added.
    fooProc => {
      proc  => "Pkg::FooProc",
      model => "Pkg::FooModel",
    },
    fooProc2 => {
      proc  => "Pkg::FooProc2",
      model => "Pkg::FooProc2Model",
    },
    fooProc3 => {
      proc  => "Pkg::FooProc3",
      model => "Pkg::FooProc3Model",
    },
  };

  # Force reload.
  $su->_load_defs_file( "Defs::Defs", 1 );
  is_deeply( $su->{defs_href}, $expect,
    "New entry 'fooProc3' is added to existing entries." );

}
ok( !$warn_occured );

sub test_warn {
  my $arg = shift;
  $warn_occured = 1;
}

