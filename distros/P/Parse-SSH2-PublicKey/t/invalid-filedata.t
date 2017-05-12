#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 16;
use File::Temp qw/tempfile/;
use File::Slurp qw/read_file write_file/;

my ($tfh, $tempfile);

use_ok('Parse::SSH2::PublicKey');

my (@keys, $k);

my $openssh_rsa_pub = q{ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6ogUplPsKJkz2FNiD4nQaPyTzMaXt8V75/hmy4dHNGWzmvMJTqJHPFM3BthQLZkjCem6Lk6rtj61CgqvWwo/yjRLuy7wFdOhwEs+ByT2BlVmvxhvTBwhL0gK2/AGSIiAUmuWguXZfNlqUN4bokr0caSv7JH8pwc+4OsUBfyGpMc8DO8SfNhyGvAiOZlUfcCJiikdEw+H9n+zq/r9vPlN6sQEO99akeGpIWkiVUfSjKrdgP6LdfeBltv1zQf2rGA0G/rKNx5r1X7tw2bIfKymVDUV/maTwPwXrQrJ/JHQjONREqmNJpq+EkugqR46Kbr3NVMGXvl8g63t1IKXNcPAZ testusr@testhost
};
my $openssh_dsa_pub = q{ssh-dss AAAAB3NzaC1kc3MAAACBAN/AnuJA/hRijCxBsKnLyY3cgsGKhsxL9vdW2HFsMmXjnH7B4Xgf2FkBuOQVc0P0YYFlmAxtQcgXjLbnb0VWDNjBPlsmuJ7ZnqSRUxNFCFl9eCB/HdOHGwOaWP0Br8rM2CkwSiGCMNfQ+aRLZTzVL4x7t9oDylfGghZ3BzVn+xdDAAAAFQDt9JwiTmmUq+rfZM6sxOV0yHl2DwAAAIEAx6n1APY+v55I6qER2qQghZ4WSw+uoJ3FJRjmAhUzoSOSpt9lAxpFAm3UoRUCnjiVZqoDjXMwnKo9Z6bAkH49OTq419wG1TffumJVpsFNlEt0JocqFk6BNeZxHih4l1JVkip/raHGvHid3RNa14HTpSzx1ucWVzBape0bDwyapQcAAACATK039wcx+zI9fcIZH7wjrCTxwA927coKR/xMSGYX5oe+iCXhEVAS9UOLl/GdAYUHB/zKxhjmvWKxAOVRw21M2oDRRrdw7hJ3GFkd13sFllq1vTMZuqGjweKgPeRW9bIyifoVVyD5wWHVYB7C0NXgKAjicstdaA7Wkp1CoKUUGiQ= testusr@testhost
};

my $secsh_pub = q{
---- BEGIN SSH2 PUBLIC KEY ----
AAAAB3NzaC1yc2EAAAADAQABAAABAQDGeSou4mEWqx2Lx8JIxOxH5MiVuXxJJrs36QOxzN
moskL6cUP4CO0TZtoqtnjVvaWryBfS65HNC9Q0KuTqLpXNTu+056mmhzvqJg5K6mhhtz44
7sMl+a5xrpS64I9uNKOIpjptRIvk8IaF//bY9n3DRLWSjxLwPVH8kZRQvWVtut3PKc5K/P
ngAd/AALRlMrBYFGY1AHDmutWL78vI2YCNusmFfJ8XEyNfsr6+ZhvnR6et1FdJd/L3HYRu
Zc9hJ2gV3Oorqj6PtUkQjvtSEsipTRJGLedg+734GXvQ0jJPsZWE0aVeq0m9jAHU1f312L
YCnbvZVjoBz/JwBoVK4Gxr
---- END SSH2 PUBLIC KEY ----
};

($tfh, $tempfile) = tempfile();
my $junk = q{
tcpmux      1/tcp               # TCP port service multiplexer
echo        7/tcp
echo        7/udp
discard     9/tcp       sink null
discard     9/udp       sink null
systat      11/tcp      users
daytime     13/tcp
daytime     13/udp
};
if ( write_file( $tempfile, $junk ) ) {
    @keys = Parse::SSH2::PublicKey->parse_file( $tempfile );
    is( @keys, 0, "Parsed invalid data, 0 keys returned." );
    undef $k; undef @keys;
}
undef $tfh; undef $tempfile;


