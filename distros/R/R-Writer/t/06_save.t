use strict;
use Test::More (tests => 14);
use File::Spec;

BEGIN
{
    use_ok("R::Writer");
}

{
    my $file = File::Spec->catfile('t', 'save.txt');
    unlink($file);
    my $R = R::Writer->new();
    $R->var(y => $R->expression('a * x ^ 2'));

    ok(! -f $file);
    $R->save($file);
    ok( -f $file );

    ok( open(my $fh, '<', $file));
    my $contents = do { local $/ = undef; <$fh> };
    is( $contents, qq|y <- expression("a * x ^ 2");\n| );
}

{
    my $file = File::Spec->catfile('t', 'save.txt');
    unlink($file);

    my $R = R::Writer->new();
    $R->var(y => $R->expression('a * x ^ 2'));

    {
        ok( open(my $fh, '>', $file) );
        $R->save($fh);
        ok( close($fh) );
    }

    {
        ok( open(my $fh, '<', $file));
        my $contents = do { local $/ = undef; <$fh> };
        is( $contents, qq|y <- expression("a * x ^ 2");\n| );
    }
}

{
    my $string = '';
    my $R = R::Writer->new();
    $R->var(y => $R->expression('a * x ^ 2'));

    $R->save(\$string);
    is( $string, qq|y <- expression("a * x ^ 2");\n| );
}

SKIP: {
    skip("Path::Class is not installed", 2)
        if (! eval { require Path::Class } || $@);
    my $file = Path::Class::File->new('t', 'save.txt');
    unlink($file);
    my $R = R::Writer->new();
    $R->var(y => $R->expression('a * x ^ 2'));

    ok(! -f $file);
    $R->save($file);
    ok( -f $file );

    ok( open(my $fh, '<', $file));
    my $contents = do { local $/ = undef; <$fh> };
    is( $contents, qq|y <- expression("a * x ^ 2");\n| );
}
