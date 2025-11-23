package Net::Amazon::S3::Operation::Object::Tags::Delete;
# ABSTRACT: Internal class to perform DeleteObjectTagging operation
$Net::Amazon::S3::Operation::Object::Tags::Delete::VERSION = '0.992';
use strict;
use warnings;

use Net::Amazon::S3::Operation::Object::Tags::Delete::Request;
use Net::Amazon::S3::Operation::Object::Tags::Delete::Response;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Tags::Delete - Internal class to perform DeleteObjectTagging operation

=head1 VERSION

version 0.992

=head1 DESCRIPTION

Implements an operation L<<DeleteObjectTagging|https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjectTagging.html>>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>.

=head1 COPYRIGHT AND LICENSE

This module is a part of L<Net::Amazon::S3> distribution.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