my $key_then_junk = q{ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMGTizB5naTwPe9bi1FHyj0FAaPsIS0UmNO31g3WBK9AtIYQbZGRjiHqg28jYOHRd3EinASn40YXS4IoGPOb3BD//Bj8dMxQ0oQTHVsCx/Y/GrGBl7+tIHlknpMasf97WkJh4+k8P4amd6lPObUV0s9JaWx2KUJPui3bh7ymcXKzi90NT+zh5wRbGczbKXa05u+2DuofdgQC7PK6xPxwgGsOF2UlpuEPW2705umhkCQ1sOmQvwCVH9zQJk9jfuqE55gAAOewijDWcdu39v+m5OxITvMydpI6tJJY9QaptJdt0ORo8htfKBDH025nCEtPn2lwbEQO6X6zpDOzwxE4G3 sshuser@host
tcpmux      1/tcp               # TCP port service multiplexer
echo        7/tcp
echo        7/udp
discard     9/tcp       sink null
discard     9/udp       sink null
systat      11/tcp      users
daytime     13/tcp
daytime     13/udp
};
my $junk_then_key = q{ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMGTizB5naTwPe9bi1FHyj0FAaPsIS0UmNO31g3WBK9AtIYQbZGRjiHqg28jYOHRd3EinASn40YXS4IoGPOb3BD//Bj8dMxQ0oQTHVsCx/Y/GrGBl7+tIHlknpMasf97WkJh4+k8P4amd6lPObUV0s9JaWx2KUJPui3bh7ymcXKzi90NT+zh5wRbGczbKXa05u+2DuofdgQC7PK6xPxwgGsOF2UlpuEPW2705umhkCQ1sOmQvwCVH9zQJk9jfuqE55gAAOewijDWcdu39v+m5OxITvMydpI6tJJY9QaptJdt0ORo8htfKBDH025nCEtPn2lwbEQO6X6zpDOzwxE4G3 sshuser@host
tcpmux      1/tcp               # TCP port service multiplexer
echo        7/tcp
echo        7/udp
discard     9/tcp       sink null
discard     9/udp       sink null
systat      11/tcp      users
daytime     13/tcp
daytime     13/udp
};

@keys = Parse::SSH2::PublicKey->parse( $key_then_junk );
is( @keys, 1, "Key then junk, got 1 key");
$k = shift @keys;

isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got the right object' );
is( $k->comment, 'sshuser@host', 'Comment from key file' );
is( $k->encryption, 'ssh-rsa', 'RSA key' );
is( $k->key, 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDMGTizB5naTwPe9bi1FHyj0FAaPsIS0UmNO31g3WBK9AtIYQbZGRjiHqg28jYOHRd3EinASn40YXS4IoGPOb3BD//Bj8dMxQ0oQTHVsCx/Y/GrGBl7+tIHlknpMasf97WkJh4+k8P4amd6lPObUV0s9JaWx2KUJPui3bh7ymcXKzi90NT+zh5wRbGczbKXa05u+2DuofdgQC7PK6xPxwgGsOF2UlpuEPW2705umhkCQ1sOmQvwCVH9zQJk9jfuqE55gAAOewijDWcdu39v+m5OxITvMydpI6tJJY9QaptJdt0ORo8htfKBDH025nCEtPn2lwbEQO6X6zpDOzwxE4G3', 'Base64 key data' );
undef $k; undef @keys;

@keys = Parse::SSH2::PublicKey->parse( $junk_then_key );
is( @keys, 1, "Junk then key, got 1 key");
$k = shift @keys;

isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got the right object' );
is( $k->comment, 'sshuser@host', 'Comment from key file' );
is( $k->encryption, 'ssh-rsa', 'RSA key' );
is( $k->key, 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDMGTizB5naTwPe9bi1FHyj0FAaPsIS0UmNO31g3WBK9AtIYQbZGRjiHqg28jYOHRd3EinASn40YXS4IoGPOb3BD//Bj8dMxQ0oQTHVsCx/Y/GrGBl7+tIHlknpMasf97WkJh4+k8P4amd6lPObUV0s9JaWx2KUJPui3bh7ymcXKzi90NT+zh5wRbGczbKXa05u+2DuofdgQC7PK6xPxwgGsOF2UlpuEPW2705umhkCQ1sOmQvwCVH9zQJk9jfuqE55gAAOewijDWcdu39v+m5OxITvMydpI6tJJY9QaptJdt0ORo8htfKBDH025nCEtPn2lwbEQO6X6zpDOzwxE4G3', 'Base64 key data' );
undef $k; undef @keys;


# This test should prove that the module can pull an SSH2 pubkey
# out of a random text block of crap.

my $junk_then_key_then_more_junk = q{
tcpmux      1/tcp               # TCP port service multiplexer
echo        7/tcp
echo        7/udp
discard     9/tcp       sink null
discard     9/udp       sink null
systat      11/tcp      users
daytime     13/tcp
daytime     13/udp---- BEGIN SSH2 PUBLIC KEY ----
AAAAB3NzaC1kc3MAAACBAN/AnuJA/hRijCxBsKnLyY3cgsGKhsxL9vdW2HFsMmXjnH7B4X
gf2FkBuOQVc0P0YYFlmAxtQcgXjLbnb0VWDNjBPlsmuJ7ZnqSRUxNFCFl9eCB/HdOHGwOa
WP0Br8rM2CkwSiGCMNfQ+aRLZTzVL4x7t9oDylfGghZ3BzVn+xdDAAAAFQDt9JwiTmmUq+
rfZM6sxOV0yHl2DwAAAIEAx6n1APY+v55I6qER2qQghZ4WSw+uoJ3FJRjmAhUzoSOSpt9l
AxpFAm3UoRUCnjiVZqoDjXMwnKo9Z6bAkH49OTq419wG1TffumJVpsFNlEt0JocqFk6BNe
ZxHih4l1JVkip/raHGvHid3RNa14HTpSzx1ucWVzBape0bDwyapQcAAACATK039wcx+zI9
fcIZH7wjrCTxwA927coKR/xMSGYX5oe+iCXhEVAS9UOLl/GdAYUHB/zKxhjmvWKxAOVRw2
1M2oDRRrdw7hJ3GFkd13sFllq1vTMZuqGjweKgPeRW9bIyifoVVyD5wWHVYB7C0NXgKAji
cstdaA7Wkp1CoKUUGiQ=
---- END SSH2 PUBLIC KEY ---- nobody:*:-2:
nogroup:*:-1:
wheel:*:0:root
daemon:*:1:root
kmem:*:2:root
sys:*:3:root
tty:*:4:root
mail:*:6:
bin:*:7:
owner:*:10:
everyone:*:12:
group:*:16:
staff:*:20:root
utmp:*:45:
};

@keys = Parse::SSH2::PublicKey->parse( $junk_then_key_then_more_junk );
is( @keys, 1, "Junk then key then more junk, extracted 1 key");
$k = shift @keys;

isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got the right object' );
is( $k->encryption, 'ssh-dss', 'DSA key' );
is( $k->key, 'AAAAB3NzaC1kc3MAAACBAN/AnuJA/hRijCxBsKnLyY3cgsGKhsxL9vdW2HFsMmXjnH7B4Xgf2FkBuOQVc0P0YYFlmAxtQcgXjLbnb0VWDNjBPlsmuJ7ZnqSRUxNFCFl9eCB/HdOHGwOaWP0Br8rM2CkwSiGCMNfQ+aRLZTzVL4x7t9oDylfGghZ3BzVn+xdDAAAAFQDt9JwiTmmUq+rfZM6sxOV0yHl2DwAAAIEAx6n1APY+v55I6qER2qQghZ4WSw+uoJ3FJRjmAhUzoSOSpt9lAxpFAm3UoRUCnjiVZqoDjXMwnKo9Z6bAkH49OTq419wG1TffumJVpsFNlEt0JocqFk6BNeZxHih4l1JVkip/raHGvHid3RNa14HTpSzx1ucWVzBape0bDwyapQcAAACATK039wcx+zI9fcIZH7wjrCTxwA927coKR/xMSGYX5oe+iCXhEVAS9UOLl/GdAYUHB/zKxhjmvWKxAOVRw21M2oDRRrdw7hJ3GFkd13sFllq1vTMZuqGjweKgPeRW9bIyifoVVyD5wWHVYB7C0NXgKAjicstdaA7Wkp1CoKUUGiQ=', 'Base64 key data' );
undef $k; undef @keys;

