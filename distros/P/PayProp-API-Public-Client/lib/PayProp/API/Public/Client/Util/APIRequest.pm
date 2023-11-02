package PayProp::API::Public::Client::Util::APIRequest;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::APIRequest /;


has '+url' => ( default => sub { '' } );

has query_params => (
	is => 'rw',
	isa => 'ArrayRef',
	lazy => 1,
	default => sub { [] },
);

has base_url => (
	is => 'rw',
	isa => 'Str',
);

sub _query_params { shift->query_params }

__PACKAGE__->meta->make_immutable;
