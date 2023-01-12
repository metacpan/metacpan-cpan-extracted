use warnings FATAL => 'all';
use strict;

use Test::More tests => 9;

use Quote::Ref ();

is eval('qwa]1]'), undef;
like $@, qr/Number found where operator|Unmatched right square bracket/;

{
	use Quote::Ref;
	is_deeply qwa]1], [qw]1]];
}

is eval('qwa]1]'), undef;
like $@, qr/Number found where operator|Unmatched right square bracket/;

use Quote::Ref;
is_deeply qwa]1], [qw]1]];

{
	no Quote::Ref;
	is eval('qwa]1]'), undef;
	like $@, qr/Number found where operator|Unmatched right square bracket/;
}

is_deeply qwa]1], [qw]1]];
