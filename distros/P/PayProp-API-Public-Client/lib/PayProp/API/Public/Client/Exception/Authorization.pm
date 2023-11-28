package PayProp::API::Public::Client::Exception::Authorization;
use parent qw/ PayProp::API::Public::Client::Exception::Base /;

use strict;
use warnings;

sub error_class { 'PayProp::API::Public::Client::Error::Authorization' }
sub error_fields { qw/ code message / }

1;

__END__

=encoding utf-8

=head1 NAME

PayProp::API::Public::Client::Exception::Authorization - Authorization exception.

=head1 SYNOPSIS

	my $Exception = PayProp::API::Public::Client::Exception::Authorization->throw(
		status_code => 500,
		errors => [
			code => 'client_credentials',
			message => 'Bad client credentials',
		],
	);

=head1 DESCRIPTION

Throw C<PayProp::API::Public::Client::Exception::Authorization> exception.

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
