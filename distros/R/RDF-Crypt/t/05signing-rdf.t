use utf8;
use Test::More tests => 10;
use RDF::Crypt;
use RDF::TrineX::Functions -all;

my $key = Crypt::OpenSSL::RSA->generate_key(1024);
my $V   = RDF::Crypt::Verifier->new_from_string($key->get_public_key_string);
my $S   = RDF::Crypt::Signer->new_from_string($key->get_private_key_string);

my $data1 = <<'EXAMPLE';
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.
@prefix contact: <http://www.w3.org/2000/10/swap/pim/contact#>.

_:b1 #
  rdf:type contact:Person;
  contact:fullName "Eric Miller";
  contact:mailbox <mailto:em@w3.org>;
  contact:personalTitle "Dr.".
EXAMPLE

my $data2 = <<'EXAMPLE';
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.
@prefix x: <http://www.w3.org/2000/10/swap/pim/contact#>.

_:b2
  rdf:type x:Person;
  x:fullName "Eric Miller";
  x:mailbox <mailto:em@w3.org>;
  x:personalTitle "Dr.".
EXAMPLE

is(
	$S->sign_model(parse $data1, as => 'Turtle', base => 'http://example.net/'),
	$S->sign_model(parse $data2, as => 'Turtle', base => 'http://example.net/'),
	"equivalent models generate same signature",
);

my $embedded = $S->sign_embed_turtle($data1);

like $embedded, qr{_:b1 #}, "kept original formatting";
like $embedded, qr{CANONICAL_SIGNATURE}, "added signature";

ok(
	$V->verify_embedded_turtle($embedded),
	"verification works",
);

$embedded =~ s{_:b1}{_:b9}g;

ok(
	$V->verify_embedded_turtle($embedded),
	"verification not broken by formatting changes",
);

$embedded =~ s{mailbox}{mbox}g;

ok(
	!$V->verify_embedded_turtle($embedded),
	"verification broken by real changes",
);

$embedded =~ s{mbox}{mailbox}g;

ok(
	$V->verify_embedded_turtle($embedded),
	"verification works again",
);

$embedded =~ s{CANONICAL_SIGNATURE.\K...}{XYZ}g;

ok(
	!$V->verify_embedded_turtle($embedded),
	"verification broken by signature tampering",
);

my $rdfxml = serialize(
	parse($data1, as => 'Turtle', base => 'http://example.net/'),
	as => 'RDFXML',
);

my $embedded_x = $S->sign_embed_rdfxml($rdfxml);
like $embedded_x, qr{CANONICAL_SIGNATURE}, "added signature to RDFXML";

ok(
	$V->verify_embedded_rdfxml($embedded_x),
	"verification works for RDFXML",
);
