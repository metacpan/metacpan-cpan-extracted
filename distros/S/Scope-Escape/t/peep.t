use warnings;
use strict;

use Test::More tests => 5;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

is_deeply [sub{
	current_escape_function->(22, 33);
	ok 0;
	(44, 55);
}->()], [22, 33];

sub pathological { 1 while 1 }

my $x;

$x = "XxYxZ";
$x =~ s{x}{y};
is $x, "XyYxZ";

$x = "XxYxZ";
$x =~ s{x}{current_escape_function->(22, 33)}e;
is $x, "X33YxZ";

$x = "XxYxZ";
$x =~ s{x}{current_escape_function->(22, 33)}eg;
is $x, "X33Y33Z";

1;
