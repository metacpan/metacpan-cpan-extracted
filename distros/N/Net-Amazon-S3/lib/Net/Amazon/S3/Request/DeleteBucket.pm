package Net::Amazon::S3::Request::DeleteBucket;
$Net::Amazon::S3::Request::DeleteBucket::VERSION = '0.85';
use Moose 0.85;
extends 'Net::Amazon::S3::Request::Bucket';

# ABSTRACT: An internal class to delete a bucket

with 'Net::Amazon::S3::Request::Role::HTTP::Method::DELETE';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::DeleteBucket - An internal class to delete a bucket

=head1 VERSION

version 0.85

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::DeleteBucket->new(
    s3     => $s3,
    bucket => $bucket,
  )->http_request;

=head1 DESCRIPTION

This module deletes a bucket.

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method returns a HTTP::Request object.

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
