use Test::Most;
use Mojo::DOM;

use strict;
use warnings;











my $tests = 8; # keep on line 17 for ,i (increment and ,d (decrement)
my $skip_most = 0;
plan tests => $tests;
diag( "Running my tests" );

my $html = '<div><p class="booboo">hi</p></div>';


my $ex = Mojo::DOM->with_roles('+Analyzer')->new($html);


my $res = $ex->find('p')->common;#my $res = $ex->find('p')->common;
is $res->tag, 'div', 'gets correct container tag for all paragraphs';

$html = '<body><div class="first"><p class="p1">hi</p></div><p class="p2">fun</p></body>';
$ex = Mojo::DOM->with_roles('+Analyzer')->new($html);

$res = $ex->find('p')->common->tag;
is $res, 'body', 'gets correct container tag for all paragraphs';

$res = $ex->at('div.first')->find('p')->common;
is $res->attr('class'), 'first', 'gets correct containter tag for object with selector';

$res = $ex->at('div.first')->common;
is $res->tag, 'body', 'gets correct container tag with "at" syntax';

my $class = $ex->at('p.p1')->common('p.p2');
is $class->tag, 'body', 'gets correct container tag for two p tag nodes';

my $tag1 = $ex->at('p.p1');
my $tag2 = $ex->at('p.p2');

my $common = $ex->common($tag1, $tag2);
is $common->tag, 'body', 'gets common ancestor with function-like call';

$html = '<html><head></head>
             <body id="body">
                  <div><h1 id="one">foo</h1></div>
                  <div><div class="container"><h1 id="two">bar</h1><p class="top">nested paragraph</p></div></div>
                  <p class="first">A paragraph.</p>
                  <p class="last">boo<a>blah<span>kdj</span></a></p>
                  <h1>hi</h1>
             </body></html>';

$ex = Mojo::DOM->with_roles('+Analyzer')->new($html);

$common = $ex->at('h1#two')->common('p.top');
is $common->attr('class'), 'container', 'gets common ancestor with method-like call';

my @analysis = $ex->tag_analysis('p');
my $result =
        [
  {
    'all_tags_have_same_depth' => 0,
    'top_level' => 1,
    'classes' => {
                   'first' => 1,
                   'last' => 1,
                   'top' => 1
                 },
    'direct_children' => 2,
    'avg_tag_depth' => '3.667',
    'selector' => 'html:nth-child(1) > body:nth-child(2)',
    'size' => 3
  },
  {
    'all_tags_have_same_depth' => 1,
    'direct_children' => 0,
    'classes' => {
                   'top' => 1
                 },
    'avg_tag_depth' => '5',
    'selector' => 'html:nth-child(1) > body:nth-child(2) > div:nth-child(2)',
    'size' => 1
  }
];

is_deeply (\@analysis, $result, 'gets correct tag analysis result');
