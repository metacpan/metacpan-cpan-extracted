use Test::More tests => 3;

use URI::Escape;

use Test::Mock::LWP::Dispatch;

use OpenID::Login;
my $fl = OpenID::Login->new( claimed_id => 'https://user.example.com', return_to => 'http://example.com/return' );

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
is( $auth_url, 'https://www.example.com/id.ssl' . '?openid.mode=checkid_setup' . '&openid.ns=http://specs.openid.net/auth/2.0' . '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select' . '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select' . '&openid.return_to=http://example.com/return', 'Generated correct authentication URL' );

my $returned_params =
      'openid.response_nonce=2012-03-01T06%3A33%3A04ZbYSWYfqVm6FF5w'
    . '&openid.mode=id_res'
    . '&openid.claimed_id=https%3A%2F%2Fuser.example.com'
    . '&openid.assoc_handle=AOQobUepGOowYCBgCtqpD6LzIOGUpcqNSVTN-eRylmOPNw6SgiZyo0hH'
    . '&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0'
    . '&openid.signed=op_endpoint%2Cclaimed_id%2Cidentity%2Creturn_to%2Cresponse_nonce%2Cassoc_handle'
    . '&openid.sig=sRBcGKb1zj5CAxGOE%2FY7R8%2Bb9G8%3D'
    . '&openid.op_endpoint=https%3A%2F%2Fwww.example.com%2Fid.ssl'
    . '&openid.identity=https%3A%2F%2Fuser.example.com'
    . '&openid.return_to=http%3A%2F%2Fexample.com%2Freturn';

my $params_hashref = {};
foreach ( split '&', $returned_params ) {
    my ( $param, $value ) = split( '=', $_ );
    $params_hashref->{$param} = uri_unescape($value);
}

my $check_params = $returned_params;
$check_params =~ s/openid\.mode=id_res/openid.mode=check_authentication/;

$mock_ua->map( qr!^https://www.example.com/id.ssl!, HTTP::Response->parse(<<'EOL3') );
HTTP/1.1 200 OK
Content-Type: text/plain

is_valid:true
ns:http://specs.openid.net/auth/2.0
EOL3

eval "use Catalyst::Request; use Catalyst::Log;";
SKIP: {
    skip "Catalyst::Request required for testing cgi param that isn't actually CGI", 1 if $@;
    my $not_cgi = Catalyst::Request->new( _log => Catalyst::Log->new() );
    $not_cgi->param( $_, $params_hashref->{$_} ) foreach keys %$params_hashref;

    my $auth_fl = OpenID::Login->new( cgi => $not_cgi, return_to => 'http://example.com/return' );
    is( $auth_fl->verify_auth(), 'https://user.example.com', 'OpenID validated cgi' );
}

my $auth_fl = OpenID::Login->new( cgi_params => $params_hashref, return_to => 'http://example.com/return' );
is( $auth_fl->verify_auth(), 'https://user.example.com', 'OpenID validated cgi_params' );
