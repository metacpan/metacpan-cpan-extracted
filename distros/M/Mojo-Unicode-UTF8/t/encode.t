use strict;
use warnings;
use utf8;
use Test::More;

use Mojo::Unicode::UTF8;
use Mojo::Util qw(b64_decode b64_encode decode encode md5_bytes);

# b64_encode (UTF-8)
is b64_encode(encode 'UTF-8', "foo\x{df}\x{0100}bar%23\x{263a}"),
  "Zm9vw5/EgGJhciUyM+KYug==\n", 'right Base64 encoded result';

# b64_decode (UTF-8)
is decode('UTF-8', b64_decode "Zm9vw5/EgGJhciUyM+KYug==\n"),
  "foo\x{df}\x{0100}bar%23\x{263a}", 'right Base64 decoded result';

# decode (invalid UTF-8)
is decode('UTF-8', "\x{1000}"), undef, 'decoding invalid UTF-8 worked';

# decode (invalid encoding)
is decode('does_not_exist', ''), undef, 'decoding with invalid encoding worked';

# encode (invalid encoding)
eval { encode('does_not_exist', '') };
like $@, qr/Unknown encoding 'does_not_exist'/, 'right error';

# md5_bytes
is unpack('H*', md5_bytes(encode 'UTF-8', 'foo bar baz ♥')),
  'a740aeb6e066f158cbf19fd92e890d2d', 'right binary md5 checksum';

done_testing();
