package SSODemoIdP;

use strict;
use warnings;
use Punk;

our $VERSION = '0.01';

# A DEMO identity provider. It exists so example/SSO can complete a login
# on one machine with no account anywhere.
#
# IT IS NOT AN IDENTITY PROVIDER. It does not authenticate anybody: it
# shows a list of users and signs an assertion for whichever one is
# clicked. There is no password, no session, no policy, and its signing
# key is committed to this repository in plain sight. Do not put it
# anywhere a browser you care about can reach.
#
# What it is good for: proving the other half of example/SSO works, and
# giving you something to point punk saml verify at.
#
# It identifies itself as 127.0.0.1 rather than localhost, deliberately.
# On this machine `localhost` resolves to ::1 first, this server listens
# on IPv4, and Fetch - which is what reads this metadata at the service
# provider's boot - does not fall back from one to the other the way a
# browser does. The address that works is the one in the document.

use Punk::SAML ();
use Punk::SAML::Metadata ();
use MIME::Base64 ();
use File::Raw::XML qw(file_xml_decode);
use Crypt::JWS ();

config 'config/punk.yml';

# The service provider this demo signs users into. In a real provider
# these come from the SP's metadata, uploaded through a console.
our $SP_ENTITY = 'https://localhost:5000/saml/metadata';
our $SP_ACS    = 'https://localhost:5000/saml/acs';

our $NS_P = 'urn:oasis:names:tc:SAML:2.0:protocol';
our $NS_A = 'urn:oasis:names:tc:SAML:2.0:assertion';
our $NS_D = 'http://www.w3.org/2000/09/xmldsig#';
our $NS_M = 'urn:oasis:names:tc:SAML:2.0:metadata';
our $EXC  = 'http://www.w3.org/2001/10/xml-exc-c14n#';
our $ENV_T = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature';
our $SHA256 = 'http://www.w3.org/2001/04/xmlenc#sha256';
our $RSA256 = 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256';

# The people this demo will sign in. A real provider has a directory.
our @USERS = (
    { name_id => 'jo@example.com',
      email   => 'jo@example.com',
      groups  => ['staff'] },
    { name_id => 'sam@example.com',
      email   => 'sam@example.com',
      groups  => ['staff', 'eng', 'oncall'] },
);

sub _slurp {
    my ($f) = @_;
    open my $fh, '<:raw', $f or die "SSODemoIdP: $f: $!\n";
    local $/;
    return <$fh>;
}

# Read once at boot. The key is committed beside this file, which is the
# whole reason this provider must never be reachable from anywhere real.
our $KEY  = _slurp('../certs/idp-key.pem');
our $CERT = _slurp('../certs/idp-cert.pem');

sub key  { $KEY }
sub cert { $CERT }

sub cert_body {
    my ($b) = cert() =~ /-----BEGIN CERTIFICATE-----(.*?)-----END/s;
    $b =~ s/\s+//g;
    return $b;
}

