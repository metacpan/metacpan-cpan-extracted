package Net_ACME_Example;

use strict;
use warnings;

use Call::Context ();

use FindBin;
use lib "$FindBin::Bin/../lib";

use Net::ACME::LetsEncrypt ();

use Crypt::OpenSSL::RSA    ();
use Crypt::OpenSSL::PKCS10 ();

my $KEY_SIZE = 2_048;

sub do_example {
    my ($handle_combination_cr) = @_;

    my $tos_url = Net::ACME::LetsEncrypt->get_terms_of_service();
    print "Look at:$/$/\t$tos_url$/$/… and hit CTRL-C if you DON’T accept these terms.$/";
    <STDIN>;

    #Safe as of 2016
    my $key_size = 2_048;

    my $reg_rsa     = Crypt::OpenSSL::RSA->generate_key($KEY_SIZE);
    my $reg_rsa_pem = $reg_rsa->get_private_key_string();

    #Want a real cert? Then comment this out.
    {
        no warnings 'redefine';
        *Net::ACME::LetsEncrypt::_HOST = \&Net::ACME::LetsEncrypt::STAGING_SERVER;
    }

    my $acme = Net::ACME::LetsEncrypt->new( key => $reg_rsa_pem );

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

    my ( $cert_key_pem, $csr_pem ) = _make_csr_for_domains(@domains);

    for my $domain (@domains) {
        my $authz_p = $acme->start_domain_authz($domain);

        for my $cmb_ar ( $authz_p->combinations() ) {

            my @challenges = $handle_combination_cr->( $domain, $cmb_ar, $reg );

            next if !@challenges;

            $acme->do_challenge($_) for @challenges;

            while (1) {
                if ( $authz_p->is_time_to_poll() ) {
                    my $poll = $authz_p->poll();

                    last if $poll->status() eq 'valid';

                    if ( $poll->status() eq 'invalid' ) {
                        my @failed = grep { $_->error() } $poll->challenges();

                        print $_->to_string() . $/ for @failed;

                        die "Failed authorization for “$domain”!$/";
                    }

                }

                sleep 1;
            }
        }
    }

    #Create your own CSR (e.g., using Crypt::OpenSSL::PKCS10).
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

sub _make_csr_for_domains {
    my (@domains) = @_;
    Call::Context::must_be_list();

    my $rsa = Crypt::OpenSSL::RSA->generate_key($KEY_SIZE);

    my $req = Crypt::OpenSSL::PKCS10->new_from_rsa($rsa);
    $req->set_subject('/');

    my @san_parts = map { "DNS.$_:$domains[$_]" } 0 .. $#domains;

    $req->add_ext(
        Crypt::OpenSSL::PKCS10::NID_subject_alt_name(),
        join( ',', @san_parts ),
    );
    $req->add_ext_final();

    $req->sign();

    return ( $rsa->get_private_key_string(), $req->get_pem_req() );
}

1;
