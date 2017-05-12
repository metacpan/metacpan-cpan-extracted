use Test::More tests => 3;
use MozRepl;

SKIP: {
    my $repl = MozRepl->new;

    eval {
        $repl->setup({
            plugins => { plugins => [qw/JSON OpenNewTab Location/] }
        });
    };
    skip("MozRepl is not started or MozLab is not installed. ", 3) if ($@);

    ok( $repl->can("location") );

    $repl->open_new_tab({ url => "http://d.hatena.ne.jp/ZIGOROu/", selected => 1 });

    my $location;
    my $i = 0;

    while ($i < 10) {
        $location = $repl->location({});
        last if ($location->{href} ne "about:blank");
        sleep(1);
        $i++;
    }

    is($location->{host}, "d.hatena.ne.jp");
    is($location->{pathname}, "/ZIGOROu/");
}
