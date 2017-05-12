use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

sub aa {
	is_deeply [sub{
		my $c = current_escape_function;
		Scope::Escape::_fake_short_cxstack();
		$c->(22, 33);
		ok 0;
	}->()], [22, 33];
}

sub bb { aa(); }

bb();

1;
