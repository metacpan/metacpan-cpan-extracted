use strict;
use warnings;

use Test::Exception;
use Test::More;
use Test::TCP;
use Test::Warnings 'warning';
use Try::Tiny;

{
	package My::REST::Client;
	use Moo;
	with 'Role::REST::Client';
	1;
}

{
	package My::TCP::Server;

	use parent qw( Plack::Component );

	use Plack::Request;

	sub call {
		my ($self, $env) = @_;
		my $req = Plack::Request->new($env);

		my $content_type = $env->{REQUEST_URI} =~ /json/i
			? 'application/json'
				: $env->{REQUEST_URI} =~ /html/i
				? 'text/html' : 'text/plain';

		return [
			200,
			[ 'Content-Type' => $content_type ],
			[ '{"foo":"bar"}' ],
		];
	}
	1;
}

use Plack::Runner;

my $host = '127.0.0.1';

my $server = try {
	Test::TCP->new(
		host => $host,
		max_wait => 3, # seconds
		code => sub {
			my $port = shift;
			my $runner = Plack::Runner->new;
			$runner->parse_options(
				'--host'   => $host,
				'--port'   => $port,
				'--env'    => 'test',
				'--server' => 'HTTP::Server::PSGI'
			);
			$runner->run(My::TCP::Server->new->to_app);
		}
	);
}
catch {
  plan skip_all => $_;
};

my $url = "http://$host:" . $server->port;
my $client = My::REST::Client->new;

# text/plain with specific undef: no deserialization
ok !ref($client->get("$url/plain", undef, {deserializer => undef })->data),
	'plain with undef';

# text/plain with default: no deserialization
ok !ref($client->get("$url/plain")->data), 'plain with default';

# text/plain with specific deserializer: deserialize
is ref($client->get(
	"$url/plain", undef, { deserializer => 'application/json'})->data), 'HASH',
	"plain with specific deserializer";

# application/json with undef deserializer: no deserialization
ok !ref($client->get("$url/json", undef, { deserializer => undef})->data),
	"json with undef";

# application/json with specific deserializer: deserialize
is ref($client->get(
	"$url/json", undef, { deserializer => 'application/json'})->data), 'HASH',
	"json with specific deserializer";

# application/json with default: deserialize
is ref($client->get("$url/json")->data), 'HASH', "json with default";

undef $server;
done_testing();
