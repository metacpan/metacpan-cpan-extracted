package Net::Amazon::S3::Operation::Object::Upload::Abort;
# ABSTRACT: Internal class to perform AbortMultipartUpload operation
$Net::Amazon::S3::Operation::Object::Upload::Abort::VERSION = '0.99';
use strict;
use warnings;

use Net::Amazon::S3::Operation::Object::Upload::Abort::Request;
use Net::Amazon::S3::Operation::Object::Upload::Abort::Response;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Upload::Abort - Internal class to perform AbortMultipartUpload operation

=head1 VERSION

version 0.99

=head1 DESCRIPTION

Implements operation L<< AbortMultipartUpload|https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html >>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
