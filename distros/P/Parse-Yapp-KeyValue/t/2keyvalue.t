use Test::More tests => 15;

BEGIN { use_ok('Parse::Yapp::KeyValue') };

my $pkv = new Parse::Yapp::KeyValue;
my $href;

isa_ok($pkv, 'Parse::Yapp::KeyValue', 'instantiate new Parse::Yapp::KeyValue object');

$href = $pkv->parse('AL=53 AK=54 crimson AB=55 TN="sweet home" A=1 tide A=2 =$ =4');

cmp_ok($href->{AL}, '==', 53,			'key/value pair: AL => 53');
cmp_ok($href->{AK}, '==', 54,			'key/value pair: AK => 54');
cmp_ok($href->{AB}, '==', 55,			'key/value pair: AB => 55');
cmp_ok($href->{TN}, 'eq', 'sweet home',	'key/value pair: TN => sweet home');

isa_ok($href->{A}, 'ARRAY', 'value for key A is an array reference');

cmp_ok(scalar(@{ $href->{A} }), '==', 2, 'value for key A has two members');

cmp_ok($href->{A}->[0], '==', 1, 'index 0 for key A: 1');
cmp_ok($href->{A}->[1], '==', 2, 'index 1 for key A: 2');

isa_ok($href->{''}, 'ARRAY', 'value for the empty key has four members');

cmp_ok($href->{''}->[0], 'eq', 'crimson',	'index 0 for empty key: crimson');
cmp_ok($href->{''}->[1], 'eq', 'tide',		'index 1 for empty key: tide');
cmp_ok($href->{''}->[2], 'eq', '$',			'index 2 for empty key: $');
cmp_ok($href->{''}->[3], '==', 4,			'index 3 for empty key: 4');

