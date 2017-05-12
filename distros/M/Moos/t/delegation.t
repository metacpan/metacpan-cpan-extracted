use Test::More;

{
    package Foos;
    use Moos;
    has 'bar';
}

{
    package Boos;
    use Moos;
    has foo => (handles => [qw/bar/]);
}

my $B = Boos->new(foo => Foos->new);
can_ok $B, qw( foo bar );

$B->bar(42);
is($B->bar, 42);
is($B->foo->bar, 42);

done_testing();
