package Net::Amazon::S3::Operation::Bucket::Location;
# ABSTRACT: Internal class for service operation ListBuckets
$Net::Amazon::S3::Operation::Bucket::Location::VERSION = '0.98';
use strict;
use warnings;

use Net::Amazon::S3::Operation::Bucket::Location::Request;
use Net::Amazon::S3::Operation::Bucket::Location::Response;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Bucket::Location - Internal class for service operation ListBuckets

=head1 VERSION

version 0.98

=head1 DESCRIPTION

Implements operation L<< GetBucketLocation|https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLocation.html >>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
