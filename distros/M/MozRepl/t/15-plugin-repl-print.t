use Test::More tests => 5;
use MozRepl;

SKIP: {
    my $repl = MozRepl->new;

    eval {
        $repl->setup( { plugins => { plugins => [qw/Repl::Print/] } } );
    };
    skip( "MozRepl is not started or MozLab is not installed.", 5 ) if ($@);

    ok( $repl->can('repl_print') );

    my %tests = (
        window                   => "[object ChromeWindow]",
        document                 => "[object XULDocument]",
        "[1, 2, 3]"              => "1,2,3",
        q|new String("zigorou")| => "zigorou"
    );

    for my $source ( keys %tests ) {
        is( $repl->repl_print( { source => $source, newline => undef } ),
            $tests{$source} );
    }
}
