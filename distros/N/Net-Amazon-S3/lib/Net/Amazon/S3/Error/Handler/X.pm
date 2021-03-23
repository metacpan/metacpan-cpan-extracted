package Net::Amazon::S3::Error::Handler::X;
$Net::Amazon::S3::Error::Handler::X::VERSION = '0.98';
# ABSTRACT: Throw error specific exception

use Moose;

extends 'Net::Amazon::S3::Error::Handler';

use Net::Amazon::S3::X;

override handle_error => sub {
	my ($self, $response, $request) = @_;

	return 1 unless $response->is_error;

	my $exception = Net::Amazon::S3::X->build (
		$response->error_code,
		request => $request,
		response => $response,
	);

	die $exception;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Error::Handler::X - Throw error specific exception

=head1 VERSION

version 0.98

=head1 DESCRIPTION

Raise error specific exception.

=head2 S3 error

For S3 errors exception it raises is instance of C<Net::Amazon::S3::X::error-code>.
AWS error code list can be found at L<https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList>

	my $s3 = Net::Amazon::S3->new (
		error_handler_class => 'Net::Amazon::S3::Error::Handler::X',
		...
	);

	eval { do s3 operation; 1 } or do {
		say 'access denied'
			if $@->$Safe::Isa::_isa ('Net::Amazon::S3::X::AccessDenied');
		...
	};

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
