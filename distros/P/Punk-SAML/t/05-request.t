#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::SAML ();
use Punk::SAML::Request ();

use MIME::Base64 ();

my $ACS    = 'https://app.example.com/saml/acs';
my $SSO    = 'https://idp.example.com/sso';
my $ISSUER = 'https://app.example.com/saml/metadata';

# ---- the request id --------------------------------------------------

{
    my %seen;
    for (1 .. 50) {
        my $id = Punk::SAML::Request->new_id;
        # xs:ID is an XML Name and an XML Name may not begin with a digit.
        # Half of a bare hex string would, so this refusal is intermittent
        # in exactly the way that hides it.
        like $id, qr/\A_[0-9a-f]{32}\z/, 'the id is _ and 32 hex'
            or last;
        $seen{$id}++;
    }
    is scalar(keys %seen), 50, 'and 50 of them are 50 different ids';
}

# ---- the document ----------------------------------------------------

my %base = (
    id          => '_abc123',
    instant     => '2026-09-08T10:00:00Z',
    destination => $SSO,
    acs_url     => $ACS,
    issuer      => $ISSUER,
);

{
    my $xml = Punk::SAML::Request->build(%base);
    like $xml, qr{\A<samlp:AuthnRequest }, 'the root element';
    like $xml, qr{xmlns:samlp="urn:oasis:names:tc:SAML:2\.0:protocol"},
        'the protocol namespace';
    like $xml, qr{xmlns:saml="urn:oasis:names:tc:SAML:2\.0:assertion"},
        'the assertion namespace';
    like $xml, qr{ ID="_abc123"},            'the ID';
    like $xml, qr{ Version="2\.0"},          'the version';
    like $xml, qr{ IssueInstant="2026-09-08T10:00:00Z"}, 'the instant';
    like $xml, qr{ Destination="\Q$SSO\E"},  'the destination, copied';
    like $xml, qr{ AssertionConsumerServiceURL="\Q$ACS\E"}, 'the ACS URL';
    like $xml, qr{ProtocolBinding="urn:oasis:names:tc:SAML:2\.0:bindings:HTTP-POST"},
        'the POST binding';
    like $xml, qr{<saml:Issuer>\Q$ISSUER\E</saml:Issuer>}, 'the issuer';

    unlike $xml, qr{NameIDPolicy}, 'no NameIDPolicy without a format';
    unlike $xml, qr{ForceAuthn},
        'no ForceAuthn when false, because providers differ on reading it';
}

{
    my $xml = Punk::SAML::Request->build(%base,
        name_id_format => 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
        force_authn    => 1);
    like $xml, qr{<samlp:NameIDPolicy Format="urn:oasis:names:tc:SAML:1\.1:nameid-format:emailAddress" AllowCreate="true"/>},
        'NameIDPolicy when a format is given';
    like $xml, qr{ ForceAuthn="true"}, 'ForceAuthn when asked for';
}

