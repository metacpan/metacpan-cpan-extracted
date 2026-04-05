use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

# simple :isa/:does

test('basic class :isa', <<'END', {'Object::Pad' => 0, 'Bar' => 0});
use Object::Pad;

class Foo :isa(Bar);
END

test('basic class version :isa', <<'END', {'Object::Pad' => 0, 'Bar' => 0});
use Object::Pad;

class Foo 1.00 :isa(Bar);
END

test('basic class :isa base version', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00'});
use Object::Pad;

class Foo :isa(Bar 2.00);
END

test('basic class version :isa base version', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00'});
use Object::Pad;

class Foo 1.00 :isa(Bar 2.00);
END

test('basic class :does', <<'END', {'Object::Pad' => 0, 'Baz' => 0, 'Quux' => 0});
use Object::Pad;

class Foo :does(Baz) :does(Quux);
END

test('basic class version :does', <<'END', {'Object::Pad' => 0, 'Baz' => 0, 'Quux' => 0});
use Object::Pad;

class Foo 1.00 :does(Baz) :does(Quux);
END

test('basic class :does role version', <<'END', {'Object::Pad' => 0, 'Baz' => '2.00', 'Quux' => '3.00'});
use Object::Pad;

class Foo :does(Baz 2.00) :does(Quux 3.00);
END

test('basic class version :does role version', <<'END', {'Object::Pad' => 0, 'Baz' => '2.00', 'Quux' => '3.00'});
use Object::Pad;

class Foo 1.00 :does(Baz 2.00) :does(Quux 3.00);
END

test('basic class :does role, role version', <<'END', {'Object::Pad' => 0, 'Baz' => 0, 'Quux' => '3.00'});
use Object::Pad;

class Foo :does(Baz) :does(Quux 3.00);
END

test('basic class version :does role, role version', <<'END', {'Object::Pad' => 0, 'Baz' => 0, 'Quux' => '3.00'});
use Object::Pad;

class Foo 1.00 :does(Baz) :does(Quux 3.00);
END

# both :isa and :does

test('basic class :does role version :isa base', <<'END', {'Object::Pad' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use Object::Pad;

class Foo :does(Baz 2.00) :does(Quux 3.00) :isa(Bar 4.00);
END

test('basic class version :does role version :isa base', <<'END', {'Object::Pad' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use Object::Pad;

class Foo 1.00 :does(Baz 2.00) :does(Quux 3.00) :isa(Bar 4.00);
END

test('basic class :isa base :does role version', <<'END', {'Object::Pad' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use Object::Pad;

class Foo :isa(Bar 4.00) :does(Baz 2.00) :does(Quux 3.00);
END

test('basic class version :isa base :does role version', <<'END', {'Object::Pad' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use Object::Pad;

class Foo 1.00 :isa(Bar 4.00) :does(Baz 2.00) :does(Quux 3.00);
END

# class/role attributes

test('basic class :does role version :isa base :attr', <<'END', {'Object::Pad' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use Object::Pad;

class Foo :does(Baz 2.00) :does(Quux 3.00) :isa(Bar 4.00) :repr(native);
END

test('basic class version :does role version :isa base :attr', <<'END', {'Object::Pad' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use Object::Pad;

class Foo 1.00 :does(Baz 2.00) :does(Quux 3.00) :isa(Bar 4.00) :strict(params)
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

test('basic class version :isa internal class', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Bar;

class Foo 1.00 :isa(Bar);
END

test('basic class :isa internal class version', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Bar;

class Foo :isa(Bar 2.00);
END

test('basic class version :isa internal class version', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Bar;

class Foo 1.00 :isa(Bar 2.00);
END

test('basic class version :does internal role', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Bar;

class Foo 1.00 :does(Bar);
END

test('basic class :does internal role version', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Bar 2.00;

class Foo :does(Bar 2.00);
END

test('basic class version :does internal role version', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Bar 2.00;

class Foo 1.00 :does(Bar 2.00);
END

# class/role blocks ####

test('basic class {}', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Foo {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version {}', <<'END', {'Object::Pad' => 0});
use Object::Pad;

class Foo 1.00 {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic role {}', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Foo {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic role version {}', <<'END', {'Object::Pad' => 0});
use Object::Pad;

role Foo 1.00 {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

# simple :isa/:does

test('basic class :isa {}', <<'END', {'Object::Pad' => 0, 'Bar' => 0});
use Object::Pad;

class Foo :isa(Bar) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version :isa {}', <<'END', {'Object::Pad' => 0, 'Bar' => 0});
use Object::Pad;

class Foo 1.00 :isa(Bar) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class :isa base version {}', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00'});
use Object::Pad;

class Foo :isa(Bar 2.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version :isa base version {}', <<'END', {'Object::Pad' => 0, 'Bar' => '2.00'});
use Object::Pad;

class Foo 1.00 :isa(Bar 2.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class :does {}', <<'END', {'Object::Pad' => 0, 'Baz' => 0, 'Quux' => 0});
use Object::Pad;

class Foo :does(Baz) :does(Quux) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version :does {}', <<'END', {'Object::Pad' => 0, 'Baz' => 0, 'Quux' => 0});
use Object::Pad;

class Foo 1.00 :does(Baz) :does(Quux) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class :does role version {}', <<'END', {'Object::Pad' => 0, 'Baz' => '2.00', 'Quux' => '3.00'});
use Object::Pad;

class Foo :does(Baz 2.00) :does(Quux 3.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version :does role version {}', <<'END', {'Object::Pad' => 0, 'Baz' => '2.00', 'Quux' => '3.00'});
use Object::Pad;

class Foo 1.00 :does(Baz 2.00) :does(Quux 3.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class :does role, role version {}', <<'END', {'Object::Pad' => 0, 'Baz' => 0, 'Quux' => '3.00'});
use Object::Pad;

class Foo :does(Baz) :does(Quux 3.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

test('basic class version :does role, role version {}', <<'END', {'Object::Pad' => 0, 'Baz' => 0, 'Quux' => '3.00'});
use Object::Pad;

class Foo 1.00 :does(Baz) :does(Quux 3.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

done_testing;
