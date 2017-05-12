use Test::More tests => 3;
use MozRepl;

SKIP: {
    my $repl = MozRepl->new;
    eval {
        $repl->setup(
            { plugins => { plugins => [qw/Repl::Enter Repl::Back/] } } );
    };
    skip( "MozRepl is not started or MozLab is not installed.", 3 ) if ($@);

    ok( $repl->can('repl_back') );

    my %obj = ();

    for my $var ( split( /\./, "window.document.location" ) ) {
        $obj{$var} = $repl->repl_enter( { source => $var } );
    }

    for my $var ( reverse split( /\./, "window.document" ) ) {
        is( $repl->repl_back, $obj{$var} );
    }
}
