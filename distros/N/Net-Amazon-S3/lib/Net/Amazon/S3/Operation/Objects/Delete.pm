package Net::Amazon::S3::Operation::Buckets::Delete;
# ABSTRACT: Internal class for service operation DeleteObjects
$Net::Amazon::S3::Operation::Buckets::Delete::VERSION = '0.991';
use strict;
use warnings;

use Net::Amazon::S3::Operation::Objects::Delete::Request;
use Net::Amazon::S3::Operation::Objects::Delete::Response;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Buckets::Delete - Internal class for service operation DeleteObjects

=head1 VERSION

version 0.991

=head1 DESCRIPTION

Implements operation L<< DeleteObjects|https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjects.html >>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
