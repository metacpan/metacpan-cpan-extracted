use Test::More tests => 1;
use MozRepl;

SKIP: {
    my $repl = MozRepl->new;
    eval {
        $repl->setup( { plugins => { plugins => [qw/Repl::Load/] } } );
    };
    skip( "MozRepl is not started or MozLab is not installed.", 1 ) if ($@);

    ok( $repl->can('repl_load') );
}
