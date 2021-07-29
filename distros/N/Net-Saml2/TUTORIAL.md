# Adding Net::SAML2 to your Web App

## Where to integrate

Net::SAML2 gets inserted into your login process (obviously).  If you already have support for multiple login types (local, ldap, oauth, etc) identify where each of those are triggered and insert yours.

As an example, Foswiki.org has support for multiple LoginManagers.  It has a configuration for:  $Foswiki::cfg{LoginManager} if you set it to 'Foswiki::LoginManager::SamlLogin' it will look in Foswiki/LoginManager for SamlLogin.pm and use that module as the login manager.

## Step 1 Integrating the login

In the case of Forwiki.org mentioned above it has a login function that is called first to begin the login process:

### Create an IdP object from the metadata

The metadata is provided by the Identity Provider (IdP).  Net::SAML2:IdP->new_from_url or Net::SAML2IdP->new_from_xml will take the metadata in the from specified and parse the metadata returning a Net::SAML2::IdP object

```
    my $idp = Net::SAML2::IdP->new_from_url(
        url => $metadata,	# URL where the xml is located
        cacert => $cacert,	# Filename of the Identity Providers CACert
        ssl_opts =>         # Optional options supported by LWP::Protocol::https
            {
                SSL_ca_file     => '/your/directory/cacert.pem',
                SSL_ca_path     => '/etc/ssl/certs',
                verify_hostname => 1,
            }

    );
```

or

```
    my $idp = Net::SAML2::IdP->new_from_xml(
        xml => $metadata_string,	# xml as a string
        cacert => $cacert,  		# Filename of the Identity Providers CACert
    );
```

The IdP object contains the Identity Providers settings that were parse from the metadata and are then used for the rest of the calls.

The Net::SAML2::IdP generated results in:

```
$VAR1 = bless( {
                 'slo_urls' => {},
                 'sso_urls' => {
                                 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST' => 'https://accounts.google.com/o/saml2/idp?idpid=C01nccos6',
                                 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect' => 'https://accounts.google.com/o/saml2/idp?idpid=C01nccos6'
                               },
                 'default_format' => 'emailAddress',
                 'cacert' => 't/cacert-google.pem',
                 'certs' => [
                              {
                                'signing' => '-----BEGIN CERTIFICATE-----
MIIDdDCCAlygAwIBAgIGAWj+rlteMA0GCSqGSIb3DQEBCwUAMHsxFDASBgNVBAoT
C0dvb2dsZSBJbmMuMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MQ8wDQYDVQQDEwZH
b29nbGUxGDAWBgNVBAsTD0dvb2dsZSBGb3IgV29yazELMAkGA1UEBhMCVVMxEzAR
BgNVBAgTCkNhbGlmb3JuaWEwHhcNMTkwMjE4MDMzNzQ1WhcNMjQwMjE3MDMzNzQ1
WjB7MRQwEgYDVQQKEwtHb29nbGUgSW5jLjEWMBQGA1UEBxMNTW91bnRhaW4gVmll
dzEPMA0GA1UEAxMGR29vZ2xlMRgwFgYDVQQLEw9Hb29nbGUgRm9yIFdvcmsxCzAJ
BgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEAubE4/cl70Lc2f7VV+ZJyzYIzuAMj6ejlbtRnym2kgyYj
aaO0MVU/r38oRC7UqdQIXwA0/S1Eu0k6EYcCUiyTGWz3HKv/OSOSnSDpN4wEWaZb
mJYvu8SjWZQCVdcM4fx1kzrtE+LEBTOKgj0k2G1qUMNI7xaqiJONO9aIeCic5zbA
CNpc+IOZoRS4RaY5Ie7W1ZIXAJ0xWL3snVdqklaJzzU2Myt5QX6W1Sd411Hzo+Ih
i5ksq18ML1tgMTFIqLkY2Luf5JJdZFRcCgvHrFF2CQywE0ftZtSSg5wD+hp3PJpL
5bxxF1vSdyKQbUia1Buc8+Cy6NTIbmLLIrcyULyHSwIDAQABMA0GCSqGSIb3DQEB
CwUAA4IBAQAXKjWrRzhgUW1+pK3V51MGl2b/yf33Ac4fm7GQql0Ag0Neye1EmdLj
D2N9gVeFawMcfRT4GABBHtS5bu01M8QHHAGjbBKfqOaPJc39v0Y/RCSd/FzXg99h
NT5UggAWVR+vC6a1IrVSUa5eKe82yBAubbdftvGtKHG90HIAsb1iyMKK2rGnTupg
JfJIUTWhWnWuemIVwduErFCxng//jYXViyEloz730faMIp6eNSD2+2cCssVGFb6F
xhCvVuNh6tgXv4vErVSWerFk/GcIh5n/biaDy/gEtAqgK154AfOifpDP3l3ZV/ce
lj1wSwcLF90e84XaVIkzb3veTcWhqaaq
-----END CERTIFICATE-----
'
                              }
                            ],
                 'formats' => {
                                'emailAddress' => 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
                              },
                 'art_urls' => {},
                 'entityid' => 'https://accounts.google.com/o/saml2?idpid=C01nccos6'
               }, 'Net::SAML2::IdP' );
```

