#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 17;

use_ok('Parse::SSH2::PublicKey');

my (@keys, $k);

my $openssh_rsa_pub = q{ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6ogUplPsKJkz2FNiD4nQaPyTzMaXt8V75/hmy4dHNGWzmvMJTqJHPFM3BthQLZkjCem6Lk6rtj61CgqvWwo/yjRLuy7wFdOhwEs+ByT2BlVmvxhvTBwhL0gK2/AGSIiAUmuWguXZfNlqUN4bokr0caSv7JH8pwc+4OsUBfyGpMc8DO8SfNhyGvAiOZlUfcCJiikdEw+H9n+zq/r9vPlN6sQEO99akeGpIWkiVUfSjKrdgP6LdfeBltv1zQf2rGA0G/rKNx5r1X7tw2bIfKymVDUV/maTwPwXrQrJ/JHQjONREqmNJpq+EkugqR46Kbr3NVMGXvl8g63t1IKXNcPAZ testusr@testhost
};
my $openssh_dsa_pub = q{ssh-dss AAAAB3NzaC1kc3MAAACBAN/AnuJA/hRijCxBsKnLyY3cgsGKhsxL9vdW2HFsMmXjnH7B4Xgf2FkBuOQVc0P0YYFlmAxtQcgXjLbnb0VWDNjBPlsmuJ7ZnqSRUxNFCFl9eCB/HdOHGwOaWP0Br8rM2CkwSiGCMNfQ+aRLZTzVL4x7t9oDylfGghZ3BzVn+xdDAAAAFQDt9JwiTmmUq+rfZM6sxOV0yHl2DwAAAIEAx6n1APY+v55I6qER2qQghZ4WSw+uoJ3FJRjmAhUzoSOSpt9lAxpFAm3UoRUCnjiVZqoDjXMwnKo9Z6bAkH49OTq419wG1TffumJVpsFNlEt0JocqFk6BNeZxHih4l1JVkip/raHGvHid3RNa14HTpSzx1ucWVzBape0bDwyapQcAAACATK039wcx+zI9fcIZH7wjrCTxwA927coKR/xMSGYX5oe+iCXhEVAS9UOLl/GdAYUHB/zKxhjmvWKxAOVRw21M2oDRRrdw7hJ3GFkd13sFllq1vTMZuqGjweKgPeRW9bIyifoVVyD5wWHVYB7C0NXgKAjicstdaA7Wkp1CoKUUGiQ= testusr@testhost
};
my $secsh_pub = q{---- BEGIN SSH2 PUBLIC KEY ----
Comment: Converted by sshuser@host001
AAAAB3NzaC1yc2EAAAADAQABAAABAQC6ogUplPsKJkz2FNiD4nQaPyTzMaXt8V75/hmy4d
HNGWzmvMJTqJHPFM3BthQLZkjCem6Lk6rtj61CgqvWwo/yjRLuy7wFdOhwEs+ByT2BlVmv
xhvTBwhL0gK2/AGSIiAUmuWguXZfNlqUN4bokr0caSv7JH8pwc+4OsUBfyGpMc8DO8SfNh
yGvAiOZlUfcCJiikdEw+H9n+zq/r9vPlN6sQEO99akeGpIWkiVUfSjKrdgP6LdfeBltv1z
Qf2rGA0G/rKNx5r1X7tw2bIfKymVDUV/maTwPwXrQrJ/JHQjONREqmNJpq+EkugqR46Kbr
3NVMGXvl8g63t1IKXNcPAZ
---- END SSH2 PUBLIC KEY ----
};

