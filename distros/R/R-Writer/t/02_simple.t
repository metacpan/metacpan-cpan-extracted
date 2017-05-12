use strict;
use Test::More (tests => 6);

BEGIN
{
    use_ok("R::Writer");
}

{
    # Simple function call
    my $R = R::Writer->new();
    $R->call("demo", "plotmath");
    like($R->as_string, qr/demo\("plotmath"\);/);
}

{
    # Simple variable initialization
    my $R = R::Writer->new();
    $R->var(x => 11);
    like($R->as_string, qr/x <- 11;\n/);
}

{
    # Simple range initialization
    my $R = R::Writer->new();
    $R->call('foo' => $R->range(0, 9));
    like($R->as_string, qr/foo\(0:9\);/);
}

{
    # Putting it all together...

    my $R = R::Writer->new();
    my $x = $R->var(x => 11);
    my $y = $R->var(y => 11);
    $R->call(c => \("x", "y"));
    is($R->as_string, qq/x <- 11;\ny <- 11;\nc(x,y);\n/);
}

{
    # x <- 1;
    # y <- x + 1;
    # cat(y);

    my $R = R::Writer->new;
    $R->var(x => 1);
    $R->var(y => 'x + 1');
    $R->call(cat => \'y');
    is( $R->as_string, qq/x <- 1;\ny <- x + 1;\ncat(y);\n/);
}
