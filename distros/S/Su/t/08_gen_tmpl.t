use Test::More tests => 1;

use lib qw(lib t/test08 ../lib);
use File::Path;
use Cwd;
use Su::Process base => './t', dir => 'test08';

BEGIN {

  my @arr = split( '/', $0 );
  my $extlib = './';
  if ( scalar @arr > 1 ) {
    $extlib = join( '/', @arr[ 0, scalar @arr - 2 ] );
  }
  unshift( @INC, Cwd::getcwd() . "/extlib" );
} ## end BEGIN

my $test_dir = "./t/test08";
rmtree($test_dir);

fail() if ( -d $test_dir );

generate_proc('GeneratedTmpl');

#$Su::Template::DEBUG=1;
my $ret = gen('GeneratedTmpl');

#$Su::Template::DEBUG=0;

is( $ret, "\n" );

#SKIP: {
#
#  eval { require Mojo::Template };
#  skip "Mojo::Template is not installed.", 1, if $@;
#  diag("Testing with Mojo::Template");
#  generate_proc( 'GeneratedMojoTmpl', 'mojo' );
#
#  $ret = gen('GeneratedMojoTmpl');
#  chomp($ret);
#
#  is( $ret, "" );
#
#} ## end SKIP:
