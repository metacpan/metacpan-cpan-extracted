use strict;
use Taint::Util ();
use Test::More tests => 3;

is(prototype("Taint::Util::tainted"), undef, 'tainted prototype');
is(prototype("Taint::Util::taint"), undef, 'taint prototype');
is(prototype("Taint::Util::untaint"), undef, 'untaint prototype');

