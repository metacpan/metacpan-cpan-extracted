use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

# simple :isa/:does

#SKIP_ALL_IF: $^V < 5.038
test('basic class :isa', <<'END', {'experimental' => 0, 'Bar' => 0});
use experimental 'class';

class Foo :isa(Bar);
END

#SKIP_IF: $^V < 5.040
test('basic class version :isa', <<'END', {'experimental' => 0, 'Bar' => 0});
use experimental 'class';

class Foo 1.00 :isa(Bar);
END

test('basic class :isa base version', <<'END', {'experimental' => 0, 'Bar' => '2.00'});
use experimental 'class';

class Foo :isa(Bar 2.00);
END

#SKIP_IF: $^V < 5.040
test('basic class version :isa base version', <<'END', {'experimental' => 0, 'Bar' => '2.00'});
use experimental 'class';

class Foo 1.00 :isa(Bar 2.00);
END

=pod

#SKIP: not implemented yet
test('basic class :does', <<'END', {'experimental' => 0, 'Baz' => 0, 'Quux' => 0});
use experimental 'class';

class Foo :does(Baz) :does(Quux);
END

#SKIP: not implemented yet
test('basic class version :does', <<'END', {'experimental' => 0, 'Baz' => 0, 'Quux' => 0});
use experimental 'class';

class Foo 1.00 :does(Baz) :does(Quux);
END

#SKIP: not implemented yet
test('basic class :does role version', <<'END', {'experimental' => 0, 'Baz' => '2.00', 'Quux' => '3.00'});
use experimental 'class';

class Foo :does(Baz 2.00) :does(Quux 3.00);
END

#SKIP: not implemented yet
test('basic class version :does role version', <<'END', {'experimental' => 0, 'Baz' => '2.00', 'Quux' => '3.00'});
use experimental 'class';

class Foo 1.00 :does(Baz 2.00) :does(Quux 3.00);
END

#SKIP: not implemented yet
test('basic class :does role, role version', <<'END', {'experimental' => 0, 'Baz' => 0, 'Quux' => '3.00'});
use experimental 'class';

class Foo :does(Baz) :does(Quux 3.00);
END

#SKIP: not implemented yet
test('basic class version :does role, role version', <<'END', {'experimental' => 0, 'Baz' => 0, 'Quux' => '3.00'});
use experimental 'class';

class Foo 1.00 :does(Baz) :does(Quux 3.00);
END

# both :isa and :does

