use Test::More tests => 4;
use MozRepl;

SKIP: {
    my $repl = MozRepl->new;
    eval { $repl->setup( { plugins => { plugins => [qw/Repl::Rename/] } } ); };
    skip( "MozRepl is not started or MozLab is not installed.", 4 ) if ($@);

    ok( $repl->can('repl_rename') );

    for my $name (qw/zigorou amachang cho45/) {
        $repl->repl_rename( { name => $name } );
        is( $repl->repl, $name );
    }
}
