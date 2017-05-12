use strict;
use warnings;

BEGIN {
    eval { require Want; };
    if ($@ || $Want::VERSION < 0.12) {
        print("1..0 # Skip Needs Want v0.12 or later\n");
        exit(0);
    }
}


use Test::More 'tests' => 163;
use Scalar::Util;

package Baz; {
    use Object::InsideOut;
    sub me
    {
        my $self = shift;
        return ("Baz($$self)");
    }
}

package Foo; {
    use Object::InsideOut;

    # Separate get and set accessors
    my @foo1 :Field('Std' => 'foo1',                          'Return' => 'NEW');
    my @foo2 :Field('Get' => 'get_foo2', 'set' => 'set_foo2', 'Return' => 'OLD');
    my @foo3 :Field('STANDARD' => 'foo3',                     'Return' => 'SELF');

    # Combined get+set accessor
    my @bar1 :Field('Combo'  => 'bar1',  'Return' => 'new');
    my @bar2 :Field('Acc'    => 'bar2',  'Return' => 'Prev');
    my @bar3 :Field('get_set' => 'bar3', 'Return' => 'obj');

    # Type checking
    my @baz1 :Field('Acc' => 'baz1', 'Return' => 'new', 'Type' => 'Baz');
    my @baz2 :Field('Acc' => 'baz2', 'Return' => 'old', 'Type' => 'Baz');
    my @baz3 :Field('Acc' => 'baz3', 'Return' => 'obj', 'Type' => 'Baz');

    my @num1 :Field('Acc' => 'num1', 'Return' => 'new', 'Type' => 'num');
    my @num2 :Field('Acc' => 'num2', 'Return' => 'old', 'Type' => 'num');
    my @num3 :Field('Acc' => 'num3', 'Return' => 'obj', 'Type' => 'num');

    sub me
    {
        my $self = shift;
        return ("Foo($$self)");
    }
}

package main;

sub change_it
{
    $_[0] = $_[1];
}

sub check_it
{
    my ($x, $y) = @_;
    if ($x eq $y) {
        ok(1, 'Checked');
    } else {
        is($x, $y, 'Check failed');
    }
}

