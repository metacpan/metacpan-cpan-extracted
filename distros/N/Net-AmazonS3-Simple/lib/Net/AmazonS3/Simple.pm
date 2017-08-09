package Net::AmazonS3::Simple;
use strict;
use warnings;

our $VERSION = '0.1.4';

use AWS::Signature4;
use LWP::UserAgent;
use Path::Tiny;

use Net::AmazonS3::Simple::HTTP;
use Net::AmazonS3::Simple::Object::File;
use Net::AmazonS3::Simple::Object::Memory;

use Class::Tiny qw(
  aws_access_key_id
  aws_secret_access_key
  ), {
    region      => 'us-west-1',
    validate    => 1,
    auto_region => 1,
    secure      => 1,
    host        => 's3.amazonaws.com',
    signer      => sub {
        my ($self) = @_;

        return AWS::Signature4->new(
            -access_key => $self->aws_access_key_id,
            -secret_key => $self->aws_secret_access_key,
        );
    },
    http_client => sub {
        return LWP::UserAgent->new();
    },
    requestator => sub {
        my ($self) = @_;

        return Net::AmazonS3::Simple::HTTP->new(
            http_client => $self->http_client,
            signer      => $self->signer,
            auto_region => $self->auto_region,
            region      => $self->region,
            secure      => $self->secure,
            host        => $self->host,
        );
    }
  };

=head1 NAME

Net::AmazonS3::Simple - simple S3 client support signature v4

=head1 SYNOPSIS

    my $s3 = Net::AmazonS3::Simple->new(
        aws_access_key_id     => 'XXX',
        aws_secret_access_key => 'YYY',
    );

    $s3->get_object($bucket, $key);

    #or for big file is better
    
    $s3->save_object_to_file($bucket, $key, $file);

=head1 DESCRIPTION

This S3 client have really simple interface and support only get object (yet).

This S3 client use L<AWS::Signature4>. Signature v4 is L<needed|http://stackoverflow.com/questions/26533245/the-authorization-mechanism-you-have-provided-is-not-supported-please-use-aws4> for EU AWS region (for other regions is optionable).
If you need other region, I recommend some other S3 client (L<SEE_ALSO|/SEE_ALSO>).

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

=head4 aws_access_key_id

=head4 aws_secret_access_key

=head4 region

default I<us-west-1>

=head4 auto_region

is is set I<wrong> C<region>, is automaticaly changed to I<expecting> region 

default I<1>

=head4 validate

object after get is validate (recalculate MD5 checksum)

default I<1>

=head4 secure

is is set, then use I<https> protocol

default I<1>


=head4 host

default I<s3.amazonaws.com>

=cut

sub BUILD {
    my ($self) = @_;

    foreach my $req (qw/aws_access_key_id aws_secret_access_key/) {
        die "$req attribute required" unless defined $self->$req;
    }
}

=head2 get_object($bucket, $key)

C<$bucket> - bucket name

C<$key> - object key

return L<Net::AmazonS3::Simple::Object::Memory>

=cut

sub get_object {
    my ($self, $bucket, $key) = @_;

    my $response = $self->requestator->request(
        bucket => $bucket,
        path   => $key,
    );

    return Net::AmazonS3::Simple::Object::Memory->create_from_response(
        validate => $self->validate,
        response => $response
    );
}

=head2 save_object_to_file($bucket, $key, $file)

C<$bucket> - bucket name

C<$key> - object key

C<$file> - file to save, optional, default is C<tempfile> 


return L<Net::AmazonS3::Simple::Object::File>

=cut

sub save_object_to_file {
    my ($self, $bucket, $key, $file) = @_;

    $file = Path::Tiny->tempfile() if !defined $file;

    my $response = $self->requestator->request(
        bucket          => $bucket,
        path            => $key,
        content_to_file => $file,
    );

    return Net::AmazonS3::Simple::Object::File->create_from_response(
        validate  => $self->validate,
        response  => $response,
        file_path => path($file),
    );
}

=head1 SEE_ALSO

L<Paws::S3> - support version 4 signature too,
L<Paws> support more AWS services,
some dependency of this module don't work on windows

L<Net::Amazon::S3> - don't support version 4 signature,
some dependency of this module don't work on windows

L<AWS::S3> - don't support version 4 signature,
object is get to memory only (no direct to file - it's not good for downloading big files),
similar interface like L<Net::Amazon::S3>

L<Amazon::S3> - don't support version 4 signature,
similar interface like L<Net::Amazon::S3>,
last update Aug 15, 2009

L<Amazon::S3::Thin> - don't support version 4 signature,
simple interface

L<Furl::S3> - don't support version 4 signature,
simple interface (similar like L<Amazon::S3::Thin>),
last update May 16, 2012

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
