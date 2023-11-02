package PayProp::API::Public::Client::Role::Attribute::Domain;

use strict;
use warnings;

use Mouse::Role;


has domain => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has scheme => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub { 'https' },
);

has abs_domain => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;

		my $scheme = $self->scheme;
		my $domain = $self->domain;

		$scheme =~ s{://}{}g;
		$domain =~ s{/*$}{}g;
		$domain =~ s{^https?://}{}g;

		my $abs_domain = $scheme . '://' . $domain;
		chomp $abs_domain;

		return $abs_domain;
	},
);

1;
