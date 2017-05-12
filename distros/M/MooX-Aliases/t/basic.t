use strictures 1;
use Test::More;

my $called = 0;
my $subclass = 0;

{
    package MyTest;
    use Moo;
    use MooX::Aliases;

    sub foo { $called++ }
    alias bar => 'foo';

    package MyTest::Sub;
    use Moo;

    extends qw(MyTest);

    sub foo { $subclass++ };
}

($called, $subclass) = (0, 0);
my $t = MyTest->new;
$t->foo;
$t->bar;
is($called, 2, 'alias calls the original method');

my $t2 = MyTest::Sub->new;
$t2->foo;
$t2->bar;
is($subclass, 2, 'subclass method called twice');
is($called, 2, 'original method not called again');

done_testing;
