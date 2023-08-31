use Test::Lib;
use Test::Net::SAML2;
use MooseX::Test::Role;
use Test::Mock::One;

requires_ok('Net::SAML2::Role::VerifyXML');

my $consumer = consuming_object(
    'Net::SAML2::Role::VerifyXML'
);

my $override = Sub::Override->new(
    'XML::Sig::verify' => sub { return 1 }
);

$override->override(
  'XML::Sig::signer_cert' => sub {
    return Test::Mock::One->new('X-Mock-Strict' => 1, subject => 'foo');
  }
);

$override->override(
  'Crypt::OpenSSL::Verify::new' => sub {
    return Test::Mock::One->new('X-Mock-Strict' => 1, verify => '1');
  }
);

lives_ok(sub { $consumer->verify_xml() }, "We verified XML");
lives_ok(sub { $consumer->verify_xml('fakexml', cacert => 'things') },
  "... also with cacert");
lives_ok(
  sub { $consumer->verify_xml('fakexml', anchors => { subject => 'foo' }) },
  "... also with anchors");

done_testing;
