package Net::Amazon::S3::Operation::Bucket::Delete;
# ABSTRACT: Internal class to perform DeleteBucket operation
$Net::Amazon::S3::Operation::Bucket::Delete::VERSION = '0.991';
use strict;
use warnings;

use Net::Amazon::S3::Operation::Bucket::Delete::Request;
use Net::Amazon::S3::Operation::Bucket::Delete::Response;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Bucket::Delete - Internal class to perform DeleteBucket operation

=head1 VERSION

version 0.991

=head1 DESCRIPTION

Implements operation L<< DeleteBucket|https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html >>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
