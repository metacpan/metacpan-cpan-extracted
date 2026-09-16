#!perl
use 5.010;
use strict;
use warnings;
use Test::More tests => 10;

BEGIN { use_ok('Struct::Codec') || print "Bail out!\n" }

ok(defined &Struct::Codec::struct_encode, 'struct_encode is reachable');
ok(defined &Struct::Codec::struct_decode, 'and so is struct_decode');
ok(defined &Struct::Codec::encode, 'encode is the short name for the same thing');
ok(defined &Struct::Codec::decode, 'and decode');

# Nothing arrives uninvited, the two long names arrive on request, and any
# other name is refused rather than ignored.
ok(!defined &main::struct_encode, 'nothing is exported by default');
ok(eval "use Struct::Codec qw(struct_encode struct_decode); 1", 'the two names import on request')
    or diag $@;
ok(defined &main::struct_encode && defined &main::struct_decode, 'and are then callable unqualified');
ok(!eval "use Struct::Codec qw(encode); 1", 'the short name is not exportable');
like($@, qr/does not export 'encode'/, 'and says so by name');

diag("Struct::Codec $Struct::Codec::VERSION, Perl $], $^X");
