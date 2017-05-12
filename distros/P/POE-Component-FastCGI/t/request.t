use Test::Simple tests => 17;

use POE::Component::FastCGI::Request;
# loaded
ok(1);

my $get = POE::Component::FastCGI::Request->new(
	undef, # XXX
	1,
  1,
	{
		REQUEST_METHOD => "GET",
		REQUEST_URI => "/test?foo=bar",
		QUERY_STRING => "foo=bar",
		HTTP_HOST => "localhost",
	}
);

ok(ref $get and $get->isa("HTTP::Request"));
ok($get->header("hOsT") eq "localhost");
ok($get->uri->host eq "localhost");
ok($get->uri->path eq "/test");
ok($get->query("foo") eq "bar");
ok(not defined $get->query("baz"));
ok(UNIVERSAL::isa($get->make_response, 'POE::Component::FastCGI::Response'));

my $post = POE::Component::FastCGI::Request->new(
	undef, # XXX
	1,
  1,
	{
		REQUEST_METHOD => "POST",
		REQUEST_URI => "/something",
		SERVER_NAME => "post.data.test:8080",
		HTTP_COOKIE => "test=ing",
	},
	"user=dgl&data=" . ('a' x 1e4),
);

ok(ref $post and $post->isa("HTTP::Request"));
ok($post->method eq "POST");
ok($post->uri->host eq "post.data.test");
ok($post->uri->port == 8080);
ok($post->cookie("test") eq "ing");

my $q = $post->query;
ok(scalar keys(%$q) == 2 && defined $q->{user} && defined $q->{data});
ok($q->{user} eq "dgl");
ok($q->{data} eq ('a' x 1e4));
ok(UNIVERSAL::isa($post->make_response, 'POE::Component::FastCGI::Response'));

