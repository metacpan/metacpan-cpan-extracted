#!perl

use 5.010;
use strict;
use warnings;

use PHPLive::Report qw(parse_phplive_transcript);
use Test::More 0.98;

my $transcript = <<'_';
Foo has joined the chat.
Foo: Hai Bar! saat ini anda terhubung dengan Live Chat PT. Maju Mundur bersama staf support Foo
Foo: Wa Alaikum Salam
Bar: Mas Foo sy td login cpanel sdh masuk user name tp bolakbalik invalid gimana ya?
Foo: Nama domainnya apa Bu?
Bar: example.com
Foo: Baik Bu saya transfer ke bagian support
Transferring chat to Baz.Connecting...
Bar: ok
Baz has joined the chat.
Baz: Sudah saya cek
Baz: Silahkan dicoba login kembali Bu
Bar: ok, thanks
Bar: masih invalid juga salah apa ya?
Bar: padahal us id psword   sy copy paste dr email
Baz: saya cek IP yang ibu gunakana terblock
Baz: dikarenakan salah memasukkan password
Baz: coba direset passwordnya melalui portal billing
Bar: ok, sy coba
Bar: mas sy klik yg mana shabis reset password?
Baz:   klik tombol "Update
Bar: maksudnya download reset password dulu ya?
Bar: kok gak ada pilihan update
Baz: Klik tombol simpan perubahan
Baz: untuk mereset password akun hosting dapat mengikuti panduan berikut
Baz: http://example.net/guide.html
Bar: ok, thanks sy sudah login. :)
Baz: sama -sama BU
The party has left or disconnected.  Chat session has ended.

_

    is_deeply(parse_phplive_transcript($transcript),
          {
              num_transfers => 1,
              num_operators => 2,
              num_msg_lines => 25,
              num_msg_words => 141,
              num_msg_chars => 822,
          });

DONE_TESTING:
done_testing;
