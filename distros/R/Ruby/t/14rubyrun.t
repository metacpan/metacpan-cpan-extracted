#!perl
use strict;
use warnings;
use Test::More tests => 4;

use Ruby::Run;

pass "inside Ruby::Run";

is __PACKAGE__, "main", "__PACKAGE__";

ok Perl::VERSION, "Perl::VERSION";
ok RUBY_VERSION, "RUBY_VERSION";
