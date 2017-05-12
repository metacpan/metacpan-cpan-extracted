use Net::OpenID::JanRain::Consumer;
use Net::OpenID::JanRain::Stores::FileStore;
use Net::OpenID::JanRain::Util qw( checkTrustRoot );
use CGI::Session;
use Test::More tests=>82;
use Net::Yadis;
Net::Yadis::_userAgentClass('TestAgent');
use HTTP::Response;
use URI;
use URI::QueryParam;
use URI::Escape;

my $num_assocs = 0;
my $num_checks = 0; #check_auths
my $token_key = '_openid_consumer_token';
my @nonces;

my $STORE_DIR = 'c_test_store_'.time;
my $SESSION_DIR = 'c_test_session_'.time;

# Yadis1: A single openid 1.0 service with no delegate
my $yadis1 = HTTP::Response->new(200);
$yadis1->header('Content-Type'=>'application/xrds+xml');
$yadis1->header('Content-Location'=>'http://example.com/yadis1');
$yadis1->content('<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns:openid="http://openid.net/xmlns/1.0"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>

    <Service priority="0">
      <Type>http://openid.net/signon/1.0</Type>
      <Type>http://openid.net/sreg/1.0</Type>
      <URI>http://www.myopenid.com/server</URI>
    </Service>

  </XRD>
</xrds:XRDS>
');

# Yadis 2: with a delegate
my $yadis2 = HTTP::Response->new(200); 
$yadis2->header('Content-Type'=>'application/xrds+xml');
$yadis2->header('Content-Location'=>'http://example.com/yadis2');
$yadis2->content('<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns:openid="http://openid.net/xmlns/1.0"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>

    <Service priority="0">
      <Type>http://openid.net/signon/1.0</Type>
      <Type>http://openid.net/sreg/1.0</Type>
      <URI>http://www.myopenid.com/server</URI>
      <openid:Delegate>http://smoker.myopenid.com/</openid:Delegate>
    </Service>

  </XRD>
</xrds:XRDS>
');

# Yadis 3: two services for fallback
my $yadis3 = HTTP::Response->new(200);
$yadis3->header('Content-Type'=>'application/xrds+xml');
$yadis3->header('Content-Location'=>'http://example.com/yadis3');
$yadis3->content('<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns:openid="http://openid.net/xmlns/1.0"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>

    <Service priority="0">
      <Type>http://openid.net/signon/1.0</Type>
      <Type>http://openid.net/sreg/1.0</Type>
      <URI>http://www.myopenid.com/server</URI>
      <openid:Delegate>http://smoker.myopenid.com/</openid:Delegate>
    </Service>
    
    <Service priority="1">
      <Type>http://openid.net/signon/1.0</Type>
      <Type>http://openid.net/sreg/1.0</Type>
      <URI>http://www.myopenid.com/server2</URI>
      <openid:Delegate>http://rekoms.myopenid.com/</openid:Delegate>
    </Service>

  </XRD>
</xrds:XRDS>
');

# lid yadis: A valid yadis file without an openid service
my $lid_yadis = HTTP::Response->new(200); 
$lid_yadis->header('Content-Type'=>'application/xrds+xml');
$lid_yadis->header('Content-Location'=>'http://example.com/lid_yadis');
$lid_yadis->content('<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns:openid="http://openid.net/xmlns/1.0"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>

    <Service priority="0">
      <Type>http://lid.netmesh.org/minimum-lid/2.0b6</Type>
      <URI>http://mylid.net/valid</URI>
    </Service>

  </XRD>
</xrds:XRDS>
');

# bad yadis: cause xml parse failure
my $bad_yadis = HTTP::Response->new(200);
$bad_yadis->header('Content-Type'=>'application/xrds+xml');
$bad_yadis->header('Content-Location'=>'http://example.com/bad_yadis');
$bad_yadis->content('non-xml junk');

my $link1 = HTTP::Response->new(200);
$link1->header('Content-Type'=>'text/html');
$link1->header('Content-Location'=>'http://example.com/link1');
$link1->content('<html><head>
    <link rel="openid.server" href="http://www.myopenid.com/server">
    </head></html>');

my $link2 = HTTP::Response->new(200);
$link2->header('Content-Type'=>'text/html');
$link2->header('Content-Location'=>'http://example.com/link2');
$link2->content('<html><head>
    <link rel="openid.server" href="http://www.myopenid.com/server">
    <link rel="openid.delegate" href="http://smoker.myopenid.com/">
    </head></html>');

my $apage = HTTP::Response->new(200);
$apage->header('Content-Type'=>'text/html'); 
$apage->header('Content-Location'=>'http://example.com/apage');
$apage->content('<html><head><title>Some Page</title></head><body>foo</body</html>');

#pretty print hash
sub pph {
    my $hr = shift;
    for (keys(%$hr)) {
	print "$_:".$hr->{$_}."\n";
    }
}

# Checks that a redirect url is:
# based at $server_url
# openid mode, identity, trust_root parameters are as specified
# return_to is under trust_root and has a nonce on it
sub check_rd_url {
    my ($rd_url, $server_url, $mode, $identity, $trust_root) = @_;

    ok($rd_url =~ /^$server_url/, "Redirect URL rooted at $server_url");
    my $u = URI->new($rd_url);
    is($u->query_param('openid.mode'), $mode, "Redirect URL has mode $mode");
    is($u->query_param('openid.identity'), $identity, "Redirect URL has id $identity");
    is($u->query_param('openid.trust_root'), $trust_root, "Redirect URL has trust_root $trust_root");
    my $rt = $u->query_param('openid.return_to');
    
    ok($rt =~ /^http/, "return to begins with http");
    
    ok(checkTrustRoot($trust_root, $rt), "Return_to valid against trust_root");

    my $rtu = URI->new($rt);
    ok($rtu->query_param('nonce'), "Return_to has a nonce");
    push @nonces, $rtu->query_param('nonce'); #save valid nonce for later
}


my $ASSOC_HANDLE = 'love_handle';
my $ASSOC_SECRET = 'hmm,20bytes.addeight';
my $ASSOC = Net::OpenID::JanRain::Association->new($ASSOC_HANDLE, $ASSOC_SECRET, time, 600, 'HMAC-SHA1');

my $ASSOC2_HANDLE = 'husk_handle';
my $ASSOC2_SECRET = 'bladerogersisdanhusk';
my $ASSOC2 = Net::OpenID::JanRain::Association->new($ASSOC2_HANDLE, $ASSOC2_SECRET, time, 600, 'HMAC-SHA1');
my $session = new CGI::Session(undef, undef, {Directory => $SESSION_DIR});

my $store = Net::OpenID::JanRain::Stores::FileStore->new($STORE_DIR);
Net::OpenID::JanRain::Util::setAgent('TestAgent');
my $consumer = Net::OpenID::JanRain::Consumer->new($session, $store);



# test consumer->begin: yadis, link, fallback, non-openid, network failure
# test authReq methods: accessors, addExtensionArg, redirectURL
# test that associations are requested properly

my ($request, $url);

is($num_assocs, 0, "baseline assoc count");

$request = $consumer->begin("http://example.com/yadis1");
isa_ok($request, "Net::OpenID::JanRain::Consumer::AuthRequest",
	"begin yadis 1");
is($num_assocs, 1, "assoc created");
# No delegate
is($request->endpoint->server_id, "http://example.com/yadis1",
    "Yadis 1 server_id");
is($request->endpoint->identity_url, "http://example.com/yadis1",
    "Yadis 1 identity_url");
is($request->endpoint->server_url, "http://www.myopenid.com/server",
    "Yadis 1 server url");

$url = $request->redirectURL('http://consumer.com/', 
			     'http://consumer.com/openid');

check_rd_url($url, $request->endpoint->server_url, "checkid_setup", $request->endpoint->server_id, 'http://consumer.com/');

$store->removeAssociation("http://www.myopenid.com/server", $ASSOC_HANDLE);
$request = $consumer->begin("http://example.com/yadis2");
isa_ok($request, "Net::OpenID::JanRain::Consumer::AuthRequest",
	"begin yadis 2");
is($num_assocs, 2, "removing assoc causes new one to be made on begin");
is($request->endpoint->server_id, "http://smoker.myopenid.com/",
    "Yadis 2 server_id");
is($request->endpoint->identity_url, "http://example.com/yadis2",
    "Yadis 2 identity_url");
is($request->endpoint->server_url, "http://www.myopenid.com/server",
    "Yadis 2 server url");
$url = $request->redirectURL('http://consumer.com/', 
			     'http://consumer.com/openid');
check_rd_url($url, $request->endpoint->server_url, "checkid_setup", $request->endpoint->server_id, 'http://consumer.com/');


$request = $consumer->begin("http://example.com/yadis3");
isa_ok($request, "Net::OpenID::JanRain::Consumer::AuthRequest",
	"begin yadis 3");

is($num_assocs, 2, "assoc should be reused");
is($request->endpoint->server_id, "http://smoker.myopenid.com/",
    "Yadis 3 server_id 1");
is($request->endpoint->identity_url, "http://example.com/yadis3",
    "Yadis 3 identity_url 1");
is($request->endpoint->server_url, "http://www.myopenid.com/server",
    "Yadis 3 server url 1");
$url = $request->redirectURL('http://consumer.com/', 
			     'http://consumer.com/openid');
check_rd_url($url, $request->endpoint->server_url, "checkid_setup", $request->endpoint->server_id, 'http://consumer.com/');

$request = $consumer->begin("http://example.com/yadis3");
isa_ok($request, "Net::OpenID::JanRain::Consumer::AuthRequest",
    "Yadis 3 Fallback begin");
is($num_assocs, 3, "new assoc for new server endpoint");
is($request->endpoint->server_id, "http://rekoms.myopenid.com/",
    "Yadis 3 server_id 2");
is($request->endpoint->identity_url, "http://example.com/yadis3",
    "Yadis 3 identity_url 2");
is($request->endpoint->server_url, "http://www.myopenid.com/server2",
    "Yadis 3 server url 2");

$request = $consumer->begin("http://example.com/link1");
isa_ok($request, "Net::OpenID::JanRain::Consumer::AuthRequest",
    "Link tag begin");
is($request->endpoint->server_id, "http://example.com/link1",
    "Link server_id (no delegate)");
is($request->endpoint->identity_url, "http://example.com/link1",
    "Link identity_url");
is($request->endpoint->server_url, "http://www.myopenid.com/server",
    "Link server url");
$url = $request->redirectURL('http://consumer.com/', 
			     'http://consumer.com/openid');
check_rd_url($url, $request->endpoint->server_url, "checkid_setup", $request->endpoint->server_id, 'http://consumer.com/');


$request = $consumer->begin("http://example.com/link2");
isa_ok($request, "Net::OpenID::JanRain::Consumer::AuthRequest",
    "Link tag (delegate) begin");
is($request->endpoint->server_id, "http://smoker.myopenid.com/",
    "Link server_id (delegate)");
is($request->endpoint->identity_url, "http://example.com/link2",
    "Link identity_url");
is($request->endpoint->server_url, "http://www.myopenid.com/server",
    "Link server url");
$url = $request->redirectURL('http://consumer.com/', 
			     'http://consumer.com/openid');
check_rd_url($url, $request->endpoint->server_url, "checkid_setup", $request->endpoint->server_id, 'http://consumer.com/');

$request = $consumer->begin("http://example.com/lid_yadis");
isa_ok($request, "Net::OpenID::JanRain::Consumer::FailureResponse",
    "Yadis with no openid service");

$request = $consumer->begin("http://example.com/bad_yadis");
isa_ok($request, "Net::OpenID::JanRain::Consumer::FailureResponse",
    "Malformed Yadis");

$request = $consumer->begin("http://example.com/apage");
isa_ok($request, "Net::OpenID::JanRain::Consumer::FailureResponse",
    "Non-openid page");


# test consumer->complete: id_res, error, cancel, setup_needed
# test that check_authentication requests are made properly

my ($query, $response);

# Faux token
$token = $consumer->{consumer}->_genToken(
		    'http://example.com/yadis1',
		    'http://smoker.myopenid.com/',
		    'http://www.myopenid.com/server');

$query = {'openid.mode' => 'id_res',
	  'openid.user_setup_url' => 'http://example.com/user_setup'};
$session->param($token_key, $token);
$response = $consumer->complete($query);
isa_ok($response, "Net::OpenID::JanRain::Consumer::SetupNeededResponse", "The setup_url response");
is($response->setup_url, $query->{'openid.user_setup_url'}, "Setup URL correct");

my $nonce = pop @nonces;
$query = {'openid.mode' => 'id_res',
	  'openid.identity' => 'http://smoker.myopenid.com/',
	  'openid.return_to' => "http://consumer.com/openid?nonce=$nonce",
	  'openid.assoc_handle' => $ASSOC_HANDLE,
	  'nonce' => $nonce,
	 };
$ASSOC->addSignature($query,['mode','identity','return_to'], 'openid.');
$session->param($token_key, $token);
$response = $consumer->complete($query);
isa_ok($response, "Net::OpenID::JanRain::Consumer::SuccessResponse",
	"plain old response");

my $nonce = pop @nonces;
$query = {'openid.mode' => 'id_res',
	  'openid.identity' => 'http://smoker.myopenid.com/',
	  'openid.return_to' => "http://consumer.com/openid?nonce=$nonce",
	  'openid.assoc_handle' => $ASSOC2_HANDLE,
	  'openid.invalidate_handle' => $ASSOC_HANDLE,
	  'nonce' => $nonce,
	 };
$ASSOC->addSignature($query, ['mode','identity','return_to'], 'openid.');
$session->param($token_key, $token);
$response = $consumer->complete($query);
isa_ok($response, "Net::OpenID::JanRain::Consumer::SuccessResponse",
	"response with invalidate_handle passing check_auth");
is($num_checks, 1, "did check_auth");

my $nonce = pop @nonces;
$query = {'openid.mode' => 'id_res',
	  'openid.identity' => 'http://smoker.myopenid.com/',
	  'openid.return_to' => "http://consumer.com/openid?nonce=$nonce",
	  'openid.assoc_handle' => $ASSOC2_HANDLE,
	  'openid.invalidate_handle' => $ASSOC_HANDLE,
	  'nonce' => $nonce,
	 };
$ASSOC->addSignature($query, ['mode','identity','return_to'], 'openid.');
$session->param($token_key, $token);
$response = $consumer->complete($query);
isa_ok($response, "Net::OpenID::JanRain::Consumer::FailureResponse",
	"response with invalidate_handle failing check_auth");
is($num_checks, 2, "did check_auth");

$query = {'openid.mode' => 'cancel'};
$session->param($token_key, $token);
$response = $consumer->complete($query);
isa_ok($response, "Net::OpenID::JanRain::Consumer::CancelResponse");

$query = {'openid.mode' => 'error',
	  'openid.error' => 'The world is so cruel'};
$session->param($token_key, $token);
$response = $consumer->complete($query);
isa_ok($response, "Net::OpenID::JanRain::Consumer::FailureResponse");


package TestAgent;
use Net::OpenID::JanRain::Util qw( fromBase64 toBase64 hashToKV );
use Net::OpenID::JanRain::CryptUtil qw( sha1 numToBase64 numToBytes base64ToNum DEFAULT_DH_GEN DEFAULT_DH_MOD );
use Test::More;
sub new {
    my $caller = shift;
    my $self = {
	assoc_secret => $ASSOC_SECRET,
	assoc_handle => $ASSOC_HANDLE,
	get_responses => {
	    'http://example.com/yadis1' => $yadis1,
	    'http://example.com/yadis2' => $yadis2,
	    'http://example.com/yadis3' => $yadis3,
	    'http://example.com/bad_yadis' => $bad_yadis,
	    'http://example.com/lid_yadis' => $lid_yadis,
	    'http://example.com/link1' => $link1,
	    'http://example.com/link2' => $link2,
	    'http://example.com/apage' => $apage,
	    }
	};

    bless($self, $caller);
}

sub get {
    my $self = shift;
    my $url = shift;
    my %headers = @_;
    my $response = $self->{get_responses}->{$url};
    return $response || HTTP::Response->new(404);
}

sub post {
    my $self = shift;
    my ($url, $query) = @_;

    my $res;
    if($query->{'openid.mode'} eq 'associate') {
	$res = server_associate($query, $self->{assoc_secret}, $self->{assoc_handle});
    }
    else {
	$res = s_c_a($query);
    }
    return response($url, 200, hashToKV($res));
}

sub response {
    my ($url, $status, $body) = @_;

    my $response = HTTP::Response->new($status);
    $response->content($body);
    $response->header('Content-Location', $url);

    return $response;
}

sub s_c_a {
    my $query = shift;
    my $reply;
    if($num_checks) {
	$reply = {is_valid => 'false'};
    }
    else {
	$reply = {is_valid => 'true'};
    }
    $num_checks++;

    return $reply;

}

# generate an associate response
sub server_associate {
    my ($q, $secret, $handle) = @_;
    is($q->{'openid.mode'}, 'associate', 'correct associate mode');
    is($q->{'openid.assoc_type'}, 'HMAC-SHA1', 'correct association type');

    my $reply = {
	assoc_type   => 'HMAC-SHA1',
	assoc_handle => $handle,
	expires_in   => '600',
	};
	
    if ($q->{'openid.session_type'} eq 'DH-SHA1') {
	my $dh = Crypt::DH->new;
	$dh->p($q->{'openid.dh_modulus'} || DEFAULT_DH_MOD);
	$dh->g($q->{'openid.dh_gen'} || DEFAULT_DH_GEN);
	$dh->generate_keys;
	$reply->{'session_type'} = 'DH-SHA1';
	$reply->{'dh_server_public'} = numToBase64($dh->pub_key);
	my $cpub = base64ToNum($q->{'openid.dh_consumer_public'});
	my $dh_sec = $dh->compute_secret($cpub);
	my $emk = toBase64(sha1(numToBytes($dh_sec)) ^ $secret);
	$reply->{'enc_mac_key'} = $emk;
    }
    else {
	$reply->{'mac_key'} = toBase64($secret);
    }

    $num_assocs++;

    return $reply;
}
