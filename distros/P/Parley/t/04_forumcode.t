#!/usr/bin/perl
use strict;
use warnings;

my @forum_tests;

BEGIN {
    # a list of tests for forumcode()
    @forum_tests = (
        # escaped HTML stuff
        {
            in  => '<b>foo</b> &',
            out => '&lt;b&gt;foo&lt;/b&gt; &amp;',
        },
        {
            in  => '#FF0000',
            out => '#FF0000',
        },
        {
            in  => '1 + 2',
            out => '1 + 2',
        },

        ## BOLD
        # [b] tag
        {
            in  => '[b]foo[/b]',
            out => '<b>foo</b>',
        },
        {
            in  => '[b]foo',
            out => '[b]foo',
        },
        # **foo** bold magic
        {
            in  => '**foo**',
            out => '<b>foo</b>',
        },
        # replace all bold tags
        {
            in  => '[b]foo[/b][b]bar[/b]**baz****quux**',
            out => '<b>foo</b><b>bar</b><b>baz</b><b>quux</b>',
        },

        ## UNDERLINE
        # [u] tag
        {
            in  => '[u]foo[/u]',
            out => '<u>foo</u>',
        },
        # __foo__ underline magic
        {
            in  => '__foo__',
            out => '<u>foo</u>',
        },
        # replace all underline tags
        {
            in  => '[u]foo[/u][u]bar[/u]__baz____quux__',
            out => '<u>foo</u><u>bar</u><u>baz</u><u>quux</u>',
        },

        ## ITALIC
        # [i] tag
        {
            in  => '[i]foo[/i]',
            out => '<i>foo</i>',
        },
#        # //foo// italic magic
#        {
#            in  => '//foo//',
#            out => '<i>foo</i>',
#        },
        # replace all italic tags
        {
            in  => '[i]foo[/i][i]bar[/i]//baz////quux//',
            out => '<i>foo</i><i>bar</i>//baz////quux//',
            #out => '<i>foo</i><i>bar</i><i>baz</i><i>quux</i>',
        },

        # link testing
        {
            in  => '[url]http://www.google.com/[/url]',
            out => '<a href="http://www.google.com/">http://www.google.com/</a>',
        },
        {
            in  => '[url name="Google"]http://www.google.com/[/url]',
            out => '<a href="http://www.google.com/">Google</a>',
        },
        {
            in  => '[url name="Google" ]http://www.google.com/[/url]',
            out => '<a href="http://www.google.com/">Google</a>',
        },
        {
            in  => '[URL="http://www.google.com/"]Google[/URL]',
            out => '<a href="http://www.google.com/">Google</a>',
        },

        # let people put odd stuff in the name if they really want
        {
            in  => '[url name=""""]X[/url]',
            out => '<a href="X">&quot;&quot;</a>',
        },

        # not proper URL tags
        {
            in  => '[url name="]X[/url]',
            out => '[url name=&quot;]X[/url]',
        },
        {
            in  => '[url name=]X[/url]',
            out => '[url name=]X[/url]',
        },
        # nothing between opening and closing tags
        {
            in  => '[url][/url]',
            out => '[url][/url]',
        },

        # bold in the URL name ..
        {
            in  => '[url name="[b]Bold[/b]"]X[/url]',
            out => '<a href="X"><b>Bold</b></a>',
        },

        # url with query params ...
        # surprisingly the escaped query-string seems to be dealt with
        # correctly (in forefox at least)
        {
            in      => '[url name="X"]http://google.com?q=Foo&something=Bar[/url]',
            out     => '<a href="http://google.com?q=Foo&amp;something=Bar">X</a>',
            diag    => 'Test this URL in browsers!',
        },

        # image tag
        {
            in  => '[img]http://somewhere.com/myImage.jpg[/img]',
            out => '<img src="http://somewhere.com/myImage.jpg" />',
        },
        {
            in      => q{[img alt='Foo']http://somewhere.com/myImage.jpg[/img]},
            out     => q{<img src="http://somewhere.com/myImage.jpg" alt='Foo' />},
            diag    => 'Test this URL in browsers!',
        },
        {
            in      => q{[img alt="Foo"]http://somewhere.com/myImage.jpg[/img]},
            out     => q{<img src="http://somewhere.com/myImage.jpg" alt="Foo" />},
            diag    => 'Test this URL in browsers!',
        },
        # explosm / cyanide style
        {
            in      => q{[IMG]http://www.flashasylum.com/db/files/Comics/Rob/luckyunderwear.png[/IMG]},
            out     => q{<img src="http://www.flashasylum.com/db/files/Comics/Rob/luckyunderwear.png" />},
        },

        {
            in      =>q{One:
[img]http://localhost:3000/static/images/btn_88x31_powered.png[/img]
And another:
[img]http://localhost:3000/static/images/btn_88x31_powered.png[/img]},
            out     => q{One:<br /><img src="http://localhost:3000/static/images/btn_88x31_powered.png" /><br />And another:<br /><img src="http://localhost:3000/static/images/btn_88x31_powered.png" />},
        },


        # colouring
        {
            in      => q{[colour=red]Red Text[/colour]},
            out     => q{<span style="color: red">Red Text</span>},
        },
        {
            in      => q{[colour=#FF0000]Red Text[/colour]},
            out     => q{<span style="color: #FF0000">Red Text</span>},
        },
        {
            in      => q{[colour=#F00]Red Text[/colour]},
            out     => q{<span style="color: #F00">Red Text</span>},
        },
        {
            in      => q{[colour=OrAnge]OrAnge Text[/colour]},
            out     => q{<span style="color: OrAnge">OrAnge Text</span>},
        },
        # coloring - for the Merkins
        {
            in      => q{[color=red]Red Text[/color]},
            out     => q{<span style="color: red">Red Text</span>},
        },
        {
            in      => q{[color=#FF0000]Red Text[/color]},
            out     => q{<span style="color: #FF0000">Red Text</span>},
        },
        {
            in      => q{[color=#F00]Red Text[/color]},
            out     => q{<span style="color: #F00">Red Text</span>},
        },
        {
            in      => q{[color=OrAnge]OrAnge Text[/color]},
            out     => q{<span style="color: OrAnge">OrAnge Text</span>},
        },


        # lists
        # unordered
        {
            in      => q{[list]
            [*]Red
            [*]Blue
            [*]Yellow
            [/list]},
            out     => q{<ul><li>Red</li><li>Blue</li><li>Yellow</li></ul>},
        },
        # ordered
        {
            in      => q{[list]
            [1]Red
            [1]Blue
            [1]Yellow
            [/list]},
            out     => q{<ol><li>Red</li><li>Blue</li><li>Yellow</li></ol>},
        },

        # 'code' style
        {
            in      => q{[code]#!/usr/bin/env perl[/code]},
            out     => q{<div class="forumcode_code">#!/usr/bin/env perl</div>},
        },
        #{<div class="forumcode_$1"><div class="forumcode_quoting">$2</div>$3</div>}xmsg;
        {
            in      => q{[quote quoting="Joe"]quote markup test[/quote]},
            out     => q{<div class="forumcode_quote"><div class="forumcode_quoting">Quoting Joe:</div>quote markup test</div>},
        },


        # Cyanide Comic (explosm.com) forum-code
        {
            in      => q{[URL="http://www.explosm.net/comics/1393/"][IMG]http://www.flashasylum.com/db/files/Comics/Rob/luckyunderwear.png[/IMG][/URL]},
            out     => q{<a href="http://www.explosm.net/comics/1393/"><img src="http://www.flashasylum.com/db/files/Comics/Rob/luckyunderwear.png" /></a>},
        },
    );

    # test count is a fixed number of tests + the length of the @tests array
    use Test::More;
    plan tests => ( 3 + scalar(@forum_tests) );

    use_ok( 'Template::Plugin::ForumCode' );
};

# create a new thingy
my $tt_forum = Template::Plugin::ForumCode->new();
isnt(undef, $tt_forum, 'Plugin object is defined');
isa_ok($tt_forum, 'Template::Plugin::ForumCode');

# now some formatting tests for forumcode()
foreach my $test (@forum_tests) {
    my $text = $tt_forum->forumcode($test->{in});
    if (defined $test->{diag}) {
        diag("$test->{out} - $test->{diag}");
    }
    is($text, $test->{out}, qq{forumcode('$test->{in}')});
}
