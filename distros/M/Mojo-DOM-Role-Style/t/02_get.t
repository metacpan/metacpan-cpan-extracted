use Test::More tests => 5;

use Mojo::DOM;

my $dom = Mojo::DOM->new('<div style="color:red;background-color:grey;font-size:12pt">some string</div>')->with_roles('+Style');

$\ = "\n";


ok($dom->at('div')->style eq  $dom->at('div')->attr('style'));

ok($dom->at('div')->style eq  "color:red;background-color:grey;font-size:12pt", 'string round trip');

ok($dom->at('div')->style->{color} eq  "red");

ok($dom->at('div')->style->all_text eq  'some string');

ok($dom->at('div')->style('color') eq  "red");
