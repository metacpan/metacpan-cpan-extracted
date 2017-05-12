use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok "Scope::Escape", qw(
	current_escape_function current_escape_continuation
); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

eval { &current_escape_function(); };
like $@, qr/\Acurrent_escape_function called as a function/;
eval { &current_escape_continuation(); };
like $@, qr/\Acurrent_escape_continuation called as a function/;

1;
