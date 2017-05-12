use Test::More tests => 9;
use lib qw(../t/test16 t/test16 lib ../lib);
use Su;
use Su::Model;

# Note that these processes clear existing files.
#my $ft = Su::Template->new(base=>'t/test16');
#$ft->gen_tmpl('MainProc');
#my $fm = Su::Model->new(base=>'t/test16');
#$fm->gen_model('Model01');
#$fm->gen_model('Model02');
#$fm->gen_model('Model03');

my $fg = Su->new( base => 't/test16' );
my @ret = $fg->resolve('exec');

my @expect = (
  "key1:val1_1
key2:val1_2
key3:val1_3
",
  "key1:val2_1
key2:val2_2
key3:val2_3
",
  "key1:val3_1
key2:val3_2
key3:val3_3
"
);

is_deeply( \@ret, \@expect );

@ret = $fg->resolve('exec_post_filter');

# Result is modified by the post filter.
@expect = (
  "modified_key1:val1_1
modified_key2:val1_2
modified_key3:val1_3
",
  "modified_key1:val2_1
modified_key2:val2_2
modified_key3:val2_3
",
  "modified_key1:val3_1
modified_key2:val3_2
modified_key3:val3_3
"
);

is_deeply( \@ret, \@expect );

@ret = $fg->resolve('exec_map_filter');

# Result is modified by the post filter.
@expect = (
  "modified_key1:val1_1
modified_key2:val1_2
modified_key3:val1_3
"
);

is_deeply( \@ret, \@expect );

my $ret_val = $fg->resolve('exec_reduce_filter');

my $expect_val =
  'modified_key1:val1_1,modified_key2:val1_2,modified_key3:val1_3';

is( $ret_val, $expect_val );

@ret = $fg->resolve('exec_map_multi_filter');

@expect =
  ( "modified_key1:val1_1", "modified_key2:val1_2", "modified_key3:val1_3", );

is_deeply( \@ret, \@expect );

$ret_val = $fg->resolve('exec_scalar_filter');

$expect_val =
  '<modified_key1:val1_1,modified_key2:val1_2,modified_key3:val1_3>';

is( $ret_val, $expect_val );

package Proc_Ret_Single;

sub process {
  return "single result";
}

sub scalar_filter {

  my $self = shift if ref $_[0] eq __PACKAGE__ or $_[0] eq __PACKAGE__;
  my $arg = shift;
  return "added:" . $arg;
} ## end sub scalar_filter

package Proc_Ret_Multi;

sub process {
  return ( "first result", "secont_result" );
}

package main;

# Test for skipping the reduce filter and apply scalar filter directly.

no warnings qw(once);
$Su::Process::SUPPRESS_LOAD_ERROR = 1;

# diag( Dumper($Su::info_href) );
my $ret = $fg->resolve( { proc => 'Proc_Ret_Single' } );
is( $ret, 'single result' );

$ret = $fg->resolve(
  { proc => 'Proc_Ret_Single', scalar_filter => 'Proc_Ret_Single' } );
is( $ret, 'added:single result' );

eval {
  $ret = $fg->resolve(
    { proc => 'Proc_Ret_Multi', scalar_filter => 'Proc_Ret_Single' } );
};

# like( $@, qr/ERROR/ );

like( $@,
qr/\[ERROR\]Can't apply scalar filter\(s\), because the result of the process is multiple and not reduced by the reduce filter/
);
