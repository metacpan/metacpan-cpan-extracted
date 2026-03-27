use strict;
use warnings;
use Test::More;

use TOON qw(encode_toon decode_toon);

my $text = encode_toon({ answer => 42 }, canonical => 1);
is($text, '{answer: 42}', 'encoded simple object');

my $data = decode_toon('{answer: 42, active: true, items: [1, 2, 3]}');
is($data->{answer}, 42, 'decoded number');
ok($data->{active}, 'decoded boolean');
is_deeply($data->{items}, [1, 2, 3], 'decoded array');

done_testing();
