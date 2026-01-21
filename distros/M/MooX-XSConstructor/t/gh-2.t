use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

use Container;
my $x = Container->new;

isa_ok(
	$MyTest::GOT{x},
	'Container',
);

isa_ok(
	$TestBase::GOT{x},
	'Container',
);

done_testing;