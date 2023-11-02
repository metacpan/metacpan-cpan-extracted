package PayProp::API::Public::Client::Error::Authorization;

use strict;
use warnings;

use Mouse;

has code => ( is => 'ro', isa => 'Maybe[Str]' );
has message => ( is => 'ro', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

	PayProp::API::Public::Client::Error::Authorization - Authorization error.

=head1 SYNOPSIS

	my $Error = PayProp::API::Public::Client::Error::Authorization->new(
		code => 'ERROR_CODE',
		message => 'ERROR_MESSAGE',
	);

=head1 DESCRIPTION

	Construct C<PayProp::API::Public::Client::Error::Authorization> errors.


=head1 ATTRIBUTES

	C<PayProp::API::Public::Client::Error::Authorization> implements the following attributes.

=head2 code

	my $error_code = $Error->code;

=head2 message

	my $error_message = $Error->message;

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
