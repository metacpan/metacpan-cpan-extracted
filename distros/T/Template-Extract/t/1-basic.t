#!/usr/bin/perl

use strict;
use Test::More tests => 16;

# TEST
use_ok('Template::Extract');

my ( $template, $document, $data );

my $obj = Template::Extract->new;
# TEST
isa_ok( $obj, 'Template::Extract' );

$template = << '.';
<ul>[% FOREACH record %]
<li><A HREF="[% url %]">[% title %]</A>: [% rating %] - [% comment %].
[% ... %]
[% END %]</ul>
.

$document = << '.';
<html><head><title>Great links</title></head><body>
<ul><li><A HREF="http://slashdot.org">News for nerds.</A>: A+ - nice.
this text is ignored.</li>
<li><A HREF="http://microsoft.com">Where do you want...</A>: Z! - yeah.
this text is ignored, too.</li></ul>
.

$data = Template::Extract->new->extract( $template, $document );

# TEST
is_deeply(
    $data,
    {
        'record' => [
            {
                'rating'  => 'A+',
                'comment' => 'nice',
                'url'     => 'http://slashdot.org',
                'title'   => 'News for nerds.',
            },
            {
                'rating'  => 'Z!',
                'comment' => 'yeah',
                'url'     => 'http://microsoft.com',
                'title'   => 'Where do you want...',
            }
        ]
    },
    'synopsis'
);

$template = << '.';
<!-- BEGIN -->
[% FOREACH record %]
<[% /\w/ %]>[% para %]</[% /\w/ %]>
[% END %]
<!-- END -->
.

$document = << '.';
<!-- BEGIN -->
<p>hello</p>
<q>world</q>
<r>, how are you?</r>
<!-- END -->
.

$data = Template::Extract->new->extract( $template, $document );

# TEST
is_deeply(
    $data,
    { record => [ map { { para => $_ } } 'hello', 'world', ', how are you?' ] },
    'implicit newlines with regex tags'
);

$template = << '.';
[% FOREACH subject %]
[% ... %]
<h1>[% sub.heading %]</h1>
<ul>[% FOREACH record %]
<li><A HREF="[% url %]">[% title %]</A>: [% rating %] - [% comment %].
[% ... %]
[% END %]</ul>
[% ... %]
[% END %]
<ol>[% FOREACH record %]
<li><A HREF="[% url %]">[% title %]</A>: [% rating %] - [% comment %].
[% ... %]
[% END %]</ol>
.

$document = << '.';
<html><head><title>Great links</title></head><body>
<h1>Foo</h1>
<ul><li><A HREF="http://slashdot.org">News for nerds.</A>: A+ - nice.
this text is ignored.</li>
<li><A HREF="http://microsoft.com">Where do you want...</A>: Z! - yeah.
this text is ignored, too.</li></ul>
<h1>Bar</h1>
<ul><li><A HREF="http://slashdot.org">News for nerds.</A>: A+ - nice.
this text is ignored.</li>
<li><A HREF="http://microsoft.com">Where do you want...</A>: Z! - yeah.
this text is ignored, too.</li></ul>
<ol><li><A HREF="http://cpan.org">CPAN.</A>: +++++ - cool.
this text is ignored, also.</li></ol>
.

$data = Template::Extract->new->extract( $template, $document );

# TEST
is_deeply(
    $data,
    {
        'record' => [
            {
                'rating'  => '+++++',
                'comment' => 'cool',
                'url'     => 'http://cpan.org',
                'title'   => 'CPAN.',
            }
        ],
        'subject' => [
            map {
                {
                    'sub'    => { 'heading' => $_ },
                    'record' => [
                        {
                            'rating'  => 'A+',
                            'comment' => 'nice',
                            'url'     => 'http://slashdot.org',
                            'title'   => 'News for nerds.',
                        },
                        {
                            'rating'  => 'Z!',
                            'comment' => 'yeah',
                            'url'     => 'http://microsoft.com',
                            'title'   => 'Where do you want...',
                        }
                    ]
                }
              } qw(Foo Bar)
        ],
    },
    'two nested and one extra FOREACH'
);

$template = << '.';
_[% C %][% D %]_
_[% D %][% E %]_
_[% E %][% D %][% C %]_
.

