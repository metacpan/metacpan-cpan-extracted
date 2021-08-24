#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/sGsOIv/10
my $tests = 
[
    {
        link_all  => "[URL](/url/)",
        link_name => "URL",
        link_url  => "/url/",
        test => q{Just a [URL](/url/).},
    },
    {
        link_all => "[URL and title](/url/ \"title\")",
        link_name => "URL and title",
        link_title => "title",
        link_title_container => "\"",
        link_url => "/url/",
        test => q{[URL and title](/url/ "title").},
    },
    {
        link_all => "[URL and title](/url/  \"title preceded by two spaces\")",
        link_name => "URL and title",
        link_title => "title preceded by two spaces",
        link_title_container => "\"",
        link_url => "/url/",
        test => q{[URL and title](/url/  "title preceded by two spaces").},
    },
    {
        link_all => "[URL and title](/url/\t\"title preceded by a tab\")",
        link_name => "URL and title",
        link_title => "title preceded by a tab",
        link_title_container => "\"",
        link_url => "/url/",
        test => q{[URL and title](/url/	"title preceded by a tab").},
    },
    {
        link_all => "[URL and title](/url/ \"title has spaces afterward\"  )",
        link_name => "URL and title",
        link_title => "title has spaces afterward",
        link_title_container => "\"",
        link_url => "/url/",
        test => q{[URL and title](/url/ "title has spaces afterward"  ).},
    },
    {
        link_all  => "[Empty]()",
        link_name => "Empty",
        link_url  => "",
        test => q{[Empty]().},
    },
    {
        link_all  => "[bar] [1]",
        link_id   => 1,
        link_name => "bar",
        test => q{[Foo [bar] [1].},
    },
    {
        link_all  => "[bar][1]",
        link_id   => 1,
        link_name => "bar",
        test => q{Foo [bar][1].},
    },
    {
        fail => 1,
        test => q{Foo [bar]},
    },
    {
        fail => 1,
        test => q{With [embedded [brackets]] [b].},
    },
    {
        link_all  => "[embedded \\[brackets\\]] [b]",
        link_id   => "b",
        link_name => "embedded \\[brackets\\]",
        test => q{With [embedded \[brackets\]] [b].},
    },
    {
        link_all  => "[this] [this]",
        link_id   => "this",
        link_name => "this",
        test => q{[this] [this] should work},
    },
    {
        link_all  => "[this][this]",
        link_id   => "this",
        link_name => "this",
        test => q{So should [this][this].},
    },
    {
        link_all  => "[this] []",
        link_id   => "",
        link_name => "this",
        test => q{And [this] [].},
    },
    {
        link_all  => "[this][]",
        link_id   => "",
        link_name => "this",
        test => q{[Something in brackets like [this][] should work]},
    },
    {
        fail => 1,
        test => q{[Same with [this].][]},
    },
    {
        link_all  => "[Same with \\[this\\].][]",
        link_id   => "",
        link_name => "Same with \\[this\\].",
        test => q{[Same with \[this\].][]},
    },
    {
        link_all  => "[this](/somethingelse/)",
        link_name => "this",
        link_url  => "/somethingelse/",
        test => q{In this case, [this](/somethingelse/) points to something else.},
    },
    {
        fail => 1,
        test => q{Backslashing should suppress \[this] and [this\].},
    },
    {
        link_all  => "[line\nbreak][]",
        link_id   => "",
        link_name => "line\nbreak",
        test => <<EOT
This one has a [line
break][].
EOT
    },
    {
        fail => 1,
        name => q{Not matching image},
        test => q{![Alt text](/path/to/img.jpg)},
    },
    {
        fail => 1,
        name => q{Not matching when escaped},
        test => q{\[Alt text](/path/to/img.jpg)},
    },
];

my $tests_auto =
[
    {
        link_all  => "<http://example.com/>",
        link_http => "http://example.com/",
        link_url  => "http://example.com/",
        test => q{Link: <http://example.com/>.},
    },
    {
        link_all  => "<http://example.com/?foo=1&bar=2>",
        link_http => "http://example.com/?foo=1&bar=2",
        link_url  => "http://example.com/?foo=1&bar=2",
        name => "With query string",
        test => q{With an ampersand: <http://example.com/?foo=1&bar=2>},
    },
    {
        link_all => "<!#\$%&'*+-/=?^_`.{|}~\@example.com>",
        link_mailto => "!#\$%&'*+-/=?^_`.{|}~\@example.com",
        link_url => "!#\$%&'*+-/=?^_`.{|}~\@example.com",
        test => q{<!#$%&'*+-/=?^_`.{|}~@example.com>},
    },
    {
        link_all => "<\"abc\@def\"\@example.com>",
        link_mailto => "\"abc\@def\"\@example.com",
        link_url => "\"abc\@def\"\@example.com",
        test => q{<"abc@def"@example.com>},
    },
    {
        link_all => "<jsmith\@[192.0.2.1]>",
        link_mailto => "jsmith\@[192.0.2.1]",
        link_url => "jsmith\@[192.0.2.1]",
        test => q{<jsmith@[192.0.2.1]>},
    },
    {
        link_all  => "<file:///Volume/User/john/Document/form.rtf>",
        link_file => "file:///Volume/User/john/Document/form.rtf",
        link_url  => "file:///Volume/User/john/Document/form.rtf",
        test => q{<file:///Volume/User/john/Document/form.rtf>},
    },
    {
        link_all  => "<news:alt.fr.perl>",
        link_news => "news:alt.fr.perl",
        link_url  => "news:alt.fr.perl",
        test => q{<news:alt.fr.perl>},
    },
    {
        link_all => "<ftp://ftp.example.com/plop/>",
        link_ftp => "ftp://ftp.example.com/plop/",
        link_url => "ftp://ftp.example.com/plop/",
        test => q{<ftp://ftp.example.com/plop/>},
    },
    {
        link_all => "<+81-90-1234-5678>",
        link_tel => "+81-90-1234-5678",
        link_url => "+81-90-1234-5678",
        test => q{<+81-90-1234-5678>},
    },
    {
        link_all => "<tel:5678-1234;phone-context=+81-3>",
        link_tel => "tel:5678-1234;phone-context=+81-3",
        link_url => "tel:5678-1234;phone-context=+81-3",
        test => q{<tel:5678-1234;phone-context=+81-3>},
    },
    {
        link_all => "<03-5678-1234>",
        link_tel => "03-5678-1234",
        link_url => "03-5678-1234",
        test => q{<03-5678-1234>},
    },
    {
        link_all => "<+1-800-LAWYERS>",
        link_tel => "+1-800-LAWYERS",
        link_url => "+1-800-LAWYERS",
        test => q{<+1-800-LAWYERS>},
    },
];

## https://regex101.com/r/edg2F7/2/tests
my $test_def =
[
    {
        link_all => "[1]: /url/  \"Title\"",
        link_id => 1,
        link_title => "Title",
        link_title_container => "\"",
        link_url => "/url/",
        test => q{[1]: /url/  "Title"},
    },
    {
        link_all   => "[refid]: /path/to/something (Title)",
        link_id    => "refid",
        link_title => "Title",
        link_url   => "/path/to/something",
        test => q{[refid]: /path/to/something (Title)},
    },
    {
        link_all => "[b]: /url/",
        link_id  => "b",
        link_url => "/url/",
        test => q{[b]: /url/},
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{Link},
    type => 'Link',
});

run_tests( $tests_auto,
{
    debug => 1,
    re => $RE{Markdown}{LinkAuto},
    type => 'Link auto',
});

run_tests( $test_def,
{
    debug => 1,
    re => $RE{Markdown}{LinkDefinition},
    type => 'Link definition',
});
