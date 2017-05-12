use strict;
use warnings;
use lib 'lib';
use Test::More tests => 34;
use Test::Exception;
use_ok('String::Koremutake');

my $k = String::Koremutake->new();
is($k->_numbers_to_koremutake([39,67,52,78,37]), "koremutake");

throws_ok { $k->_numbers_to_koremutake([-1]) } qr/0 <= -1 <= 127/;
throws_ok { $k->_numbers_to_koremutake([128]) } qr/0 <= 128 <= 127/;

is_deeply($k->_koremutake_to_numbers("koremutake"), [39,67,52,78,37]);
throws_ok { $k->_koremutake_to_numbers("qwe") } qr/Phoneme qwe not valid/;

dies_ok { $k->integer_to_koremutake(-1) };

throws_ok { $k->integer_to_koremutake() } qr/No integer given/;
throws_ok { $k->koremutake_to_integer() } qr/No koremutake string given/;

is($k->integer_to_koremutake(0), 'ba');
is($k->integer_to_koremutake(39), 'ko');
is($k->integer_to_koremutake(67), 're');
is($k->integer_to_koremutake(52), 'mu');
is($k->integer_to_koremutake(78), 'ta');
is($k->integer_to_koremutake(37), 'ke');
is($k->integer_to_koremutake(128), 'beba');
is($k->integer_to_koremutake(256), 'biba');
is($k->integer_to_koremutake(65535), 'botretre');
is($k->integer_to_koremutake(65536), 'bubaba');
is($k->integer_to_koremutake(5059), 'kore');
is($k->integer_to_koremutake(10610353957), 'koremutake');

dies_ok { $k->koremutake_to_intger("Hello world") };

is($k->koremutake_to_integer('ba'), 0);
is($k->koremutake_to_integer('ko'), 39);
is($k->koremutake_to_integer('re'), 67);
is($k->koremutake_to_integer('mu'), 52);
is($k->koremutake_to_integer('ta'), 78);
is($k->koremutake_to_integer('ke'), 37);
is($k->koremutake_to_integer('beba'), 128);
is($k->koremutake_to_integer('biba'), 256);
is($k->koremutake_to_integer('botretre'), 65535);
is($k->koremutake_to_integer('bubaba'), 65536);
is($k->koremutake_to_integer('kore'), 5059);
is($k->koremutake_to_integer('koremutake'), 10610353957);
