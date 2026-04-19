use Test::More tests => 2;

use Mojo::DOM;

my $dom = Mojo::DOM->new('<div style="color:red;background-color:grey;font-size:12pt">some string</div>')->with_roles('+Style');

$\ = "\n";

ok($dom->at('div')->style->{color} eq 'red', 'parse');

$dom->at('div')->style->{color} = 'blue';

ok($dom->at('div')->style->{color} eq 'red', 'set from hash');


print $dom;


