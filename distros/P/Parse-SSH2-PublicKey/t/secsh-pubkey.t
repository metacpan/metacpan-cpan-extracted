#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 21;
use Carp;

use_ok('Parse::SSH2::PublicKey');

my (@keys, $k);

my $secsh_pub = q{---- BEGIN SSH2 PUBLIC KEY ----
Subject: "sshuser@host001"
Comment: "2048-bit rsa, sshuser@host001, Wed Dec 09 2009 13:26:29 -060\
0"
AAAAB3NzaC1yc2EAAAADAQABAAABAQC6ogUplPsKJkz2FNiD4nQaPyTzMaXt8V75/hmy4d
HNGWzmvMJTqJHPFM3BthQLZkjCem6Lk6rtj61CgqvWwo/yjRLuy7wFdOhwEs+ByT2BlVmv
xhvTBwhL0gK2/AGSIiAUmuWguXZfNlqUN4bokr0caSv7JH8pwc+4OsUBfyGpMc8DO8SfNh
yGvAiOZlUfcCJiikdEw+H9n+zq/r9vPlN6sQEO99akeGpIWkiVUfSjKrdgP6LdfeBltv1z
Qf2rGA0G/rKNx5r1X7tw2bIfKymVDUV/maTwPwXrQrJ/JHQjONREqmNJpq+EkugqR46Kbr
3NVMGXvl8g63t1IKXNcPAZ
---- END SSH2 PUBLIC KEY ----
};

