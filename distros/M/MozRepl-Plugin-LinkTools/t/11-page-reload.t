use Test::More tests => 3;
use MozRepl;

SKIP: {
    my $repl = MozRepl->new;

    eval {
        $repl->setup({
            plugins => { plugins => [qw/OpenNewTab PageReload/] }
        });
    };
    skip("MozRepl is not started or MozLab is not installed. ", 3) if ($@);

    ok( $repl->can("page_reload") );
    $repl->open_new_tab({ url => "http://d.hatena.ne.jp/ZIGOROu/", selected => 1 });
    $repl->open_new_tab({ url => "http://d.hatena.ne.jp/amachang/" });

    sleep(5);

    ok( $repl->page_reload({ regex => q|/hatena/| }) >= 2);
    ok( $repl->page_reload() == 1);
}
