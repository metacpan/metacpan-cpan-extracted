
use FindBin qw/$Bin/;
use lib $Bin;
use Test::More tests => 1;

use Pod::Coverage::MethodSignatures;

my $pc = Pod::Coverage::MethodSignatures->new(package => 'FooTestHalfPod');

is( $pc->coverage, 0.5, "Half pod" );
diag( $pc->why_unrated );
