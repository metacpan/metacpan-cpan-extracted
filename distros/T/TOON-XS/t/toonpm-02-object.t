use strict;
use warnings;
use Test::More;

use TOON::XS;

my $toon = TOON::XS->new( 'syntax' => 'brace' )->pretty->canonical;
my $text = $toon->encode({ b => 2, a => [1, 'two'] });

like($text, qr/\A\{\n/s, 'pretty output starts with object');
like($text, qr/^  a: \[/m, 'canonical order used');

my $data = $toon->decode($text);
is($data->{b}, 2, 'object method decode works');
is_deeply($data->{a}, [1, 'two'], 'round trip ok');

done_testing();
