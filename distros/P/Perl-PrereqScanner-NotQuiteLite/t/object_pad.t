use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
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

# simple isa/does

test('basic class isa', <<'END', {'Object::Pad' => 0, 'Bar' => 0});
use Object::Pad;

class Foo isa Bar;
END

test('basic class version isa', <<'END', {'Object::Pad' => 0, 'Bar' => 0});
use Object::Pad;

class Foo 1.00 isa Bar;
END

test('basic class isa base version', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00'});
use Object::Pad;

class Foo isa Bar 2.00;
END

test('basic class version isa base version', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00'});
use Object::Pad;

class Foo 1.00 isa Bar 2.00;
END

test('basic class does', <<'END', {'Object::Pad' => 0, 'Bar' => 0, 'Baz' => 0});
use Object::Pad;

class Foo does Bar, Baz;
END

test('basic class version does', <<'END', {'Object::Pad' => 0, 'Bar' => 0, 'Baz' => 0});
use Object::Pad;

class Foo 1.00 does Bar, Baz;
END

test('basic class does role version', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00', 'Baz' => '3.00'});
use Object::Pad;

class Foo does Bar 2.00, Baz 3.00;
END

test('basic class version does role version', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00', 'Baz' => '3.00'});
use Object::Pad;

class Foo 1.00 does Bar 2.00, Baz 3.00;
END

test('basic class does role, role version', <<'END', {'Object::Pad' => 0, 'Bar' => 0, 'Baz' => '3.00'});
use Object::Pad;

class Foo does Bar Baz 3.00;
END

test('basic class version does role, role version', <<'END', {'Object::Pad' => 0, 'Bar' => 0, 'Baz' => '3.00'});
use Object::Pad;

class Foo 1.00 does Bar, Baz 3.00;
END

# both isa and does

test('basic class does role version isa base', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00', 'Baz' => '3.00', 'Quux' => '4.00'});
use Object::Pad;

class Foo does Bar 2.00, Baz 3.00 isa Quux 4.00;
END

test('basic class version does role version isa base', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00', 'Baz' => '3.00', 'Quux' => '4.00'});
use Object::Pad;

class Foo 1.00 does Bar 2.00, Baz 3.00 isa Quux 4.00;
END

test('basic class isa base does role version', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00', 'Baz' => '3.00', 'Quux' => '4.00'});
use Object::Pad;

class Foo isa Quux 4.00 does Bar 2.00, Baz 3.00;
END

test('basic class version isa base does role version', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00', 'Baz' => '3.00', 'Quux' => '4.00'});
use Object::Pad;

class Foo 1.00 isa Quux 4.00 does Bar 2.00, Baz 3.00;
END

# class/role attributes

test('basic class does role version isa base :attr', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00', 'Baz' => '3.00', 'Quux' => '4.00'});
use Object::Pad;

class Foo does Bar 2.00, Baz 3.00 isa Quux 4.00 :repr(native), :repr(default), :strict(params);
END

test('basic class version does role version isa base :attr', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00', 'Baz' => '3.00', 'Quux' => '4.00'});
use Object::Pad;

class Foo 1.00 does Bar 2.00, Baz 3.00 isa Quux 4.00 :repr(native), :repr(default), :strict(params)
END

test('basic role :attr', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Foo :compat(invokable);
END

test('basic role version :attr', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Foo 1.00 :compat(invokable);
END

# internal classes/roles

test('basic class version isa internal class', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Bar;

class Foo 1.00 isa Bar;
END

test('basic class isa internal class version', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Bar;

class Foo isa Bar 2.00;
END

test('basic class version isa internal class version', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Bar;

class Foo 1.00 isa Bar 2.00;
END

test('basic class version does internal role', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Bar;

class Foo 1.00 does Bar;
END

test('basic class does internal role version', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Bar;

class Foo does Bar 2.00;
END

test('basic class version does internal role version', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Bar;

class Foo 1.00 does Bar 2.00;
END

# class/role blocks ####

test('basic class {}', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Foo {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version {}', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Foo 1.00 {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic role {}', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Foo {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic role version {}', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Foo 1.00 {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

# simple isa/does

test('basic class isa {}', <<'END', {'Object::Pad' => 0, 'Bar' => 0});
use Object::Pad;

class Foo isa Bar {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version isa {}', <<'END', {'Object::Pad' => 0, 'Bar' => 0});
use Object::Pad;

class Foo 1.00 isa Bar {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class isa base version {}', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00'});
use Object::Pad;

class Foo isa Bar 2.00 {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version isa base version {}', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00'});
use Object::Pad;

class Foo 1.00 isa Bar 2.00 {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class does {}', <<'END', {'Object::Pad' => 0, 'Bar' => 0, 'Baz' => 0});
use Object::Pad;

class Foo does Bar, Baz {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version does {}', <<'END', {'Object::Pad' => 0, 'Bar' => 0, 'Baz' => 0});
use Object::Pad;

class Foo 1.00 does Bar, Baz {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class does role version {}', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00', 'Baz' => '3.00'});
use Object::Pad;

class Foo does Bar 2.00, Baz 3.00 {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version does role version {}', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00', 'Baz' => '3.00'});
use Object::Pad;

class Foo 1.00 does Bar 2.00, Baz 3.00 {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class does role, role version {}', <<'END', {'Object::Pad' => 0, 'Bar' => 0, 'Baz' => '3.00'});
use Object::Pad;

class Foo does Bar Baz 3.00 {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version does role, role version {}', <<'END', {'Object::Pad' => 0, 'Bar' => 0, 'Baz' => '3.00'});
use Object::Pad;

class Foo 1.00 does Bar, Baz 3.00 {
  has $x :param = 0;
  has $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

done_testing;
