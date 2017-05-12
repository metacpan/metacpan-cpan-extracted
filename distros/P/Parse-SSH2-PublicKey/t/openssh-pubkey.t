#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 11;

use_ok('Parse::SSH2::PublicKey');

my (@keys, $k);

my $openssh_rsa_pub = q{ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMGTizB5naTwPe9bi1FHyj0FAaPsIS0UmNO31g3WBK9AtIYQbZGRjiHqg28jYOHRd3EinASn40YXS4IoGPOb3BD//Bj8dMxQ0oQTHVsCx/Y/GrGBl7+tIHlknpMasf97WkJh4+k8P4amd6lPObUV0s9JaWx2KUJPui3bh7ymcXKzi90NT+zh5wRbGczbKXa05u+2DuofdgQC7PK6xPxwgGsOF2UlpuEPW2705umhkCQ1sOmQvwCVH9zQJk9jfuqE55gAAOewijDWcdu39v+m5OxITvMydpI6tJJY9QaptJdt0ORo8htfKBDH025nCEtPn2lwbEQO6X6zpDOzwxE4G3 sshuser@host};
my $openssh_dsa_pub = q{ssh-dss AAAAB3NzaC1kc3MAAACBAKxe0WtI19h2zNNJBbh0C52lGcs7WUvs6jlktWjd1anOVBwYEGIPUbcU0Frq8kyr9daJv44FEClEougVrz3uiMnDAKpD7rJ32/oc94c7YlVF/SjTz2fLA4n0nA9d/lkC1X6Tfj5JDwuMPURi1mNZlKZ9EhyQ916Sj1IakvnmQ9BNAAAAFQC706Ie1+oDglySpaHIIUNnDMAUtwAAAIAaCVEpV/IeEXvWtDhH7MzZMTn1JbhOzgIehuXX0XpGRI9q+OI7Khw7JmvhFBCTYfYpK3PK9bBMHiX8b1tNaorMc2UNQlJzJzjR2hTJgPJ8DgG/RyXbqpkUruXp8IyD4i+NSl1xNFEKentL32d+I4HshWO9n9XVH225GQrrVnZ/OgAAAIBHa5XkFIFKxiJxNurFYX4/X0a2IiaHGxO5ot6/73Atme7+3JhQvteR19d67bE1f7CXDl56el2oMHNrkpcPZkBWP6CnG7bLa65tN23sXjkbrV7HqZdCMZv4drzRtYo+I6MHNPsMmwGToOYeeL3JQH/EIUeXYLXlIw9+LM6P/k5iag== My 1024-bit DSA key};

# parse openssh rsa key
@keys = Parse::SSH2::PublicKey->parse( $openssh_rsa_pub );
$k    = $keys[0];
isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got Parse::SSH2::PublicKey object' );
is ( $k->type, 'public', 'Public key' );
is ( $k->encryption, 'ssh-rsa', 'RSA key' );
is( $k->comment, 'sshuser@host', 'OpenSSH RSA comment parsed.' );
is( $k->key, 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDMGTizB5naTwPe9bi1FHyj0FAaPsIS0UmNO31g3WBK9AtIYQbZGRjiHqg28jYOHRd3EinASn40YXS4IoGPOb3BD//Bj8dMxQ0oQTHVsCx/Y/GrGBl7+tIHlknpMasf97WkJh4+k8P4amd6lPObUV0s9JaWx2KUJPui3bh7ymcXKzi90NT+zh5wRbGczbKXa05u+2DuofdgQC7PK6xPxwgGsOF2UlpuEPW2705umhkCQ1sOmQvwCVH9zQJk9jfuqE55gAAOewijDWcdu39v+m5OxITvMydpI6tJJY9QaptJdt0ORo8htfKBDH025nCEtPn2lwbEQO6X6zpDOzwxE4G3', 'OpenSSH RSA key parsed' );
undef $k; undef @keys;

# parse openssh dsa keys...
@keys = Parse::SSH2::PublicKey->parse( $openssh_dsa_pub );
$k    = $keys[0];
isa_ok( $k, 'Parse::SSH2::PublicKey', 'Got Parse::SSH2::PublicKey object' );
is ( $k->type, 'public', 'Public key' );
is ( $k->encryption, 'ssh-dss', 'DSA key' );
is( $k->comment, 'My 1024-bit DSA key', 'OpenSSH DSA comment parsed.' );
is( $k->key, 'AAAAB3NzaC1kc3MAAACBAKxe0WtI19h2zNNJBbh0C52lGcs7WUvs6jlktWjd1anOVBwYEGIPUbcU0Frq8kyr9daJv44FEClEougVrz3uiMnDAKpD7rJ32/oc94c7YlVF/SjTz2fLA4n0nA9d/lkC1X6Tfj5JDwuMPURi1mNZlKZ9EhyQ916Sj1IakvnmQ9BNAAAAFQC706Ie1+oDglySpaHIIUNnDMAUtwAAAIAaCVEpV/IeEXvWtDhH7MzZMTn1JbhOzgIehuXX0XpGRI9q+OI7Khw7JmvhFBCTYfYpK3PK9bBMHiX8b1tNaorMc2UNQlJzJzjR2hTJgPJ8DgG/RyXbqpkUruXp8IyD4i+NSl1xNFEKentL32d+I4HshWO9n9XVH225GQrrVnZ/OgAAAIBHa5XkFIFKxiJxNurFYX4/X0a2IiaHGxO5ot6/73Atme7+3JhQvteR19d67bE1f7CXDl56el2oMHNrkpcPZkBWP6CnG7bLa65tN23sXjkbrV7HqZdCMZv4drzRtYo+I6MHNPsMmwGToOYeeL3JQH/EIUeXYLXlIw9+LM6P/k5iag==', 'OpenSSH DSA key parsed' );
undef $k; undef @keys;

