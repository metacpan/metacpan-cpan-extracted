use Test::More tests => 7;

use CGI;

use Test::Mock::LWP;
$Mock_ua->set_isa('LWP::UserAgent');

use Net::Google::FederatedLogin;
my $fl = Net::Google::FederatedLogin->new(
    claimed_id => 'example@example.com',
    return_to => 'http://example.com/return',
    extensions => [
        {
            ns          => 'ax',
            uri         => 'http://openid.net/srv/ax/1.0',
            attributes  => {
                mode        => 'fetch_request',
                required    => 'email',
                type        => {
                    email => 'http://axschema.org/contact/email'
                }
            }
        },
        {
            ns          => 'other',
            uri         => 'http://example.com/some_schema',
            attributes  => {
                argument    => 'value',
            }
        }
    ]);

my %update_mock_response = (
    'https://www.google.com/accounts/o8/.well-known/host-meta?hd=example.com'   => sub {
        $Mock_response->mock(is_success => sub {return 1});
        $Mock_response->mock(decoded_content => sub { return q{Link: <https://www.google.com/accounts/o8/site-xrds?ns=2&hd=example.com>; rel="describedby http://reltype.google.com/openid/xrd-op"; type="application/xrds+xml"}})
    },
    'https://www.google.com/accounts/o8/site-xrds?ns=2&hd=example.com'  => sub {
        $Mock_response->mock(decoded_content => sub { return q{<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
  <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <ds:SignedInfo>
  <ds:CanonicalizationMethod Algorithm="http://docs.oasis-open.org/xri/xrd/2009/01#canonicalize-raw-octets" />
  <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />
  </ds:SignedInfo>
  <ds:KeyInfo>
  <ds:X509Data>
  <ds:X509Certificate>
  MIIDLjCCApegAwIBAgIHALrcoAADBTANBgkqhkiG9w0BAQUFADBGMQswCQYDVQQGEwJVUzETMBEGA1UEChMKR29vZ2xlIEluYzEiMCAGA1UEAxMZR29vZ2xlIEludGVybmV0IEF1dGhvcml0eTAeFw0xMDA0MDcwMDAwMDBaFw0xMDA0MDkwMDAwMDBaMFYxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRMwEQYDVQQKEwpHb29nbGUgSW5jMR0wGwYDVQQDExRob3N0ZWQtaWQuZ29vZ2xlLmNvbTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA7UT2l+gZ7CjMCLvsMfvx3kWKojN9mmx2Aomylz8YnG60vE/WmQ/xZc9cw4orUgTFaqLcoju1khhg2kAPYRWB/ucC68NSIS/9/zex7Ssizz2MzxWxTc72nFwpTeOVygi0kw5TFCdYeNA110LpQ/+UOhjnFFtjS+ZDmkxXZj73eTMCAwEAAaOCARQwggEQMAkGA1UdEwQCMAAwHQYDVR0OBBYEFJ7cx4ptai4iTZ+RQO6mjTom1hIgMB8GA1UdIwQYMBaAFL/AMOv1QxE+Z7qekfv8atrjaxIkMFsGA1UdHwRUMFIwUKBOoEyGSmh0dHA6Ly93d3cuZ3N0YXRpYy5jb20vR29vZ2xlSW50ZXJuZXRBdXRob3JpdHkvR29vZ2xlSW50ZXJuZXRBdXRob3JpdHkuY3JsMGYGCCsGAQUFBwEBBFowWDBWBggrBgEFBQcwAoZKaHR0cDovL3d3dy5nc3RhdGljLmNvbS9Hb29nbGVJbnRlcm5ldEF1dGhvcml0eS9Hb29nbGVJbnRlcm5ldEF1dGhvcml0eS5jcnQwDQYJKoZIhvcNAQEFBQADgYEAmHHGVA4FsHBmSXJNXMPl7OVmBGvnV9Z91rLvJ8V0l8Bw7VVgUEHzCuclfO5hzRLlvyQLDGG+KtrDEx1lVZ9Qes3Y3WYL6M1yYAVKtxcDLXOTwgvfrVh/otgIOKtoSrDg62BjpKGgXWXAnOlsjvRF/OgIOQOMGhUgzDCTdkjC3+k=
  </ds:X509Certificate>
  <ds:X509Certificate>
  MIICsDCCAhmgAwIBAgIDC2dxMA0GCSqGSIb3DQEBBQUAME4xCzAJBgNVBAYTAlVTMRAwDgYDVQQKEwdFcXVpZmF4MS0wKwYDVQQLEyRFcXVpZmF4IFNlY3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMDkwNjA4MjA0MzI3WhcNMTMwNjA3MTk0MzI3WjBGMQswCQYDVQQGEwJVUzETMBEGA1UEChMKR29vZ2xlIEluYzEiMCAGA1UEAxMZR29vZ2xlIEludGVybmV0IEF1dGhvcml0eTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAye23pIucV+eEPkB9hPSP0XFjU5nneXQUr0SZMyCSjXvlKAy6rWxJfoNfNFlOCnowzdDXxFdF7dWq1nMmzq0yE7jXDx07393cCDaob1FEm8rWIFJztyaHNWrbqeXUWaUr/GcZOfqTGBhs3t0lig4zFEfC7wFQeeT9adGnwKziV28CAwEAAaOBozCBoDAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFL/AMOv1QxE+Z7qekfv8atrjaxIkMB8GA1UdIwQYMBaAFEjmaPkr0rKV10fYIyAQTzOYkJ/UMBIGA1UdEwEB/wQIMAYBAf8CAQAwOgYDVR0fBDMwMTAvoC2gK4YpaHR0cDovL2NybC5nZW90cnVzdC5jb20vY3Jscy9zZWN1cmVjYS5jcmwwDQYJKoZIhvcNAQEFBQADgYEAuIojxkiWsRF8YHdeBZqrocb6ghwYB8TrgbCoZutJqOkM0ymt9e8kTP3kS8p/XmOrmSfLnzYhLLkQYGfN0rTw8Ktx5YtaiScRhKqOv5nwnQkhClIZmloJ0pC3+gz4fniisIWvXEyZ2VxVKfmlUUIuOss4jHg7y/j7lYe8vJD5UDI=
  </ds:X509Certificate>
  </ds:X509Data>
  </ds:KeyInfo>
  </ds:Signature>
  <XRD>
  <CanonicalID>example.com</CanonicalID>
  <Service priority="0">
  <Type>http://specs.openid.net/auth/2.0/server</Type>
  <Type>http://openid.net/srv/ax/1.0</Type>
  <Type>http://specs.openid.net/extensions/ui/1.0/mode/popup</Type>
  <Type>http://specs.openid.net/extensions/ui/1.0/icon</Type>
  <Type>http://specs.openid.net/extensions/pape/1.0</Type>
  <URI>https://www.google.com/a/example.com/o8/ud?be=o8</URI>
  </Service>
  <Service priority="0" xmlns:openid="http://namespace.google.com/openid/xmlns">
  <Type>http://www.iana.org/assignments/relation/describedby</Type>
  <MediaType>application/xrds+xml</MediaType>
  <openid:URITemplate>https://www.google.com/accounts/o8/user-xrds?uri={%uri}</openid:URITemplate>
  <openid:NextAuthority>hosted-id.google.com</openid:NextAuthority>
  </Service>
  </XRD>
</xrds:XRDS>}})
    },
);

$Mock_ua->mock(get => sub {
        my $self = shift;
        my $url = shift;
        
        die 'Unexpected request URL: ' . $url unless exists $update_mock_response{$url};
        $update_mock_response{$url}->();
        return $Mock_response;
    }
);

my $auth_url = $fl->get_auth_url();
is($auth_url, 'https://www.google.com/a/example.com/o8/ud'
    . '?be=o8'
    . '&openid.mode=checkid_setup'
    . '&openid.ns=http://specs.openid.net/auth/2.0'
    . '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select'
    . '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
    . '&openid.return_to=http://example.com/return'
    . '&openid.ns.other=http://example.com/some_schema'
        . '&openid.other.argument=value'
    . '&openid.ns.ax=http://openid.net/srv/ax/1.0'
        . '&openid.ax.mode=fetch_request'
        . '&openid.ax.required=email'
        . '&openid.ax.type.email=http://axschema.org/contact/email'
    , 'Generated correct authentication URL');

$fl->get_extension('http://openid.net/srv/ax/1.0')->set_parameter('type.country' => 'http://axschema.org/contact/country/home');
$fl->get_extension('http://openid.net/srv/ax/1.0')->set_parameter('required' => 'country,email');

$auth_url = $fl->get_auth_url();
is($auth_url, 'https://www.google.com/a/example.com/o8/ud'
    . '?be=o8'
    . '&openid.mode=checkid_setup'
    . '&openid.ns=http://specs.openid.net/auth/2.0'
    . '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select'
    . '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
    . '&openid.return_to=http://example.com/return'
    . '&openid.ns.other=http://example.com/some_schema'
        . '&openid.other.argument=value'
    . '&openid.ns.ax=http://openid.net/srv/ax/1.0'
        . '&openid.ax.mode=fetch_request'
        . '&openid.ax.required=country,email'
        . '&openid.ax.type.country=http://axschema.org/contact/country/home'
        . '&openid.ax.type.email=http://axschema.org/contact/email'
    , 'Generated correct authentication URL after simple param addition');

$fl->get_extension('http://openid.net/srv/ax/1.0')->set_parameter(
    type        => {
        firstname   => 'http://axschema.org/namePerson/first',
        lastname    => 'http://axschema.org/namePerson/last',
    },
    required    => 'country,email,firstname,lastname'
);

$auth_url = $fl->get_auth_url();
is($auth_url, 'https://www.google.com/a/example.com/o8/ud'
    . '?be=o8'
    . '&openid.mode=checkid_setup'
    . '&openid.ns=http://specs.openid.net/auth/2.0'
    . '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select'
    . '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
    . '&openid.return_to=http://example.com/return'
    . '&openid.ns.other=http://example.com/some_schema'
        . '&openid.other.argument=value'
    . '&openid.ns.ax=http://openid.net/srv/ax/1.0'
        . '&openid.ax.mode=fetch_request'
        . '&openid.ax.required=country,email,firstname,lastname'
        . '&openid.ax.type.country=http://axschema.org/contact/country/home'
        . '&openid.ax.type.email=http://axschema.org/contact/email'
        . '&openid.ax.type.firstname=http://axschema.org/namePerson/first'
        . '&openid.ax.type.lastname=http://axschema.org/namePerson/last'
    , 'Generated correct authentication URL after nested param addition');

my $returned_params = 'openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0'
    . '&openid.mode=id_res'
    . '&openid.op_endpoint=https%3A%2F%2Fwww.google.com%2Fa%2Fexample.com%2Fo8%2Fud%3Fbe%3Do8'
    . '&openid.response_nonce=2010-04-07T09%3A37%3A44ZPnOORXHxuLpppA'
    . '&openid.return_to=http%3A%2F%2Fexample.com%2Freturn'
    . '&openid.assoc_handle=AOQobUepGOowYCBgCtqpD6LzIOGUpcqNSVTN-eRylmOPNw6SgiZyo0hH'
    . '&openid.signed=op_endpoint%2Cclaimed_id%2Cidentity%2Creturn_to%2Cresponse_nonce%2Cassoc_handle'
        . '%2Cns.ext1%2Cext1.mode%2Cext1.type.firstname%2Cext1.value.firstname%2Cext1.type.email%2Cext1.value.email%2Cext1.type.lastname%2Cext1.value.lastname'
    . '&openid.sig=sRBcGKb1zj5CAxGOE%2FY7R8%2Bb9G8%3D'
    . '&openid.identity=http%3A%2F%2Fexample.com%2Fopenid%3Fid%3D108441225163454056756'
    . '&openid.claimed_id=http%3A%2F%2Fexample.com%2Fopenid%3Fid%3D108441225163454056756'
    . '&openid.ns.ext1=http%3A%2F%2Fopenid.net%2Fsrv%2Fax%2F1.0'
        . '&openid.ext1.mode=fetch_response'
        . '&openid.ext1.type.firstname=http%3A%2F%2Faxschema.org%2FnamePerson%2Ffirst'
        . '&openid.ext1.value.firstname=Somé'
        . '&openid.ext1.type.email=http%3A%2F%2Faxschema.org%2Fcontact%2Femail'
        . '&openid.ext1.value.email=somebody%40example.com'
        . '&openid.ext1.type.lastname=http%3A%2F%2Faxschema.org%2FnamePerson%2Flast'
        . '&openid.ext1.value.lastname=Body';

my $cgi = CGI->new($returned_params);
my $auth_fl = Net::Google::FederatedLogin->new(cgi => $cgi, return_to => 'http://example.com/return');
$update_mock_response{'https://www.google.com/accounts/o8/user-xrds?uri=http%3A%2F%2Fexample.com%2Fopenid%3Fid%3D108441225163454056756'} = sub {
        $Mock_response->mock(decoded_content => sub { return q{<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
  <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <ds:SignedInfo>
  <ds:CanonicalizationMethod Algorithm="http://docs.oasis-open.org/xri/xrd/2009/01#canonicalize-raw-octets" />
  <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />
  </ds:SignedInfo>
  <ds:KeyInfo>
  <ds:X509Data>
  <ds:X509Certificate>
  MIIDLjCCApegAwIBAgIHALrcoAADBTANBgkqhkiG9w0BAQUFADBGMQswCQYDVQQGEwJVUzETMBEGA1UEChMKR29vZ2xlIEluYzEiMCAGA1UEAxMZR29vZ2xlIEludGVybmV0IEF1dGhvcml0eTAeFw0xMDA0MDcwMDAwMDBaFw0xMDA0MDkwMDAwMDBaMFYxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRMwEQYDVQQKEwpHb29nbGUgSW5jMR0wGwYDVQQDExRob3N0ZWQtaWQuZ29vZ2xlLmNvbTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA7UT2l+gZ7CjMCLvsMfvx3kWKojN9mmx2Aomylz8YnG60vE/WmQ/xZc9cw4orUgTFaqLcoju1khhg2kAPYRWB/ucC68NSIS/9/zex7Ssizz2MzxWxTc72nFwpTeOVygi0kw5TFCdYeNA110LpQ/+UOhjnFFtjS+ZDmkxXZj73eTMCAwEAAaOCARQwggEQMAkGA1UdEwQCMAAwHQYDVR0OBBYEFJ7cx4ptai4iTZ+RQO6mjTom1hIgMB8GA1UdIwQYMBaAFL/AMOv1QxE+Z7qekfv8atrjaxIkMFsGA1UdHwRUMFIwUKBOoEyGSmh0dHA6Ly93d3cuZ3N0YXRpYy5jb20vR29vZ2xlSW50ZXJuZXRBdXRob3JpdHkvR29vZ2xlSW50ZXJuZXRBdXRob3JpdHkuY3JsMGYGCCsGAQUFBwEBBFowWDBWBggrBgEFBQcwAoZKaHR0cDovL3d3dy5nc3RhdGljLmNvbS9Hb29nbGVJbnRlcm5ldEF1dGhvcml0eS9Hb29nbGVJbnRlcm5ldEF1dGhvcml0eS5jcnQwDQYJKoZIhvcNAQEFBQADgYEAmHHGVA4FsHBmSXJNXMPl7OVmBGvnV9Z91rLvJ8V0l8Bw7VVgUEHzCuclfO5hzRLlvyQLDGG+KtrDEx1lVZ9Qes3Y3WYL6M1yYAVKtxcDLXOTwgvfrVh/otgIOKtoSrDg62BjpKGgXWXAnOlsjvRF/OgIOQOMGhUgzDCTdkjC3+k=
  </ds:X509Certificate>
  <ds:X509Certificate>
  MIICsDCCAhmgAwIBAgIDC2dxMA0GCSqGSIb3DQEBBQUAME4xCzAJBgNVBAYTAlVTMRAwDgYDVQQKEwdFcXVpZmF4MS0wKwYDVQQLEyRFcXVpZmF4IFNlY3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMDkwNjA4MjA0MzI3WhcNMTMwNjA3MTk0MzI3WjBGMQswCQYDVQQGEwJVUzETMBEGA1UEChMKR29vZ2xlIEluYzEiMCAGA1UEAxMZR29vZ2xlIEludGVybmV0IEF1dGhvcml0eTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAye23pIucV+eEPkB9hPSP0XFjU5nneXQUr0SZMyCSjXvlKAy6rWxJfoNfNFlOCnowzdDXxFdF7dWq1nMmzq0yE7jXDx07393cCDaob1FEm8rWIFJztyaHNWrbqeXUWaUr/GcZOfqTGBhs3t0lig4zFEfC7wFQeeT9adGnwKziV28CAwEAAaOBozCBoDAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFL/AMOv1QxE+Z7qekfv8atrjaxIkMB8GA1UdIwQYMBaAFEjmaPkr0rKV10fYIyAQTzOYkJ/UMBIGA1UdEwEB/wQIMAYBAf8CAQAwOgYDVR0fBDMwMTAvoC2gK4YpaHR0cDovL2NybC5nZW90cnVzdC5jb20vY3Jscy9zZWN1cmVjYS5jcmwwDQYJKoZIhvcNAQEFBQADgYEAuIojxkiWsRF8YHdeBZqrocb6ghwYB8TrgbCoZutJqOkM0ymt9e8kTP3kS8p/XmOrmSfLnzYhLLkQYGfN0rTw8Ktx5YtaiScRhKqOv5nwnQkhClIZmloJ0pC3+gz4fniisIWvXEyZ2VxVKfmlUUIuOss4jHg7y/j7lYe8vJD5UDI=
  </ds:X509Certificate>
  </ds:X509Data>
  </ds:KeyInfo>
  </ds:Signature>
  <XRD>
  <CanonicalID>example.com</CanonicalID>
  <Service priority="0">
  <Type>http://specs.openid.net/auth/2.0/server</Type>
  <Type>http://openid.net/srv/ax/1.0</Type>
  <Type>http://specs.openid.net/extensions/ui/1.0/mode/popup</Type>
  <Type>http://specs.openid.net/extensions/ui/1.0/icon</Type>
  <Type>http://specs.openid.net/extensions/pape/1.0</Type>
  <URI>https://www.google.com/a/example.com/o8/ud?be=o8</URI>
  </Service>
  <Service priority="0" xmlns:openid="http://namespace.google.com/openid/xmlns">
  <Type>http://www.iana.org/assignments/relation/describedby</Type>
  <MediaType>application/xrds+xml</MediaType>
  <openid:URITemplate>https://www.google.com/accounts/o8/user-xrds?uri={%uri}</openid:URITemplate>
  <openid:NextAuthority>hosted-id.google.com</openid:NextAuthority>
  </Service>
  </XRD>
</xrds:XRDS>}})
};
my $check_url = 'https://www.google.com/a/example.com/o8/ud?be=o8&' . $returned_params;
$check_url =~ s/\Qopenid.mode=id_res\E/openid.mode=check_authentication/;
$check_url =~ s/Somé/Som%C3%A9/;
$update_mock_response{$check_url} = sub {
        $Mock_response->mock(decoded_content => sub { return qq{is_valid:true\nns:http://specs.openid.net/auth/2.0}})
};
my $bad_utf8_check_url = $check_url;
$bad_utf8_check_url =~ s/%C3%A9/%C3%83%C2%A9/;
$update_mock_response{$bad_utf8_check_url} = sub {
        $Mock_response->mock(decoded_content => sub { return qq{is_valid:false\nns:http://specs.openid.net/auth/2.0}})
};
ok($auth_fl->verify_auth, 'Verified correctly (utf8 shenanigans)');
my $extension = $auth_fl->get_extension('http://openid.net/srv/ax/1.0');

is($extension->get_parameter('value.firstname'), 'Somé');
is($extension->get_parameter('value.lastname'), 'Body');
is($extension->get_parameter('value.email'), 'somebody@example.com');
