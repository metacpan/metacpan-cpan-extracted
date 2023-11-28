package PayProp::API::Public::Client::Request::Export;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::Attribute::UA /;
with qw/ PayProp::API::Public::Client::Role::Attribute::Domain /;
with qw/ PayProp::API::Public::Client::Role::Attribute::Authorization /;

has beneficiaries => (
	is => 'ro',
	isa => 'PayProp::API::Public::Client::Request::Export::Beneficiaries',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;

		require PayProp::API::Public::Client::Request::Export::Beneficiaries;

		return PayProp::API::Public::Client::Request::Export::Beneficiaries->new(
			ua => $self->ua,
			domain => $self->domain,
			scheme => $self->scheme,
			authorization => $self->authorization,
		);
	},
);

has tenants => (
	is => 'ro',
	isa => 'PayProp::API::Public::Client::Request::Export::Tenants',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;

		require PayProp::API::Public::Client::Request::Export::Tenants;

		return PayProp::API::Public::Client::Request::Export::Tenants->new(
			ua => $self->ua,
			domain => $self->domain,
			scheme => $self->scheme,
			authorization => $self->authorization,
		);
	},
);

__PACKAGE__->meta->make_immutable;


__END__

=encoding utf-8

=head1 NAME

PayProp::API::Public::Client::Request::Export - Module containing various export types as attributes.

=head1 SYNOPSIS

	my $Export = $Client->export;
	my $beneficiaries_export = $Export->beneficiaries;

	$beneficiaries_export
		->list_p({...})
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
			See L<PayProp::API::Public::Client::Response::Export::*>
		} )
		->wait
	;

=head1 DESCRIPTION

Contains various API export types defined as attributes.
This module is intended to be accessed via instance of C<PayProp::API::Public::Client>.

=head1 ATTRIBUTES

C<PayProp::API::Public::Client::Request::Export> implements the following attributes.

=head2 beneficiaries

	my $beneficiaries_export = $Export->beneficiaries;

See L<PayProp::API::Public::Client::Request::Export::Beneficiaries>.

=head2 tenants

	my $tenants_export = $Export->tenants;

See L<PayProp::API::Public::Client::Request::Export::Tenants>.

=head1 AUTHOR

Yanga Kandeni E<lt>yangak@cpan.orgE<gt>

Valters Skrupskis E<lt>malishew@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2023- PayProp

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

L<https://github.com/Humanstate/api-client-public-module>

=cut
