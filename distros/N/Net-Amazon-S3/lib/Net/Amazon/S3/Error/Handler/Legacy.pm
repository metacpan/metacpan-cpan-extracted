package Net::Amazon::S3::Error::Handler::Legacy;
$Net::Amazon::S3::Error::Handler::Legacy::VERSION = '0.992';
# ABSTRACT: An internal class to report errors like legacy API

use Moose;

extends 'Net::Amazon::S3::Error::Handler::Status';

use HTTP::Status;

our @CARP_NOT = __PACKAGE__;

my %croak_on_response = map +($_ => 1), (
	'Net::Amazon::S3::Operation::Bucket::Acl::Fetch::Response',
	'Net::Amazon::S3::Operation::Object::Acl::Fetch::Response',
	'Net::Amazon::S3::Operation::Object::Fetch::Response',
);

override handle_error => sub {
	my ($self, $response, $request) = @_;

	return super unless exists $croak_on_response{ref $response};

	$self->s3->err (undef);
	$self->s3->errstr (undef);

	return 1 unless $response->is_error;
	return 0 if $response->http_response->code == HTTP::Status::HTTP_NOT_FOUND;

	$self->s3->err ("network_error");
	$self->s3->errstr ($response->http_response->status_line);

	Carp::croak ("Net::Amazon::S3: Amazon responded with ${\ $self->s3->errstr }\n");
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Error::Handler::Legacy - An internal class to report errors like legacy API

=head1 VERSION

version 0.992

=head1 DESCRIPTION

Handle errors like L<Net::Amazon::S3> API does.

Carp::croak in case of I<object fetch>, I<object acl fetch>, and I<bucket acl fetch>.
set C<err> / C<errstr> only otherwise.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
