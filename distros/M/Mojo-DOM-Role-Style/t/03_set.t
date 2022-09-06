use Test::More tests => 5;

use Mojo::DOM;

my $dom = Mojo::DOM->new('<div style="color:red;background-color:grey;font-size:12pt">some string</div>')->with_roles('+Style');

$\ = "\n";

ok($dom->at('div')->style({ 'color' => 'blue'})->style->{color} eq 'blue', 'merge 1');

ok($dom->at('div')->style eq "color:blue;background-color:grey;font-size:12pt", 'merge 2');

ok($dom->at('div')->style({ 'font-size' => '16pt' })->style->{'font-size'} eq "16pt");

ok($dom->at('div')->style('color', 'purple')->style eq "color:purple", 'replace 2');

ok($dom->at('div')->style(undef)->style eq "", 'undefine');

print $dom;


