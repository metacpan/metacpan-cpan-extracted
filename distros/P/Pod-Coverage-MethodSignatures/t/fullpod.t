
use FindBin qw/$Bin/;
use lib $Bin;
use Test::More tests => 2;

BEGIN {use_ok( 'Pod::Coverage::MethodSignatures' ); }

my $pc = Pod::Coverage::MethodSignatures->new(package => 'FooTestFullPod');

is( $pc->coverage, 1, "Full pod" );
diag( $pc->why_unrated );
