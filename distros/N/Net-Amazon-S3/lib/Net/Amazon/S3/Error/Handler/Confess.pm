package Net::Amazon::S3::Error::Handler::Confess;
$Net::Amazon::S3::Error::Handler::Confess::VERSION = '0.991';
# ABSTRACT: An internal class to report errors via Carp::confess

use Moose;
use Carp;
use HTTP::Status;

extends 'Net::Amazon::S3::Error::Handler';

our @CARP_NOT = (__PACKAGE__);

my %return_false = (
	NoSuchKey => {
		'Net::Amazon::S3::Operation::Object::Head::Response' => 1,
	},
	NoSuchBucket => {
		'Net::Amazon::S3::Operation::Object::Head::Response' => 1,
	},
	'404' => {
                'Net::Amazon::S3::Operation::Object::Head::Response' => 1,
        },
);

sub handle_error {
	my ($self, $response) = @_;

	return 1 unless $response->is_error;

	return 0
		if exists $return_false{ $response->error_code }
		&& exists $return_false{ $response->error_code }{ ref $response }
		;

	Carp::confess ("${\ $response->error_code }: ${\ $response->error_message }");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Error::Handler::Confess - An internal class to report errors via Carp::confess

=head1 VERSION

version 0.991

=head1 DESCRIPTION

Carp::confess on error.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
