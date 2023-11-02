package PayProp::API::Public::Client::Role::Attribute::UA;

use strict;
use warnings;

use Mouse::Role;
use Mojo::UserAgent;


has ua => (
	is => 'ro',
	isa => 'Mojo::UserAgent',
	lazy => 1,
	default => sub {
		my $UA = Mojo::UserAgent->new
			->insecure(1)
			->max_redirects(1)
			->connect_timeout(10)
			->inactivity_timeout(10)
		;

		$UA->transactor->name('PayProp API Client');

		return $UA;
	},
);

1;
