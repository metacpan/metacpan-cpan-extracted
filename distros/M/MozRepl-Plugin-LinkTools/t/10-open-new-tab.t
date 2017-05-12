use Test::More tests => 3;
use MozRepl;

SKIP: {
    my $repl = MozRepl->new;

    eval {
        $repl->setup({
            plugins => { plugins => [qw/OpenNewTab/] }
        });
    };
    skip("MozRepl is not started or MozLab is not installed. ", 3) if ($@);

    ok( $repl->can("open_new_tab") );
    ok( $repl->open_new_tab({ url => "http://d.hatena.ne.jp/ZIGOROu/" }) );
    ok( $repl->open_new_tab({ url => "http://labs.cybozu.co.jp/blog/yamaguchi/", selected => 1 }) );
}
