package Net::Amazon::S3::Operation::Object::Part;
# ABSTRACT: Internal class to perform UploadPart operation
$Net::Amazon::S3::Operation::Object::Part::VERSION = '0.99';
use strict;
use warnings;

use Net::Amazon::S3::Operation::Object::Upload::Part::Request;
use Net::Amazon::S3::Operation::Object::Upload::Part::Response;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Part - Internal class to perform UploadPart operation

=head1 VERSION

version 0.99

=head1 DESCRIPTION

Implements an operation L<< UploadPart|https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html >>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
