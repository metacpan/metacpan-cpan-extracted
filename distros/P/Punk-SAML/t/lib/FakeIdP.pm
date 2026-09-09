package FakeIdP;

# Builds and signs Responses for the suite.
#
# The fixtures are GENERATED rather than checked in, so a test can break
# exactly one thing about an otherwise valid document and nothing else.
# A checked-in fixture with a hand-edited signature proves only that the
# edit broke it, not which check caught it.
#
# The canonicalisation and the digest go through File::Raw::XML and
# Crypt::JWS, which is to say through the same code the verifier uses.
# That is a real limitation and it is stated rather than hidden: this
# harness cannot prove the c14n is right, only that the verifier agrees
# with the signer. What proves the c14n is phase 1's transcribed W3C
# vectors, and what proves the whole against reality is phase 11's
# logins against Okta and Entra ID.

use 5.010;
use strict;
use warnings;

use MIME::Base64 ();
use File::Raw::XML qw(file_xml_decode);
use Crypt::JWS ();
use Crypt::JWS::Key ();

our $NS_P   = 'urn:oasis:names:tc:SAML:2.0:protocol';
our $NS_A   = 'urn:oasis:names:tc:SAML:2.0:assertion';
our $NS_D   = 'http://www.w3.org/2000/09/xmldsig#';
our $EXC    = 'http://www.w3.org/2001/10/xml-exc-c14n#';
our $ENV    = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature';
our $SHA256 = 'http://www.w3.org/2001/04/xmlenc#sha256';
our $RSA256 = 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256';

sub new {
    my ($class, %o) = @_;
    my $key = $o{key} || Crypt::JWS::Key->generate('RS256');
    return bless {
        key       => $key,
        priv      => $key->to_pem(1),
        pub       => $key->to_pem,
        entity_id => $o{entity_id} // 'https://idp.example.com/entity',
        sp_entity => $o{sp_entity} // 'https://app.example.com/saml/metadata',
        acs       => $o{acs}       // 'https://app.example.com/saml/acs',
    }, $class;
}

sub pub  { $_[0]{pub} }
sub certs { [ $_[0]{pub} ] }
sub entity_id { $_[0]{entity_id} }
sub sp_entity { $_[0]{sp_entity} }
sub acs  { $_[0]{acs} }

sub _t { my $t = shift // time; my @g = gmtime $t;
         sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ',
             $g[5]+1900, $g[4]+1, $g[3], $g[2], $g[1], $g[0] }