# parse secsh
@keys = Parse::SSH2::PublicKey->parse( $secsh_pub );
$k    = $keys[0];
isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got Parse::SSH2::PublicKey object' );
is( $k->comment, 'Converted by sshuser@host001', 'SSH secsh comment' );
is( $k->key, 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC6ogUplPsKJkz2FNiD4nQaPyTzMaXt8V75/hmy4dHNGWzmvMJTqJHPFM3BthQLZkjCem6Lk6rtj61CgqvWwo/yjRLuy7wFdOhwEs+ByT2BlVmvxhvTBwhL0gK2/AGSIiAUmuWguXZfNlqUN4bokr0caSv7JH8pwc+4OsUBfyGpMc8DO8SfNhyGvAiOZlUfcCJiikdEw+H9n+zq/r9vPlN6sQEO99akeGpIWkiVUfSjKrdgP6LdfeBltv1zQf2rGA0G/rKNx5r1X7tw2bIfKymVDUV/maTwPwXrQrJ/JHQjONREqmNJpq+EkugqR46Kbr3NVMGXvl8g63t1IKXNcPAZ', 'SECSH Base64 key data' );
is ( $k->encryption, 'ssh-rsa', 'RSA key' );
is ( $k->type, 'public', 'Public key' );
undef $k; undef @keys;

# parse openssh rsa key
@keys = Parse::SSH2::PublicKey->parse( $openssh_rsa_pub );
$k    = $keys[0];
isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got Parse::SSH2::PublicKey object' );
is( $k->comment, 'testusr@testhost', 'OpenSSH comment' );
is( $k->key, 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC6ogUplPsKJkz2FNiD4nQaPyTzMaXt8V75/hmy4dHNGWzmvMJTqJHPFM3BthQLZkjCem6Lk6rtj61CgqvWwo/yjRLuy7wFdOhwEs+ByT2BlVmvxhvTBwhL0gK2/AGSIiAUmuWguXZfNlqUN4bokr0caSv7JH8pwc+4OsUBfyGpMc8DO8SfNhyGvAiOZlUfcCJiikdEw+H9n+zq/r9vPlN6sQEO99akeGpIWkiVUfSjKrdgP6LdfeBltv1zQf2rGA0G/rKNx5r1X7tw2bIfKymVDUV/maTwPwXrQrJ/JHQjONREqmNJpq+EkugqR46Kbr3NVMGXvl8g63t1IKXNcPAZ', 'OpenSSH Base64 key data' );
is ( $k->encryption, 'ssh-rsa', 'RSA key' );
is ( $k->type, 'public', 'Public key' );
undef $k; undef @keys;


# parse openssh dsa key
@keys = Parse::SSH2::PublicKey->parse( $openssh_dsa_pub );
$k    = $keys[0];
isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got Parse::SSH2::PublicKey object' );
is( $k->comment, 'testusr@testhost', 'OpenSSH comment' );
is( $k->key, 'AAAAB3NzaC1kc3MAAACBAN/AnuJA/hRijCxBsKnLyY3cgsGKhsxL9vdW2HFsMmXjnH7B4Xgf2FkBuOQVc0P0YYFlmAxtQcgXjLbnb0VWDNjBPlsmuJ7ZnqSRUxNFCFl9eCB/HdOHGwOaWP0Br8rM2CkwSiGCMNfQ+aRLZTzVL4x7t9oDylfGghZ3BzVn+xdDAAAAFQDt9JwiTmmUq+rfZM6sxOV0yHl2DwAAAIEAx6n1APY+v55I6qER2qQghZ4WSw+uoJ3FJRjmAhUzoSOSpt9lAxpFAm3UoRUCnjiVZqoDjXMwnKo9Z6bAkH49OTq419wG1TffumJVpsFNlEt0JocqFk6BNeZxHih4l1JVkip/raHGvHid3RNa14HTpSzx1ucWVzBape0bDwyapQcAAACATK039wcx+zI9fcIZH7wjrCTxwA927coKR/xMSGYX5oe+iCXhEVAS9UOLl/GdAYUHB/zKxhjmvWKxAOVRw21M2oDRRrdw7hJ3GFkd13sFllq1vTMZuqGjweKgPeRW9bIyifoVVyD5wWHVYB7C0NXgKAjicstdaA7Wkp1CoKUUGiQ=', 'OpenSSH Base64 key data' );
is ( $k->encryption, 'ssh-dss', 'DSA key' );
is ( $k->type, 'public', 'Public key' );
undef $k; undef @keys;

# parse different pubkey formats in the SAME FILE!!
my $data = $openssh_rsa_pub . $openssh_dsa_pub .  $secsh_pub;
@keys = Parse::SSH2::PublicKey->parse($data);
is( @keys, 3, "Correct number of keys parsed from input" );


