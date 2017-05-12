use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok("R::Writer");
}

{
    my $R = R::Writer->new();
    $R->var(y => $R->expression('a * x ^ 2'));
    $R->reset();
    is( $R->as_string(), qq||);
}