use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test('basic class', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Foo;
END

test('basic class version', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Foo 1.00;
END

test('basic role', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Foo;
END

test('basic role version', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Foo 1.00;
END

done_testing;