### Create the authentication request

There are two methods to create the Authentication Request.

1. Net::SAML2::Protocol::AuthnRequest->new
2. Net::SAML2::Protocol::AuthnRequest->as_xml

However, it is better to use new() here because it makes tracking the AuthnRequest ID easier for later verification.

```
    my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
        issuer        => $issuer,
        destination   => $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
        provider_name => $provider_name,
    );

    # Store the request's id for later verification
    my saml_request_id = $authnreq->id
```

The **issuer** is the identifier that the web application uses to identify itself to the SAML2 Identity Provider.  You will need to specify that identifier in the setup of your chosen Identity provider (GSuite, Azure, OneLogin, KeyCloak, etc)

The **provider_name** is not really used by most IdPs that I have looked at.

The **destination** is set to the IdP's Single Sign-On Url that was parsed from the metadata.

The Net::SAML2::Protocol::AuthnRequest contains:

```
    $VAR1 = bless( {
        'issue_instant' => '2021-02-06T20:04:33Z',
        'RequestedAuthnContext_Comparison' => 'exact',
        'issuer' => bless( do{\(my $o = 'http://localhost:3000')}, 'URI::http' ),
        'id' => 'NETSAML2_2b0619fe11c985257aafeceec7de69b2',
        'destination' => bless( do{\(my $o = 'http://sso.dev.venda.com/opensso')}, 'URI::http' ),
        'AuthnContextClassRef' => [],
        'nameidpolicy_format' => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        'AuthnContextDeclRef' => []
    }, 'Net::SAML2::Protocol::AuthnRequest' );
```
and produces the following XML:

```
<saml2p:AuthnRequest
    Destination="http://sso.dev.venda.com/opensso"
    IssueInstant="2021-02-06T20:07:01Z"
    ID="NETSAML2_8b051f5fadfc747def3a8972df2c4984"
    Version="2.0"
    xmlns:saml2p="urn:oasis:names:tc:SAML:2.0:protocol"
    xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion">
        <saml2:Issuer>http://localhost:3000</saml2:Issuer>
        <saml2p:NameIDPolicy
            Format="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent">
        </saml2p:NameIDPolicy>
</saml2p:AuthnRequest>
```

The following fields are from the creation of the Net::SAML2::Protocol::AuthnRequest:

1. issuer
2. destination

The other important generated fields are:

1. id
2. issue_instant

#### id
The **id** is a xml-id type and is generated automatically.  The AuthnRequest ID sent to the Identity Provider is echoed back to the Service Provider in the SAMLResponse's InResponseTo field.

For the greatest security it is critical for the Service Provider (your web application) to track the submitted ID and verify that the response's InResponseTo is identical to ensure the response is associated to the request.

#### issue_instant

The **issue_instant** is the date and time of the request and is generated automatically.

### Create the Redirect object

The Net::SAML2::Binding::Redirect is used to create the redirect URL that will be used to redirect the user's browser to the Identity Provider's web site to login.

In addition, it could be used to process a redirect from the IdP to process a LoginRequest or LogoutResponse.

```
    my $redirect = Net::SAML2::Binding::Redirect->new(
        key => $sp_signing_cert,
        cert => $idp->cert('signing'),
        param => 'SAMLRequest',
        # The ssl_url destination for redirect
        url => $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
    );
```

**Note:** This is an odd one.  The cert parameter here is the IdP's signing certificate.

