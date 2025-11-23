package Net::Amazon::S3::Operation::Object::Fetch;
# ABSTRACT: Internal class to perform PutObject operation
$Net::Amazon::S3::Operation::Object::Fetch::VERSION = '0.992';
use strict;
use warnings;

use Net::Amazon::S3::Operation::Object::Fetch::Request;
use Net::Amazon::S3::Operation::Object::Fetch::Response;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Fetch - Internal class to perform PutObject operation

=head1 VERSION

version 0.992

=head1 DESCRIPTION

Implements operation L<< GetObject|https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html >>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
