use Test::More;

use Mojo::DOM;

my $dom = Mojo::DOM->new('<div style="color:red;background-color:grey;font-size:12pt">some string</div>')->with_roles('+Style');

$\ = "\n";


ok($dom->at('div')->style eq $dom->at('div')->attr('style'), "check against attr");

ok($dom->at('div')->style eq "color:red;background-color:grey;font-size:12pt", 'string round trip');

ok($dom->at('div')->style->{color} eq  "red");

# deleted this - makes no sense
# ok($dom->at('div')->style->all_text eq  'some string');

ok($dom->at('div')->style('color') eq  "red");

done_testing()
