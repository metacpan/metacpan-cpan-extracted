use Test::Most;
use Mojo::DOM;

use strict;
use warnings;











my $tests = 14; # keep on line 17 for ,i (increment and ,d (decrement)
plan tests => $tests;
diag( "Running my tests" );

my $html = '<html><head></head><body><div><h1 id="one">foo</h1></div><div><div><h1 id="two">bar></h1></div></div><p class="first">A paragraph.</p><p class="last">boo<a>blah<span>kdj</span></a></p><h1>hi</h1></body></html>';

my $ex = Mojo::DOM->with_roles('+Analyzer')->new($html);

my $count = $ex->at('body')->element_count;
is $count, 10, 'gets element count';

my $tag = $ex->parent_ptags->tag;
is $tag, 'body', 'gets correct container tag for paragraphs';

my $tag1 = $ex->at('p.first');
my $tag2 = $ex->at('p.last');

my $result = $ex->compare($tag1, $tag2);
is $result, -1, 'can compare tags with function-like method';

$result = $tag1 cmp $tag2;
is $result, -1, 'can compare tags with operator';

$result = $tag2 cmp $tag1;
is $result, 1, 'gets correct results when comparing tags';

$result = $tag2 cmp $tag1;
is $result, 1, 'gets correct results when comparing tags';

is $ex->at('p.first')->compare('p.last'), -1, 'can compare with method operator';

my $depth = $ex->at('p.first')->depth;
is $depth, 3, 'gets depth';

my $deepest = $ex->deepest;
is $deepest, 5, 'gets deepest depth';

my $common = $ex->at('h1')->common('p');
is $common->tag, 'body', 'gets common ancestor with method-like call';

$common = $ex->common($tag1, $tag2);
is $common->tag, 'body', 'gets common ancestor with function-like call';

my $distance = $ex->at('p')->distance('a');
is $distance, 3, 'gets distance between nodes';

my $closest_up = $ex->at('p')->closest_up('h1');
is $closest_up->attr('id'), 'one', 'gets closest node going up DOM';

my $closest_down = $ex->at('h1')->closest_down('p');
is $closest_down->attr('class'), 'first', 'gets closest node going down DOM';
