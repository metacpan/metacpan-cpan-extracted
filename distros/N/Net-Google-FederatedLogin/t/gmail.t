use Test::More tests => 2;

use CGI;

use Test::Mock::LWP;
$Mock_ua->set_isa('LWP::UserAgent');

use Net::Google::FederatedLogin;
my $fl = Net::Google::FederatedLogin->new(claimed_id => 'example@gmail.com', return_to => 'http://example.com/return');

$Mock_ua->mock(get => sub {
        my $self = shift;
        my $url = shift;
        die 'Unexpected request URL: ' . $url unless $url eq 'https://www.google.com/accounts/o8/id';
        return $Mock_response;
    }
);

$Mock_response->mock(decoded_content => sub {
        return q{<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
  <XRD>
  <Service priority="0">
  <Type>http://specs.openid.net/auth/2.0/server</Type>
  <Type>http://openid.net/srv/ax/1.0</Type>
  <Type>http://specs.openid.net/extensions/ui/1.0/mode/popup</Type>
  <Type>http://specs.openid.net/extensions/ui/1.0/icon</Type>
  <Type>http://specs.openid.net/extensions/pape/1.0</Type>
  <URI>https://www.google.com/accounts/o8/ud</URI>
  </Service>
  </XRD>
</xrds:XRDS>};
    }
);

my $auth_url = $fl->get_auth_url();
is($auth_url, 'https://www.google.com/accounts/o8/ud'
    . '?openid.mode=checkid_setup'
    . '&openid.ns=http://specs.openid.net/auth/2.0'
    . '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select'
    . '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
    . '&openid.return_to=http://example.com/return', 'Generated correct authentication URL');

my $returned_params = 'openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0'
    . '&openid.mode=id_res'
    . '&openid.op_endpoint=https%3A%2F%2Fwww.google.com%2Faccounts%2Fo8%2Fud'
    . '&openid.response_nonce=2010-04-07T06%3A33%3A04ZbYSWYfqVm6FF5w'
    . '&openid.return_to=http%3A%2F%2Fexample.com%2Freturn'
    . '&openid.assoc_handle=AOQobUepGOowYCBgCtqpD6LzIOGUpcqNSVTN-eRylmOPNw6SgiZyo0hH'
    . '&openid.signed=op_endpoint%2Cclaimed_id%2Cidentity%2Creturn_to%2Cresponse_nonce%2Cassoc_handle'
    . '&openid.sig=sRBcGKb1zj5CAxGOE%2FY7R8%2Bb9G8%3D'
    . '&openid.identity=https%3A%2F%2Fwww.google.com%2Faccounts%2Fo8%2Fid%3Fid%3DAItOawlUNZx4cswq6NC0rwOvok80v8DyAg2V-Co'
    . '&openid.claimed_id=https%3A%2F%2Fwww.google.com%2Faccounts%2Fo8%2Fid%3Fid%3DAItOawlUNZx4cswq6NC0rwOvok80v8DyAg2V-Co';
my $cgi = CGI->new($returned_params);
my $auth_fl = Net::Google::FederatedLogin->new(cgi => $cgi, return_to => 'http://example.com/return');

my $check_params = $returned_params;
$check_params =~ s/openid\.mode=id_res/openid.mode=check_authentication/;
$Mock_ua->mock(get => sub {
        my $self = shift;
        my $url = shift;
        if($url ne 'https://www.google.com/accounts/o8/id') {
            die 'Unexpected request URL: ' . $url unless $url eq 'https://www.google.com/accounts/o8/ud?'.$check_params;
            $Mock_response->mock(decoded_content => sub {
                return qq{ns:http://specs.openid.net/auth/2.0\nis_valid:true}})
        }
        
        return $Mock_response;
    }
);

is($auth_fl->verify_auth(), 'https://www.google.com/accounts/o8/id?id=AItOawlUNZx4cswq6NC0rwOvok80v8DyAg2V-Co', 'OpenID validated');
