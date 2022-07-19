package Net::Amazon::S3::Operation::Bucket::Tags::Delete::Response;
# ABSTRACT: An internal class to handle DeleteBucketTagging responses
$Net::Amazon::S3::Operation::Bucket::Tags::Delete::Response::VERSION = '0.991';
use Moose;
extends 'Net::Amazon::S3::Response';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Bucket::Tags::Delete::Response - An internal class to handle DeleteBucketTagging responses

=head1 VERSION

version 0.991

=head1 DESCRIPTION

Implements a response part of an operation L<DeleteBucketTagging|https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketTagging.html>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is a part of L<Net::Amazon::S3> distribution.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
