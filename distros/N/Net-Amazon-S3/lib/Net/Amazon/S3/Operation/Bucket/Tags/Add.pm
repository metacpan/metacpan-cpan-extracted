package Net::Amazon::S3::Operation::Bucket::Tags::Add;
# ABSTRACT: Internal class to perform PutBucketTagging operation
$Net::Amazon::S3::Operation::Bucket::Tags::Add::VERSION = '0.99';
use strict;
use warnings;

use Net::Amazon::S3::Operation::Bucket::Tags::Add::Request;
use Net::Amazon::S3::Operation::Bucket::Tags::Add::Response;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Bucket::Tags::Add - Internal class to perform PutBucketTagging operation

=head1 VERSION

version 0.99

=head1 DESCRIPTION

Implements an operation L<<PutBucketTagging|https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketTagging.html>>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>.

=head1 COPYRIGHT AND LICENSE

This module is a part of L<Net::Amazon::S3> distribution.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
