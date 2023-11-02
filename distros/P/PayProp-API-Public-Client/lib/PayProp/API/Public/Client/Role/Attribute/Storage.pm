package PayProp::API::Public::Client::Role::Attribute::Storage;

use strict;
use warnings;

use Mouse::Role;
use Mouse::Util::TypeConstraints;


subtype 'StorageType'
	=> as (
		class_type('PayProp::API::Public::Client::Authorization::Storage::Local')
		| class_type('PayProp::API::Public::Client::Authorization::Storage::Memcached')
		# | class_type('PayProp::API::Public::Client::Authorization::Storage::***')
	)
;

has storage => (
	is => 'ro',
	isa => 'StorageType',
	lazy => 1,
	predicate => 'has_storage',
	default => sub { die 'storage not implemented' },
);

has storage_key => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub { die 'storage_key not implemented' },
);

1;
