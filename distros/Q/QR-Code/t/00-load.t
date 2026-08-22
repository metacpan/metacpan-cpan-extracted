use strict;
use warnings;
use Test::More;

BEGIN { use_ok('QR::Code') }

ok defined $QR::Code::VERSION, 'has a version';

my $st = QR::Code::_abi_selftest();
is ref $st, 'HASH', 'abi selftest returns a report';
cmp_ok $st->{version}, '>=', 1, 'abi version at least 1';
ok $st->{matrix_ok}, 'abi matrix agrees with the encoder';
ok $st->{svg_ok},    'abi svg renders';
ok $st->{free_ok},   'abi free_fn present';

ok QR::Code::_abi_ptr() > 0, '_abi_ptr returns an address';

done_testing;
