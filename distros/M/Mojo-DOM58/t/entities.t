use strict;
use warnings;
use utf8;
use Test::More;
use Mojo::DOM58::Entities qw(html_attr_unescape html_escape html_unescape);
use Encode 'decode';

subtest 'html_unescape' => sub {
  is html_unescape('&#x3c;foo&#x3E;bar&lt;baz&gt;&#x0026;&#34;'),
    "<foo>bar<baz>&\"", 'right HTML unescaped result';
};

subtest 'html_unescape (special entities)' => sub {
  is html_unescape('foo &#x2603; &CounterClockwiseContourIntegral; bar &sup1baz'),
    "foo ☃ \x{2233} bar ¹baz", 'right HTML unescaped result';
};

subtest 'html_unescape (multi-character entity)' => sub {
  is html_unescape(decode 'UTF-8', '&acE;'), "\x{223e}\x{0333}",
    'right HTML unescaped result';
};

subtest 'html_unescape (invalid code points)' => sub {
  is html_unescape('&#0;'),             "\N{U+FFFD}",           'null character reference';
  is html_unescape('&#x0;'),            "\N{U+FFFD}",           'null character reference';
  is html_unescape('&#xD800;'),         "\N{U+FFFD}",           'leading surrogate';
  is html_unescape('&#xDBFF;'),         "\N{U+FFFD}",           'leading surrogate';
  is html_unescape('&#xDC00;'),         "\N{U+FFFD}",           'trailing surrogate';
  is html_unescape('&#xDFFF;'),         "\N{U+FFFD}",           'trailing surrogate';
  is html_unescape('&#55296;'),         "\N{U+FFFD}",           'surrogate in decimal';
  is html_unescape('&#1114112;'),       "\N{U+FFFD}",           'outside unicode range';
  is html_unescape('&#9999999;'),       "\N{U+FFFD}",           'outside unicode range';
  is html_unescape('&#xD83D;&#xDE00;'), "\N{U+FFFD}\N{U+FFFD}", 'surrogate pairs are not combined';
  is html_unescape('&#xD7FF;'),         "\N{U+D7FF}",           'below surrogate range';
  is html_unescape('&#xE000;'),         "\N{U+E000}",           'above surrogate range';
  is html_unescape('&#x10FFFF;'),       "\N{U+10FFFF}",         'noncharacters are preserved';
  is html_unescape('&#xFFFE;'),         "\N{U+FFFE}",           'noncharacters are preserved';
};

subtest 'html_unescape (windows-1252 remap)' => sub {
  is html_unescape('&#x80;'),  "\N{U+20AC}", 'euro sign';
  is html_unescape('&#128;'),  "\N{U+20AC}", 'euro sign in decimal';
  is html_unescape('&#0128;'), "\N{U+20AC}", 'euro sign with leading zero';
  is html_unescape('&#x93;'),  "\N{U+201C}", 'left double quotation mark';
  is html_unescape('&#x99;'),  "\N{U+2122}", 'trade mark sign';
  is html_unescape('&#x9F;'),  "\N{U+0178}", 'latin capital letter y with diaeresis';
  is html_unescape('&#x81;'),  "\N{U+81}",   'unmapped control is preserved';
  is html_unescape('&#x9D;'),  "\N{U+9D}",   'unmapped control is preserved';
  is html_unescape('&#x7F;'),  "\N{U+7F}",   'delete is not remapped';
  is html_unescape('&#xA0;'),  "\N{U+A0}",   'no-break space is not remapped';
};

subtest 'html_unescape (apos)' => sub {
  is html_unescape('foobar&apos;&lt;baz&gt;&#x26;&#34;'), "foobar'<baz>&\"",
    'right HTML unescaped result';
};

subtest 'html_unescape (nothing to unescape)' => sub {
  is html_unescape('foobar'), 'foobar', 'right HTML unescaped result';
};

subtest 'html_unescape (relaxed)' => sub {
  is html_unescape('&0&Ltf&amp&0oo&nbspba;&ltr'), "&0&Ltf&&0oo\x{00a0}ba;<r",
    'right HTML unescaped result';
};

subtest 'html_attr_unescape' => sub {
  is html_attr_unescape('/?foo&lt=bar'), '/?foo&lt=bar',
    'right HTML unescaped result';
  is html_attr_unescape('/?f&ltoo=bar'), '/?f&ltoo=bar',
    'right HTML unescaped result';
  is html_attr_unescape('/?f&lt-oo=bar'), '/?f<-oo=bar',
    'right HTML unescaped result';
  is html_attr_unescape('/?foo=&lt'), '/?foo=<', 'right HTML unescaped result';
  is html_attr_unescape('/?f&lt;oo=bar'), '/?f<oo=bar',
    'right HTML unescaped result';
};

subtest 'html_unescape (bengal numbers with nothing to unescape)' => sub {
  is html_unescape('&#০৩৯;&#x০৩৯;'), '&#০৩৯;&#x০৩৯;', 'no changes';
};

subtest 'html_unescape (UTF-8)' => sub {
  is html_unescape(decode 'UTF-8', 'foo&lt;baz&gt;&#x26;&#34;&OElig;&Foo;'),
    "foo<baz>&\"\x{152}&Foo;", 'right HTML unescaped result';
};

subtest 'html_escape' => sub {
  is html_escape(qq{la<f>\nbar"baz"'yada\n'&lt;la}),
    "la&lt;f&gt;\nbar&quot;baz&quot;&#39;yada\n&#39;&amp;lt;la",
    'right HTML escaped result';
};

subtest 'html_escape (UTF-8 with nothing to escape)' => sub {
  is html_escape('привет'), 'привет', 'right HTML escaped result';
};

subtest 'html_escape (UTF-8)' => sub {
  is html_escape('привет<foo>'), 'привет&lt;foo&gt;',
    'right HTML escaped result';
};

subtest 'Hide DATA usage from error messages' => sub {
  eval { die 'whatever' };
  unlike $@, qr/DATA/, 'DATA has been hidden';
};

done_testing;
