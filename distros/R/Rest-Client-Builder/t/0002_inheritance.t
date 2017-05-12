use strict;
use warnings;

package Your::API;
use base qw(Rest::Client::Builder);

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
	my ($self, $method, $path, $args) = @_;
	return $args->{force};
}

package Your::API::resource;
sub post {
	my ($self, $args) = (shift, shift);
	$args->{force} = 1;
	return $self->SUPER::post($args, @_);
}

package Your::API::resource::state;
sub post {
	my ($self, $args) = (shift, shift);
	$args->{force} = 0;
	return $self->SUPER::post($args, @_);
}

package default;
use Test::More tests => 2;

my $api = Your::API->new();

my $result = $api->resource->post();
ok($result, 'inheritance test 1');

$result = $api->resource(1)->state->post();
ok(! $result, 'inheritance test 2');
