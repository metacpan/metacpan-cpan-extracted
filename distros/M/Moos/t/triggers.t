use Test::More;

my ($foo, $bar, $baz, $bat) = (0) x 4;
{
    package Foos;
    use Moos;
    has foo => ( trigger => sub { $foo++ } );
    has bar => ( trigger => sub { $bar++ } );
    has baz => ( trigger => sub { $baz++ }, default => sub { 42 } );
    has bat => ( trigger => 1 );
    sub _trigger_bat { $bat = $_[2] };
}


my $obj = Foos->new(foo => 1);
is $foo, 1;
is $bar, 0;
is $baz, 0;
is $bat, 0;

$obj->foo(2); $obj->baz($obj->baz + 1);
is($obj->baz, 43);
is $foo, 2;
is $bar, 0;
is $baz, 1;
is $bat, 0;

$obj->bat(3);
is $bat, undef;
$obj->bat(42);
is $bat, 3;

done_testing;