# every interpolated value is escaped
{
    my $xml = Punk::SAML::Request->build(%base,
        issuer      => 'https://a/b?x=1&y=2',
        destination => 'https://i/s?q="v"');
    like $xml, qr{<saml:Issuer>https://a/b\?x=1&amp;y=2</saml:Issuer>},
        'an ampersand in the issuer is escaped';
    like $xml, qr{ Destination="https://i/s\?q=&quot;v&quot;"},
        'a quote in an attribute is escaped';
    unlike $xml, qr{"v"},
        'and the raw quote does not survive to break the attribute';
}

# ---- the URL encoder -------------------------------------------------

# RFC 3986 unreserved through, everything else %XX with upper-case hex.
# The three disagreements that break a redirect signature are `~`, space,
# and the case of the hex, so each is asserted rather than assumed.
is Punk::SAML::_urlenc('AZaz09-._~'), 'AZaz09-._~',
    'the unreserved set passes through, tilde included';
is Punk::SAML::_urlenc(' '),   '%20', 'a space is %20, never +';
is Punk::SAML::_urlenc('/'),   '%2F', 'a slash is escaped';
is Punk::SAML::_urlenc('+'),   '%2B', 'a plus is escaped';
is Punk::SAML::_urlenc('='),   '%3D', 'an equals is escaped';
is Punk::SAML::_urlenc("\xff"), '%FF', 'a high byte, in upper-case hex';
is Punk::SAML::_urlenc("\x0a"), '%0A', 'and a low one';
is Punk::SAML::_urlenc(''),    '',    'empty';

# ---- the redirect binding --------------------------------------------

SKIP: {
    eval { require IO::Uncompress::RawInflate; 1 }
        or skip 'IO::Uncompress::RawInflate required', 3;

    my $xml = Punk::SAML::Request->build(%base);
    my $b64 = Punk::SAML::_deflate_b64($xml);

    # The round trip through something that is not this encoder. A stored
    # block is legal DEFLATE and the only proof of that is an inflater
    # written by somebody else. Transparent => 0 because IO::Uncompress
    # passes unrecognised data straight through, which would turn a
    # broken encoder into a passing test.
    my $out;
    my $raw = MIME::Base64::decode_base64($b64);
    ok IO::Uncompress::RawInflate::rawinflate(\$raw => \$out, Transparent => 0),
        'the SAMLRequest payload is valid raw DEFLATE';
    is $out, $xml, 'and inflates back to the document';

    # not zlib and not gzip: a header is the commonest reason a provider
    # says "invalid request" with no detail
    isnt substr($raw, 0, 1), "\x78", 'there is no zlib header';
}

{
    my $xml = Punk::SAML::Request->build(%base);
    my $url = Punk::SAML::Request->redirect_url($SSO, $xml, '_flow1');
    like $url, qr{\A\Q$SSO\E\?SAMLRequest=}, 'the query starts after a ?';
    like $url, qr{&RelayState=_flow1\z},     'RelayState is appended';
    unlike $url, qr{SigAlg},  'and nothing is signed without a key';

    my $q = Punk::SAML::Request->redirect_url("$SSO?tenant=1", $xml, undef);
    like $q, qr{\A\Q$SSO\E\?tenant=1&SAMLRequest=},
        'an SSO URL with a query gets an & instead';
    unlike $q, qr{RelayState}, 'and no empty RelayState when there is none';
}

# ---- the signed string -----------------------------------------------

is Punk::SAML::_signed_string('AAA', 'BBB', 'CCC'),
   'SAMLRequest=AAA&RelayState=BBB&SigAlg=CCC',
   'the order of Bindings 3.4.4.1';
is Punk::SAML::_signed_string('AAA', '', 'CCC'),
   'SAMLRequest=AAA&SigAlg=CCC',
   'RelayState is omitted entirely when absent, not sent empty';

# ---- the redirect signature ------------------------------------------

SKIP: {
    eval { require Crypt::JWS; require Crypt::JWS::Key; 1 }
        or skip 'Crypt::JWS required', 10;

    for my $case (['RS256', 'rsa-sha256'], ['ES256', 'ecdsa-sha256']) {
        my ($alg, $uri) = @$case;
        my $key = Crypt::JWS::Key->generate($alg);
        my $pem = $key->to_pem(1);
        my $pub = $key->to_pem;

        my $xml = Punk::SAML::Request->build(%base);
        my $url = Punk::SAML::Request->redirect_url($SSO, $xml, '_flow1', $pem);

        like $url, qr/SigAlg=[^&]*\Q$uri\E/, "$alg: the SigAlg URI is derived from the key";

        # Verify the signature, rather than measure it. A test that checks
        # only that a Signature is present, or that it is the right
        # length, passes for a signature over the WRONG STRING - and the
        # wrong string is the entire failure mode this binding has.
        #
        # The signed string is reconstructed here the way a provider
        # reconstructs it: from the query as sent, in the order the
        # specification fixes, using the bytes on the wire and not
        # anything re-encoded.
        my ($qs) = $url =~ /\?(.*)\z/s;
        my %f = map { my ($k, $v) = split /=/, $_, 2; ($k => $v) }
                split /&/, $qs;
        is_deeply [sort keys %f],
                  [sort qw(SAMLRequest RelayState SigAlg Signature)],
                  "$alg: the query carries exactly the four fields";

        my $signed = "SAMLRequest=$f{SAMLRequest}"
                   . "&RelayState=$f{RelayState}"
                   . "&SigAlg=$f{SigAlg}";
        (my $sig = $f{Signature}) =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
        $sig = MIME::Base64::decode_base64($sig);

        ok Punk::SAML::_verify_bytes($pub, $alg, $signed, $sig),
            "$alg: the signature verifies over the query as sent";

        # and does not verify over a string that differs by one byte,
        # which is what proves the assertion above is not vacuous
        ok !Punk::SAML::_verify_bytes($pub, $alg, $signed . 'x', $sig),
            "$alg: and not over anything else";
    }

    # unsigned when there is no key, signed when there is: the option is
    # not a suggestion
    my $xml = Punk::SAML::Request->build(%base);
    unlike(Punk::SAML::Request->redirect_url($SSO, $xml, '_f'),
           qr/Signature=/, 'no key means no signature');

    # a key that will not parse is refused by name rather than producing
    # an unsigned request
    my $err = do {
        local $@;
        eval { Punk::SAML::Request->redirect_url($SSO, $xml, '_f', 'not a pem') };
        $@;
    };
    like $err, qr/will not parse as a PEM private key/,
        'a bad key croaks instead of silently sending an unsigned request';
}

# ---- the inbound field -----------------------------------------------

{
    my $bytes = '<samlp:Response/>';
    my $enc   = MIME::Base64::encode_base64($bytes, '');
    is Punk::SAML::_decode_field($enc, 262144), $bytes,
        'a SAMLResponse field decodes';

    # wrapped at 76 columns, which several providers do and every other
    # implementation accepts
    my $long    = '<samlp:Response>' . ('x' x 200) . '</samlp:Response>';
    my $wrapped = MIME::Base64::encode_base64($long);
    like $wrapped, qr/\n/, 'the oracle wrapped it';
    is Punk::SAML::_decode_field($wrapped, 262144), $long,
        'wrapped base64 is accepted';

    # the cap is on the ENCODED field, before any allocation
    my $err = do { local $@; eval { Punk::SAML::_decode_field($enc, 4) }; $@ };
    isa_ok $err, 'Punk::SAML::Error', 'over max_response throws';
    is $err->{code}, 'bad_base64', '  ... with the code';
    like $err->{message}, qr/over the max_response/, '  ... and says so';

    for my $bad (['the url alphabet', 'ab-_'],
                 ['not base64',       '****'],
                 ['bad padding',      'A===']) {
        my ($name, $str) = @$bad;
        my $e = do { local $@; eval { Punk::SAML::_decode_field($str, 0) }; $@ };
        isa_ok $e, 'Punk::SAML::Error', "refused: $name";
    }
}

done_testing();
