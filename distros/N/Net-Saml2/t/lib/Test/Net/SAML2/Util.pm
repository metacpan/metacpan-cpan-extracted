package Test::Net::SAML2::Util;
use warnings;
use strict;

# ABSTRACT: Utils for testsuite of Net::SAML2

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
    get_xpath
    test_xml_attribute_ok
    test_xml_value_ok
    net_saml2_sp
    looks_like_a_cert
 );

our @EXPORT_OK;

our %EXPORT_TAGS = (
    all => [@EXPORT, @EXPORT_OK],
);

use XML::LibXML::XPathContext;
use XML::LibXML;
use Sub::Override;
use Test::More;
use Test::Exception;
use Net::SAML2::SP;
use Crypt::OpenSSL::X509;

sub net_saml2_sp {
    return Net::SAML2::SP->new(
        id               => 'http://localhost:3000',
        url              => 'http://localhost:3000',
        cert             => 't/sign-nopw-cert.pem',
        key              => 't/sign-nopw-cert.pem',
        cacert           => 't/cacert.pem',
        org_name         => 'Test',
        org_display_name => 'Test',
        org_contact      => 'test@example.com',
        @_,
    );
}

sub get_xpath {
    my ($xml, %ns) = @_;

    my $xp = XML::LibXML::XPathContext->new(
        XML::LibXML->load_xml(string => $xml)
    );

    $xp->registerNs($_, $ns{$_}) foreach keys %ns;

    return $xp;
}

sub test_xml_attribute_ok {
    my ($xpath, $search, $value) = @_;

    my @nodes = $xpath->findnodes($search);
    if (is(@nodes, 1, "$search returned one node")) {
        if (ref $value eq 'Regexp') {
            return like($nodes[0]->getValue, $value,
                ".. and value is what we expect");
        }
        return is($nodes[0]->getValue, $value, ".. and has value '$value'");
    }
    return 0;
}

sub test_xml_value_ok {
    my ($xpath, $search, $value) = @_;

    my @nodes = $xpath->findnodes($search);
    if (is(@nodes, 1, "$search returned one node")) {
        if (ref $value eq 'Regexp') {
            return like($nodes[0]->textContent, $value,
                ".. and value is what we expect");
        }
        return is($nodes[0]->textContent, $value, ".. and has value '$value'");
    }
    return 0;
}

sub looks_like_a_cert {
    my $cert = shift;
    lives_ok(
        sub {
            Crypt::OpenSSL::X509->new_from_string($cert);
        },
        "Looks like a certificate"
    );
}


1;

__END__

=head1 DESCRIPTION

=head1 SYNOPSIS

    use Test::Net::SAML2::XML;

    my $xpath = get_xpath($xml);
    # go from here
