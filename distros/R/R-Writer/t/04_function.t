use strict;
use Test::More (tests => 3);

BEGIN
{
    use_ok("R::Writer");
}

{
    my $R = R::Writer->new();
    $R->call('foo' => $R->call('dnorm'));
    is( $R->as_string(), qq|foo(dnorm());\n|);
}

{
    my $R = R::Writer->new();
    $R->call(func1 => $R->call(func2 => $R->call(func3 => 3)));
    is( $R->as_string(), qq|func1(func2(func3(3)));\n|);
}

{
    my $R = R::Writer->new();
    $R->call
}
