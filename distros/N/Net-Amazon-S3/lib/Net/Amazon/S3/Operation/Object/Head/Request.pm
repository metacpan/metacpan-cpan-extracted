package Net::Amazon::S3::Operation::Object::Head::Request;
# ABSTRACT: An internal class to handle HeadObject request
$Net::Amazon::S3::Operation::Object::Head::Request::VERSION = '0.992';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;

extends 'Net::Amazon::S3::Request::Object';

with 'Net::Amazon::S3::Request::Role::HTTP::Method::HEAD';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Head::Request - An internal class to handle HeadObject request

=head1 VERSION

version 0.992

=head1 DESCRIPTION

Implements operation L<< HeadObject|https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html >>.

=head1 COPYRIGHT AND LICENSE

This module is part of L<Net::Amazon::S3> distribution.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
