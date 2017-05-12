use Test::More tests => 3;
use MozRepl;
use Data::Dump qw(dump);

SKIP: {
    my $repl = MozRepl->new;

    eval {
        $repl->setup({
            plugins => { plugins => [qw/JSON OpenNewTab Location LinkExtor/] }
        });
    };
    skip("MozRepl is not started or MozLab is not installed. ", 3) if ($@);

    ok( $repl->can("linkextor") );

    $repl->open_new_tab({ url => "http://www.google.co.jp/", selected => 1 });

    my $location;
    my $i;

    while ($i < 10) {
        $location = $repl->location({});
        last if ($location->{href} ne "about:blank");
        sleep(1);
        $i++;
    }

    my $links = $repl->linkextor({});

    ok(ref $links);
    ok(1);
}
