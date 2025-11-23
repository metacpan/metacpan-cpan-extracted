package Net::Amazon::S3::Operation::Object::Head;
# ABSTRACT: Internal class to perform HeadObject operation
$Net::Amazon::S3::Operation::Object::Head::VERSION = '0.992';
use strict;
use warnings;

use Net::Amazon::S3::Operation::Object::Head::Request;
use Net::Amazon::S3::Operation::Object::Head::Response;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Head - Internal class to perform HeadObject operation

=head1 VERSION

version 0.992

=head1 DESCRIPTION

Implements operation L<< HeadObject|https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html >>

=head1 COPYRIGHT AND LICENSE

This module is part of L<Net::Amazon::S3> distribution.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