sub _instant {
    my ($t) = @_;
    my @g = gmtime($t // time);
    return sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ',
        $g[5] + 1900, $g[4] + 1, $g[3], $g[2], $g[1], $g[0];
}

sub _id { '_' . unpack 'H*', Crypt::JWS::random_bytes(16) }

# ---- routes -----------------------------------------------------------

# This provider's metadata, which is what example/SSO reads. Exactly the
# shape a real provider publishes: the certificate, never the key.
get '/idp/metadata' => sub {
    my ($c) = @_;
    my $cert = cert_body();
    my $doc = qq{<md:EntityDescriptor xmlns:md="$NS_M" xmlns:ds="$NS_D" }
        . qq{entityID="http://127.0.0.1:5001/idp/metadata">}
        . qq{<md:IDPSSODescriptor protocolSupportEnumeration="$NS_P">}
        . qq{<md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data>}
        . qq{<ds:X509Certificate>$cert</ds:X509Certificate>}
        . qq{</ds:X509Data></ds:KeyInfo></md:KeyDescriptor>}
        . qq{<md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>}
        . qq{<md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" }
        . qq{Location="http://127.0.0.1:5001/idp/sso"/>}
        . qq{</md:IDPSSODescriptor></md:EntityDescriptor>};
    return [200, ['Content-Type', 'application/samlmetadata+xml'], [$doc]];
};

# Where the service provider's redirect lands. A real provider
# authenticates the user here. This one asks which user to be.
get '/idp/sso' => sub {
    my ($c) = @_;

    # The AuthnRequest arrives deflated and base64'd on the query string.
    # Reading it is optional for this demo, but the request id has to
    # come back as InResponseTo or the service provider will refuse the
    # answer - correctly, with code bad_in_response_to.
    my $req_id = '';
    my $acs    = $SP_ACS;
    if (my $enc = $c->param('SAMLRequest')) {
        my $raw = MIME::Base64::decode_base64($enc);
        my $xml;
        require IO::Uncompress::RawInflate;
        # Transparent => 0: IO::Uncompress passes data it does not
        # recognise straight through, which would turn a broken request
        # into one that looks fine.
        if (IO::Uncompress::RawInflate::rawinflate(\$raw => \$xml,
                                                   Transparent => 0)) {
            my $doc = eval { file_xml_decode($xml, id_attrs => ['ID']) };
            if ($doc) {
                my $root = $doc->root;
                $req_id = $root->attr('ID')                         // '';
                $acs    = $root->attr('AssertionConsumerServiceURL') // $SP_ACS;
            }
        }
    }
    my $relay = $c->param('RelayState') // '';

    my $rows = join '', map {
        my $u = $_;
        my $groups = join ', ', @{ $u->{groups} };
        qq{<form method="post" action="/idp/sso">}
        . qq{<input type="hidden" name="name_id" value="$u->{name_id}">}
        . qq{<input type="hidden" name="req_id" value="$req_id">}
        . qq{<input type="hidden" name="relay" value="$relay">}
        . qq{<input type="hidden" name="acs" value="$acs">}
        . qq{<button type="submit">Sign in as $u->{email}</button>}
        . qq{ <small>groups: $groups</small></form>}
    } @USERS;

    return $c->html(<<"HTML");
<!doctype html><meta charset="utf-8"><title>Demo identity provider</title>
<style>body{font:16px/1.5 system-ui;margin:3rem auto;max-width:40rem}
form{margin:.5rem 0}button{font:inherit;padding:.4rem .8rem}
.warn{background:#fee;border:1px solid #c00;padding:1rem;margin:1rem 0}</style>
<h1>Demo identity provider</h1>
<p class="warn"><strong>This authenticates nobody.</strong> It signs an
assertion for whichever user you click, with a key committed to the
repository. It exists to prove the other half of the example works.</p>
<p>Request: <code>@{[ $req_id || 'none (unsolicited)' ]}</code></p>
$rows
HTML
};

# Sign an assertion and POST it back, which is the HTTP-POST binding: an
# auto-submitting form is how every real provider does this.
post '/idp/sso' => sub {
    my ($c) = @_;
    my $name_id = $c->param('name_id') // $USERS[0]{name_id};
    my $req_id  = $c->param('req_id')  // '';
    my $relay   = $c->param('relay')   // '';
    my $acs     = $c->param('acs')     // $SP_ACS;

    my ($user) = grep { $_->{name_id} eq $name_id } @USERS;
    $user ||= $USERS[0];

    my $now = time;
    my $aid = _id();
    my $rid = _id();
    my $irt = $req_id ? qq{ InResponseTo="$req_id"} : '';

    my $attrs = join '',
        qq{<saml:Attribute Name="email" FriendlyName="E-Mail Address">}
      . qq{<saml:AttributeValue>$user->{email}</saml:AttributeValue>}
      . qq{</saml:Attribute>},
        (map { qq{<saml:Attribute Name="groups">}
             . qq{<saml:AttributeValue>$_</saml:AttributeValue>}
             . qq{</saml:Attribute>} } @{ $user->{groups} });

    my $assertion =
        qq{<saml:Assertion xmlns:saml="$NS_A" ID="$aid" Version="2.0" }
      . qq{IssueInstant="@{[ _instant($now) ]}">}
      . qq{<saml:Issuer>http://127.0.0.1:5001/idp/metadata</saml:Issuer>}
      . qq{<saml:Subject>}
      . qq{<saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">$user->{name_id}</saml:NameID>}
      . qq{<saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">}
      . qq{<saml:SubjectConfirmationData$irt Recipient="$acs" }
      . qq{NotOnOrAfter="@{[ _instant($now + 300) ]}"/>}
      . qq{</saml:SubjectConfirmation></saml:Subject>}
      . qq{<saml:Conditions NotBefore="@{[ _instant($now - 60) ]}" }
      . qq{NotOnOrAfter="@{[ _instant($now + 300) ]}">}
      . qq{<saml:AudienceRestriction><saml:Audience>$SP_ENTITY</saml:Audience>}
      . qq{</saml:AudienceRestriction></saml:Conditions>}
      . qq{<saml:AuthnStatement AuthnInstant="@{[ _instant($now) ]}" SessionIndex="@{[ _id() ]}">}
      . qq{<saml:AuthnContext><saml:AuthnContextClassRef>}
      . qq{urn:oasis:names:tc:SAML:2.0:ac:classes:Password}
      . qq{</saml:AuthnContextClassRef></saml:AuthnContext></saml:AuthnStatement>}
      . qq{<saml:AttributeStatement>$attrs</saml:AttributeStatement>}
      . qq{</saml:Assertion>};

    my $response =
        qq{<samlp:Response xmlns:samlp="$NS_P" xmlns:saml="$NS_A" }
      . qq{ID="$rid" Version="2.0" IssueInstant="@{[ _instant($now) ]}"$irt }
      . qq{Destination="$acs">}
      . qq{<saml:Issuer>http://127.0.0.1:5001/idp/metadata</saml:Issuer>}
      . qq{<samlp:Status><samlp:StatusCode }
      . qq{Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status>}
      . $assertion
      . qq{</samlp:Response>};

    # Sign the Assertion. Punk::SAML::Metadata->sign puts an enveloped
    # signature on the element with this ID - the same code path the
    # plugin uses for its own metadata, and the same one its verifier
    # checks.
    my $signed = Punk::SAML::Metadata->sign($response, $aid, key(), cert());

    my $b64 = MIME::Base64::encode_base64($signed, '');
    my $rs  = $relay;
    for ($b64, $rs) { s/&/&amp;/g; s/"/&quot;/g; s/</&lt;/g }

    return $c->html(<<"HTML");
<!doctype html><meta charset="utf-8"><title>Signing you in</title>
<body onload="document.forms[0].submit()">
<p>Posting the assertion back to the service provider...</p>
<form method="post" action="$acs">
<input type="hidden" name="SAMLResponse" value="$b64">
<input type="hidden" name="RelayState" value="$rs">
<noscript><button type="submit">Continue</button></noscript>
</form>
HTML
};

get '/' => sub {
    my ($c) = @_;
    return $c->html(<<'HTML');
<!doctype html><meta charset="utf-8"><title>Demo identity provider</title>
<style>body{font:16px/1.5 system-ui;margin:3rem auto;max-width:40rem}</style>
<h1>Demo identity provider</h1>
<p>Start at the service provider, not here:
<a href="https://localhost:5000/">https://localhost:5000/</a></p>
<p>This provider's metadata: <a href="/idp/metadata">/idp/metadata</a></p>
HTML
};

1;

__END__
