use Test::More tests => 6;
use RDF::ACL;

my $acl = RDF::ACL->new;

my $authid = $acl->allow(
	'agent'       => ['http://example.com/fembot#me'],
	'agent_class' => ['http://xmlns.com/foaf/0.1/Person'],
	'item_class'  => 'http://xmlns.com/foaf/0.1/Document',
	'level'       => ['read']
	);
my $authid2 = $acl->allow(
	'agent'       => ['http://example.com/fembot#me'],
	'item_class'  => 'http://xmlns.com/foaf/0.1/PersonalProfileDocument',
	'level'       => ['append', 'read']
	);

my $proper = <<CANON;
<$authid> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/ns/auth/acl#Authorization> .
<$authid> <http://www.w3.org/ns/auth/acl#accessToClass> <http://xmlns.com/foaf/0.1/Document> .
<$authid> <http://www.w3.org/ns/auth/acl#agent> <http://example.com/fembot#me> .
<$authid> <http://www.w3.org/ns/auth/acl#agentClass> <http://xmlns.com/foaf/0.1/Person> .
<$authid> <http://www.w3.org/ns/auth/acl#mode> <http://www.w3.org/ns/auth/acl#Read> .
<$authid2> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/ns/auth/acl#Authorization> .
<$authid2> <http://www.w3.org/ns/auth/acl#accessToClass> <http://xmlns.com/foaf/0.1/PersonalProfileDocument> .
<$authid2> <http://www.w3.org/ns/auth/acl#agent> <http://example.com/fembot#me> .
<$authid2> <http://www.w3.org/ns/auth/acl#mode> <http://www.w3.org/ns/auth/acl#Append> .
<$authid2> <http://www.w3.org/ns/auth/acl#mode> <http://www.w3.org/ns/auth/acl#Read> .
CANON
$proper =~ s/\r?\n/\r\n/g;

#is($proper, $acl->save(RDF::Trine::Serializer::NTriples::Canonical->new), "allow seems to generate sensible triples");

ok(!$acl->check(
		'http://example.com/joe#me',
		'http://example.com/private/document',
		'Read'),
	"by default, deny access"
	);

my $agent_info = [<<AGENTINFO, parser => 'Turtle', base => 'http://example.com/'];
<http://example.com/joe#me> a <http://xmlns.com/foaf/0.1/Person> .
<http://example.com/joe#me> a <http://xmlns.com/foaf/0.1/Agent> .
<http://example.com/fembot#me> a <http://xmlns.com/foaf/0.1/Agent> .
AGENTINFO

my $document_info = [<<DOCINFO, parser => 'Turtle', base => 'http://example.com/'];
<http://example.com/private/document> a <http://xmlns.com/foaf/0.1/Document> .
<http://example.com/private/document> a <http://xmlns.com/foaf/0.1/PersonalProfileDocument> .
DOCINFO

ok($acl->check(
		'http://example.com/joe#me',
		'http://example.com/private/document',
		'Read',
		$agent_info,
		$document_info,
	),
	"with class info, allow access!"
	);
	
my @reasons = $acl->why(
	'http://example.com/fembot#me',
	'http://example.com/private/document',
	'Read',
	$agent_info,
	$document_info);
is(2, scalar @reasons, "first explanation works ok");

my @reasons2 = $acl->why(
	'http://example.com/fembot#me',
	'http://example.com/private/document',
	'append',
	$agent_info,
	$document_info);
is(1, scalar @reasons2, "second explanation works ok");

$acl->deny($authid2);

ok(!$acl->check(
		'http://example.com/fembot#me',
		'http://example.com/private/document',
		'APPEND',
		$agent_info,
		$document_info),
	"removed append authorisation"
	);

ok($acl->check(
		'http://example.com/fembot#me',
		'http://example.com/private/document',
		'read',
		$agent_info,
		$document_info),
	"but kept read"
	);