In a Net::SAML2::Binding::Redirect->Sign() it is not used at all (you are signing the request with the SP's signing key).

In Net::SAML2::Binding::Redirect->Verify() the IdP's signing certificate is used to verify a Redirect from the IdP.

the creation of the Net::SAML2::Binding::Redirect results in:

```
    $VAR1 = bless( {
        'param' => 'SAMLRequest',
        'url' => bless( do{\(my $o = 'http://sso.dev.venda.com/opensso/SSORedirect/metaAlias/idp')}, 'URI::http' ),
        'cert' => [
            {
                'signing' => '-----BEGIN CERTIFICATE-----
MIIDFTCCAf2gAwIBAgIBATANBgkqhkiG9w0BAQUFADA3MQswCQYDVQQGEwJVUzEO
MAwGA1UECgwFbG9jYWwxCzAJBgNVBAsMAmN0MQswCQYDVQQDDAJDQTAeFw0xMDEw
MDYxMjM4MTRaFw0xMTEwMDYxMjM4MTRaMFcxCzAJBgNVBAYTAlVTMQ4wDAYDVQQK
DAVsb2NhbDELMAkGA1UECwwCY3QxDTALBgNVBAMMBHNhbWwxHDAaBgkqhkiG9w0B
CQEWDXNhbWxAY3QubG9jYWwwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAMhu
pJZpvu1m6ys+IrWrm3pK+onwRAYCyrgQ0RyK2cHbVLFbjBqTjKnt+PiVbnZPZUTs
tkV9oijZGQvaMy9ingJursICUQzmOfYRDm4s9gFJJOHUGYnItRhp4uj3EoWWyX8I
6Mr+g3/vNgNFvD5S9L7Hk1mSw8SnPlblZAWlFUwXAgMBAAGjgY8wgYwwDAYDVR0T
AQH/BAIwADAxBglghkgBhvhCAQ0EJBYiUnVieS9PcGVuU1NMIEdlbmVyYXRlZCBD
ZXJ0aWZpY2F0ZTAdBgNVHQ4EFgQUGy/iPd7PVObrF+lK4+ZShcbStLYwCwYDVR0P
BAQDAgXgMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcDBDANBgkqhkiG9w0B
AQUFAAOCAQEAYoYq3Rc6jC7f8DnKxDHntHxH91F5mfp8Y3j7ALcRG/mrzkMhvxU2
O2qmh4aHzZBoY1EU9VjrVgyPJPAjFQVC+OjIE46Gavh5wobzYmVGeFLOa9NhPv50
h3EOw1eCda3VwcvStWw1OhT8cpEGqgJJVAcjwcm4VBtWjodxRn3E4zBr/xxzR1HU
ISvnu1/xomsSS+aenG5toWmhoJIKFbfhQkpnBlgGD5+12Cxn2jHpgv15262ZZIJS
WPp/0bQqdAAUzkJZPpUGUN1sTXPJexYT6na7XvLd6mvO1g+WDk6aZnW/zcT3T9tL
Iavyic/p4gZtXckweq+VTn9CdZp6ZTQtVw==
-----END CERTIFICATE-----
'
            }
                ],
        'key' => 't/sign-nopw-cert.pem'
    }, 'Net::SAML2::Binding::Redirect' );
```

#### key

The **key** is the absolute filename of the Service Provider's private key that should be used to sign the AuthnRequest that is being sent to the Identity Provider.

#### cert

The **cert** is the IdP signing cert as included in the Net::SAML2::IdP object.  It is used for the verify of a Redirect from the IdP.

#### url

The **url** is the the Single Sign On URL that was specified in the Identity Provider's metadata.

## Sign the AuthnRequest and generate the URL

The URL is created by calling the sign function of the Net::SAML2::Binding::Redirect object with the xml version of the AuthnRequest.

```
    my $url = $redirect->sign($authnreq->as_xml);

```
The signed URL is that results is:

```
$VAR1 = 'http://sso.dev.venda.com/opensso/SSORedirect/metaAlias/idp?SAMLRequest=fZFfS4RQEMXf%2BxRy39Xrv9wGFRYsWKglaumhl5j0ioLea8641Lfvagu1EPt6OHPOb2YywqEPR9jO3Oon9TErYudFTdQZnYvQk8LZlbnY3x6etw%2F34dtNXMcSqybB5Po9SYOmwUSGMTbBRkYyRWsnmtVOE6NmmyDDwJWhK9ODDCBOIdq8Cqe0LZ1GXkta5hF8n8h4tTp6R6Vr9Coz%2BGZU2qrC%2BRx6TfBDmot50mCQOgKNgyLgChY2sLAwToZNZfqzmcsjSKSmhUQU2WqHdYOpOHH1psK%2BNcQQSSkz%2F8yTnc63t7G78tH0XfXl3JlpQL7cuihd7TarFcbl4MRKs4Xw%2F8n8Vf8%2Bqrj6Bg%3D%3D&RelayState=http%3A%2F%2Freturn%2Furl&SigAlg=http%3A%2F%2Fwww.w3.org%2F2000%2F09%2Fxmldsig%23rsa-sha1&Signature=hCgKM%2FTqG2IGXw7Wqu7RlNNb%2BMaSUM1CSIzVaY4dgEtw1CLZzqFNUrji2owwgBS5QzW4FY77%2BY0UCTgI2X4VJel0Dc5VuPJV2RRYjPSQi9pUQ7fon4NAUbMbGFVGTTfh0sq2lNj8wdBMRXMdkbOJZqTmHNVoMfANj2%2FB7TrM0lo%3D';
```

## Redirect to the user's browser to the URL

At this point the web application needs to redirect the user's browser to the URL.  The Identity Provider will receive the XML at the sso_url that was defined in the metadata:

Using a browser add-on like **SAML Message Decoder** you should be able to view the fields in the SAML2 request that the browser sent.

```
    <saml2p:AuthnRequest
        Destination="http://sso.dev.venda.com/opensso"
        IssueInstant="2021-02-06T20:07:01Z"
        ID="NETSAML2_8b051f5fadfc747def3a8972df2c4984"
        Version="2.0"
        xmlns:saml2p="urn:oasis:names:tc:SAML:2.0:protocol"
        xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion">
            <saml2:Issuer>http://localhost:3000</saml2:Issuer>
            <saml2p:NameIDPolicy
                Format="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent">
            </saml2p:NameIDPolicy>
    </saml2p:AuthnRequest>
```

At this stage it is important for you to have the Service Provider SAML2 settings at the Identity Provider set correctly to match the values sent in the **AuthnRequest**


**Issuer** is also known as the **Entity ID**

You should get the Identity Provider's login page at this point.  If you do not, you need to review the AuthnRequest settings and the Service Providers settings to ensure that they match.  It is often useful to use a separate browser to avoid automatic login skipping steps.

## Step 2: Processing the SAMLResponse

After the successful login at the Identity provider it will perform a HTTP POST request via the user's browser to the Service Providers's ACS URL.  This can be a separate URL handled by the Web Application or the same login URL that the user accessed to initiate the login.  A callback looks for the **SAMLResponse** in the POST and processed that response.

### Your application specific items
There are a few things to think about for handling the response and mapping it to a user in your application:

1. Not accidentally passing through values from a previous login.  If your application sets session values during the processing the response specifically clear those values before you start processing.
2. SAMLResponse shown in the URL - Do you really want the user to see this?  If not delete it from the response after you have it in a variable to use.
3. Mapping your application user to the nameid returned.  You may need to provide a mapper to do things like remove @cpan.org from timlegge@cpan.org for example if your application expects timlegge to be the username.
4. Following your application's logic to generate the session token that indicates that the user is logged in.

### Extract the SAMLResponse from the HTTP Response

This will be different depending on your web application and how it handles POST responses.  Foswiki's SAMLLoginContrib for instance does the following:

```
    my $saml_response = $query->param('SAMLResponse');

    if (defined $saml_response) {
        $this->samlCallback($saml_response, $query, $session);
    }
```

Basically the $query in this case contains the POST to the web application and if there is a SAMLResponse parameter in the $query it passes the response to the callback function to handle the response.

### Create the POST object to process response

The security of SAML2 responses depends on trust in the Identity Provider.  Trust is implemented by signed XML in the response to the request.  The XML is signed by the Identity Provider with a private key that can be verified with the CACert provided by the Identity Provider.  This CACert should be capable of verifying at least one of the signing certificates provided in the metadata.

```
    $post = Net::SAML2::Binding::POST->new(
        cacert => $idp_cacert  # Filename of the Identity Providers CACert
    );

```
this results in:
```
    $VAR1 = bless( {
        'cacert' => 't/cacert.pem'
    }, 'Net::SAML2::Binding::POST' );
```

### Handle the response

The handle_response() of the Net::SAML2::Binding::POST object processes the response from the Identity Provider.

```
    # Send the SAMLResponse to the Binding for the POST
    # The return has the CA certificate Subject and verified if correct
    my $ret = $post->handle_response(
        $saml_response
    );
```

handle_response is pretty short but does a couple of important things:

1. Calls Net::SAML2::XML::Sig to verify the signatures in the $saml_response XML
2. Verifies that the certificate that signed the XML was signed by the $cacert

### Get the Assertion from the SAMLResponse XML

The SAMLResponse is base64 encoded XML.  The Net::SAML2::Protocol::Assertion->new_from_xml processes the full XML and create the Net::SAML2::Protocol::Assertion containing the assertion.

```
    my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
        xml => decode_base64($saml_response)
    );
```

### Validating the Assertion

A SAML2 Assertion is a point in time verification that the user logging into your web application was able to authenticate properly according to the rules of the Identity Provider.  As a point of interest adding two factor authentication to you web application is easy - if the Identity Provider supports it simply turn it on and the user must provide a second factor before the authentication is complete and before you receive the assertion.

As it is a point in time assertion, you need to verify the validity of the NotBefore and NotAfter values and the Issuer that the Identity Provider is providing the Assertion for the $saml_request_id.

For the $saml_request_id you need to retrieve it from wherever it was stored during the creation of the Net::SAML2::Protocol::AuthnRequest.  Foswiki.org SamlLoginContrib for instance had stored it in the user session.

```
    my $issuer = $Foswiki::cfg{Saml}{issuer};
    my $saml_request_id = $this->getAndClearSessionValue('saml_request_id');

    # $assertion->valid() checks the dates and the audience
    my $valid = $assertion->valid($issuer, $saml_request_id);
```

The call to $assertion->valid validates the following for the assertion:

1. That the $issuer configure in your application is the $audience of the assertion
2. That the $saml_request_id is the InResponseTo of the assertion
3. That the current time is within the NotBefore and NotAfter datetimes of the assertion

The security of your application is drastically reduced if you do not validate the assertion.

### Using the Assertion Results

The basic values you will need from the Assertion are contained in the following attributes of the Net::SAML2::Protocol::Assertion.

1. $assertion->nameid
2. $assertion->attributes

The nameid is the Identity Providers canonical userid that can be considered to be unique and is likely what you want to map to your application's user.

An example assertion attributes returned by GSuite could look like:

```
    $VAR1 = {
        'title' => [
            'Net::SAML2 Maintainer'
        ],
        'fname' => [
            'Timothy'
         ],
        'lname' => [
           'Legge'
         ],
        'Email' => [
           'timlegge@cpan.org'
         ],
        'phone' => [
           '4328675309',
           '4325551212'
         ]
    };
```
The assertion attributes are very specific to the combination of the Identity Provider and the SAML2 configuration.  It can include any user specific values that can be accessed or transformed during the setup.  It can also contain groups.

As a developer you need to review what is returned in the SAML2 Assertion from the Identity Provider and tweak the configuration of the SAML2 setup to obtain the values you would like to have processed by your web application.

Regardless, the attributes of the assertion will contain those values,  It is up to your application to use or ignore them as you see fit.

## Step 3: Generating the Service Provider (SP) Metadata (Optional)

Some Identity Providers allow you to import a XML file that has the Service Provider settings.  This allows you to ensure that the settings defined in your application are the same as those configured as the Service Provider settings in Identity Provider.

### Create the Service Provider (SP)

Typically an application will provide a method to request a copy of the SP metadata based on the configuration used in the application.  This can be on the configuration page or an actual URI like:

    login/saml?metadata=1

As it is an optional function and all web applications are different you need to find a place to integrate it into your application if you choose to implement.

```
    my $sp = Net::SAML2::SP->new(
        id                     => $provider_name,
        url                    => $issuer,
        cert                   => $sp_signing_cert,
        key                    => $sp_signing_key,
        cacert                 => $cacert,
        org_contact            => 'timlegge@cpan.org',
        org_name               => 'Net::SAML2',
        org_url                => 'https://metacpan.org/pod/Net::SAML2',
        org_display_name       => 'Net::SAML2',
        authnreq_signed        => '0', # Optional
        want_assertions_signed => '0', # Optional

    );
    my $xml = $sp->metatdata();
    return $xml;
```

this results in the following XML

```
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                     xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
                     entityID="http://localhost:3000">
  <md:SPSSODescriptor WantAssertionsSigned="0"
                      protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol"
                      AuthnRequestsSigned="0"
                      errorURL="http://localhost:3000/saml/error">
    <md:KeyDescriptor use="signing">
      <ds:KeyInfo>
        <ds:X509Data>
          <ds:X509Certificate>
          MIIDFTCCAf2gAwIBAgIBATANBgkqhkiG9w0BAQUFADA3MQswCQYDVQQGEwJVUzEO
          MAwGA1UECgwFbG9jYWwxCzAJBgNVBAsMAmN0MQswCQYDVQQDDAJDQTAeFw0xMDEw
          MDYxMjM4MTRaFw0xMTEwMDYxMjM4MTRaMFcxCzAJBgNVBAYTAlVTMQ4wDAYDVQQK
          DAVsb2NhbDELMAkGA1UECwwCY3QxDTALBgNVBAMMBHNhbWwxHDAaBgkqhkiG9w0B
          CQEWDXNhbWxAY3QubG9jYWwwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAMhu
          pJZpvu1m6ys+IrWrm3pK+onwRAYCyrgQ0RyK2cHbVLFbjBqTjKnt+PiVbnZPZUTs
          tkV9oijZGQvaMy9ingJursICUQzmOfYRDm4s9gFJJOHUGYnItRhp4uj3EoWWyX8I
          6Mr+g3/vNgNFvD5S9L7Hk1mSw8SnPlblZAWlFUwXAgMBAAGjgY8wgYwwDAYDVR0T
          AQH/BAIwADAxBglghkgBhvhCAQ0EJBYiUnVieS9PcGVuU1NMIEdlbmVyYXRlZCBD
          ZXJ0aWZpY2F0ZTAdBgNVHQ4EFgQUGy/iPd7PVObrF+lK4+ZShcbStLYwCwYDVR0P
          BAQDAgXgMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcDBDANBgkqhkiG9w0B
          AQUFAAOCAQEAYoYq3Rc6jC7f8DnKxDHntHxH91F5mfp8Y3j7ALcRG/mrzkMhvxU2
          O2qmh4aHzZBoY1EU9VjrVgyPJPAjFQVC+OjIE46Gavh5wobzYmVGeFLOa9NhPv50
          h3EOw1eCda3VwcvStWw1OhT8cpEGqgJJVAcjwcm4VBtWjodxRn3E4zBr/xxzR1HU
          ISvnu1/xomsSS+aenG5toWmhoJIKFbfhQkpnBlgGD5+12Cxn2jHpgv15262ZZIJS
          WPp/0bQqdAAUzkJZPpUGUN1sTXPJexYT6na7XvLd6mvO1g+WDk6aZnW/zcT3T9tL
          Iavyic/p4gZtXckweq+VTn9CdZp6ZTQtVw==
 
          </ds:X509Certificate>
        </ds:X509Data>
      </ds:KeyInfo>
    </md:KeyDescriptor>
    <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
                            Location="http://localhost:3000/saml/slo-soap" />
    <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                            Location="http://localhost:3000/saml/sls-redirect-response" />
    <md:AssertionConsumerService isDefault="true"
                                 Location="http://localhost:3000/saml/consumer-post"
                                 index="1"
                                 Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" />
    <md:AssertionConsumerService index="2"
                                 Location="http://localhost:3000/saml/consumer-artifact"
                                 isDefault="false"
                                 Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact" />
  </md:SPSSODescriptor>
  <md:Organization>
    <md:OrganizationName xml:lang="en">Net::SAML2</md:OrganizationName>
    <md:OrganizationDisplayName xml:lang="en">Net::SAML2</md:OrganizationDisplayName>
    <md:OrganizationURL xml:lang="en">https://metacpan.org/pod/Net::SAML2</md:OrganizationURL>
  </md:Organization>
  <md:ContactPerson contactType="other">
    <md:Company>Net::SAML2</md:Company>
    <md:EmailAddress>timlegge@cpan.org</md:EmailAddress>
  </md:ContactPerson>
</md:EntityDescriptor>

```

