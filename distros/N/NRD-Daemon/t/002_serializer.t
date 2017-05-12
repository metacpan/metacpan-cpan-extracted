#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use NRD::Serialize;

use Data::Dumper;

use Clone qw(clone);

plan tests => 5;

my $un = NRD::Serialize->instance_of('plain', { });
my $s = NRD::Serialize->instance_of('crypt', {'encrypt_type' => 'Blowfish', 'encrypt_key' => 'xxxx' });
my $d = NRD::Serialize->instance_of('digest', {'digest_type' => 'MD5', 'digest_key' => 'secret' });


#diag('will use IV ' . $s->{'iv'} . ' length ' . length($s->{'iv'}));

my $uns = NRD::Serialize->instance_of('crypt', {'encrypt_type' => 'Blowfish', 'encrypt_key' => 'xxxx'});
$uns->helo($s->helo);

my $und = NRD::Serialize->instance_of('digest', {'digest_type' => 'MD5', 'digest_key' => 'secret' });
my $und_error = NRD::Serialize->instance_of('digest', {'digest_type' => 'MD5', 'digest_key' => 'wrong' });

my $orig_r = {'command' => 'result', data => { 'hostname' => 'this is a string' } };

# copy $r

my $r = clone($orig_r);
my $no_crypt = $un->freeze($r);

$r = clone($orig_r);
my $crypted = $s->freeze($r);

$r = clone($orig_r);
my $digested = $d->freeze($r);

cmp_ok($crypted, 'ne', $no_crypt, 'Crypted and no_crypt versions are different');
cmp_ok($digested, 'ne', $no_crypt, 'Digested and no_crypt versions are different');


my $uncrypted = $uns->unfreeze($crypted);
is_deeply($uncrypted, $orig_r, 'Unencrypted and no_crypt versions are equal');

my $undigested = $und->unfreeze($digested);
is_deeply($undigested, $orig_r, 'Undigested and no_crypt versions are equal');

eval {
  $und_error->unfreeze($digested);
};
like($@, qr/check that digest_keys are the same/, 'got exception if unserializing with wrong digest_key');
