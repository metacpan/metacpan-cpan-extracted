use strict;
use warnings;
use Test::More;
use QR::Code;

# The provider table: resolvable, versioned, and agreeing with the
# Perl-visible encoder. Version 2 added capacity and the full styled
# serialiser; the selftest exercises both from the C side, where the
# size-prefixed argument structs actually matter.

my $ptr = QR::Code::_abi_ptr();
ok($ptr, 'the table resolves to a non-NULL pointer');
is($ptr, QR::Code::_abi_ptr(), 'and is stable across calls');

my $self = QR::Code::_abi_selftest();
is($self->{version}, 2, 'QR_ABI_VERSION is 2');
ok($self->{free_ok}, 'free_fn is populated');
ok($self->{matrix_ok},
   'a matrix through the table equals one through qr_encode');
ok($self->{svg_ok}, 'svg through the table renders a document');
ok($self->{capacity_ok},
   'capacity agrees with the encoder and refuses bad arguments');
ok($self->{styled_ok},
   'svg_styled honours style, logo, and the info struct');

done_testing;