#SKIP: not implemented yet
test('basic class :does role version :isa base', <<'END', {'experimental' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use experimental 'class';

class Foo :does(Baz 2.00) :does(Quux 3.00) :isa(Bar 4.00);
END

#SKIP: not implemented yet
test('basic class version :does role version :isa base', <<'END', {'experimental' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use experimental 'class';

class Foo 1.00 :does(Baz 2.00) :does(Quux 3.00) :isa(Bar 4.00);
END

#SKIP: not implemented yet
test('basic class :isa base :does role version', <<'END', {'experimental' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use experimental 'class';

class Foo :isa(Bar 4.00) :does(Baz 2.00) :does(Quux 3.00);
END

#SKIP: not implemented yet
test('basic class version :isa base :does role version', <<'END', {'experimental' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use experimental 'class';

class Foo 1.00 :isa(Bar 4.00) :does(Baz 2.00) :does(Quux 3.00);
END

# class/role attributes

#SKIP: not implemented yet
test('basic class :does role version :isa base :attr', <<'END', {'experimental' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use experimental 'class';

class Foo :does(Baz 2.00) :does(Quux 3.00) :isa(Bar 4.00) :repr(native);
END

#SKIP: not implemented yet
test('basic class version :does role version :isa base :attr', <<'END', {'experimental' => 0, 'Baz' => '2.00', 'Quux' => '3.00', 'Bar' => '4.00'});
use experimental 'class';

class Foo 1.00 :does(Baz 2.00) :does(Quux 3.00) :isa(Bar 4.00) :strict(params)
END

#SKIP: not implemented yet
test('basic role :attr', <<'END', {'experimental' => 0});
use experimental 'class';

role Foo :compat(invokable);
END

#SKIP: not implemented yet
test('basic role version :attr', <<'END', {'experimental' => 0});
use experimental 'class';

role Foo 1.00 :compat(invokable);
END

# internal classes/roles

#SKIP: not implemented yet
test('basic class version :isa internal class', <<'END', {'experimental' => 0});
use experimental 'class';

class Bar;

class Foo 1.00 :isa(Bar);
END

#SKIP: not implemented yet
test('basic class :isa internal class version', <<'END', {'experimental' => 0});
use experimental 'class';

class Bar;

class Foo :isa(Bar 2.00);
END

#SKIP: not implemented yet
test('basic class version :isa internal class version', <<'END', {'experimental' => 0});
use experimental 'class';

class Bar;

class Foo 1.00 :isa(Bar 2.00);
END

#SKIP: not implemented yet
test('basic class version :does internal role', <<'END', {'experimental' => 0});
use experimental 'class';

role Bar;

class Foo 1.00 :does(Bar);
END

#SKIP: not implemented yet
test('basic class :does internal role version', <<'END', {'experimental' => 0});
use experimental 'class';

role Bar 2.00;

class Foo :does(Bar 2.00);
END

#SKIP: not implemented yet
test('basic class version :does internal role version', <<'END', {'experimental' => 0});
use experimental 'class';

role Bar 2.00;

class Foo 1.00 :does(Bar 2.00);
END

=cut

# class/role blocks ####

test('basic class {}', <<'END', {'experimental' => 0});
use experimental 'class';

class Foo {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

#SKIP_IF: $^V < 5.040
test('basic class version {}', <<'END', {'experimental' => 0});
use experimental 'class';

class Foo 1.00 {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

=pod

#SKIP: not implemented yet
test('basic role {}', <<'END', {'experimental' => 0});
use experimental 'class';

role Foo {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

#SKIP: not implemented yet
test('basic role version {}', <<'END', {'experimental' => 0});
use experimental 'class';

role Foo 1.00 {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

=cut

# simple :isa/:does

test('basic class :isa {}', <<'END', {'experimental' => 0, 'Bar' => 0});
use experimental 'class';

class Foo :isa(Bar) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

#SKIP_IF: $^V < 5.040
test('basic class version :isa {}', <<'END', {'experimental' => 0, 'Bar' => 0});
use experimental 'class';

class Foo 1.00 :isa(Bar) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

#SKIP_IF: $^V < 5.040
test('basic class :isa base version {}', <<'END', {'experimental' => 0, 'Bar' => '2.00'});
use experimental 'class';

class Foo :isa(Bar 2.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

#SKIP_IF: $^V < 5.040
test('basic class version :isa base version {}', <<'END', {'experimental' => 0, 'Bar' => '2.00'});
use experimental 'class';

class Foo 1.00 :isa(Bar 2.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

=pod

#SKIP: not implemented yet
test('basic class :does {}', <<'END', {'experimental' => 0, 'Baz' => 0, 'Quux' => 0});
use experimental 'class';

class Foo :does(Baz) :does(Quux) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

#SKIP: not implemented yet
test('basic class version :does {}', <<'END', {'experimental' => 0, 'Baz' => 0, 'Quux' => 0});
use experimental 'class';

class Foo 1.00 :does(Baz) :does(Quux) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

#SKIP: not implemented yet
test('basic class :does role version {}', <<'END', {'experimental' => 0, 'Baz' => '2.00', 'Quux' => '3.00'});
use experimental 'class';

class Foo :does(Baz 2.00) :does(Quux 3.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

#SKIP: not implemented yet
test('basic class version :does role version {}', <<'END', {'experimental' => 0, 'Baz' => '2.00', 'Quux' => '3.00'});
use experimental 'class';

class Foo 1.00 :does(Baz 2.00) :does(Quux 3.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

#SKIP: not implemented yet
test('basic class :does role, role version {}', <<'END', {'experimental' => 0, 'Baz' => 0, 'Quux' => '3.00'});
use experimental 'class';

class Foo :does(Baz) :does(Quux 3.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

#SKIP: not implemented yet
test('basic class version :does role, role version {}', <<'END', {'experimental' => 0, 'Baz' => 0, 'Quux' => '3.00'});
use experimental 'class';

class Foo 1.00 :does(Baz) :does(Quux 3.00) {
  field $x :param = 0;
  field $y :param = 0;

  method move ($dX, $dY) {
    $x += $dX;
    $y += $dY;
  }
}
END

=cut

done_testing;
