package MyTypes;
use Test::More;

use MooseX::Types -declare => [
    qw(MyHashRefLevel1 MyHashRefLevel2)
];
use MooseX::Types::Moose qw(HashRef Str);

subtype MyHashRefLevel1, as HashRef[Str];

subtype MyHashRefLevel2, as MyHashRefLevel1;

use MooseX::Attribute::Deflator;
deflate 'HashRef[]', via {};

my $reg = MooseX::Attribute::Deflator->get_registry;

my ($tc, $code, $inline) = $reg->find_deflator(MyHashRefLevel2);
is($tc, 'HashRef[Str]', 'found correct type');
ok(!$inline, 'no inlined code');

($tc, $code, $inline) = $reg->find_deflator(Str);
is($tc, 'Item', 'found Item type deflator for Str type');
ok($inline, 'found inline code as well');

done_testing;