use 5.012;
use warnings;
use Test::More;
use Panda::Lib;
use Test::Deep;
use Encode qw/decode_utf8 encode_utf8/;
use Storable qw/dclone/;

my $word_enc = 'жопа';
my $word_dec = decode_utf8($word_enc);

ok(length($word_enc) == 8 and length($word_dec) == 4);

my $enc_struct = {a => $word_enc, b => [1,2,{c => $word_enc}, $word_enc]};
my $dec_struct = {a => $word_dec, b => [1,2,{c => $word_dec}, $word_dec]};

my $test1 = dclone($enc_struct);
Panda::Lib::decode_utf8_struct($test1);
cmp_deeply($test1, $dec_struct);

my $test2 = dclone($dec_struct);
Panda::Lib::encode_utf8_struct($test2);
cmp_deeply($test2, $enc_struct);

done_testing();
