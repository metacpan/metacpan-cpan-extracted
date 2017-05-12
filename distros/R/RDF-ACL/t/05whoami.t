use Test::More tests => 6;
use RDF::ACL;
use Error qw(:try);

my $acl = RDF::ACL->new;

my $id = $acl->allow(
	'webid'     => ['http://example.com/joe#me'],
	'item'      => 'http://example.com/private/document',
	'level'     => ['read']
	);

$acl->i_am('http://example.com/joe#me');

is($acl->who_am_i, 'http://example.com/joe#me',
	"who_am_i works");

try
{
	$acl->allow(
		'webid'     => ['http://example.com/joe#me'],
		'item'      => 'http://example.com/private/document',
		'level'     => ['write']
		);
}
catch Error::Simple with
{
	my $e = shift;
	ok($e, "This is supposed to fail:- $e");
};

try
{
	$acl->deny($id);
}
catch Error::Simple with
{
	my $e = shift;
	ok($e, "This is also supposed to fail:- $e");
};

$acl->i_am(undef);

ok($acl->allow(
		'webid'     => ['http://example.com/joe#me'],
		'item'      => 'http://example.com/private/document',
		'level'     => ['control']
		),
	"Assigning control access to joe.");

$acl->i_am('http://example.com/joe#me');

ok($acl->allow(
		'webid'     => ['http://example.com/joe#me'],
		'item'      => 'http://example.com/private/document',
		'level'     => ['write']
		),
	"Now it works!");

ok($acl->deny($id), "This works too!");
