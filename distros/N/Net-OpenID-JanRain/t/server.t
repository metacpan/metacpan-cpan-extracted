use Net::OpenID::JanRain::Server;
use Net::OpenID::JanRain::Stores::FileStore;

use Test::More qw( no_plan ); # tests => 23

use bigint;

$ALT_MODULUS = 0xCAADDDEC1667FC68B5FA15D53C4E1532DD24561A1A2D47A12C01ABEA1E00731F6921AAC40742311FDF9E634BB7131BEE1AF240261554389A910425E044E88C8359B010F5AD2B80E29CB1A5B027B19D9E01A6F63A6F45E5D7ED2FF6A2A0085050A7D0CF307C3DB51D2490355907B4427C23A98DF1EB8ABEF2BA209BB7AFFE86A7;
$ALT_GEN = 5;

sub printhr {
    my $hr = shift;

    print "{\n";
    while (my ($k, $v) = each (%$hr)) {
        print " $k => $v ,\n";
    }
    print "}\n";
}

my $now = time;
my $store = Net::OpenID::JanRain::Stores::FileStore->new("oidtest$now");
########## Test Server Object Instantiation
my $server = Net::OpenID::JanRain::Server->new('a sows ear');
is($server, undef, "You can't make an OpenID server from 'a sows ear'");

$server = Net::OpenID::JanRain::Server->new($store);
isa_ok($server, Net::OpenID::JanRain::Server, "A server made from a store");

## Test Signatory
my $signatory = $server->signatory;
my ($assoc, $assoc2);

$assoc = $signatory->createAssociation(0);
isa_ok($assoc, Net::OpenID::JanRain::Association,
        "Normal-mode association");
$assoc2 = $signatory->getAssociation($assoc->handle, 0);
ok($assoc->equals($assoc2),'Successfully retrieve smart association');
$assoc2 = $signatory->getAssociation($assoc->handle, 1);
is($assoc2, undef, "smart assoc not retrieved with dumb get");

$assoc = $signatory->createAssociation(1);
isa_ok($assoc, Net::OpenID::JanRain::Association,
        "Dumb-mode association");
$assoc2 = $signatory->getAssociation($assoc->handle, 1);
ok($assoc->equals($assoc2),'Successfully retrieve dumb association');
$assoc2 = $signatory->getAssociation($assoc->handle, 0);
is($assoc2, undef, "dumb assoc not retrieved with smart get");


## Transaction tests
my ($args, $request, $response);

########## Test Decoding Errors
$request = $server->decodeRequest({});
is($request, undef, "decode empty query gives undef");

$request = $server->decodeRequest({hasno => 'openidargs'});
is($request, undef, "decode query with no openid-namespaced params gives undef");

$request = $server->decodeRequest({'openid.dance' => 'funkymonkey'});
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "query with openid ns'd nonsense decoded");

$request = $server->decodeRequest({'openid.mode' => 'depeche'});
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "query with bad openid.mode decoded");


########## Test mode=associate


$args = {'openid.mode' => 'associate',
         'openid.assoc_type' => 'free'};
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "associate with bad assoc_type decoded");
is($request->whichEncoding(), 'kvform', 
        "kvform error response for mode=associate");

$args = {'openid.mode' => 'associate',
         'openid.session_type' => 'jam'};
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "associate with bad session_type");
is($request->whichEncoding(), 'kvform', 
        "kvform error response for mode=associate");
            
$args = {'openid.mode' => 'associate',
         'openid.session_type' => 'DH-SHA1'};
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "associate 'DH-SHA1' without consumer public key");
is($request->whichEncoding(), 'kvform', 
        "kvform error response for mode=associate");

$args = {'openid.mode' => 'associate',
         'openid.session_type' => 'DH-SHA1',
         'openid.dh_consumer_public' => 'junk'};
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "associate 'DH-SHA1' with bad consumer public key");
is($request->whichEncoding(), 'kvform', 
        "kvform error response for mode=associate");

$args = {'openid.mode' => 'associate'};
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::AssociateRequest,
        "associate with no more args is ok");
is($request->session_type, 'plaintext', 
    'plaintext session_type set for associate request without explicit type');
is($request->assoc_type, 'HMAC-SHA1', "assoc_type is HMAC-SHA1 by default");
$assoc = $server->signatory->createAssociation();
$response = $request->answer($assoc);
# test the response XXX


# Test associate successes XXX

# Test check_authentication

# Make a dumb association
$assoc = $server->signatory->createAssociation(1);

$args = {'openid.mode' => 'check_authentication'};
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "check_authentication with no more args");
print 'error text: ' . $request->text ."\n";
is($request->whichEncoding(), 'kvform', 
        "kvform error response for mode=check_authentication");

