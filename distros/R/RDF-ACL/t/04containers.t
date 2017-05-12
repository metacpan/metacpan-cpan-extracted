use Test::More tests => 2;
use RDF::ACL;

my $acl = RDF::ACL->new;

my $authid = $acl->allow(
	'webid'     => ['http://example.com/joe#me'],
	'container' => 'http://example.com/private/',
	'level'     => ['read']
	);

$acl->created(
	'http://example.com/private/document',
	'http://example.com/private/'
	);

ok($acl->check(
		'http://example.com/joe#me',
		'http://example.com/private/document',
		'Read'),
	"Access granted because of container's default authorisation"
	);

my @reasons = $acl->why(
	'http://example.com/joe#me',
	'http://example.com/private/document',
	'Read'
	);

ok($authid ne $reasons[0], "Default authorisation is cloned");