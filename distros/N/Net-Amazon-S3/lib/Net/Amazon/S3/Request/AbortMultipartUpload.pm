package Net::Amazon::S3::Request::AbortMultipartUpload;
$Net::Amazon::S3::Request::AbortMultipartUpload::VERSION = '0.80';
use Moose 0.85;
use Digest::MD5 qw/md5 md5_hex/;
use MIME::Base64;
use Carp qw/croak/;
use XML::LibXML;

extends 'Net::Amazon::S3::Request';

has 'bucket'    => ( is => 'ro', isa => 'BucketName', required => 1 );
has 'key'       => ( is => 'ro', isa => 'Str',        required => 1 );
has 'upload_id' => ( is => 'ro', isa => 'Str',        required => 1 );

__PACKAGE__->meta->make_immutable;

sub http_request {
  my $self = shift;

  #build signed request
  return Net::Amazon::S3::HTTPRequest->new(    #See patch below
    s3      => $self->s3,
    method  => 'DELETE',
    path    => $self->_uri( $self->key ) . '?uploadId=' . $self->upload_id,
  )->http_request;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::AbortMultipartUpload - An internal class to complete a multipart upload

=head1 VERSION

version 0.80

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::AbortMultipartUpload->new(
    s3                  => $s3,
    bucket              => $bucket,
    key                 => $key
    upload_id           => $upload_id,
  )->http_request;

=head1 DESCRIPTION

This module aborts a multipart upload.

=head1 NAME

Net::Amazon::S3::Request::AbortMultipartUpload - An internal class to abort a multipart upload

=head1 VERSION

version 0.59

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method returns a HTTP::Request object.

=head1 AUTHOR

Pedro Figueiredo <me@pedrofigueiredo.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Rusty Conover <rusty@luckydinosaur.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: An internal class to complete a multipart upload

