use Test::More tests => 5;

use URI::Escape;

use Test::Mock::LWP;
$Mock_ua->set_isa('LWP::UserAgent');

use Net::Google::FederatedLogin;
my $fl = Net::Google::FederatedLogin->new(claimed_id => 'example@gmail.com', return_to => 'http://example.com/return');

sub reset_mock
{
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
}
reset_mock();

my $auth_url = $fl->get_auth_url();
is($auth_url, 'https://www.google.com/accounts/o8/ud'
    . '?openid.mode=checkid_setup'
    . '&openid.ns=http://specs.openid.net/auth/2.0'
    . '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select'
    . '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
    . '&openid.return_to=http://example.com/return', 'Generated correct authentication URL');

my $returned_params = 'openid.response_nonce=2010-04-07T06%3A33%3A04ZbYSWYfqVm6FF5w'
    . '&openid.mode=id_res'
    . '&openid.claimed_id=https%3A%2F%2Fwww.google.com%2Faccounts%2Fo8%2Fid%3Fid%3DAItOawlUNZx4cswq6NC0rwOvok80v8DyAg2V-Co'
    . '&openid.assoc_handle=AOQobUepGOowYCBgCtqpD6LzIOGUpcqNSVTN-eRylmOPNw6SgiZyo0hH'
    . '&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0'
    . '&openid.signed=op_endpoint%2Cclaimed_id%2Cidentity%2Creturn_to%2Cresponse_nonce%2Cassoc_handle'
    . '&openid.sig=sRBcGKb1zj5CAxGOE%2FY7R8%2Bb9G8%3D'
    . '&openid.op_endpoint=https%3A%2F%2Fwww.google.com%2Faccounts%2Fo8%2Fud'
    . '&openid.identity=https%3A%2F%2Fwww.google.com%2Faccounts%2Fo8%2Fid%3Fid%3DAItOawlUNZx4cswq6NC0rwOvok80v8DyAg2V-Co'
    . '&openid.return_to=http%3A%2F%2Fexample.com%2Freturn';

sub params_to_hashref
{
    my $params = shift;
    my $hashref = {};
    foreach (split '&', $params)
    {
        my ($param, $value) = split('=', $_);
        $hashref->{$param} = uri_unescape($value);
    }
    return $hashref;
}

my $params_hashref = params_to_hashref($returned_params);

my $check_params = $params_hashref;
$check_params->{'openid.mode'} = 'check_authentication';

eval "use Catalyst::Request";
SKIP: {
    skip "Catalyst::Request required for testing cgi param that isn't actually CGI", 2 if $@;
    my $not_cgi = Catalyst::Request->new(_log => undef);
    $not_cgi->param($_, $params_hashref->{$_}) foreach keys %$params_hashref;
    
    my $auth_fl = Net::Google::FederatedLogin->new(cgi => $not_cgi, return_to => 'http://example.com/return');
    
    $Mock_ua->mock(get => sub {
            my $self = shift;
            my $url = shift;
            if($url ne 'https://www.google.com/accounts/o8/id') {
                is_deeply(params_to_hashref(substr($url, 38)), $check_params);
                $Mock_response->mock(decoded_content => sub {
                    return qq{ns:http://specs.openid.net/auth/2.0\nis_valid:true}})
            }
            
            return $Mock_response;
        }
    );
    
    is($auth_fl->verify_auth(), 'https://www.google.com/accounts/o8/id?id=AItOawlUNZx4cswq6NC0rwOvok80v8DyAg2V-Co', 'OpenID validated');
};

reset_mock();

my $auth_fl = Net::Google::FederatedLogin->new(cgi_params => $params_hashref, return_to => 'http://example.com/return');

$Mock_ua->mock(get => sub {
        my $self = shift;
        my $url = shift;
        if($url ne 'https://www.google.com/accounts/o8/id') {
            is_deeply(params_to_hashref(substr($url, 38)), $check_params);
            $Mock_response->mock(decoded_content => sub {
                return qq{ns:http://specs.openid.net/auth/2.0\nis_valid:true}})
        }
        
        return $Mock_response;
    }
);

is($auth_fl->verify_auth(), 'https://www.google.com/accounts/o8/id?id=AItOawlUNZx4cswq6NC0rwOvok80v8DyAg2V-Co', 'OpenID validated');
