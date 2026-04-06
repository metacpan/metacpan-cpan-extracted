package Net_ACME2_Example;

use strict;
use warnings;

use Call::Context;
use Crypt::Perl::ECDSA::Generate;
use Crypt::Perl::PKCS10;

sub _get_challenge_from_authz {
    my ($class, $authz_obj) = @_;

    my $challenge_type = $class->_CHALLENGE_TYPE();

    my ($challenge) = grep { $_->type() eq $challenge_type } $authz_obj->challenges();

    if (!$challenge) {
        die "No “$challenge_type” challenge for “$authz_obj”!\n";
    }

    return $challenge;
}

sub _get_domains {
    my ($self) = @_;

    print $/;

    my @domains;
    while (1) {
        print "Enter a domain for the certificate (or ENTER if you’re done): ";
        my $d = <STDIN>;
        chomp $d;

        if (!defined $d || !length $d) {
            last if @domains;

            warn "Give at least one domain.$/";
        }
        else {
            if ($d =~ tr<*><> && !$self->CAN_WILDCARD) {
                warn "This authorization type can’t do wildcard!\n";
            }
            else {
                push( @domains, $d );
            }
        }
    }

    return @domains;
}

sub _make_key_and_csr_for_domains {
    my ($class, @domains) = @_;

    Call::Context::must_be_list();

    #ECDSA is used here because it’s quick enough to run in pure Perl.
    #If you need/want RSA, look at Crypt::PK::RSA, and/or
    #install Math::BigInt::GMP (or M::BI::Pari) and use
    #Crypt::Perl::RSA::Generate. Or just do qx<openssl genrsa>. :)
    my $key = Crypt::Perl::ECDSA::Generate::by_name($class->_ECDSA_CURVE());

    my $pkcs10 = Crypt::Perl::PKCS10->new(
        key => $key,

        subject => [
            commonName => $domains[0],
        ],

        attributes => [
            [ 'extensionRequest',
                [ 'subjectAltName', map { ( dNSName => $_ ) } @domains ],
            ],
        ],
    );

    return ( $key->to_pem_with_curve_name(), $pkcs10->to_pem() );
}

1;
