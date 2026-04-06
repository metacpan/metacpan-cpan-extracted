package Net_ACME2_Example_Sync;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use parent 'Net_ACME2_Example';

use Crypt::Perl::ECDSA::Generate ();
use Crypt::Perl::PKCS10 ();

use HTTP::Tiny ();

# Used to report failed challenges.
use Data::Dumper;

use Net::ACME2::LetsEncrypt ();

use constant {
    _ECDSA_CURVE => 'secp384r1',
    CAN_WILDCARD => 0,
};

sub run {
    my ($class) = @_;

    my $_test_key = Crypt::Perl::ECDSA::Generate::by_name(_ECDSA_CURVE())->to_pem_with_curve_name();

    my $acme = Net::ACME2::LetsEncrypt->new(
        environment => 'staging',
        key => $_test_key,
    );

    #conditional is for if you want to modify this example to use
    #a pre-existing account.
    if (!$acme->key_id()) {
        print "$/Indicate acceptance of the terms of service at:$/$/";
        print "\t" . $acme->get_terms_of_service() . $/ . $/;
        print "… by hitting ENTER now.$/";
        <>;

        my $created = $acme->create_account(
            termsOfServiceAgreed => 1,
        );
    }

    my @domains = $class->_get_domains();

    my $order = $acme->create_order(
        identifiers => [ map { { type => 'dns', value => $_ } } @domains ],
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

    while (1) {
        for my $authz (@authzs) {
            next if $authz->status() eq 'valid';

            my $status = $acme->poll_authorization($authz);

            my $name = $authz->identifier()->{'value'};
            substr($name, 0, 0, '*.') if $authz->wildcard();

            if ($status eq 'valid') {

                print "$/“$name” has passed validation.$/";
            }
            elsif ($status eq 'pending') {
                print "$/“$name”’s authorization is still pending …$/";
            }
            else {
                if ($status eq 'invalid') {
                    my $challenge = $class->_get_challenge_from_authz($authz);
                    print Dumper($challenge);
                }

                die "$/“$name”’s authorization is in “$status” state.";
            }
        }

        $valid_authz_count = grep { $_->status() eq 'valid' } @authzs;
        last if $valid_authz_count == @authzs;

        sleep 1;
    }

    my ($key, $csr) = $class->_make_key_and_csr_for_domains(@domains);

    print "Finalizing order …$/";

    $acme->finalize_order($order, $csr);

    while ($order->status() ne 'valid') {
        sleep 1;
        $acme->poll_order($order);
    }

    print "Certificate key:$/$key$/$/";

    print "Certificate chain:$/$/";

    print $acme->get_certificate_chain($order);

    return;
}

1;
