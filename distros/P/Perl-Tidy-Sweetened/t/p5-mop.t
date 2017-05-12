use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'Simple empty class', '',  );
class Point{
}
sub name3{}
RAW
class Point {
}
sub name3 { }
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with inheritance', '',  );
class   Point3D  extends Point{
}
RAW
class Point3D extends Point {
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with attribute', '',  );
class Point {
    has  $!x;
}

sub name3 {}
RAW
class Point {
    has $!x;
}

sub name3 { }
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with attribute and trait', '',  );
class Point {
    has $!x  is  ro;
}
RAW
class Point {
    has $!x is ro;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with attribute with default value', '',  );
class Point {
    has $!x  is  ro  = 1 ;
}
RAW
class Point {
    has $!x is ro = 1;
}
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Class with method', '',  );
class Point {
    has $!x;

    method set_x($x) {
        $!x = $x;
    }
}

sub name3 {}
RAW
class Point {
    has $!x;

    method set_x ($x) {
        $!x = $x;
    }
}

sub name3 { }
TIDIED

run_test( <<'RAW', <<'TIDIED', 'Multipart class', '',  );
class A::Point {
    has $!x  is  ro  = 1 ;
}
RAW
class A::Point {
    has $!x is ro = 1;
}
TIDIED

done_testing;
