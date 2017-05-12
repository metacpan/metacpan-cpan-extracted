use Test::More tests => 5;
use MozRepl;

SKIP: {
    my $repl = MozRepl->new;
    eval { $repl->setup( { plugins => { plugins => [qw/Repl::Search/] } } ); };
    skip( "MozRepl is not started or MozLab is not installed.", 5 ) if ($@);

    ok( $repl->can('repl_search') );

    {
        my @search = $repl->repl_search(
            { pattern => '/^set/', context => 'window' } );

        ok( ( grep { $_ eq "setInterval" } @search ) == 1 );
        ok( ( grep { $_ eq "setTimeout" } @search ) == 1 );
    }

    {
        my @search = $repl->repl_search(
            { pattern => '/^get/', context => 'document' } );

        ok( ( grep { $_ eq "getElementById" } @search ) == 1 );
        ok( ( grep { $_ eq "getElementsByTagName" } @search ) == 1 );
    }
}
