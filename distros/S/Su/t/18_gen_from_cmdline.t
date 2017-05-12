use lib qw(lib ../lib ../t/test18 t/test18 );
use Su;
use Data::Dumper;
use Test::More tests => 11;

sub convert_sep {
  my $cmd = shift;
  if ( $^O eq 'MSWin32' ) {
    $cmd =~ s/\"/\\\"/g;
    $cmd =~ s/'/\"/g;
  }
  $cmd;
} ## end sub convert_sep

if ( -f "./t/test18/Pkg/TestProc.pm" ) {
  unlink "./t/test18/Pkg/TestProc.pm" or die $!;
}

SKIP: {

  # Check whether we can call external perl program.
  `perl -e ""`;
  skip "Can't call extenal perl command for this test.", 11 if $? != 0;

  # Set base form Su::Template package.
  my $cmd =
"perl -Ilib -I../lib -MSu::Process=base,./t/test18/ -e 'Su::Process::generate_proc(\"Pkg::TestProc\")'";
  $cmd = convert_sep($cmd);

  #diag($cmd);
  `$cmd`;
  ok( -f "./t/test18/Pkg/TestProc.pm" );

  my $suproc = Su::Process->new;
  my $proc   = $suproc->load_module('Pkg::TestProc');
  ok( $proc, 'Load a Template which has nested packag name.' );

  if ( -f "./t/test18/SuPkg/TestProc.pm" ) {
    unlink "./t/test18/SuPkg/TestProc.pm" or die $!;
  }

  # Set base form Su package.
  $cmd =
"perl -Ilib -I../lib -MSu::Process=base,./t/test18/ -e 'Su::Process::generate_proc(\"SuPkg::TestProc\")'";
  $cmd = convert_sep($cmd);
  `$cmd`;

  ok( -f "./t/test18/SuPkg/TestProc.pm" );

## Generate Model test.

  if ( -f "./t/test18/SuModelPkg/TestModel.pm" ) {
    unlink "./t/test18/SuModelPkg/TestModel.pm" or die $!;
  }

  $cmd =
"perl -Ilib -I../lib -MSu::Model=base,./t/test18/ -e 'Su::Model::generate_model(\"SuModelPkg::TestModel\")'";
  $cmd = convert_sep($cmd);
  `$cmd`;
  ok( -f "./t/test18/SuModelPkg/TestModel.pm" );

  my $su_model = Su::Model->new;
  my $mdl      = $su_model->load_model('SuModelPkg::TestModel');

  ok($mdl);

  if ( -f "./t/test18/Defs/Defs.pm" ) {
    unlink "./t/test18/Defs/Defs.pm" or die $!;
  }

  $cmd = "perl -Ilib -I../lib -MSu=base,./t/test18/ -e 'Su::gen_defs()'";
  $cmd = convert_sep($cmd);
  `$cmd`;
  ok( -f "./t/test18/Defs/Defs.pm" );

  if ( -f "./t/test18/MyDefs/MyDefs.pm" ) {
    unlink "./t/test18/MyDefs/MyDefs.pm" or die $!;
  }

  $cmd =
"perl -Ilib -I../lib -MSu=base,./t/test18/ -e 'Su::gen_defs(\"MyDefs::MyDefs\")'";
  $cmd = convert_sep($cmd);
  `$cmd`;
  ok( -f "./t/test18/MyDefs/MyDefs.pm" );

  my $su = Su->new( base => 't/test18', defs_module => 'MyDefs::MyDefs' );

  is( $su->{defs_module}, 'MyDefs::MyDefs' );

  diag( Dumper() );

  my $expect = {
    'main' => {
      'proc'  => 'MainProc',
      'model' => 'Model',
    },
    resource => {
      proc  => "Su::Procs::ResourceProc",
      model => "ResourceModel",
    },

  };

  is_deeply( $su->_load_defs_file, $expect );

  if ( -f "./t/test18/Pkg/TestProcFromSu.pm" ) {
    unlink "./t/test18/Pkg/TestProcFromSu.pm" or die $!;
  }

  # Set base form Su package.
  $cmd =
"perl -Ilib -I../lib -MSu=base,./t/test18/ -e 'Su::gen_proc(\"Pkg::TestProcFromSu\")'";
  $cmd = convert_sep($cmd);
  `$cmd`;
  ok( -f "./t/test18/Pkg/TestProcFromSu.pm" );

  if ( -f "./t/test18/Pkg/TestModelFromSu.pm" ) {
    unlink "./t/test18/Pkg/TestModelFromSu.pm" or die $!;
  }

  # Set base form Su package.
  $cmd =
"perl -Ilib -I../lib -MSu=base,./t/test18/ -e 'Su::gen_model(\"Pkg::TestModelFromSu\")'";
  $cmd = convert_sep($cmd);
  `$cmd`;
  ok( -f "./t/test18/Pkg/TestModelFromSu.pm" );

} ## end SKIP:
