package Net::Amazon::S3::Operation::Object::Tags::Add;
# ABSTRACT: Internal class to perform PutObjectTagging operation
$Net::Amazon::S3::Operation::Object::Tags::Add::VERSION = '0.97';
use strict;
use warnings;

use Net::Amazon::S3::Operation::Object::Tags::Add::Request;
use Net::Amazon::S3::Operation::Object::Tags::Add::Response;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Tags::Add - Internal class to perform PutObjectTagging operation

=head1 VERSION

version 0.97

=head1 DESCRIPTION

Implements an operation L<<PutObjectTagging|https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectTagging.html>>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>.

=head1 COPYRIGHT AND LICENSE

This module is a part of L<Net::Amazon::S3> distribution.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