# An unsigned Response. %o lets a test change exactly one thing.
sub response {
    my ($self, %o) = @_;
    my $now    = $o{now}    // time;
    my $aid    = $o{assertion_id} // '_assertion1';
    my $rid    = $o{response_id}  // '_response1';
    my $irt    = exists $o{in_response_to} ? $o{in_response_to} : '_flow1';
    my $status = $o{status} // 'urn:oasis:names:tc:SAML:2.0:status:Success';
    my $nb     = _t($now - 60);
    my $na     = _t($now + 300);
    my $iss    = $o{issuer}    // $self->{entity_id};
    # The Assertion's Issuer separately from the Response's, so a test can
    # build the one document the two-issuer check exists for: a Response
    # from the configured provider carrying an Assertion minted by another.
    my $aiss   = $o{assertion_issuer} // $iss;
    my $aud    = $o{audience}  // $self->{sp_entity};
    my $recip  = $o{recipient} // $self->{acs};
    my $dest   = exists $o{destination} ? $o{destination} : $self->{acs};
    my $nameid = $o{name_id}   // 'jo@example.com';

    my $irt_attr  = defined $irt ? qq{ InResponseTo="$irt"} : '';
    my $dest_attr = defined $dest ? qq{ Destination="$dest"} : '';
    my $attrs = $o{attributes} // <<"XML";
<saml:AttributeStatement>
<saml:Attribute Name="email" FriendlyName="E-Mail Address">
<saml:AttributeValue>jo\@example.com</saml:AttributeValue>
</saml:Attribute>
<saml:Attribute Name="groups">
<saml:AttributeValue>staff</saml:AttributeValue>
<saml:AttributeValue>eng</saml:AttributeValue>
</saml:Attribute>
</saml:AttributeStatement>
XML
    $attrs =~ s/\n//g;

    my $assertion = qq{<saml:Assertion xmlns:saml="$NS_A" ID="$aid" Version="2.0" IssueInstant="} . _t($now) . qq{">}
      . qq{<saml:Issuer>$aiss</saml:Issuer>}
      . ($o{extra_in_assertion} // '')
      . qq{<saml:Subject><saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">$nameid</saml:NameID>}
      . qq{<saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">}
      . qq{<saml:SubjectConfirmationData$irt_attr Recipient="$recip" NotOnOrAfter="$na"/>}
      . qq{</saml:SubjectConfirmation></saml:Subject>}
      . qq{<saml:Conditions NotBefore="$nb" NotOnOrAfter="$na">}
      . ($o{no_audience} ? '' : qq{<saml:AudienceRestriction><saml:Audience>$aud</saml:Audience></saml:AudienceRestriction>})
      . qq{</saml:Conditions>}
      . ($o{no_authn} ? '' : qq{<saml:AuthnStatement AuthnInstant="} . _t($now) . qq{" SessionIndex="_sess1">}
                           . qq{<saml:AuthnContext><saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef></saml:AuthnContext>}
                           . qq{</saml:AuthnStatement>})
      . $attrs
      . qq{</saml:Assertion>};

    $assertion = $o{assertion_override} if exists $o{assertion_override};

    return qq{<samlp:Response xmlns:samlp="$NS_P" xmlns:saml="$NS_A" ID="$rid" Version="} . ($o{version} // '2.0') . qq{" IssueInstant="} . _t($now) . qq{"$irt_attr$dest_attr>}
      . qq{<saml:Issuer>$iss</saml:Issuer>}
      . ($o{extensions} // '')
      . qq{<samlp:Status><samlp:StatusCode Value="$status"/>}
      . ($o{status_message} ? qq{<samlp:StatusMessage>$o{status_message}</samlp:StatusMessage>} : '')
      . qq{</samlp:Status>}
      # first_assertion goes BEFORE the real one, because "which Assertion
      # does the reader take" has a different answer from "which does the
      # signer sign" depending on the side, and position is how a wrapping
      # attempt exploits that. second_assertion is the same attack after.
      . ($o{first_assertion} // '')
      . ($o{no_assertion} ? '' : $assertion)
      . ($o{second_assertion} // '')
      . qq{</samlp:Response>};
}

# Sign the element with the given ID, in place, by inserting a Signature
# as its first child after Issuer - which is where the schema puts it and
# where a real provider emits it.
sub sign {
    my ($self, $xml, $id, %o) = @_;

    my $ref_uri  = $o{ref_uri}  // "#$id";
    my $c14n_alg = $o{c14n_alg} // $EXC;
    my $sig_alg  = $o{sig_alg}  // $RSA256;
    my $dig_alg  = $o{dig_alg}  // $SHA256;
    my $tr1      = $o{transform1} // $ENV;
    my $tr2      = $o{transform2} // $EXC;

    # canonicalise the target element as the verifier will: exclusive,
    # with the (not yet present) Signature excluded, which is what
    # enveloped-signature means
    my $doc  = file_xml_decode($xml, id_attrs => ['ID']);
    my $node = $doc->by_id(ID => $id) or die "no element with ID $id";
    my $canon = $node->c14n(mode => 'exclusive');
    # the digest follows the declared DigestMethod, so a test that changes
    # the algorithm gets a fixture that is CONSISTENT with it rather than
    # one that fails for the unrelated reason that the bytes disagree
    my $digest = MIME::Base64::encode_base64(
        $dig_alg eq 'http://www.w3.org/2000/09/xmldsig#sha1'
            ? Crypt::JWS::sha1($canon)
            : Crypt::JWS::sha256($canon), '');
    $digest = $o{digest} if exists $o{digest};

    my $signed_info =
        qq{<ds:SignedInfo xmlns:ds="$NS_D">}
      . qq{<ds:CanonicalizationMethod Algorithm="$c14n_alg"/>}
      . qq{<ds:SignatureMethod Algorithm="$sig_alg"/>}
      . qq{<ds:Reference URI="$ref_uri">}
      . qq{<ds:Transforms><ds:Transform Algorithm="$tr1"/><ds:Transform Algorithm="$tr2"/>}
      . ($o{extra_transform} // '')
      . qq{</ds:Transforms>}
      . qq{<ds:DigestMethod Algorithm="$dig_alg"/>}
      . qq{<ds:DigestValue>$digest</ds:DigestValue>}
      . qq{</ds:Reference>}
      . ($o{second_reference} // '')
      . qq{</ds:SignedInfo>};

    # canonicalise SignedInfo on its own, which is what is signed
    my $si_doc  = file_xml_decode($signed_info);
    my $si_c14n = $si_doc->root->c14n(mode => 'exclusive');
    my $sigval  = $o{sigval} // MIME::Base64::encode_base64(
        Punk::SAML::_sign_bytes($self->{priv}, 'RS256', $si_c14n), '');

    # KeyInfo, when a test asks for one. The verifier must never read it -
    # every key it tries is one the deployer configured - so the only way
    # to prove that is to put a key in here and watch it be ignored.
    my $key_info = '';
    if (defined $o{key_info}) {
        my ($b) = $o{key_info} =~ /-----BEGIN [^-]+-----(.*?)-----END/s;
        $b //= $o{key_info};
        $b =~ s/\s+//g;
        $key_info = qq{<ds:KeyInfo><ds:X509Data>}
                  . qq{<ds:X509Certificate>$b</ds:X509Certificate>}
                  . qq{</ds:X509Data></ds:KeyInfo>};
    }

    my $sig = qq{<ds:Signature xmlns:ds="$NS_D">$signed_info}
            . qq{<ds:SignatureValue>$sigval</ds:SignatureValue>}
            . $key_info . qq{</ds:Signature>};

    # insert after the element's Issuer
    my $where = $o{place} // 'after_issuer';
    if ($where eq 'after_issuer') {
        my $tag = $id =~ /^_assertion/ ? 'saml:Assertion' : 'samlp:Response';
        $xml =~ s{(<\Q$tag\E\b[^>]*\bID="\Q$id\E"[^>]*>(?:<saml:Issuer>.*?</saml:Issuer>)?)}{$1$sig}s
            or die "could not place the signature";
    }
    else {
        $xml =~ s{\Q$where\E}{$sig$where}s or die "could not place at $where";
    }
    return $xml;
}

1;
