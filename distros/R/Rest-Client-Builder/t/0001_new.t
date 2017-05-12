use strict;
use warnings;

package Your::API;
use base qw(Rest::Client::Builder);

use Test::More tests => 6;

sub new {
my ($class) = @_;
	my $self;
	$self = $class->SUPER::new({
		on_request => sub {
			return $self->request(@_);
		},
	}, 'http://hostname/api');

	return bless($self, $class);
};

sub request {
	my ($self, $method, $path, $args, $add) = @_;
	return sprintf('%s %s %s %s', $method, $path, ($args->{value} ? $args->{value} : 'undef'), $add);
}

my $api = Your::API->new();

my $result = $api->resource->get({ value => 1 }, 2);
ok($result eq 'GET http://hostname/api/resource 1 2', 'get');

$result = $api->resource(10)->post({ value => 1 }, 2);
ok($result eq 'POST http://hostname/api/resource/10 1 2', 'post');

$result = $api->resource(10)->subresource('alfa', 'beta')->state->put({ value => 1 }, 2);
ok($result eq 'PUT http://hostname/api/resource/10/subresource/alfa/beta/state 1 2', 'put');

$result = $api->resource(10)->subresource('alfa', 'beta')->delete({}, 2);
ok($result eq 'DELETE http://hostname/api/resource/10/subresource/alfa/beta undef 2', 'delete');

$result = $api->resource(10, 1, 2)->child(1)->head({}, 2);
ok($result eq 'HEAD http://hostname/api/resource/10/1/2/child/1 undef 2', 'head');

$result = $api->resource(10)->something->patch({ value => 1 }, 2);
ok($result eq 'PATCH http://hostname/api/resource/10/something 1 2', 'patch');