$document = << '.';
_doeray_
_rayme_
_meraydoe_
.

$data = Template::Extract->new->extract( $template, $document );

# TEST
is_deeply(
    $data,
    {
        'C' => 'doe',
        'D' => 'ray',
        'E' => 'me',
    },
    'backtracking'
);

my $ext_data = { F => 'fa' };
$data = Template::Extract->new->extract( $template, $document, $ext_data );

# TEST
is_deeply(
    $data,
    {
        'C' => 'doe',
        'D' => 'ray',
        'E' => 'me',
        'F' => 'fa',
    },
    'external data'
);

# TEST
is_deeply( $data, $ext_data, 'ext_data should be the same as data' );

$template = << '.';
[% FOREACH entry %]
[% ... %]
<div>[% FOREACH title %]<i>[% title_text %]</i>[% END %]<br>[% content %]</div>
  ([% FOREACH comment %][% SET sub.comment = 1 %]<b>[% comment_text %]</b> |[% END %]Comment on this)
[% END %]
.

$document = << '.';
<div><i>Title 1</i><i>Title 1.a</i><br>xxx</div>
  (<b>1 Comment</b> |Comment on this)
<div><i>Title 2</i><br>foo</div>
  (Comment on this)
.

$data = Template::Extract->new->extract( $template, $document );

# TEST
is_deeply(
    $data,
    {
        'entry' => [
            {
                'comment' => [
                    {
                        'comment_text' => '1 Comment',
                        'sub'          => { 'comment' => 1 },
                    }
                ],
                'content' => 'xxx',
                'title'   => [
                    { 'title_text' => 'Title 1', },
                    { 'title_text' => 'Title 1.a', }
                ],
            },
            {
                'content' => 'foo',
                'title'   => [ { 'title_text' => 'Title 2', } ],
            }
        ],
    },
    'two FOREACHs nested inside a FOREACH'
);

$template = << '.';
[% FOREACH top %][% FOREACH foo %][% SET bar.x = "set" %]<[% baz.y %]|[% qux.z %]>[% END %][% END %]
.

$document = << '.';
<test1|1><test2|2><test3
.

$data = Template::Extract->new->extract( $template, $document );

# TEST
is_deeply(
    $data,
    {
        top => [
            {
                foo => [
                    {
                        bar => { x => 'set' },
                        baz => { y => 'test1' },
                        qux => { z => '1' },
                    },
                    {
                        bar => { x => 'set' },
                        baz => { y => 'test2' },
                        qux => { z => '2' },
                    }
                ]
            }
        ]
    },
    'SET directive inside two FOREACHs'
);

$template = "[% FOREACH item %]hello [% foo %]<br>[% END %]";
$document = " hello name<br>";

$data = Template::Extract->new->extract( $template, $document );

# TEST
is_deeply( $data, { item => [ { foo => 'name' } ] }, 'extra prepended data' );

$Template::Extract::EXACT = 1;
$data = Template::Extract->new->extract( $template, $document );

# TEST
is( $data, undef, 'partial match when $EXACT == 1 should fail' );

$Template::Extract::EXACT = 0;

$template = '[% year %]-[% month %]-[% day %]';
$document = '2004-12-17';

$data = Template::Extract->new->extract( $template, $document );

# TEST
is_deeply( $data, { year => 2004, month => 12, day => 17 }, 'trailing match' );

$template = '<%year>-<%month>-<%day>';
$document = '2004-12-17';

$data =
  Template::Extract->new( { TAG_STYLE => 'mason' } )
  ->extract( $template, $document );

# TEST
is_deeply(
    $data,
    { year => 2004, month => 12, day => 17 },
    'change of TAG_STYLE'
);

$document = << '.';
<h2></h2>
<h2>hello</h2>
.

$template = '<h2>[% d =~ /((?!<h2|<\/h2).+?)/ %]</h2>';

$data = Template::Extract->new->extract( $template, $document );

# TEST
is_deeply( $data, { d => 'hello' }, 'capturing regex' );

$document = << '.';
<p>hello</p>
<p>42</p>
.

$template = '<p>[% a.b =~ /(\d+)/ %]</p>';

$data = Template::Extract->new->extract( $template, $document );

# TEST
is_deeply( $data, { a => { b => '42' }}, 'structured var with capturing regex' );
