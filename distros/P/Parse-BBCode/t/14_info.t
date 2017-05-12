use Test::More tests => 16;
use Parse::BBCode;
use strict;
use warnings;

eval {
    require
        URI::Find;
};
my $uri_find = $@ ? 0 : 1;

SKIP: {
    skip "no URI::Find", 9 unless $uri_find;

    my $url_finder_1 = {
        max_length => 10,
        format => '<a href="%s" rel="nofollow">%s</a>',
    };
    # really really simple url finder just for PoC
    my $url_finder_2 = sub {
        my ($ref_content, $post, $info) = @_;
        my $out = '';
        while ($$ref_content =~ s{(.*)?\b(http://[^<>'" ]+)}{}g) {
            $out .= $post->("$1") . "<$2>";
        }
        $out .= $post->($$ref_content);
        $$ref_content = $out;
    };
    my $post = sub {
        my ($text, $info) = @_;
        my $out = '';
        while ($text =~ s/(.*)( |^)(:\))(?= |$)//mgs) {
            my ($pre, $sp, $smiley) = ($1, $2, $3);
            $out .= Parse::BBCode::escape_html($pre) . $sp . '*smile*';
        }
        $out .= Parse::BBCode::escape_html($text);
        return $out;
    };
    my @tests = (
        [ q#[url]http://foo/[/url]#,
            q#<a href="http://foo/" rel="nofollow">http://foo/</a>#, $url_finder_1 ],
        [ q#[url=http://foo/]<hr>[/url]#,
            q#<a href="http://foo/" rel="nofollow">&lt;hr&gt;</a>#, $url_finder_1 ],
        [ qq#http://foo/\ntest#,
            qq#<a href="http://foo/" rel="nofollow">http://foo/</a>\ntest#, 1, undef, 0],
        [ q#<hr> http://foo/#,
            qq#&lt;hr&gt; <http://foo/>#, $url_finder_2],
        [ q#http://foo/#,
            qq#<a href="http://foo/" rel="nofollow">http://foo...</a>#, $url_finder_1 ],
        [ q#[url=http://foo/] :) [/url] :)#,
            q#<a href="http://foo/" rel="nofollow"> *smile* </a> *smile*#, $url_finder_1, $post ],
        [ q#[url=http://foo/] :) [/url] :)#,
            q#<a href="http://foo/" rel="nofollow"> *smile* </a> *smile*#, 0, $post ],
        [ qq#[url=http://foo/] :) [/url]\n :)#,
            qq#<a href="http://foo/" rel="nofollow"> *smile* </a>\n *smile*#, 0, $post, 0 ],
        [ qq#[url=http://foo/] :) [/url]\n :)#,
            qq#<a href="http://foo/" rel="nofollow"> *smile* </a><br>\n *smile*#, 0, $post, 1 ],
    );
    for my $test (@tests) {
        my ($text, $exp, $url_finder, $post, $linebreaks) = @$test;
        unless (defined $linebreaks) {
            $linebreaks = 1;
        }
        my $p = Parse::BBCode->new({                                                              
                url_finder => $url_finder,
                text_processor => $post,
                linebreaks => $linebreaks,
                tags => {
                    'url'   => 'url:<a href="%{link}A" rel="nofollow">%s</a>',
                },
            }
        );

        my $title = ref $url_finder ? 'http://foo...' : 'http://foo/';
        my $parsed = $p->render($text);
        #warn __PACKAGE__.':'.__LINE__.": $parsed\n";
        #s/[\r\n]//g for ($exp, $parsed);
        $text =~ s/\r/\\r/g;
        $text =~ s/\n/\\n/g;
        cmp_ok($parsed, 'eq', $exp, "parse '$text'");
    }

}

my $p = Parse::BBCode->new({                                                              
        tags => {
            'list'  => {
                parse => 1,
                class => 'block',
                code => sub {
                    my ($parser, $attr, $content, $attribute_fallback, $tag, $info) = @_;
                    $$content =~ s/^\n+//;
                    $$content =~ s/\n+\z//;
                    return "<ul>$$content</ul>";
                },
            },
            '*' => {
                parse => 1,
                code => sub {
                    my ($parser, $attr, $content, $attribute_fallback, $tag, $info) = @_;
                    $$content =~ s/\n+\z//;
                    $$content = "<li>$$content</li>";
                    unless ($info->{stack}->[-2] eq 'list') {
                        return $tag->raw_text;
                    }
                    return $$content;
                },
                close => 0,
                class => 'block',
            },
            'quote' => 'block:<blockquote>%{html}a:%s</blockquote>',

        },
    }
);
my @tests = (
    [ qq#[list]\n[*]1\n[*]2\n[/list]#,
        q#<ul><li>1</li><li>2</li></ul># ],
    [ q#[quote][*]1[*]2[/quote]#,
        q#<blockquote>:[*]1[*]2</blockquote># ],
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

$p = Parse::BBCode->new();
my $bbcode = q#start [b]1[/b][b]2[b]3[/b][b]4[/b] [b]5 [b]6[/b] [/b] [/b]#;
my $tree = $p->parse($bbcode);
my $tag = $tree->get_content->[3]->get_content->[1];
my $num = $tag->get_num;
my $level = $tag->get_level;
cmp_ok($num, '==', 3, "get_num");
cmp_ok($level, '==', 2, "get_level");

$p = Parse::BBCode->new({
    tags => {
        code => {
            code => sub {
                my ($parser, $attr, $content, $attribute_fallback, $tag, $info) = @_;
                my $title = Parse::BBCode::escape_html($attr);
                my $code = Parse::BBCode::escape_html($$content);
                my $aid = $parser->get_params->{article_id};
                my $cid = $tag->get_num;
                return <<"EOM";
<code_header><a href="code?article_id=$aid;code_id=$cid">Download</a></code_header>
<code_body>$code</code_body>

EOM
            },
        },
    },
});
$bbcode = "[code=1]test[/code]";
my $rendered = $p->render($bbcode, { article_id => 23 });
cmp_ok($rendered, '=~', 'code\?article_id=23;code_id=1', "params");

$p = Parse::BBCode->new({
        smileys => {
            icons       => {qw/ :-) smile.png :-( sad.png :-P tongue.gif :-'| cold.png /},
            base_url    => '/icons/',
            # sprintf format
            format      => '<img alt="%2$s" src="%1$s">',
        },
        text_processor => sub {
            my ($text) = @_;
            $text = uc $text;
            return Parse::BBCode::escape_html($text);
        },
    });
@tests = (
    [ qq#:-)[b]bold<hr> :-)[/b] :-(\n:-P :-'|\ntest:-P end#,
        qq#<img alt=":-)" src="/icons/smile.png"><b>BOLD&lt;HR&gt; <img alt=":-)" src="/icons/smile.png"></b> <img alt=":-(" src="/icons/sad.png"><br>\n<img alt=":-P" src="/icons/tongue.gif"> <img alt=":-&\#39;|" src="/icons/cold.png"><br>\nTEST:-P END# ],
    [q#:-) :-)#,
        q#<img alt=":-)" src="/icons/smile.png"> <img alt=":-)" src="/icons/smile.png">#],
);
for my $test (@tests) {
    my ($text, $exp) = @$test;
    my $parsed = $p->render($text);
    #warn __PACKAGE__.':'.__LINE__.": $parsed\n";
    $text =~ s/\r/\\r/g;
    $text =~ s/\n/\\n/g;
    cmp_ok($parsed, 'eq', $exp, "parse '$text'");
}