# parse secsh public key
@keys = Parse::SSH2::PublicKey->parse( $secsh_pub );
$k    = $keys[0];
isa_ok( $k, 'Parse::SSH2::PublicKey', 'Returned an object' );
is ( $k->type, 'public', 'key type = public' );
is ( $k->encryption, 'ssh-rsa', 'RSA key' );
is( $k->subject, '"sshuser@host001"', 'SECSH pubkey subject' );
is( $k->comment, '"2048-bit rsa, sshuser@host001, Wed Dec 09 2009 13:26:29 -0600"', 'SECSH pubkey comment' );
is( $k->key, 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC6ogUplPsKJkz2FNiD4nQaPyTzMaXt8V75/hmy4dHNGWzmvMJTqJHPFM3BthQLZkjCem6Lk6rtj61CgqvWwo/yjRLuy7wFdOhwEs+ByT2BlVmvxhvTBwhL0gK2/AGSIiAUmuWguXZfNlqUN4bokr0caSv7JH8pwc+4OsUBfyGpMc8DO8SfNhyGvAiOZlUfcCJiikdEw+H9n+zq/r9vPlN6sQEO99akeGpIWkiVUfSjKrdgP6LdfeBltv1zQf2rGA0G/rKNx5r1X7tw2bIfKymVDUV/maTwPwXrQrJ/JHQjONREqmNJpq+EkugqR46Kbr3NVMGXvl8g63t1IKXNcPAZ', 'SECSH key data' );
undef $k; undef @keys;


my $secsh_dsa_file = 'dontuse-secsh.dsa.pub';
my $secsh_rsa_file = 'dontuse-secsh.rsa.pub';

my $secsh_dsa_key = q{---- BEGIN SSH2 PUBLIC KEY ----
AAAAB3NzaC1kc3MAAACBAN/AnuJA/hRijCxBsKnLyY3cgsGKhsxL9vdW2HFsMmXjnH7B4X
gf2FkBuOQVc0P0YYFlmAxtQcgXjLbnb0VWDNjBPlsmuJ7ZnqSRUxNFCFl9eCB/HdOHGwOa
WP0Br8rM2CkwSiGCMNfQ+aRLZTzVL4x7t9oDylfGghZ3BzVn+xdDAAAAFQDt9JwiTmmUq+
rfZM6sxOV0yHl2DwAAAIEAx6n1APY+v55I6qER2qQghZ4WSw+uoJ3FJRjmAhUzoSOSpt9l
AxpFAm3UoRUCnjiVZqoDjXMwnKo9Z6bAkH49OTq419wG1TffumJVpsFNlEt0JocqFk6BNe
ZxHih4l1JVkip/raHGvHid3RNa14HTpSzx1ucWVzBape0bDwyapQcAAACATK039wcx+zI9
fcIZH7wjrCTxwA927coKR/xMSGYX5oe+iCXhEVAS9UOLl/GdAYUHB/zKxhjmvWKxAOVRw2
1M2oDRRrdw7hJ3GFkd13sFllq1vTMZuqGjweKgPeRW9bIyifoVVyD5wWHVYB7C0NXgKAji
cstdaA7Wkp1CoKUUGiQ=
---- END SSH2 PUBLIC KEY ----
};

my $secsh_rsa_key = q{---- BEGIN SSH2 PUBLIC KEY ----
AAAAB3NzaC1yc2EAAAADAQABAAABAQC6ogUplPsKJkz2FNiD4nQaPyTzMaXt8V75/hmy4d
HNGWzmvMJTqJHPFM3BthQLZkjCem6Lk6rtj61CgqvWwo/yjRLuy7wFdOhwEs+ByT2BlVmv
xhvTBwhL0gK2/AGSIiAUmuWguXZfNlqUN4bokr0caSv7JH8pwc+4OsUBfyGpMc8DO8SfNh
yGvAiOZlUfcCJiikdEw+H9n+zq/r9vPlN6sQEO99akeGpIWkiVUfSjKrdgP6LdfeBltv1z
Qf2rGA0G/rKNx5r1X7tw2bIfKymVDUV/maTwPwXrQrJ/JHQjONREqmNJpq+EkugqR46Kbr
3NVMGXvl8g63t1IKXNcPAZ
---- END SSH2 PUBLIC KEY ----
};

@keys = Parse::SSH2::PublicKey->parse( $secsh_rsa_key );
is( @keys, 1, 'Got 1 key' );

$k    = shift @keys;
isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got the right object' );
is( $k->encryption, 'ssh-rsa', 'RSA key' );

@keys = Parse::SSH2::PublicKey->parse( $secsh_dsa_key );
is( @keys, 1, 'Got 1 key' );

$k    = shift @keys;
isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got the right object' );
is( $k->encryption, 'ssh-dss', 'DSA key' );


# two in one text block
my $two_keys = $secsh_pub . $secsh_dsa_key;
#say "two_keys = [$two_keys]";

# parse public keyS
@keys = Parse::SSH2::PublicKey->parse( $two_keys );
is( @keys, 2, "Correct number of keys parsed from input" );

my $k1 = shift @keys;
my $k2 = shift @keys;

is( $k1->comment, '"2048-bit rsa, sshuser@host001, Wed Dec 09 2009 13:26:29 -0600"', 'Comment field from 1st key in text block' );
is( $k1->subject, '"sshuser@host001"', 'Comment field from 1st key in text block' );
is( $k1->key, 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC6ogUplPsKJkz2FNiD4nQaPyTzMaXt8V75/hmy4dHNGWzmvMJTqJHPFM3BthQLZkjCem6Lk6rtj61CgqvWwo/yjRLuy7wFdOhwEs+ByT2BlVmvxhvTBwhL0gK2/AGSIiAUmuWguXZfNlqUN4bokr0caSv7JH8pwc+4OsUBfyGpMc8DO8SfNhyGvAiOZlUfcCJiikdEw+H9n+zq/r9vPlN6sQEO99akeGpIWkiVUfSjKrdgP6LdfeBltv1zQf2rGA0G/rKNx5r1X7tw2bIfKymVDUV/maTwPwXrQrJ/JHQjONREqmNJpq+EkugqR46Kbr3NVMGXvl8g63t1IKXNcPAZ', 'Base64 key data from 1st key in text block' );
is( $k1->encryption, 'ssh-rsa', 'RSA key' );

is( $k2->comment, '', 'Comment field from 2nd key in text block' );
is( $k2->key, 'AAAAB3NzaC1kc3MAAACBAN/AnuJA/hRijCxBsKnLyY3cgsGKhsxL9vdW2HFsMmXjnH7B4Xgf2FkBuOQVc0P0YYFlmAxtQcgXjLbnb0VWDNjBPlsmuJ7ZnqSRUxNFCFl9eCB/HdOHGwOaWP0Br8rM2CkwSiGCMNfQ+aRLZTzVL4x7t9oDylfGghZ3BzVn+xdDAAAAFQDt9JwiTmmUq+rfZM6sxOV0yHl2DwAAAIEAx6n1APY+v55I6qER2qQghZ4WSw+uoJ3FJRjmAhUzoSOSpt9lAxpFAm3UoRUCnjiVZqoDjXMwnKo9Z6bAkH49OTq419wG1TffumJVpsFNlEt0JocqFk6BNeZxHih4l1JVkip/raHGvHid3RNa14HTpSzx1ucWVzBape0bDwyapQcAAACATK039wcx+zI9fcIZH7wjrCTxwA927coKR/xMSGYX5oe+iCXhEVAS9UOLl/GdAYUHB/zKxhjmvWKxAOVRw21M2oDRRrdw7hJ3GFkd13sFllq1vTMZuqGjweKgPeRW9bIyifoVVyD5wWHVYB7C0NXgKAjicstdaA7Wkp1CoKUUGiQ=', 'Key data from 2nd key in text block' );
is( $k2->encryption, 'ssh-dss', 'DSA key' );

undef @keys;
undef $k1;
undef $k2;


