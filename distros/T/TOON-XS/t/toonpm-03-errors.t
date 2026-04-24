use strict;
use warnings;
use Test::More;

use TOON::XS;

my $toon = TOON::XS->new('syntax' => 'brace');
my $ok = eval { $toon->decode('{a: [1, 2}') ; 1 };
ok(!$ok, 'invalid input throws');
like("$@", qr/Expected '\]'/, 'error mentions expected token');

done_testing();
