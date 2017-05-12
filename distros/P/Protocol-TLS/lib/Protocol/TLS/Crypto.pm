package Protocol::TLS::Crypto;
use strict;
use warnings;
use Module::Runtime qw(compose_module_name require_module);

# TODO: select backend
our $BACKEND = 'CryptX';

my $crypto  = undef;
my @methods = (qw(PRF PRF_hash random rsa_encrypt cert_pubkey));

sub new {
    return $crypto if $crypto;
    my $module = compose_module_name( 'Protocol::TLS::Crypto', $BACKEND );
    require_module $module;
    my $crypto = $module->new;
    for (@methods) {
        die ref($crypto) . " backend doesn't implement method $_\n"
          unless $crypto->can($_);
    }
    $crypto;
}

1
