package Net::Amazon::S3::Request::DeleteObject;
$Net::Amazon::S3::Request::DeleteObject::VERSION = '0.90';
use Moose 0.85;
use Moose::Util::TypeConstraints;
extends 'Net::Amazon::S3::Request::Object';

# ABSTRACT: An internal class to delete an object

with 'Net::Amazon::S3::Request::Role::HTTP::Method::DELETE';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::DeleteObject - An internal class to delete an object

=head1 VERSION

version 0.90

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::DeleteObject->new(
    s3     => $s3,
    bucket => $bucket,
    key    => $key,
  )->http_request;

=head1 DESCRIPTION

This module deletes an object.

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method returns a HTTP::Request object.

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
