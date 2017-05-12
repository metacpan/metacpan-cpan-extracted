use strict;
use warnings;

BEGIN {
    if ($] < 5.008) {
        print("1..0 # Skip :lvalue requires Perl 5.8.0 or later\n");
        exit(0);
    }
    eval { require Want; };
    if ($@ || $Want::VERSION < 0.12) {
        print("1..0 # Skip Needs Want v0.12 or later\n");
        exit(0);
    }
}

use Test::More 'tests' => 182;
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
    my @foo1 :Field('Std' => 'foo1',                          'LValue' => 1, 'Return' => 'NEW');
    my @foo2 :Field('Get' => 'get_foo2', 'set' => 'set_foo2', 'lv'     => 1, 'Return' => 'OLD');
    my @foo3 :Field('STANDARD' => 'foo3',                     'LVALUE' => 1, 'Return' => 'SELF');

    # Combined get+set accessor
    my @bar1 :Field('LValue' => 'bar1',                'Return' => 'new');
    my @bar2 :Field('Acc'    => 'bar2', 'lvalue' => 1, 'Return' => 'Prev');
    my @bar3 :Field('get_set' => 'bar3', 'lv'    => 1, 'Return' => 'obj');

    # Type checking
    my @baz1 :Field('lv' => 'baz1', 'Return' => 'new', 'Type' => 'Baz');
    my @baz2 :Field('lv' => 'baz2', 'Return' => 'old', 'Type' => 'Baz');
    my @baz3 :Field('lv' => 'baz3', 'Return' => 'obj', 'Type' => 'Baz');

    my @num1 :Field('lv' => 'num1', 'Return' => 'new', 'Type' => 'num');
    my @num2 :Field('lv' => 'num2', 'Return' => 'old', 'Type' => 'num');
    my @num3 :Field('lv' => 'num3', 'Return' => 'obj', 'Type' => 'num');

    my @bork
        :Field
        :Type(Array_Ref(HASH))
        :LV(bork);

    my @zork
        :Field
        :Type(ScalarRef)
        :LV(zork);

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

    $obj->set_foo1() = $b2;
    is($obj->get_foo1(), $b2            => 'lvalue assign');

    $obj->set_foo1('foo') = 'Bert';
    is($obj->get_foo1(), 'Bert'         => 'lvalue assign (arg ignored)');

    $obj->set_foo1() =~ s/er/re/;
    is($obj->get_foo1(), 'Bret'         => 'lvalue re');

    change_it($obj->set_foo1(), 'Fred');
    is($obj->get_foo1(), 'Fred'         => 'lvalue');
    check_it($obj->set_foo1(), 'Fred');

    change_it($obj->set_foo1('Bert'), 'Mike');
    is($obj->get_foo1(), 'Mike'         => 'lvalue + arg new');
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

    $obj->set_foo2() = $b2;
    is($obj->get_foo2(), $b2            => 'lvalue assign');

    $obj->set_foo2('foo') = 'Bert';
    is($obj->get_foo2(), 'Bert'         => 'lvalue assign (arg ignored)');

    $obj->set_foo2() =~ s/er/re/;
    is($obj->get_foo2(), 'Bret'         => 'lvalue re');

    change_it($obj->set_foo2(), 'Fred');
    is($obj->get_foo2(), 'Fred'         => 'lvalue');
    check_it($obj->set_foo2(), 'Fred');

    change_it($obj->set_foo2('Bert'), 'Mike');
    is($obj->get_foo2(), 'Bert'         => 'lvalue + arg old');
    check_it($obj->set_foo2('Ralph'), 'Bert');

    $obj->set_foo2($b1);
    eval { $val = $obj->set_foo2()->me(); };
    like($@, qr/Missing arg/            => 'chain set needs arg');

    $obj->set_foo2('bork');
    $val = $obj->set_foo2('bar')->me();
    is($val, 'Foo(1)'                   => 'chain self');

    $obj->set_foo2($b1);
    $val = $obj->set_foo2($b2)->me();
    is($val, 'Baz(1)'                   => 'chain old object');


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

    $obj->set_foo3() = $b2;
    is($obj->get_foo3(), $b2            => 'lvalue assign');

    $obj->set_foo3('foo') = 'Bert';
    is($obj->get_foo3(), 'Bert'         => 'lvalue assign (arg ignored)');

    $obj->set_foo3() =~ s/er/re/;
    is($obj->get_foo3(), 'Bret'         => 'lvalue re');

    change_it($obj->set_foo3(), 'Fred');
    is($obj->get_foo3(), 'Fred'         => 'lvalue');
    check_it($obj->set_foo3(), 'Fred');

    my $obj_old = $obj;
    change_it($obj->set_foo3('Bert'), 'Mike');
    is($obj, 'Mike'                     => 'lvalue + arg self');
    $obj = $obj_old;
    is($obj->get_foo3(), 'Bert'         => 'Change did set');
    check_it($obj->set_foo3('Ralph'), $obj);
    is($obj->get_foo3(), 'Ralph'        => 'Check did set');

    $obj->set_foo3($b1);
    eval { $val = $obj->set_foo3()->me(); };
    like($@, qr/Missing arg/            => 'chain set needs arg');

    $val = $obj->set_foo3('bork')->me();
    is($val, 'Foo(1)'                   => 'chain self');

    $val = $obj->set_foo3($b2)->me();
    is($val, 'Foo(1)'                   => 'chain self');


    # get_set - return new
    $obj->bar1('val');
    is($obj->bar1(), 'val'              => 'rvalue set void');

    eval { $obj->bar1(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->bar1($b1);
    is($val, $b1                        => 'rvalue set returns new');

    $val2 = $obj->bar1();
    is($val2, $b1                       => 'rvalue get');

    $obj->bar1() = $b2;
    is($obj->bar1(), $b2                => 'lvalue assign');

    $obj->bar1('foo') = 'Bert';
    is($obj->bar1(), 'Bert'             => 'lvalue assign (arg ignored)');

    $obj->bar1() =~ s/er/re/;
    is($obj->bar1(), 'Bret'             => 'lvalue re');

    change_it($obj->bar1(), 'Fred');
    is($obj->bar1(), 'Fred'             => 'lvalue');
    check_it($obj->bar1(), 'Fred');

    change_it($obj->bar1('Bert'), 'Mike');
    is($obj->bar1(), 'Mike'             => 'lvalue + arg new');
    check_it($obj->bar1('Ralph'), 'Ralph');

    $obj->bar1($b1);
    $val = $obj->bar1()->me();
    is($val, 'Baz(1)'                   => 'chain get');

    $val = $obj->bar1('bork')->me();
    is($val, 'Foo(1)'                   => 'chain self');

    $val = $obj->bar1($b2)->me();
    is($val, 'Baz(2)'                   => 'chain new object');


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

    $obj->bar2() = $b2;
    is($obj->bar2(), $b2                => 'lvalue assign');

    $obj->bar2('foo') = 'Bert';
    is($obj->bar2(), 'Bert'             => 'lvalue assign (arg ignored)');

    $obj->bar2() =~ s/er/re/;
    is($obj->bar2(), 'Bret'             => 'lvalue re');

    change_it($obj->bar2(), 'Fred');
    is($obj->bar2(), 'Fred'             => 'lvalue');
    check_it($obj->bar2(), 'Fred');

    change_it($obj->bar2('Bert'), 'Mike');
    is($obj->bar2(), 'Bert'             => 'lvalue + arg old');
    check_it($obj->bar2('Ralph'), 'Bert');

    $obj->bar2($b1);
    $val = $obj->bar2()->me();
    is($val, 'Baz(1)'                   => 'chain get');

    $obj->bar2('bork');
    $val = $obj->bar2('bar')->me();
    is($val, 'Foo(1)'                   => 'chain self');

    $obj->bar2($b1);
    $val = $obj->bar2($b2)->me();
    is($val, 'Baz(1)'                   => 'chain old object');


    # get_set - return self
    $obj->bar3('val');
    is($obj->bar3(), 'val'              => 'rvalue set void');

    eval { $obj->bar3(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->bar3($b1);
    is($val, $obj                       => 'rvalue set returns self');

    $val2 = $obj->bar3();
    is($val2, $b1                       => 'rvalue get');

    $obj->bar3() = $b2;
    is($obj->bar3(), $b2                => 'lvalue assign');

    $obj->bar3('foo') = 'Bert';
    is($obj->bar3(), 'Bert'             => 'lvalue assign (arg ignored)');

    $obj->bar3() =~ s/er/re/;
    is($obj->bar3(), 'Bret'             => 'lvalue re');

    change_it($obj->bar3(), 'Fred');
    is($obj->bar3(), 'Fred'              => 'lvalue');
    check_it($obj->bar3(), 'Fred');

    $obj_old = $obj;
    change_it($obj->bar3('Bert'), 'Mike');
    is($obj, 'Mike'                     => 'lvalue + arg self');
    $obj = $obj_old;
    is($obj->bar3(), 'Bert'             => 'Change did set');
    check_it($obj->bar3('Ralph'), $obj);
    is($obj->bar3(), 'Ralph'            => 'Check did set');

    $obj->bar1($b1);
    $val = $obj->bar1()->me();
    is($val, 'Baz(1)'                   => 'chain get');

    $val = $obj->bar3('bork')->me();
    is($val, 'Foo(1)'                   => 'chain self');

    $val = $obj->bar3($b2)->me();
    is($val, 'Foo(1)'                   => 'chain self');


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

    $obj->baz1() = $b2;
    is($obj->baz1(), $b2                => 'lvalue assign');

    eval { $obj->baz1() = 'val'; };
    like($@, qr/must be of type 'Baz'/  => 'lvalue assign - bad');

    $obj->baz1($obj) = $b2;
    is($obj->baz1(), $b2                => 'lvalue assign (arg ignored)');

    eval { $obj->baz1() =~ s/Baz/Boing/; };     # Evil
    ok(! Scalar::Util::blessed($obj->baz1()) => 'lvalue re');
    like($obj->baz1(), qr/^Boing=SCALAR\(/   => 'lvalue re');

    change_it($obj->baz1(), 'Fred');
    is($obj->baz1(), 'Fred'             => 'lvalue - no type check');
    check_it($obj->baz1(), 'Fred');

    change_it($obj->baz1($b1), 'Mike');
    is($obj->baz1(), 'Mike'             => 'lvalue + arg new - no type check');
    check_it($obj->baz1($b2), $b2);

    $val = $obj->baz1()->me();
    is($val, 'Baz(2)'                   => 'chain get');

    $val = $obj->baz1($b1)->me();
    is($val, 'Baz(1)'                   => 'chain new object');


    # get_set - return old - type class
    $obj->baz2($b2);
    is($obj->baz2(), $b2                => 'rvalue set void');

    eval { $obj->baz2(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->baz2($b1);
    is($val, $b2                        => 'rvalue set returns old');

    $val2 = $obj->baz2();
    is($val2, $b1                       => 'rvalue get');

    $obj->baz2() = $b2;
    is($obj->baz2(), $b2                => 'lvalue assign');

    $obj->baz2($obj) = $b2;
    is($obj->baz2(), $b2                => 'lvalue assign (arg ignored)');

    change_it($obj->baz2(), 'Fred');
    is($obj->baz2(), 'Fred'             => 'lvalue - no type check');
    check_it($obj->baz2(), 'Fred');

    change_it($obj->baz2($b1), 'Mike');
    is($obj->baz2(), $b1                => 'lvalue + arg old');
    check_it($obj->baz2($b2), $b1);

    $val = $obj->baz2()->me();
    is($val, 'Baz(2)'                   => 'chain get');

    $val = $obj->baz2($b1)->me();
    is($val, 'Baz(2)'                   => 'chain old object');


    # get_set - return self - type class
    $obj->baz3($b1);
    is($obj->baz3(), $b1                => 'rvalue set void');

    eval { $obj->baz3(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->baz3($b2);
    is($val, $obj                       => 'rvalue set returns self');

    $val2 = $obj->baz3();
    is($val2, $b2                       => 'rvalue get');

    $obj->baz3() = $b1;
    is($obj->baz3(), $b1                => 'lvalue assign');

    $obj->baz3($obj) = $b2;
    is($obj->baz3(), $b2                => 'lvalue assign (arg ignored)');

    change_it($obj->baz3(), 'Fred');
    is($obj->baz3(), 'Fred'             => 'lvalue - no type check');
    check_it($obj->baz3(), 'Fred');

    $obj_old = $obj;
    change_it($obj->baz3($b1), 'Mike');
    is($obj, 'Mike'                     => 'lvalue + arg self - no type check');
    $obj = $obj_old;
    is($obj->baz3(), $b1                => 'Change did set');
    check_it($obj->baz3($b2), $obj);
    is($obj->baz3(), $b2                => 'Check did set');

    $val = $obj->baz3()->me();
    is($val, 'Baz(2)'                   => 'chain get');

    $val = $obj->baz3($b1)->me();
    is($val, 'Foo(1)'                   => 'chain self');


    # get_set - return new - type num
    $obj->num1(1);
    is($obj->num1(), 1                  => 'rvalue set void');

    eval { $obj->num1($b1); };
    like($@, qr/must be a number/        => 'rvalue set void - bad');

    eval { $obj->num1(); };
    is($@, ''                           => 'rvalue get void');

    $val = $obj->num1(2);
    is($val, 2                          => 'rvalue set returns new');

    $val2 = $obj->num1();
    is($val2, 2                         => 'rvalue get');

    $obj->num1() = 3;
    is($obj->num1(), 3                  => 'lvalue assign');

    eval { $obj->num1() = 'val'; };
    like($@, qr/must be a number/        => 'lvalue assign - bad');

    $obj->num1('bork') = 4;
    is($obj->num1(), 4                  => 'lvalue assign (arg ignored)');

    $obj->num1(5);
    eval { $obj->num1() =~ s/5/Boing/; };     # Evil
    is($obj->num1(), 'Boing'            => 'lvalue re');

    change_it($obj->num1(), 'Fred');
    is($obj->num1(), 'Fred'             => 'lvalue - no type check');
    check_it($obj->num1(), 'Fred');

    change_it($obj->num1(6), 'Mike');
    is($obj->num1(), 'Mike'             => 'lvalue + arg new - no type check');
    check_it($obj->num1(7), 7);

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

    $obj->num2() = 3;
    is($obj->num2(), 3                  => 'lvalue assign');

    $obj->num2('bork') = 4;
    is($obj->num2(), 4                  => 'lvalue assign (arg ignored)');

    change_it($obj->num2(), 'Fred');
    is($obj->num2(), 'Fred'             => 'lvalue - no type check');
    check_it($obj->num2(), 'Fred');

    change_it($obj->num2(5), 'Mike');
    is($obj->num2(), 5                  => 'lvalue + arg old');
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

    $obj->num3() = 3;
    is($obj->num3(), 3                  => 'lvalue assign');

    $obj->num3($obj) = 4;
    is($obj->num3(), 4                  => 'lvalue assign (arg ignored)');

    change_it($obj->num3(), 'Fred');
    is($obj->num3(), 'Fred'             => 'lvalue - no type check');
    check_it($obj->num3(), 'Fred');

    $obj_old = $obj;
    change_it($obj->num3(5), 'Mike');
    is($obj, 'Mike'                     => 'lvalue + arg self - no type check');
    $obj = $obj_old;
    is($obj->num3(), 5                  => 'Change did set');
    check_it($obj->num3(6), $obj);
    is($obj->num3(), 6                  => 'Check did set');

    eval { $val = $obj->num3()->me(); };
    like($@, qr/Can't (?:call|locate object) method/ => 'chain get needs object');

    $val = $obj->num3(7)->me();
    is($val, 'Foo(1)'                   => 'chain self');
    is($obj->num3(), 7                  => 'chain set');

    $obj->bork() = [ {a=>5,b=>'foo'}, {}, {99=>'bork'} ];
    is_deeply($obj->bork(), [ {a=>5,b=>'foo'}, {}, {99=>'bork'} ]
                                        => 'lv array_ref subtype=hash');

    my $x = 42;
    $obj->zork() = \$x;
    is($obj->zork(), \$x                => 'lv scalar_ref');
    my $y = $obj->zork();
    is($$y, 42                          => 'lv scalar_ref value')
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
