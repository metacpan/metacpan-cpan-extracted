use 5.014;

use Test::More tests => 1;

my $class = 'Roman::Unicode';
use_ok( $class ) or say "Bail out! $@";
my $version = $class->VERSION;

diag( "Testing $class $version, $^X ($^V)" );

