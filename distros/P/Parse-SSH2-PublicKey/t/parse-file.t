#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 18;
use File::Temp qw/tempfile/;
use File::Slurp qw/read_file write_file/;

my ($tfh, $tempfile);

use_ok('Parse::SSH2::PublicKey');

my (@keys, $k);

my $openssh_rsa_pub = q{ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMGTizB5naTwPe9bi1FHyj0FAaPsIS0UmNO31g3WBK9AtIYQbZGRjiHqg28jYOHRd3EinASn40YXS4IoGPOb3BD//Bj8dMxQ0oQTHVsCx/Y/GrGBl7+tIHlknpMasf97WkJh4+k8P4amd6lPObUV0s9JaWx2KUJPui3bh7ymcXKzi90NT+zh5wRbGczbKXa05u+2DuofdgQC7PK6xPxwgGsOF2UlpuEPW2705umhkCQ1sOmQvwCVH9zQJk9jfuqE55gAAOewijDWcdu39v+m5OxITvMydpI6tJJY9QaptJdt0ORo8htfKBDH025nCEtPn2lwbEQO6X6zpDOzwxE4G3 sshuser@host
};
my $openssh_dsa_pub = q{ssh-dss AAAAB3NzaC1kc3MAAACBAKxe0WtI19h2zNNJBbh0C52lGcs7WUvs6jlktWjd1anOVBwYEGIPUbcU0Frq8kyr9daJv44FEClEougVrz3uiMnDAKpD7rJ32/oc94c7YlVF/SjTz2fLA4n0nA9d/lkC1X6Tfj5JDwuMPURi1mNZlKZ9EhyQ916Sj1IakvnmQ9BNAAAAFQC706Ie1+oDglySpaHIIUNnDMAUtwAAAIAaCVEpV/IeEXvWtDhH7MzZMTn1JbhOzgIehuXX0XpGRI9q+OI7Khw7JmvhFBCTYfYpK3PK9bBMHiX8b1tNaorMc2UNQlJzJzjR2hTJgPJ8DgG/RyXbqpkUruXp8IyD4i+NSl1xNFEKentL32d+I4HshWO9n9XVH225GQrrVnZ/OgAAAIBHa5XkFIFKxiJxNurFYX4/X0a2IiaHGxO5ot6/73Atme7+3JhQvteR19d67bE1f7CXDl56el2oMHNrkpcPZkBWP6CnG7bLa65tN23sXjkbrV7HqZdCMZv4drzRtYo+I6MHNPsMmwGToOYeeL3JQH/EIUeXYLXlIw9+LM6P/k5iag== My 1024-bit DSA key};
my $secsh_pub = q{---- BEGIN SSH2 PUBLIC KEY ----
Subject: "sshuser AT domain DOT tld would be my email address if I we\
re to register it. Filler text will go here. We use filler text to ta\
ke up space as if it were a valid block of text, but in this case its\
 not valid for anything except taking up space."
Comment: "2048-bit rsa, user@host, Wed Dec 09 2009 13:26:29 -0600 and \
Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam non\
ummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volut\
pat."
AAAAB3NzaC1yc2EAAAADAQABAAABAQDGeSou4mEWqx2Lx8JIxOxH5MiVuXxJJrs36QOxzN
moskL6cUP4CO0TZtoqtnjVvaWryBfS65HNC9Q0KuTqLpXNTu+056mmhzvqJg5K6mhhtz44
7sMl+a5xrpS64I9uNKOIpjptRIvk8IaF//bY9n3DRLWSjxLwPVH8kZRQvWVtut3PKc5K/P
ngAd/AALRlMrBYFGY1AHDmutWL78vI2YCNusmFfJ8XEyNfsr6+ZhvnR6et1FdJd/L3HYRu
Zc9hJ2gV3Oorqj6PtUkQjvtSEsipTRJGLedg+734GXvQ0jJPsZWE0aVeq0m9jAHU1f312L
YCnbvZVjoBz/JwBoVK4Gxr
---- END SSH2 PUBLIC KEY ----
};


