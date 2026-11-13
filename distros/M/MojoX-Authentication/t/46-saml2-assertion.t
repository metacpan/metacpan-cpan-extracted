use v5.24;
use warnings;
use experimental qw< signatures >;
use Test::More;
use FindBin qw< $Bin >;
use MIME::Base64 qw< encode_base64 >;
use POSIX qw< strftime >;

eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 }
   or plan skip_all => 'Net::SAML2 0.86 not available';

require Net::SAML2::XML::Sig;
require MojoX::Authentication::Model::SAML2;

# parse_assertion is the security gate for SAML2: a good assertion goes
# through, anything not signed by the IdP, not for this request, not for
# this SP or out of its validity window must be refused and never cached.

my $data  = "$Bin/data";
my $sp_id = 'https://srv.example.com/sp';
my $saml2 = MojoX::Authentication::Model::SAML2->new(
   idp => "$data/test-idp-metadata.xml",
   sp_configuration => {
      identifier => $sp_id,
      key        => "$Bin/../eg/server.key",
   },
);

sub ts ($offset) { strftime('%Y-%m-%dT%H:%M:%SZ', gmtime(time() + $offset)) }

sub response_xml (%o) {
   my $id  = $o{id};
   my $irt = $o{in_response_to} // $id;
   my $aud = $o{audience}       // $sp_id;
   my $iss = $o{issuer}         // q{https://idp.example.com};
   my $nb  = ts($o{not_before}  // -60);
   my $na  = ts($o{not_after}   // 300);
   my $nameid = $o{nameid};
   my $subject = defined($nameid) ? "<saml:NameID>$nameid</saml:NameID>" : q{};
   return qq{<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="resp-$id" InResponseTo="$irt" Version="2.0" IssueInstant="$nb"><saml:Issuer>$iss</saml:Issuer><samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status><saml:Assertion ID="assert-$id" Version="2.0" IssueInstant="$nb"><saml:Issuer>$iss</saml:Issuer><saml:Subject>$subject<saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer"><saml:SubjectConfirmationData InResponseTo="$irt" NotOnOrAfter="$na"/></saml:SubjectConfirmation></saml:Subject><saml:Conditions NotBefore="$nb" NotOnOrAfter="$na"><saml:AudienceRestriction><saml:Audience>$aud</saml:Audience></saml:AudienceRestriction></saml:Conditions><saml:AttributeStatement><saml:Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"><saml:AttributeValue>Alice</saml:AttributeValue></saml:Attribute></saml:AttributeStatement></saml:Assertion></samlp:Response>};
}

sub signed ($xml, $who = 'test-idp') {
   my $signer = Net::SAML2::XML::Sig->new({
      x509 => 1,
      key  => "$data/$who.key",
      cert => "$data/$who.crt",
      no_xml_declaration => 1,
   });
   return $signer->sign($xml);
}

# parse $xml as the answer to a pending request $id
sub parse ($id, $xml) {
   $saml2->cache->set({ ts => time() }, $saml2->_key(authnreq_id => $id), time() + 30);
   return $saml2->parse_assertion($id, encode_base64($xml, ''));
}

{
   my $user = eval {
      parse('req-good',
         signed(response_xml(id => 'req-good', nameid => 'good@example.com')));
   };
   is $@, '', 'good assertion: no error';
   is $user && $user->{key}, 'good@example.com', 'good assertion: uid from NameID';
   is $user && $user->{fullname}, 'Alice', 'good assertion: attributes remapped';
   ok $saml2->load_user(undef, 'good@example.com'),
      'good assertion: user is cached';
}

my $bad_signature = qr{signature|certificate}i;
my $invalid       = qr{Invalid SAMLResponse};
my %why = (
   tampered                => $bad_signature,
   unsigned                => $bad_signature,
   'signed by another key' => $bad_signature,
   'wrong InResponseTo'    => $invalid,
   'wrong audience'        => $invalid,
   'foreign issuer'        => qr{saml:Issuer|Invalid SAMLResponse},
   expired                 => $invalid,
   'no NameID'             => qr{NameID},
   'empty NameID'          => qr{NameID},
);

my %bad = (
   tampered => sub ($id, $nameid) {
      my $xml = signed(response_xml(id => $id, nameid => 'innocent@example.com'));
      $xml =~ s{innocent\@example\.com}{$nameid}g;
      return $xml;
   },
   unsigned => sub ($id, $nameid) {
      response_xml(id => $id, nameid => $nameid);
   },
   'signed by another key' => sub ($id, $nameid) {
      signed(response_xml(id => $id, nameid => $nameid), 'other-idp');
   },
   'wrong InResponseTo' => sub ($id, $nameid) {
      signed(response_xml(id => $id, nameid => $nameid,
         in_response_to => 'req-someone-else'));
   },
   'wrong audience' => sub ($id, $nameid) {
      signed(response_xml(id => $id, nameid => $nameid,
         audience => 'https://other-sp.example.com/sp'));
   },
   # same key, another issuer: e.g. a tenant of a multi-tenant IdP
   # platform signing every tenant with one key
   'foreign issuer' => sub ($id, $nameid) {
      signed(response_xml(id => $id, nameid => $nameid,
         issuer => 'https://other-tenant.example.net'));
   },
   expired => sub ($id, $nameid) {
      signed(response_xml(id => $id, nameid => $nameid,
         not_before => -600, not_after => -60));
   },
   'no NameID' => sub ($id, $nameid) {
      signed(response_xml(id => $id, nameid => undef));
   },
   'empty NameID' => sub ($id, $nameid) {
      signed(response_xml(id => $id, nameid => q{}));
   },
);

my $n = 0;
for my $case (sort keys %bad) {
   my $id     = 'req-bad-' . ++$n;
   my $nameid = "bad-$n\@example.com";
   my $user = eval { parse($id, $bad{$case}->($id, $nameid)) };
   my $error = $@;    # copy: evals below reset $@
   ok !defined($user), "$case: no user returned";
   like "$error", $why{$case}, "$case: refused for the right reason";
   is $saml2->load_user(undef, $nameid), undef, "$case: nothing cached";
   next unless $case =~ m{NameID};
   is $saml2->load_user(undef, q{}), undef, "$case: nothing cached without a uid";
   $saml2->wipe_user(q{});   # keep a failure from leaking into other cases
}

done_testing();
