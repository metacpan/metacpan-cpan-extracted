package Net::Amazon::S3::Error::Handler::Status;
$Net::Amazon::S3::Error::Handler::Status::VERSION = '0.99';
# ABSTRACT: An internal class to report response errors via err properties

use Moose;

extends 'Net::Amazon::S3::Error::Handler';

sub handle_error {
	my ($self, $response) = @_;

	$self->s3->err (undef);
	$self->s3->errstr (undef);

	return 1 unless $response->is_error;

	$self->s3->err ($response->error_code);
	$self->s3->errstr ($response->error_message);

	return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Error::Handler::Status - An internal class to report response errors via err properties

=head1 VERSION

version 0.99

=head1 DESCRIPTION

Propagate error code and error message via connection's C<err> / C<errstr>
methods.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
