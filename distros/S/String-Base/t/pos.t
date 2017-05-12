use warnings;
use strict;

use Test::More tests => 16;

our $t = "abcdefghi";
scalar($t =~ /abcde/g);
our $r = \$t;

use String::Base +3;

is_deeply [ scalar pos($t) ], [ 8 ];
is_deeply [ pos($t) ], [ 8 ];
is_deeply [ scalar pos($$r) ], [ 8 ];
is_deeply [ pos($$r) ], [ 8 ];

{
	# Under "no warnings", an older version of the pos() code
	# underwent duff constant folding.
	no warnings;
	is_deeply [ scalar pos($t) ], [ 8 ];
	is_deeply [ pos($t) ], [ 8 ];
	is_deeply [ scalar pos($$r) ], [ 8 ];
	is_deeply [ pos($$r) ], [ 8 ];
}

scalar($t =~ /x/g);

is_deeply [ scalar pos($t) ], [ undef ];
is_deeply [ pos($t) ], [ undef ];
is_deeply [ scalar pos($$r) ], [ undef ];
is_deeply [ pos($$r) ], [ undef ];

{
	no warnings;
	is_deeply [ scalar pos($t) ], [ undef ];
	is_deeply [ pos($t) ], [ undef ];
	is_deeply [ scalar pos($$r) ], [ undef ];
	is_deeply [ pos($$r) ], [ undef ];
}

1;
