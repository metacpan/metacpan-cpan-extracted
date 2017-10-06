use Test2::V0;

{
    package Foo;
    use Moo;
    use Smart::Args::TypeTiny;
    use Types::Standard -all;

    sub foo {
        args my $self, my $x, my $y => Int;    # omit to set the type of $x
        return ($x, $y);
    }
}

{
    package Bar;
    use Moo;
    use Smart::Args::TypeTiny;
    use Types::Standard -all;

    sub bar {
        args_pos my $self, my $x, my $y => Int;    # omit to set the type of $x
        return ($x, $y);
    }
}

my $foo = Foo->new;

is [$foo->foo(x => 10, y => 20)], [10, 20];
is [$foo->foo(y => 20, x => 10)], [10, 20];

like dies {
    $foo->foo(x => 10, y => 3.14);
}, qr/Type check failed/;

like dies {
    $foo->foo(y => 10);
}, qr/Required parameter 'x' not passed/;

my $bar = Bar->new;

is [$bar->bar(10, 20)], [10, 20];

like dies {
    $bar->bar(10, 3.14);
}, qr/Type check failed in binding to parameter '\$y'; Value "3\.14" did not pass type constraint "Int"/;

like dies {
    $bar->bar(10);
}, qr/Required parameter 'y' not passed/;

done_testing;
