package PayProp::API::Public::Client::Role::Attribute::Authorization;

use strict;
use warnings;

use Mouse::Role;


has authorization => (
	is => 'ro',
	isa => 'PayProp::API::Public::Client::Authorization::Base',
	required => 1,
);

1;
