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
