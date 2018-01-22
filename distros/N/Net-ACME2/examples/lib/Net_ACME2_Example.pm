package Net_ACME2_Example;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Crypt::Perl::ECDSA::Generate ();
use Crypt::Perl::PKCS10 ();

use HTTP::Tiny ();

use Net::ACME2::LetsEncrypt ();

use constant {
    _ECDSA_CURVE => 'secp384r1',
    CAN_WILDCARD => 0,
};

sub run {
    my ($class) = @_;

    my $_test_key = Crypt::Perl::ECDSA::Generate::by_name(_ECDSA_CURVE())->to_pem_with_curve_name();
    print "Account key:$/$_test_key$/";

    my $acme = Net::ACME2::LetsEncrypt->new(
        key => $_test_key,
    );

    #conditional is for if you want to modify this example to use
    #a pre-existing account.
    if (!$acme->key_id()) {
        print "$/Indicate acceptance of the terms of service at:$/$/";
        print "\t" . $acme->get_terms_of_service() . $/ . $/;
        print "… by hitting ENTER now.$/";
        <>;

        my $created = $acme->create_new_account(
            termsOfServiceAgreed => 1,
        );

        printf "key ID: %s$/", $acme->key_id();
    }

    my @domains = $class->_get_domains();

    my $order = $acme->create_new_order(
        identifiers => [ map { { type => 'dns', value => $_ } } @domains ],
        #notAfter => (time + 86400),
        #notAfter => 'hahahahah',   #it accepts this?!?
    );

    my @authzs = map { $acme->get_authorization($_) } $order->authorizations();
    my $valid_authz_count = 0;

    for my $authz_obj (@authzs) {
        my $domain = $authz_obj->identifier()->{'value'};

        if ($authz_obj->status() eq 'valid') {
            $valid_authz_count++;
            print "$/This account is already authorized on $domain.$/";
            next;
        }

        my $challenge = $class->_authz_handler($acme, $authz_obj);

        $acme->accept_challenge($challenge);
    }

    while ($valid_authz_count != @authzs) {
        my $waiting;
        for my $authz (@authzs) {
            next if $authz->status() eq 'valid';
            if ($acme->poll_authorization($authz)) {
                $valid_authz_count++;
            }
            else {
                $waiting = 1;
            }
        }

        sleep 1 if $waiting;
    }

    my ($key, $csr) = _make_key_and_csr_for_domains(@domains);

    $acme->finalize_order($order, $csr);

    while ($order->status() ne 'valid') {
        sleep 1;
        $acme->poll_order($order);
    }

    print "Certificate key:$/$key$/$/";

    print "$/Certificate URL: " . $order->certificate() . $/ . $/;

    print HTTP::Tiny->new()->get($order->certificate())->{'content'};

    return;
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
    my (@domains) = @_;

    Call::Context::must_be_list();

    #ECDSA is used here because it’s quick enough to run in pure Perl.
    #If you need/want RSA, look at Crypt::OpenSSL::RSA, and/or
    #install Math::BigInt::GMP (or M::BI::Pari) and use
    #Crypt::Perl::RSA::Generate. Or just do qx<openssl genrsa>. :)
    my $key = Crypt::Perl::ECDSA::Generate::by_name(_ECDSA_CURVE());

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
