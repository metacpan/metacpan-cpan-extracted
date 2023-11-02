package PayProp::API::Public::Client::Request::Entity;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::Attribute::UA /;
with qw/ PayProp::API::Public::Client::Role::Attribute::Domain /;
with qw/ PayProp::API::Public::Client::Role::Attribute::Authorization /;

has payment => (
	is => 'ro',
	isa => 'PayProp::API::Public::Client::Request::Entity::Payment',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;

		require PayProp::API::Public::Client::Request::Entity::Payment;

		return PayProp::API::Public::Client::Request::Entity::Payment->new(
			ua => $self->ua,
			domain => $self->domain,
			scheme => $self->scheme,
			authorization => $self->authorization,
		);
	},
);

has invoice => (
	is => 'ro',
	isa => 'PayProp::API::Public::Client::Request::Entity::Invoice',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;

		require PayProp::API::Public::Client::Request::Entity::Invoice;

		return PayProp::API::Public::Client::Request::Entity::Invoice->new(
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

	PayProp::API::Public::Client::Request::Entity - Module containing various entity types as attributes.

=head1 SYNOPSIS

	my $Entity = $Client->entity;
	my $payment_entity = $Entity->payment;

	$payment_entity
		->list_p({...})
		->then( sub {
			my ( $Payment ) = @_;
			...;
			See See L<PayProp::API::Public::Client::Response::Entity::*>
		} )
		->wait
	;

=head1 DESCRIPTION

	Contains various API entity types defined on attributes.
	This module is intended to be accessed via instance of C<PayProp::API::Public::Client>.

=head1 ATTRIBUTES

	C<PayProp::API::Public::Client::Request::Entity> implements the following attributes.

=head2 payment

	my $payment_entity = $Entity->payment;

	See L<PayProp::API::Public::Client::Request::Entity::Payment>.

=head2 invoice

	my $invoice_entity = $Entity->invoice;

	See L<PayProp::API::Public::Client::Request::Entity::Invoice>.

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
