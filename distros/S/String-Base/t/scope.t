use warnings;
use strict;

use Test::More tests => 10;

our $t = "abcdef";

is substr($t,3,1), "d";
use String::Base +3;
is substr($t,3,1), "a";
{
	is substr($t,3,1), "a";
	use String::Base -1;
	is substr($t,3,1), "e";
	use String::Base +0;
	is substr($t,3,1), "d";
	use String::Base +1;
	is substr($t,3,1), "c";
	no String::Base;
	is substr($t,3,1), "d";
}
is substr($t,3,1), "a";
use t::scope_0;
is scope0_test(), "d";

is eval(q{
	use String::Base +3;
	BEGIN { my $x = "foo\x{666}"; $x =~ /foo\p{Alnum}/; }
	substr($t,3,1);
}), "a";

1;