$args = {'openid.mode' => 'id_res',
         'openid.assoc_handle' => $assoc->handle,
         'openid.jan' => 'in_january_it'};
$assoc->addSignature($args, ['mode','jan'], 'openid.');
$args->{'openid.mode'} = 'check_authentication';
$args->{'openid.signed'} = 'mode,jan,rain';
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "check_authentication missing signed arg");
print 'error text: ' . $request->text . "\n";
is($request->whichEncoding(), 'kvform', 
        "kvform error response for mode=check_authentication");

$args = {'openid.mode' => 'id_res',
         'openid.assoc_handle' => 'bad',
         'openid.jan' => 'in_january_it'};
$assoc->addSignature($args, ['mode','jan'], 'openid.');
$args->{'openid.mode'} = 'check_authentication';
$request = $server->decodeRequest($args);
isa_ok($request, Net::OpenID::JanRain::Server::CheckAuthRequest,
        'CheckAuth with bad assoc_handle');
$response = $request->answer($server->signatory);
isa_ok($response, Net::OpenID::JanRain::Server::Response,
    "CheckAuth with bad assoc_handle response");
is($response->{fields}->{'is_valid'}, 'false', 'CheckAuth with bad assoc_handle responds with is_valid=false');
is($response->whichEncoding(), 'kvform',
        'CheckAuth response encodes to kvform');

# valid
$assoc = $server->signatory->createAssociation(1);
$args = {'openid.mode' => 'id_res',
         'openid.assoc_handle' => $assoc->handle,
         'openid.jan' => 'in_january_it',
         'openid.rain' => 'rains_in_portland',
         'openid.dinepo' => 'palindrome'};
$assoc->addSignature($args, ['mode','jan','rain'], 'openid.');
$args->{'openid.mode'} = 'check_authentication';
$request = $server->decodeRequest($args);
isa_ok($request, Net::OpenID::JanRain::Server::CheckAuthRequest,
    "Valid check_auth request decode");
$response = $request->answer($server->signatory);
isa_ok($response, Net::OpenID::JanRain::Server::Response,
    "Response to valid check_auth request");
is($response->fields->{is_valid},'true', 'Valid check_auth responds with is_valid=true');
$webresp = $server->encodeResponse($response);
isa_ok($webresp, Net::OpenID::JanRain::Server::WebResponse,
    "Encoded response to WebResponse");

# replay
$response = $request->answer($server->signatory);
isa_ok($response, Net::OpenID::JanRain::Server::Response,
    "Response to replay check_auth request");
is($response->fields->{is_valid},'false', 'Replay check_auth responds with is_valid=false');

$args = {'openid.mode' => 'check_authentication',
         'openid.assoc_handle' => '_dumb_handle_',
         'openid.sig' => 'dontgivemeanerror',
         'openid.signed' => 'jan,rain,mode',
         'openid.jan' => 'in_january_it',
         'openid.rain' => 'rains_in_portland',
         'openid.invalidate_handle' => '_smart_nonexistent_handle_'};
$request = $server->decodeRequest($args);
$response = $server->handleRequest($request);
is($response->fields->{invalidate_handle}, '_smart_nonexistent_handle_',
    "Invalidate nonexistent handle");


$assoc = $server->signatory->createAssociation(0);
$args = {'openid.mode' => 'check_authentication',
         'openid.assoc_handle' => '_dumb_handle_',
         'openid.sig' => 'dontgivemeanerror',
         'openid.signed' => 'jan,rain,mode',
         'openid.jan' => 'in_january_it',
         'openid.rain' => 'rains_in_portland',
         'openid.invalidate_handle' => $assoc->handle};
$request = $server->decodeRequest($args);
$response = $server->handleRequest($request);
is($response->fields->{invalidate_handle}, undef,
    "Don't invalidate good handle");
        

# CheckID requests.
$args = {'openid.mode' => 'checkid_setup'};
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "checkid_setup with no other args");
print 'error text: ' . $request->text . "\n";

$args = {'openid.mode' => 'checkid_setup',
         'openid.identity' => 'http://idurl.com/',
         };
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "checkid_setup missing return_to");
print 'error text: ' . $request->text . "\n";
print 'error encoding: '. $request->whichEncoding ."\n";

$args = {'openid.mode' => 'checkid_setup',
         'openid.identity' => 'http://idurl.com/',
         'openid.return_to' => 'http://www.consumer.com/return_to',
         'openid.trust_root' => 'http://somethingelse.com/',
         };
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "checkid_setup with return_to not under trust_root");
print 'error text: ' . $request->text . "\n";
is($request->whichEncoding, 'url',
    "return_to not under trust_root error encodes to URL");

$args = {'openid.mode' => 'checkid_setup',
         'openid.identity' => 'http://idurl.com/',
         'openid.return_to' => 'http://www.consumer.com/return_to',
         };
