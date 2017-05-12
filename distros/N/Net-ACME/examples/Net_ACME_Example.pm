package Net_ACME_Example;

use strict;
use warnings;

use Call::Context ();

use FindBin;
use lib "$FindBin::Bin/../lib";

use Net::ACME::Crypt ();
use Net::ACME::LetsEncrypt ();

use Crypt::Perl::ECDSA::Generate ();
use Crypt::Perl::PKCS10 ();

#LE doesn’t seem to support this curve.
#my $ECDSA_CURVE = 'secp521r1';

my $ECDSA_CURVE = 'secp384r1';

sub do_example {
    my ($handle_combination_cr) = @_;

    my $tos_url = Net::ACME::LetsEncrypt->get_terms_of_service();
    print "Look at:$/$/\t$tos_url$/$/… and hit CTRL-C if you DON’T accept these terms.$/";
    <STDIN>;

    my $reg_key = Crypt::Perl::ECDSA::Generate::by_name($ECDSA_CURVE);

    my $reg_key_pem = $reg_key->to_pem_with_curve_name();

    #Want a real cert? Then comment this out.
    {
        no warnings 'redefine';
        *Net::ACME::LetsEncrypt::_HOST = \&Net::ACME::LetsEncrypt::STAGING_SERVER;
    }

    my $acme = Net::ACME::LetsEncrypt->new( key => $reg_key_pem );

    my $reg = $acme->register();

    $acme->accept_tos( $reg->uri(), $tos_url );

    #----------------------------------------------------------------------

    my @domains;
    while (1) {
        print 'Enter a domain for the certificate (or ENTER if you’re done): ';
        my $d = <STDIN>;
        chomp $d;
        last if !defined $d || !length $d;
        push( @domains, $d );
    }

    print $/;

    my ( $cert_key_pem, $csr_pem ) = _make_key_and_csr_for_domains(@domains);

    my $jwk = Net::ACME::Crypt::parse_key($reg_key_pem)->get_struct_for_public_jwk();

    for my $domain (@domains) {
        my $authz_p = $acme->start_domain_authz($domain);

        for my $cmb_ar ( $authz_p->combinations() ) {

            my @challenges = $handle_combination_cr->( $domain, $cmb_ar, $jwk );

            next if !@challenges;

            $acme->do_challenge($_) for @challenges;

            while (1) {
                if ( $authz_p->is_time_to_poll() ) {
                    my $poll = $authz_p->poll();

                    last if $poll->status() eq 'valid';

                    if ( $poll->status() eq 'invalid' ) {
                        my @failed = map { $_->error() } $poll->challenges();

                        print $_->to_string() . $/ for @failed;

                        die "Failed authorization for “$domain”!$/";
                    }

                }

                sleep 1;
            }
        }
    }

    my $cert = $acme->get_certificate($csr_pem);

    #This shouldn’t actually be necessary for Let’s Encrypt,
    #but the ACME protocol describes it.
    while ( !$cert->pem() ) {
        sleep 1;
        next if !$cert->is_time_to_poll();
        $cert = $cert->poll() || $cert;
    }

    print map { "$_$/" } $cert_key_pem, $cert->pem(), $cert->issuers_pem();

    return;
}

sub _make_key_and_csr_for_domains {
    my (@domains) = @_;

    Call::Context::must_be_list();

    #ECDSA is used here because it’s quick enough to run in pure Perl.
    #If you need/want RSA, look at Crypt::OpenSSL::RSA, and/or
    #install Math::BigInt::GMP (or M::BI::Pari) and use
    #Crypt::Perl::RSA::Generate. Or just do qx<openssl genrsa>. :)
    my $key = Crypt::Perl::ECDSA::Generate::by_name($ECDSA_CURVE);

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
