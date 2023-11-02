package PayProp::API::Public::Client::Role::Attribute::APIVersion;

use strict;
use warnings;

use Mouse::Role;


has api_version => (
	is => 'ro',
	isa => 'Str',
	default => 'v1.1',
);

1;
