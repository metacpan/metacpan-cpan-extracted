use Mojo::Base -strict;

use Test::More tests => 32;
use Test::Mojo;
use Mojo::URL;

use Mojolicious::Lite;

BEGIN { use_ok('Mojolicious::Plugin::Crypto') };

sub rndStr{ join'', @_[ map{ rand @_ } 1 .. shift ] }

plugin 'crypto', {};

my $t = Test::Mojo->new(app);

my $fix_key = 'secretpassphrase';
my $plain = "NemuxMojoCrypt";

my $blow_key   = "MyNameisMarcoRomano";
my $blow_plain = ":::nemux::: [ All Glory to The Hypnotoad ]";

## AES Test
my ($crypted, $key)  = $t->app->crypt_aes($plain, $fix_key);
ok($fix_key eq $key, "AES return KEY expected $fix_key i got $key");
my ($clean) =  $t->app->decrypt_aes($crypted, $fix_key);
ok($plain eq $clean, "AES ENC/DEC expected $plain i got $clean");

my ($wrong_clean) =  $t->app->decrypt_aes($crypted, "WrongPassword");
ok($plain ne $wrong_clean, "AES ENC/DEC expected $plain i got $wrong_clean");

## BlowFish Test
$blow_plain = $blow_plain . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_blowfish($blow_plain, $blow_key);
ok($key eq  $blow_key, "Blowfish return KEY");
my ($clean_blow) =  $t->app->decrypt_blowfish($crypted, $blow_key);
ok($blow_plain eq $clean_blow, "Blowfish ENC/DEC expected $blow_plain i got $clean_blow");

## DES test
$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_des($blow_plain, $blow_key);
ok($key eq $blow_key, "DES return KEY");
my ($clean_des) =  $t->app->decrypt_des($crypted, $blow_key);
ok($blow_plain eq $clean_des, "DES ENC/DEC expected $blow_plain i got $clean_des");

## 3DES test
$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_3des($blow_plain, $blow_key);
ok($key eq  $blow_key, "3DES return KEY");
my ($clean_3des) =  $t->app->decrypt_3des($crypted, $blow_key);
ok($blow_plain eq $clean_3des, "3DES ENC/DEC expected $blow_plain i got $clean_3des");

## IDEA test
#$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
#($crypted, $key)  = $t->app->crypt_idea($blow_plain, $blow_key);
#ok($key eq  $blow_key, "IDEA return KEY");
#my ($clean_idea) =  $t->app->decrypt_idea($crypted, $blow_key);
#ok($blow_plain eq $clean_idea, "IDEA ENC/DEC expected $blow_plain i got $clean_idea");

## twofish test
$blow_plain = "All Glory to The Hypnotoad ". rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_twofish($blow_plain, $blow_key);
ok($key eq $blow_key, "twofish return KEY");
my ($clean_twofish) =  $t->app->decrypt_twofish($crypted, $blow_key);
ok($blow_plain eq $clean_twofish, "twofish ENC/DEC expected $blow_plain i got $clean_twofish");

## XTEA test
$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_xtea($blow_plain, $blow_key);
ok($key eq  $blow_key, "xtea return KEY");
my ($clean_xtea) =  $t->app->decrypt_xtea($crypted, $blow_key);
ok($blow_plain eq $clean_xtea, "xtea ENC/DEC expected $blow_plain i got $clean_xtea");

## ANUBI test
$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_anubis($blow_plain, $blow_key);
ok($key eq $blow_key, "anubi return KEY");
my ($clean_anubi) =  $t->app->decrypt_anubis($crypted, $blow_key);
ok($blow_plain eq $clean_anubi, "anubi ENC/DEC expected $blow_plain i got $clean_anubi");

## CAMELLIA test
$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_camellia($blow_plain, $blow_key);
ok($key eq $blow_key, "camellia return KEY");
my ($clean_camellia) =  $t->app->decrypt_camellia($crypted, $blow_key);
ok($blow_plain eq $clean_camellia, "camellia ENC/DEC expected $blow_plain i got $clean_camellia");

## Khazad test
$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_khazad($blow_plain, $blow_key);
ok($key eq $blow_key, "camellia return KEY");
my ($clean_khazad) =  $t->app->decrypt_khazad($crypted, $blow_key);
ok($blow_plain eq $clean_khazad, "camellia ENC/DEC expected $blow_plain i got $clean_khazad");

## MULTI2 test
$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_multi2($blow_plain, $blow_key);
ok($key eq  $blow_key, "multi2 return KEY");
my ($clean_multi2) =  $t->app->decrypt_multi2($crypted, $blow_key);
ok($blow_plain eq $clean_multi2, "multi2 ENC/DEC expected $blow_plain i got $clean_multi2");

## NOEKEON test
$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_noekeon($blow_plain, $blow_key);
ok($key eq $blow_key, "noekeon return KEY");
my ($clean_noekeon)=  $t->app->decrypt_noekeon($crypted, $blow_key);
ok($blow_plain eq $clean_noekeon, "noekeon ENC/DEC expected $blow_plain i got $clean_noekeon");

## RC2 test
$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_rc2($blow_plain, $blow_key);
ok($key eq  $blow_key, "RC2 return KEY");
my ($clean_rc2)=  $t->app->decrypt_rc2($crypted, $blow_key);
ok($blow_plain eq $clean_rc2, "rc2 ENC/DEC expected $blow_plain i got $clean_rc2");

## RC5 test
$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_rc5($blow_plain, $blow_key);
ok($key eq $blow_key, "RC5 return KEY");
my ($clean_rc5) = $t->app->decrypt_rc5($crypted, $blow_key);
ok($blow_plain eq $clean_rc5, "rc5 ENC/DEC expected $blow_plain i got $clean_rc5");

## RC6 test
$blow_plain = "All Glory to The Hypnotoad " . rndStr 42, 'a'..'z', 0..9;
($crypted, $key)  = $t->app->crypt_rc6($blow_plain, $blow_key);
ok($key eq $blow_key, "RC6 return KEY");
my ($clean_rc6)=  $t->app->decrypt_rc6($crypted, $blow_key);
ok($blow_plain eq $clean_rc6, "rc6 ENC/DEC expected $blow_plain i got $clean_rc6");

### SUPER CRYPTO FUNCTION :)
my $super_plain = "Look mom i'm a cryptO programmer";
my $super_secret = "LookMomStupidSecret";
($crypted, $key)  = $t->app->crypt_xtea($t->app->crypt_twofish($t->app->crypt_3des($t->app->crypt_blowfish($t->app->crypt_aes($super_plain,$super_secret)))));
ok($super_secret eq $key, "MULTI CRYPTO return KEY");

my ($clean_super) = $t->app->decrypt_aes($t->app->decrypt_blowfish($t->app->decrypt_3des($t->app->decrypt_twofish($t->app->decrypt_xtea($crypted,$super_secret)))));
ok($clean_super eq $super_plain, "MULTI CRYPTO ENC/DEC expected $super_plain i got $clean_super");


done_testing(32);