$request = $server->decodeRequest($args);
isa_ok($request, Net::OpenID::JanRain::Server::CheckIDRequest,
        "checkid_setup request with implicit trust_root");
is($request->trust_root, 'http://www.consumer.com/return_to',
    "trust_root defaults to return_to");
is($request->return_to, 'http://www.consumer.com/return_to',
    "trust_root set properly for checkid_setup request");
is($request->identity, 'http://idurl.com/',
    "identity set properly for checkid_setup request");
ok((not $request->immediate), "checkid_setup request not immediate");

$args = {'openid.mode' => 'checkid_setup',
         'openid.identity' => 'http://idurl.com/',
         'openid.return_to' => 'http://www.consumer.com/return_to',
         'openid.trust_root' => 'http://www.consumer.com/',
         };
$request = $server->decodeRequest($args);
isa_ok($request, Net::OpenID::JanRain::Server::CheckIDRequest,
        "checkid_setup request with plain trust_root");
is($request->trust_root, 'http://www.consumer.com/',
    "specified trust_root set properly");

$response = $request->answer(0);
isa_ok($response, Net::OpenID::JanRain::Server::Response,
        "Denied checkid_setup response");
is($response->fields->{'mode'}, 'cancel', 
        'Denied checkid_setup response mode is cancel');
is($response->whichEncoding, 'url',
        'Denied checkid_setup response encodes to url');
is($response->signed, undef, "Cancel response has no signed args");

$webresp = $server->encodeResponse($response);
isa_ok($webresp, Net::OpenID::JanRain::Server::WebResponse,
        "Encoded checkidResponse is webresponse");
is($webresp->code, 302, "Response code is 302");
is($webresp->headers->{Location}, 
    "http://www.consumer.com/return_to?openid.mode=cancel",
    "Response encodes cancel return URL correctly");
is($webresp->body, undef, "No body for redirect response");

$args = {'openid.mode' => 'checkid_setup',
         'openid.identity' => 'http://idurl.com/',
         'openid.return_to' => 'http://www.consumer.com/return_to',
         'openid.trust_root' => 'http://*.consumer.com/',
         };
$request = $server->decodeRequest($args);
isa_ok($request, Net::OpenID::JanRain::Server::CheckIDRequest,
        "checkid_setup request with wildcard trust_root");
is($request->trust_root, 'http://*.consumer.com/',
    "specified wildcard trust_root set properly");
$response = $request->answer(1);
isa_ok($response, Net::OpenID::JanRain::Server::Response,
        "Approved checkid_setup response");
is($response->fields->{'mode'}, 'id_res', 
        'Approved checkid_setup response mode is id_res');
is($response->fields->{'identity'}, 'http://idurl.com/', 
        'Approved checkid_setup response has correct identity field');
is($response->fields->{'return_to'}, 'http://www.consumer.com/return_to',
        'Approved checkid_setup response has correct return_to');
is(join(',',@{$response->signed}), "return_to,identity,mode",
        'Approved checkid_setup response lists correct fields to sign');
$webresp = $server->encodeResponse($response);
my $assoc_handle = $response->fields->{'assoc_handle'};
ok($assoc_handle, "Approved checkid_setup response (dumb mode) has assoc_handle");
$assoc = $server->signatory->getAssociation($assoc_handle, 1);
ok($assoc, "and the handle has a dumb mode association on it");
ok($response->fields->{'sig'}, "Approved checkid_setup response has a sig");
is($response->fields->{'signed'}, "return_to,identity,mode",
        "Approved checkid_setup response has correct signed fields");
is($response->whichEncoding, 'url',
        'Approved checkid_setup response encodes to url');

isa_ok($webresp, Net::OpenID::JanRain::Server::WebResponse,
        "Encoded checkidResponse is webresponse");
is($webresp->code, 302, "Response code is 302");
is($webresp->body, undef, "No body for redirect response");




$args = {'openid.mode' => 'checkid_immediate'};
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "checkid_immediate with no other args");

$args = {'openid.mode' => 'checkid_immediate',
         'openid.identity' => 'http://idurl.com/',
         };
$request = $server->decodeRequest($args);
isa_ok($request,Net::OpenID::JanRain::Server::ProtocolError,
        "checkid_immediate missing return_to");

$args = {'openid.mode' => 'checkid_immediate',
         'openid.identity' => 'http://idurl.com/',
         'openid.return_to' => 'http://www.consumer.com/return_to',
         };
$request = $server->decodeRequest($args);
isa_ok($request, Net::OpenID::JanRain::Server::CheckIDRequest,
    "proper checkid_immediate request");
ok($request->immediate, "checkid_immediate request is immediate");
