use Test::More tests => 3;
use MozRepl;

SKIP: {
    my $repl = MozRepl->new;

    eval {
        $repl->setup( { plugins => { plugins => [qw/Repl::Inspect/] } } );
    };
    skip( "MozRepl is not started or MozLab is not installed.", 3 ) if ($@);

    ok( $repl->can('repl_inspect') );

    $repl->repl_inspect( { source => 'repl' } );

    {
        my $response = $repl->repl_inspect( { source => 'repl' } );
        like( $response, qr/rename=\[function\]/ );
        like( $response, qr/search=\[function\]/ );
    }
}