MAIN:
{
    my $b1 = Baz->new();
    my $b2 = Baz->new();
    my $obj = Foo->new();
    ok($b1 && $b2 && $obj, 'Objects created');

    can_ok($obj, qw(new clone DESTROY CLONE
                    get_foo1 set_foo1 get_foo2 set_foo2 get_foo3 set_foo3
                    bar1 bar2 bar3));

    # set - return new
    eval { $obj->set_foo1(); };
    like($@, qr/Missing arg/            => 'rvalue set needs arg');

    $obj->set_foo1('val');
    is($obj->get_foo1(), 'val'          => 'rvalue set void');

    eval { $obj->get_foo1(); };
    is($@, ''                           => 'rvalue get void');

    my $val = $obj->set_foo1($b1);
    is($val, $b1                        => 'rvalue set returns new');

    my $val2 = $obj->get_foo1();
    is($val2, $b1                       => 'rvalue get');

    eval { $obj->set_foo1() = $b2; };
    like($@, qr/non-lvalue subroutine/  => 'not lvalue');

    change_it($obj->set_foo1('Bert'), 'Mike');
    is($obj->get_foo1(), 'Bert'         => 'lvalue does not work');
    check_it($obj->set_foo1('Ralph'), 'Ralph');

    $obj->set_foo1($b1);
    eval { $val = $obj->set_foo1()->me(); };
    like($@, qr/Missing arg/            => 'chain set needs arg');

    $val = $obj->set_foo1('bork')->me();
    is($val, 'Foo(1)'                   => 'chain self');

    $val = $obj->set_foo1($b2)->me();
    is($val, 'Baz(2)'                   => 'chain new object');


    # set - return old
    eval { $obj->set_foo2(); };
    like($@, qr/Missing arg/            => 'rvalue set needs arg');

    $obj->set_foo2('val');
    is($obj->get_foo2(), 'val'          => 'rvalue set void');

    eval { $obj->get_foo2(); };
    is($@, ''                           => 'rvalue get void');

    $obj->set_foo2($b2);
    $val = $obj->set_foo2($b1);
    is($val, $b2                        => 'rvalue set returns old');

    $val2 = $obj->get_foo2();
    is($val2, $b1                       => 'rvalue get');

    eval { $obj->set_foo2() = $b2; };
    like($@, qr/non-lvalue subroutine/  => 'not lvalue');

    eval { $obj->set_foo2() =~ s/er/re/; };
    like($@, qr/non-lvalue subroutine/  => 'not lvalue');

    change_it($obj->set_foo2('Bert'), 'Mike');
    is($obj->get_foo2(), 'Bert'         => 'lvalue does not work');
    check_it($obj->set_foo2('Ralph'), 'Bert');

    $obj->set_foo2($b1);
    eval { $val = $obj->set_foo2()->me(); };
    like($@, qr/Missing arg/            => 'chain set needs arg');

    $obj->set_foo2('bork');
    $val = $obj->set_foo2('bar')->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->get_foo2(), 'bar'          => 'chain set');

    $obj->set_foo2($b1);
    $val = $obj->set_foo2($b2)->me();
    is($val, 'Baz(1)'                   => 'chain old object');
    is($obj->get_foo2(), $b2            => 'chain set');


    # set - return self
    eval { $obj->set_foo3(); };
    like($@, qr/Missing arg/            => 'rvalue set needs arg');

    $obj->set_foo3('val');
    is($obj->get_foo3(), 'val'          => 'rvalue set void');

    eval { $obj->get_foo3(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->set_foo3($b1);
    is($val, $obj                       => 'rvalue set returns self');

    $val2 = $obj->get_foo3();
    is($val2, $b1                       => 'rvalue get');

    eval { $obj->set_foo3() = $b2; };
    like($@, qr/non-lvalue subroutine/  => 'not lvalue');

    my $obj_old = $obj;
    change_it($obj->set_foo3('Bert'), 'Mike');
    is($obj, $obj_old                   => 'lvalue does not work');
    is($obj->get_foo3(), 'Bert'         => 'Change did set');
    check_it($obj->set_foo3('Ralph'), $obj);
    is($obj->get_foo3(), 'Ralph'        => 'Check did set');

    $obj->set_foo3($b1);
    is($obj->get_foo3()->me(), 'Baz(1)' => 'chain get');

    eval { $val = $obj->set_foo3()->me(); };
    like($@, qr/Missing arg/            => 'chain set needs arg');

    $val = $obj->set_foo3('bork')->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->get_foo3(), 'bork'         => 'chain set');

    $val = $obj->set_foo3($b2)->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->get_foo3(), $b2            => 'chain set');


    # get_set - return new
    $obj->bar1('val');
    is($obj->bar1(), 'val'              => 'rvalue set void');

    eval { $obj->bar1(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->bar1($b1);
    is($val, $b1                        => 'rvalue set returns new');

    $val2 = $obj->bar1();
    is($val2, $b1                       => 'rvalue get');

    eval { $obj->bar1() = $b2; };
    like($@, qr/non-lvalue subroutine/  => 'not lvalue');

    eval { $obj->bar1() =~ s/er/re/; };
    like($@, qr/non-lvalue subroutine/  => 'not lvalue');

    change_it($obj->bar1(), 'Fred');
    is($obj->bar1(), $b1                => 'lvalue does not work');
    check_it($obj->bar1(), $b1);

    change_it($obj->bar1('Bert'), 'Mike');
    is($obj->bar1(), 'Bert'             => 'lvalue does not work');
    check_it($obj->bar1('Ralph'), 'Ralph');

    $obj->bar1($b1);
    is($obj->bar1(), $b1                => 'set');

    $val = $obj->bar1()->me();
    is($val, 'Baz(1)'                   => 'chain get');

    $val = $obj->bar1('bork')->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->bar1(), 'bork'             => 'chain set');

    $val = $obj->bar1($b2)->me();
    is($val, 'Baz(2)'                   => 'chain new object');
    is($obj->bar1(), $b2                => 'chain set');


    # get_set - return old
    $obj->bar2('val');
    is($obj->bar2(), 'val'              => 'rvalue set void');

    eval { $obj->bar2(); };
    is($@, ''                           => 'rvalue get void');

    $obj->bar2($b2);
    $val = $obj->bar2($b1);
    is($val, $b2                        => 'rvalue set returns old');

    $val2 = $obj->bar2();
    is($val2, $b1                       => 'rvalue get');

    eval { $obj->bar2() = $b2; };
    like($@, qr/non-lvalue subroutine/  => 'not lvalue');

    change_it($obj->bar2(), 'Fred');
    is($obj->bar2(), $b1                => 'lvalue does not work');
    check_it($obj->bar2(), $b1);

    change_it($obj->bar2('Bert'), 'Mike');
    is($obj->bar2(), 'Bert'             => 'lvalue probably does not work');
    check_it($obj->bar2($b1), 'Bert');
    is($obj->bar2(), $b1                => 'set');

    $val = $obj->bar2()->me();
    is($val, 'Baz(1)'                   => 'chain get');

    $obj->bar2('bork');
    $val = $obj->bar2('bar')->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->bar2(), 'bar'              => 'chain set');

    $obj->bar2($b1);
    $val = $obj->bar2($b2)->me();
    is($val, 'Baz(1)'                   => 'chain old object');
    is($obj->bar2(), $b2                => 'chain set');


    # get_set - return self
    $obj->bar3('val');
    is($obj->bar3(), 'val'              => 'rvalue set void');

    eval { $obj->bar3(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->bar3($b1);
    is($val, $obj                       => 'rvalue set returns self');

    $val2 = $obj->bar3();
    is($val2, $b1                       => 'rvalue get');

    change_it($obj->bar3(), 'Fred');
    is($obj->bar3(), $b1                => 'lvalue does not work');
    check_it($obj->bar3(), $b1);

    change_it($obj->bar3('Bert'), 'Mike');
    is(ref($obj), 'Foo'                 => 'lvalue does not work');
    is($obj->bar3(), 'Bert'             => 'Change did set');
    check_it($obj->bar3('Ralph'), $obj);
    is($obj->bar3(), 'Ralph'            => 'Check did set');

    $obj->bar3($b1);
    is($obj->bar3(), $b1                => 'set');

    $val = $obj->bar3()->me();
    is($val, 'Baz(1)'                   => 'chain get');

    $val = $obj->bar3('bork')->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->bar3(), 'bork'             => 'chain set');

    $val = $obj->bar3($b2)->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->bar3(), $b2                => 'chain set');


    # get_set - return new - type class
    $obj->baz1($b1);
    is($obj->baz1(), $b1                => 'rvalue set void');

    eval { $obj->baz1('val'); };
    like($@, qr/must be of type 'Baz'/  => 'rvalue set void - bad');

    eval { $obj->baz1(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->baz1($b1);
    is($val, $b1                        => 'rvalue set returns new');

    $val2 = $obj->baz1();
    is($val2, $b1                       => 'rvalue get');

    eval { $obj->baz1() = $b2; };
    like($@, qr/non-lvalue subroutine/  => 'not lvalue');

    eval { $obj->baz1($obj) = $b2; };
    like($@, qr/non-lvalue subroutine/  => 'not lvalue');
    is($obj->baz1(), $b1                => 'not changed');

    eval { $obj->baz1() =~ s/Baz/Boing/; };     # Evil
    like($@, qr/non-lvalue subroutine/  => 'not lvalue');
    is($obj->baz1(), $b1                => 'not changed');

    change_it($obj->baz1(), 'Fred');
    is($obj->baz1(), $b1                => 'lvalue does not work');
    check_it($obj->baz1(), $b1);

    change_it($obj->baz1($b1), 'Mike');
    is($obj->baz1(), $b1                => 'lvalue does not work');
    check_it($obj->baz1($b2), $b2);

    $val = $obj->baz1()->me();
    is($val, 'Baz(2)'                   => 'chain get');

    $val = $obj->baz1($b1)->me();
    is($val, 'Baz(1)'                   => 'chain new object');
    is($obj->baz1, $b1                  => 'chain set');


    # get_set - return old - type class
    $obj->baz2($b2);
    is($obj->baz2(), $b2                => 'rvalue set void');

    eval { $obj->baz2(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->baz2($b1);
    is($val, $b2                        => 'rvalue set returns old');

    $val2 = $obj->baz2();
    is($val2, $b1                       => 'rvalue get');

    change_it($obj->baz2(), 'Fred');
    is($obj->baz2(), $b1                => 'lvalue does not work');
    check_it($obj->baz2(), $b1);

    change_it($obj->baz2($b2), 'Mike');
    is($obj->baz2(), $b2                => 'lvalue does not work');
    check_it($obj->baz2($b1), $b2);
    is($obj->baz2(), $b1                => 'set');

    $val = $obj->baz2()->me();
    is($val, 'Baz(1)'                   => 'chain get');

    $val = $obj->baz2($b2)->me();
    is($val, 'Baz(1)'                   => 'chain old object');
    is($obj->baz2(), $b2                => 'chain set');


    # get_set - return self - type class
    $obj->baz3($b1);
    is($obj->baz3(), $b1                => 'rvalue set void');

    eval { $obj->baz3(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->baz3($b2);
    is($val, $obj                       => 'rvalue set returns self');

    $val2 = $obj->baz3();
    is($val2, $b2                       => 'rvalue get');

    change_it($obj->baz3(), 'Fred');
    is($obj->baz3(), $b2                => 'lvalue does not work');
    check_it($obj->baz3(), $b2);

    change_it($obj->baz3($b1), 'Mike');
    is($obj->baz3(), $b1                => 'lvalue does not work');
    check_it($obj->baz3($b2), $obj);
    is($obj->baz3(), $b2                => 'Check did set');

    $val = $obj->baz3()->me();
    is($val, 'Baz(2)'                   => 'chain get');

    $val = $obj->baz3($b1)->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->baz3(), $b1                => 'chain set');


    # get_set - return new - type num
    $obj->num1(1);
    is($obj->num1(), 1                  => 'rvalue set void');

    eval { $obj->num1($b1); };
    like($@, qr/must be a number/       => 'rvalue set void - bad');

    eval { $obj->num1(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->num1(2);
    is($val, 2                          => 'rvalue set returns new');

    $val2 = $obj->num1();
    is($val2, 2                         => 'rvalue get');

    eval { $obj->num1('bork') = 3; };
    like($@, qr/non-lvalue subroutine/  => 'not lvalue');

    change_it($obj->num1(), 'Fred');
    is($obj->num1(), 2                  => 'lvalue does not work');
    check_it($obj->num1(), 2);

    change_it($obj->num1(4), 'Mike');
    is($obj->num1(), 4                  => 'lvalue does not work');
    check_it($obj->num1(5), 5);

    eval { $val = $obj->num1()->me(); };
    like($@, qr/Can't (?:call|locate object) method/ => 'chain get needs object');

    $val = $obj->num1(8)->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->num1(), 8                  => 'chain set');


    # get_set - return old - type num
    $obj->num2(1);
    is($obj->num2(), 1                  => 'rvalue set void');

    eval { $obj->num2(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->num2(2);
    is($val, 1                          => 'rvalue set returns old');

    $val2 = $obj->num2();
    is($val2, 2                         => 'rvalue get');

    change_it($obj->num2(5), 'Mike');
    is($obj->num2(), 5                  => 'lvalue does not work');
    check_it($obj->num2(6), 5);

    $val = $obj->num2(7)->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->num2(), 7                  => 'chain set');


    # get_set - return self - type num
    $obj->num3(1);
    is($obj->num3(), 1                  => 'rvalue set void');

    eval { $obj->num3(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->num3(2);
    is($val, $obj                       => 'rvalue set returns self');
    is($obj->num3(), 2                  => 'rvalue set');

    $val2 = $obj->num3();
    is($val2, 2                         => 'rvalue get');

    change_it($obj->num3(5), 'Mike');
    is($obj->num3(), 5                  => 'lvalue does not work');
    check_it($obj->num3(6), $obj);
    is($obj->num3(), 6                  => 'Check did set');

    eval { $val = $obj->num3()->me(); };
    like($@, qr/Can't (?:call|locate object) method/ => 'chain get needs object');

    $val = $obj->num3(7)->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->num3(), 7                  => 'chain set');
}

exit(0);

__END__

:LVALUE                             set    get_set
    $obj->foo('val');                               rvalue set void
    $obj->foo();                    ERR    get      rvalue get void

    my $x = $obj->foo('val');                       rvalue set return
        NEW
        OLD
        SELF
    my $x = $obj->foo();            ERR    get      rvalue get

    $obj->foo() = 'val';                            lvalue assign
    $obj->foo('ignored') = 'val';                   lvalue assign

    $obj->foo() =~ s/x/y/;             fld          lvalue re

    bar($obj->foo());                  fld          lvalue
        change_it
        check_it
    bar($obj->foo('val'));                          lvalue + arg
        change_it
        check_it
        NEW                            fld
        OLD                            ret
        SELF                           obj

    $obj->foo()->bar();             ERR     fld     lvalue + want(obj)
    $obj->foo('val')->bar();                        lvalue + arg + want(obj)
        NEW                            fld/obj
        OLD                            ret/obj
        SELF                           obj

Non-lvalue
    $obj->foo('val');                               rvalue set void
    $obj->foo();                    ERR     get     rvalue get void

    my $x = $obj->foo('val');                       rvalue set return
        NEW
        OLD
        SELF
    my $x = $obj->foo();            ERR     get     rvalue get

    $obj->foo() = 'val';               ERR
    $obj->foo('ignored') = 'val';      ERR
    $obj->foo() =~ s/x/y/;             ERR

    bar($obj->foo());               ERR     get
    bar($obj->foo('val'));
        NEW                            fld
        OLD                            ret
        SELF                           obj

    $obj->foo()->bar();             ERR     get
    $obj->foo('val')->bar();
        NEW                            fld/obj
        OLD                            ret/obj
        SELF                           obj

# EOF
