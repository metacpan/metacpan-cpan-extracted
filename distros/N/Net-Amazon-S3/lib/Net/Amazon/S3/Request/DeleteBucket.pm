package Net::Amazon::S3::Request::DeleteBucket;
$Net::Amazon::S3::Request::DeleteBucket::VERSION = '0.80';
use Moose 0.85;
extends 'Net::Amazon::S3::Request';

# ABSTRACT: An internal class to delete a bucket

has 'bucket' => ( is => 'ro', isa => 'BucketName', required => 1 );

__PACKAGE__->meta->make_immutable;

sub http_request {
    my $self = shift;

    return Net::Amazon::S3::HTTPRequest->new(
        s3     => $self->s3,
        method => 'DELETE',
        path   => $self->bucket . '/',
    )->http_request;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::DeleteBucket - An internal class to delete a bucket

=head1 VERSION

version 0.80

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

Rusty Conover <rusty@luckydinosaur.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
