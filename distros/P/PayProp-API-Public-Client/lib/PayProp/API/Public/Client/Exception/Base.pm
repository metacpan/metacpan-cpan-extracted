package PayProp::API::Public::Client::Exception::Base;

use strict;
use warnings;
use parent qw/ Exception::Class::Base /;

use Module::Load qw//;


sub error_class { undef }

sub error_fields { undef }

sub errors { shift->{errors} }

sub status_code { shift->{status_code} }

sub Fields { qw/ status_code errors / } # for Exception::Class::Base

sub throw {
	my ( $self, @args ) = @_;

	my $args_size = scalar @args;

	die 'wrong number of args for throw - expected either an error message or pairs'
		if $args_size > 1 && $args_size % 2
	;

	# allow ->throw('my error message') that would otherwise cause args to be ( 'my error message' => undef )
	# for e.g. PayProp::API::Public::Client::Exception::Connection
	my %args = $args_size == 1 ? ( message => "$args[0]" ) : @args;

	# for e.g. PayProp::API::Public::Client::Exception::Authorization
	if ( $self->error_class && $self->error_fields ) {
		my $error_class = $self->error_class;
		Module::Load::load( $error_class );

		$args{errors} = [
			map {
				my $error_ref = $_;

				$error_class->new(
					(
						map {
							my $value = $error_ref->{ $_ } // '';
							$_ => "$value";
						} $self->error_fields
					)
				)
			} @{ $args{errors} // [] }
		];
	}

	$self->SUPER::throw( %args );
}

sub to_hashref {
	my ( $self ) = @_;

	return {
		class => ref( $self ),
		message => $self->{message},
		status_code => $self->{status_code},
		errors => [
			map {
				my $error = $_;
				+{
					class => ref( $error ),
					fields => {
						map { $_ => $error->{ $_ } } qw/ path code message /
					},
				}
			} @{ $self->{errors} // [] }
		],
	};
}

1;

__END__

=encoding utf-8

=head1 NAME

PayProp::API::Public::Client::Exception::Base - Base module for exceptions.

=head1 SYNOPSIS

	{
		package PayProp::API::Public::Client::Exception::Custom;
		use parent qw/ PayProp::API::Public::Client::Exception::Base /;

		# Optional error class to construct C<errors> field.
		sub error_class { 'PayProp::API::Public::Client::Error::Custom' }

		# Optional error fields as defined in C<PayProp::API::Public::Client::Error::Custom>
		sub error_fields { qw/ custom_field_1 / }

		1;
	}

	PayProp::API::Public::Client::Exception::Custom->throw(
		status_code => 500,
		errors => [
			{ custom_field_1 => 'Hello' },
		],
	);

=head1 DESCRIPTION

*DO NOT INSTANTIATE THIS MODULE DIRECTLY*

This is a base exception module from which specific exceptions are extended. For new exception
types use this module as a parent.

See C<PayProp::API::Public::Client::Exception::*> for examples.

=head1 METHODS

=head2 error_class

Can be optionally overridden in C<PayProp::API::Public::Client::Exception::*>.

=head2 error_fields

Can be optionally overridden in C<PayProp::API::Public::Client::Exception::*>.

=head2 throw

Main method to call to throw an exception from C<PayProp::API::Public::Client::Exception::*>.

	my $Exception = PayProp::API::Public::Client::Exception::Custom->throw('I am an exception!');

	or

	my $Exception = PayProp::API::Public::Client::Exception::Custom->throw(
		status_code => 500,
		errors => [
			{ custom_field_1 => 'Hello' },
		],
	);

=head2 errors

Return instances of C<PayProp::API::Public::Client::Error::*>, if defined.

	my $errors = PayProp::API::Public::Client::Exception::Custom->errors;

=head2 status_code

Return exception status code, if defined.

	my $status_code = PayProp::API::Public::Client::Exception::Custom->status_code;

=head2 Fields

To be extended for additional fields to be available on C<PayProp::API::Public::Client::Exception::*>.

=head2 to_hashref

Convert C<PayProp::API::Public::Client::Exception::*> to hashref, in place for easier debugging.

	my $error_ref = PayProp::API::Public::Client::Exception::Custom->to_hashref;

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
