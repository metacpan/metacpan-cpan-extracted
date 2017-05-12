use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Protocol::BitTorrent;

my $t = new_ok('Protocol::BitTorrent');

# Check whether our bencode implementation is working
is($t->bdecode('i12e'), 12, 'number matches');
is($t->bdecode('4:test'), 'test', 'string matches');
ok(exception { $t->bdecode('4:tes') }, 'short string raises exception');
ok(exception { $t->bdecode('i12') }, 'invalid int raises exception');
ok(exception { $t->bdecode('l1:a') }, 'short list raises exception');

done_testing;
