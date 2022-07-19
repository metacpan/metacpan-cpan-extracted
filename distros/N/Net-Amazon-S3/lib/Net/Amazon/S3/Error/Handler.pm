package Net::Amazon::S3::Error::Handler;
$Net::Amazon::S3::Error::Handler::VERSION = '0.991';
use Moose;

# ABSTRACT: A base class for S3 response error handler

has s3 => (
	is => 'ro',
	isa => 'Net::Amazon::S3',
	required => 1,
);

sub handle_error;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Error::Handler - A base class for S3 response error handler

=head1 VERSION

version 0.991

=head1 CONSTRUCTOR

=over

=item s3

Instance of L<< Net::Amazon::S3 >>

=back

=head1 METHODS

=head2 handle_error ($response)

=head2 handle_error ($response, $request)

Method will receive instance of L<< Net::Amazon::S3::Response >> sub-class.

Method should return false (or throw exception) in case of error, true otherwise.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
