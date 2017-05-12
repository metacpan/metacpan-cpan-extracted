use Test::More tests => 10;
use Parse::BBCode;
use strict;
use warnings;

my $p = Parse::BBCode->new({
        tags => {
            Parse::BBCode::HTML->defaults,
            wikipedia => {
                short => 1,
                output => '<a href="http://wikipedia/?search=%{uri}A">%{parse}s</a>',
                class => 'url',
                classic => 0,
            },
            thread => {
                class => 'url',
                output => 'Thread: %s (%A)',
                short => 1,
                classic => 1,
            },
            doc => {
                class => 'url',
                output => qq{%{uri}A.html:%s},
                short => 1,
                classic => 1,
            },
        },
    }
);
my @tests = (
    [ qq#test [wikipedia://Harold & Maude|Movie] end#,
        q#test <a href="http://wikipedia/?search=Harold%20%26%20Maude">Movie</a> end# ],
    [ qq#[b]test [wikipedia://Harold & Maude|Movie] end[/b]#,
        q#<b>test <a href="http://wikipedia/?search=Harold%20%26%20Maude">Movie</a> end</b># ],
    [ qq#[url=http://perl.org/]test [wikipedia://Harold & Maude|Movie] end[/url]#,
        q#<a href="http://perl.org/" rel="nofollow">test [wikipedia://Harold &amp; Maude|Movie] end</a># ],
    [ qq#test [wikipedia://Harold & Maude end#,
        q#test [wikipedia://Harold &amp; Maude end# ],
    [ qq#test [thread://1] test [thread]1[/thread] end#,
        q#test Thread: 1 (1) test Thread: 1 (1) end# ],
    [ qq#test [thread://1|title <hr>] test [thread=1]title <hr>[/thread] end#,
        q#test Thread: title &lt;hr&gt; (1) test Thread: title &lt;hr&gt; (1) end# ],
    [ qq#test [thread://] end#,
        q#test [thread://] end# ],
    [ qq#[b]test[/b] [thread://1] [i]end[/i]#,
        q#<b>test</b> Thread: 1 (1) <i>end</i># ],
    [ qq#[b]test[/b] [thread=1]test[/thread] [thread://1] [i]end[/i]#,
        q#<b>test</b> Thread: test (1) Thread: 1 (1) <i>end</i># ],
    [ qq#[doc=perlipc]ipc[/doc] [doc://perlipc]#,
        q#perlipc.html:ipc perlipc.html:perlipc# ],
);
for my $test (@tests) {
    my ($text, $exp, $forbid, $parser) = @$test;
    $parser ||= $p;
    if ($forbid) {
        $parser->forbid($forbid);
    }
    my $parsed = $parser->render($text);
    #warn __PACKAGE__.':'.__LINE__.": $parsed\n";
    s/[\r\n]//g for ($exp, $parsed);
    $text =~ s/[\r\n]//g;
    cmp_ok($parsed, 'eq', $exp, "parse '$text'");
}



