use Test::More tests => 2;
use MozRepl;

SKIP: {
    my $repl = MozRepl->new;
    eval {
        $repl->setup({ plugins => { plugins => [qw/Repl::Home/] } } );
    };
    skip( "MozRepl is not started or MozLab is not installed.", 2 ) if ($@);

    ok( $repl->can('repl_home') );
    is($repl->repl_home, "[object ChromeWindow]");
}
