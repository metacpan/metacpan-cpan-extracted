use Test::More tests => 7;
use MozRepl;
use MozRepl::Util;

SKIP: {
    my $repl = MozRepl->new;

    eval {
        $repl->setup(
            { plugins => { plugins => [qw/Repl::Util::DocFor/] } } );
    };
    skip( "MozRepl is not started or MozLab is not installed.", 7 ) if ($@);

    ok( $repl->can('repl_doc_for') );

    is( $repl->repl_doc_for( { source => "window" } )->{type}, "object" );

    {
        my $result = $repl->repl_doc_for( { source => "window.document" } );
        is( $result->{type},     "object" );
        is( $result->{nodename}, "#document" );
    }

    {
        my $result
            = $repl->repl_doc_for( { source => $repl->repl . ".inspect" } );
        is( $result->{type}, "function" );
        is( $result->{name}, "inspect" );
        is( join( " ", @{ $result->{args} } ),
            q|obj maxDepth name curDepth| );
    }
}
