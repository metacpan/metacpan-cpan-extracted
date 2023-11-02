package PayProp::API::Public::Client::Role::Attribute::Token;

use strict;
use warnings;

use Mouse::Role;
use Mouse::Util::TypeConstraints;


enum TokenType => [qw/ APIkey Bearer Basic /];

has token_type => (
	is => 'rw',
	isa => 'TokenType',
	default => sub { die 'you must override default token_type value' },
);

1;
