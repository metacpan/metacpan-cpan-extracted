
use FindBin qw/$Bin/;
use lib $Bin;
use Test::More tests => 1;

use Pod::Coverage::MethodSignatures;

my $pc = Pod::Coverage::MethodSignatures->new(package => 'FooTestNoPod');

is( $pc->coverage, undef, "No pod" );
diag( $pc->why_unrated );
