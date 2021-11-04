use strict;
use warnings;

use Test::Lib;
use Test::Net::SAML2;

use MIME::Base64;
use Net::SAML2::IdP;
use Net::SAML2::Protocol::Assertion;

# This test follows the flow of the TUTORIAL.md.  The comments below
# follows the major headings of that document to implement a full
# SP client authentication process.

# The only part that is missing is the user, redirect, IdP
# web server flow.  That is implemented via a call to
# Test::Net::SAML2->net_saml2_binding_redirect_request($url, $idp).

# The function receives the url that would be used to access the IdP and
# responds with the SAMLResponse that the web browser would receive back
# from the IdP.  Essentially implementing the login process at the IdP.

my $idp_issuer;
my $idp_audience;
my $cacert          = 't/net-saml2-cacert.pem';
my $audience        = $idp_issuer   = "http://sso.dev.venda.com/opensso";
my $issuer          = $idp_audience = 'http://ct.local/saml/consumer-post';
my $provider        = "Net::SAML2-Testing-Provider";
my $sp_signing_key  = 't/net-saml2-key.pem';
my $metadata        = 't/net-saml2-metadata.xml';

#########################################
# Create an IdP object from the metadata
#########################################
my $metadata_xml    = path($metadata)->slurp;
ok ($metadata_xml, "Metadata loaded");

my $idp = Net::SAML2::IdP->new_from_xml(
        xml => $metadata_xml,       # xml as a string
        cacert => $cacert,          # Filename of the Identity Providers CACert
);
isa_ok ($idp, "Net::SAML2::IdP", "IdP created successfully");

####################################
# Create the authentication request
####################################
my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
        issuer        => $issuer,
        destination   => $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
        provider_name => $provider,
);
isa_ok($authnreq, "Net::SAML2::Protocol::AuthnRequest", "AuthnRequest created successfully");

my $saml_request_id = $authnreq->id;
ok($saml_request_id =~ /NETSAML2_/, "Valid AuthnRequest ID: $saml_request_id");

#############################
# Create the Redirect object
#############################
my $redirect = Net::SAML2::Binding::Redirect->new(
        key => $sp_signing_key,
        cert => $idp->cert('signing'),
        param => 'SAMLRequest',
        # The ssl_url destination for redirect
        url => $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
);
isa_ok($redirect, "Net::SAML2::Binding::Redirect", "Redirect created successfully");

#############################################
# Sign the AuthnRequest and generate the URL
#############################################
my $url = $redirect->sign($authnreq->as_xml);
ok($url =~ /rsa/, "Sucessfully signed AuthnRequest");

############################################
# Redirect to the user's browser to the URL
############################################
my $saml_response = net_saml2_binding_redirect_request($url, $idp);

#############################################
# Create the POST object to process response
#############################################
my $post = Net::SAML2::Binding::POST->new(
        cacert => $idp->cacert  # Filename of the Identity Providers CACert
);
isa_ok($post, "Net::SAML2::Binding::POST", "POST Binding created");

######################
# Handle the response
######################
my $ret = $post->handle_response(
        $saml_response
);

##############################################
# Get the Assertion from the SAMLResponse XML
##############################################
my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
        xml => decode_base64($saml_response)
);

if (defined $assertion->{response_status}) {
    # Not currently implemented in Net::SAML2::Protocol::Assertion
    ok($assertion->{response_status} eq 'urn:oasis:names:tc:SAML:2.0:status:Success', "Response Status - Success")
}
ok($assertion->{in_response_to} eq $saml_request_id,
    "Assertion InResponseTo: $assertion->{in_response_to}");

###########################
# Validating the Assertion
###########################
my $valid = $assertion->valid($issuer, $saml_request_id);
ok($valid, "Assertion is valid");

##############################
# Using the Assertion Results
##############################
my $attributes = $assertion->attributes;
ok($assertion->{nameid} eq 'timlegge@cpan.org', "$assertion->{nameid} would login sucessfully");
ok($assertion->{issuer} eq $idp_issuer, "IdP Issuer is: $assertion->{issuer}");
ok($assertion->{audience} eq $idp_audience, "Audience found in response: $assertion->{audience}");
if (defined $assertion->{provider}) {
        ok($assertion->{provider} eq $provider, "$assertion->{provider}");
}
ok($assertion->{nameid} eq 'timlegge@cpan.org', "$assertion->{nameid} would login sucessfully");
ok($attributes->{fname}[0] eq 'Timothy', "First Name: $attributes->{fname}[0]");
ok($attributes->{lname}[0] eq 'Legge', "Last Name: $attributes->{lname}[0]");
ok($attributes->{Email}[0] eq 'timlegge@cpan.org', "Email Address: $attributes->{Email}[0]");
ok($attributes->{title}[0] eq 'Developer', "Title: $attributes->{title}[0]");
ok($attributes->{phone}[0] eq '4408675309', "Phone 1: $attributes->{phone}[0]");
ok($attributes->{phone}[1] eq '4408675310', "Phone 2: $attributes->{phone}[1]");
done_testing();
