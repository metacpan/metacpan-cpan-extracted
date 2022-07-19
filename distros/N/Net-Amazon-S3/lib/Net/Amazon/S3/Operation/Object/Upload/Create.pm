package Net::Amazon::S3::Operation::Object::Upload::Create;
# ABSTRACT: Internal class to perform CreateMultipartUpload operation
$Net::Amazon::S3::Operation::Object::Upload::Create::VERSION = '0.991';
use strict;
use warnings;

use Net::Amazon::S3::Operation::Object::Upload::Create::Request;
use Net::Amazon::S3::Operation::Object::Upload::Create::Response;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Upload::Create - Internal class to perform CreateMultipartUpload operation

=head1 VERSION

version 0.991

=head1 DESCRIPTION

Implements operation L<< CreateMultipartUpload|https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html >>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