# parse SECSH format
($tfh, $tempfile) = tempfile();
if ( write_file( $tempfile, $secsh_pub ) ) {
    @keys = Parse::SSH2::PublicKey->parse_file( $tempfile );
    $k    = $keys[0];
    isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got Parse::SSH2::PublicKey object' );
    is( $k->comment, '"2048-bit rsa, user@host, Wed Dec 09 2009 13:26:29 -0600 and Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat."', 'SECSH key comment' );
    is( $k->subject, '"sshuser AT domain DOT tld would be my email address if I were to register it. Filler text will go here. We use filler text to take up space as if it were a valid block of text, but in this case its not valid for anything except taking up space."', 'SECSH key subject' );
    is( $k->key, 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDGeSou4mEWqx2Lx8JIxOxH5MiVuXxJJrs36QOxzNmoskL6cUP4CO0TZtoqtnjVvaWryBfS65HNC9Q0KuTqLpXNTu+056mmhzvqJg5K6mhhtz447sMl+a5xrpS64I9uNKOIpjptRIvk8IaF//bY9n3DRLWSjxLwPVH8kZRQvWVtut3PKc5K/PngAd/AALRlMrBYFGY1AHDmutWL78vI2YCNusmFfJ8XEyNfsr6+ZhvnR6et1FdJd/L3HYRuZc9hJ2gV3Oorqj6PtUkQjvtSEsipTRJGLedg+734GXvQ0jJPsZWE0aVeq0m9jAHU1f312LYCnbvZVjoBz/JwBoVK4Gxr', 'SECSH key data' );
    is ( $k->encryption, 'ssh-rsa', 'RSA key' );
    is ( $k->type, 'public', 'Public key' );
    undef $k; undef @keys;
}
undef $tfh; undef $tempfile;


# parse openssh rsa keys...
($tfh, $tempfile) = tempfile();
if ( write_file( $tempfile, $openssh_rsa_pub ) ) {
    @keys = Parse::SSH2::PublicKey->parse_file( $tempfile );
    $k    = $keys[0];
    isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got Parse::SSH2::PublicKey object' );
    is( $k->comment, 'sshuser@host', 'OpenSSH RSA comment parsed.' );
    is( $k->key, 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDMGTizB5naTwPe9bi1FHyj0FAaPsIS0UmNO31g3WBK9AtIYQbZGRjiHqg28jYOHRd3EinASn40YXS4IoGPOb3BD//Bj8dMxQ0oQTHVsCx/Y/GrGBl7+tIHlknpMasf97WkJh4+k8P4amd6lPObUV0s9JaWx2KUJPui3bh7ymcXKzi90NT+zh5wRbGczbKXa05u+2DuofdgQC7PK6xPxwgGsOF2UlpuEPW2705umhkCQ1sOmQvwCVH9zQJk9jfuqE55gAAOewijDWcdu39v+m5OxITvMydpI6tJJY9QaptJdt0ORo8htfKBDH025nCEtPn2lwbEQO6X6zpDOzwxE4G3', 'OpenSSH RSA key parsed' );
    is ( $k->encryption, 'ssh-rsa', 'RSA key' );
    is ( $k->type, 'public', 'Public key' );
    undef $k; undef @keys;
}
undef $tfh; undef $tempfile;


# parse openssh dsa keys...
($tfh, $tempfile) = tempfile();
if ( write_file( $tempfile, $openssh_dsa_pub ) ) {
    @keys = Parse::SSH2::PublicKey->parse_file( $tempfile );
    $k    = $keys[0];
    isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got Parse::SSH2::PublicKey object' );
    is( $k->comment, 'My 1024-bit DSA key', 'OpenSSH DSA comment parsed.' );
    is( $k->key, 'AAAAB3NzaC1kc3MAAACBAKxe0WtI19h2zNNJBbh0C52lGcs7WUvs6jlktWjd1anOVBwYEGIPUbcU0Frq8kyr9daJv44FEClEougVrz3uiMnDAKpD7rJ32/oc94c7YlVF/SjTz2fLA4n0nA9d/lkC1X6Tfj5JDwuMPURi1mNZlKZ9EhyQ916Sj1IakvnmQ9BNAAAAFQC706Ie1+oDglySpaHIIUNnDMAUtwAAAIAaCVEpV/IeEXvWtDhH7MzZMTn1JbhOzgIehuXX0XpGRI9q+OI7Khw7JmvhFBCTYfYpK3PK9bBMHiX8b1tNaorMc2UNQlJzJzjR2hTJgPJ8DgG/RyXbqpkUruXp8IyD4i+NSl1xNFEKentL32d+I4HshWO9n9XVH225GQrrVnZ/OgAAAIBHa5XkFIFKxiJxNurFYX4/X0a2IiaHGxO5ot6/73Atme7+3JhQvteR19d67bE1f7CXDl56el2oMHNrkpcPZkBWP6CnG7bLa65tN23sXjkbrV7HqZdCMZv4drzRtYo+I6MHNPsMmwGToOYeeL3JQH/EIUeXYLXlIw9+LM6P/k5iag==', 'OpenSSH DSA key parsed' );
    is ( $k->encryption, 'ssh-dss', 'DSA key' );
    is ( $k->type, 'public', 'Public key' );
    undef $k; undef @keys;
}
undef $tfh; undef $tempfile;


# parse BOTH formats of SSH2 pubkey from the SAME FILE!!
($tfh, $tempfile) = tempfile();
my $data = q{ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMGTizB5naTwPe9bi1FHyj0FAaPsIS0UmNO31g3WBK9AtIYQbZGRjiHqg28jYOHRd3EinASn40YXS4IoGPOb3BD//Bj8dMxQ0oQTHVsCx/Y/GrGBl7+tIHlknpMasf97WkJh4+k8P4amd6lPObUV0s9JaWx2KUJPui3bh7ymcXKzi90NT+zh5wRbGczbKXa05u+2DuofdgQC7PK6xPxwgGsOF2UlpuEPW2705umhkCQ1sOmQvwCVH9zQJk9jfuqE55gAAOewijDWcdu39v+m5OxITvMydpI6tJJY9QaptJdt0ORo8htfKBDH025nCEtPn2lwbEQO6X6zpDOzwxE4G3 sshuser@host
ssh-dss AAAAB3NzaC1kc3MAAACBAKxe0WtI19h2zNNJBbh0C52lGcs7WUvs6jlktWjd1anOVBwYEGIPUbcU0Frq8kyr9daJv44FEClEougVrz3uiMnDAKpD7rJ32/oc94c7YlVF/SjTz2fLA4n0nA9d/lkC1X6Tfj5JDwuMPURi1mNZlKZ9EhyQ916Sj1IakvnmQ9BNAAAAFQC706Ie1+oDglySpaHIIUNnDMAUtwAAAIAaCVEpV/IeEXvWtDhH7MzZMTn1JbhOzgIehuXX0XpGRI9q+OI7Khw7JmvhFBCTYfYpK3PK9bBMHiX8b1tNaorMc2UNQlJzJzjR2hTJgPJ8DgG/RyXbqpkUruXp8IyD4i+NSl1xNFEKentL32d+I4HshWO9n9XVH225GQrrVnZ/OgAAAIBHa5XkFIFKxiJxNurFYX4/X0a2IiaHGxO5ot6/73Atme7+3JhQvteR19d67bE1f7CXDl56el2oMHNrkpcPZkBWP6CnG7bLa65tN23sXjkbrV7HqZdCMZv4drzRtYo+I6MHNPsMmwGToOYeeL3JQH/EIUeXYLXlIw9+LM6P/k5iag== My 1024-bit DSA key
---- BEGIN SSH2 PUBLIC KEY ----
Subject: "sshuser AT domain DOT tld would be my email address if I we\
re to register it. Filler text will go here. We use filler text to ta\
ke up space as if it were a valid block of text, but in this case its\
 not."
Comment: "2048-bit rsa, user@host, Wed Dec 09 2009 13:26:29 -0600 and \
then we went fishin... and we caught a real big one. But not as big as\
 the one johnny brought home that one night. THE END"
AAAAB3NzaC1yc2EAAAADAQABAAABAQDGeSou4mEWqx2Lx8JIxOxH5MiVuXxJJrs36QOxzN
moskL6cUP4CO0TZtoqtnjVvaWryBfS65HNC9Q0KuTqLpXNTu+056mmhzvqJg5K6mhhtz44
7sMl+a5xrpS64I9uNKOIpjptRIvk8IaF//bY9n3DRLWSjxLwPVH8kZRQvWVtut3PKc5K/P
ngAd/AALRlMrBYFGY1AHDmutWL78vI2YCNusmFfJ8XEyNfsr6+ZhvnR6et1FdJd/L3HYRu
Zc9hJ2gV3Oorqj6PtUkQjvtSEsipTRJGLedg+734GXvQ0jJPsZWE0aVeq0m9jAHU1f312L
YCnbvZVjoBz/JwBoVK4Gxr
---- END SSH2 PUBLIC KEY ----
};

if ( write_file( $tempfile, $data ) ) {
    @keys = Parse::SSH2::PublicKey->parse_file( $tempfile );
    is( @keys, 3, "Correct number of keys parsed from input" );
    undef $k; undef @keys;
}
undef $tfh; undef $tempfile;


# parse BOTH formats of SSH2 pubkey from the SAME FILE!!
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
    #is( @keys, 3, "Invalid data." );
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



