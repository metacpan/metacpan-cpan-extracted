use Test::More tests => 6;

use CGI;
use Test::Mock::LWP::Dispatch;

use OpenID::Login;
my $fl = OpenID::Login->new(
    claimed_id => 'https://user.example.com/',
    return_to  => 'http://example.com/return',
    extensions => [
        {   ns         => 'ax',
            uri        => 'http://openid.net/srv/ax/1.0',
            attributes => {
                mode     => 'fetch_request',
                required => 'email',
                type     => { email => 'http://axschema.org/contact/email' }
            }
        },
        {   ns         => 'other',
            uri        => 'http://example.com/some_schema',
            attributes => { argument => 'value', }
        }
    ]
);

$mock_ua->map( 'https://user.example.com/', HTTP::Response->parse(<<'EOL1') );
HTTP/1.1 200 OK
P3P: CP='NOI DSP LAW NID IND'
X-XRDS-Location: https://user.example.com/xrds/
Content-Type: text/html; charset=utf-8

<html>
    <head>
    <title>Example</title>
    <meta http-equiv="P3P" content="CP='NOI DSP LAW NID IND'">
    <link rel="openid2.provider openid.server" href="https://www.example.com/id.ssl" />
    <link rel="openid2.local_id openid.delegate" href="https://user.example.com/" />
    </head>
    <body>
        <h1>Nothing interesting</h1>
    </body>
</html>
EOL1

$mock_ua->map( 'https://user.example.com/xrds/', HTTP::Response->parse(<<'EOL2') );
HTTP/1.1 200 OK
Content-Type: application/xrds+xml

<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="0">
      <Type>http://specs.openid.net/auth/2.0/signon</Type>
      <Type>http://openid.net/signon/1.1</Type>
      <URI>https://www.example.com/id.ssl</URI>
      <LocalID>https://user.example.com/</LocalID>
    </Service>
  </XRD>
</xrds:XRDS>
EOL2

my $auth_url = $fl->get_auth_url();

is( $auth_url,
    'https://www.example.com/id.ssl'
        . '?openid.mode=checkid_setup'
        . '&openid.ns=http://specs.openid.net/auth/2.0'
        . '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select'
        . '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
        . '&openid.return_to=http://example.com/return'
        . '&openid.ns.other=http://example.com/some_schema'
        . '&openid.other.argument=value'
        . '&openid.ns.ax=http://openid.net/srv/ax/1.0'
        . '&openid.ax.mode=fetch_request'
        . '&openid.ax.required=email'
        . '&openid.ax.type.email=http://axschema.org/contact/email',
    'Generated correct authentication URL'
);

$fl->get_extension('http://openid.net/srv/ax/1.0')->set_parameter( 'type.country' => 'http://axschema.org/contact/country/home' );
$fl->get_extension('http://openid.net/srv/ax/1.0')->set_parameter( 'required'     => 'country,email' );

$auth_url = $fl->get_auth_url();
is( $auth_url,
    'https://www.example.com/id.ssl'
        . '?openid.mode=checkid_setup'
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
        . '&openid.ax.type.email=http://axschema.org/contact/email',
    'Generated correct authentication URL after simple param addition'
);

$fl->get_extension('http://openid.net/srv/ax/1.0')->set_parameter(
    type => {
        firstname => 'http://axschema.org/namePerson/first',
        lastname  => 'http://axschema.org/namePerson/last',
    },
    required => 'country,email,firstname,lastname'
);

$auth_url = $fl->get_auth_url();
is( $auth_url,
    'https://www.example.com/id.ssl'
        . '?openid.mode=checkid_setup'
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
        . '&openid.ax.type.lastname=http://axschema.org/namePerson/last',
    'Generated correct authentication URL after nested param addition'
);

my $returned_params =
      'openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0'
    . '&openid.mode=id_res'
    . '&openid.op_endpoint=https%3A%2F%2Fwww.example.com%2Fid.ssl'
    . '&openid.response_nonce=2012-03-01T09%3A37%3A44ZPnOORXHxuLpppA'
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
    . '&openid.ext1.value.firstname=Some'
    . '&openid.ext1.type.email=http%3A%2F%2Faxschema.org%2Fcontact%2Femail'
    . '&openid.ext1.value.email=somebody%40example.com'
    . '&openid.ext1.type.lastname=http%3A%2F%2Faxschema.org%2FnamePerson%2Flast'
    . '&openid.ext1.value.lastname=Body';

my $cgi       = CGI->new($returned_params);
my $auth_fl   = OpenID::Login->new( cgi => $cgi, return_to => 'http://example.com/return' );
my $extension = $auth_fl->get_extension('http://openid.net/srv/ax/1.0');

is( $extension->get_parameter('value.firstname'), 'Some' );
is( $extension->get_parameter('value.lastname'),  'Body' );
is( $extension->get_parameter('value.email'),     'somebody@example.com' );
