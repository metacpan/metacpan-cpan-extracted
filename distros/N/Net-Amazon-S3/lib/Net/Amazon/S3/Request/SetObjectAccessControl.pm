package Net::Amazon::S3::Request::SetObjectAccessControl;
$Net::Amazon::S3::Request::SetObjectAccessControl::VERSION = '0.80';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
extends 'Net::Amazon::S3::Request';

# ABSTRACT: An internal class to set an object's access control

has 'bucket'    => ( is => 'ro', isa => 'BucketName',      required => 1 );
has 'key'       => ( is => 'ro', isa => 'Str',             required => 1 );
has 'acl_short' => ( is => 'ro', isa => 'Maybe[AclShort]', required => 0 );
has 'acl_xml'   => ( is => 'ro', isa => 'Maybe[Str]',      required => 0 );

__PACKAGE__->meta->make_immutable;

sub http_request {
    my $self = shift;

    unless ( $self->acl_xml || $self->acl_short ) {
        confess "need either acl_xml or acl_short";
    }

    if ( $self->acl_xml && $self->acl_short ) {
        confess "can not provide both acl_xml and acl_short";
    }

    my $headers
        = ( $self->acl_short )
        ? { 'x-amz-acl' => $self->acl_short }
        : {};
    my $xml = $self->acl_xml || '';

    return Net::Amazon::S3::HTTPRequest->new(
        s3      => $self->s3,
        method  => 'PUT',
        path    => $self->_uri( $self->key ) . '?acl',
        headers => $headers,
        content => $xml,
    )->http_request;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::SetObjectAccessControl - An internal class to set an object's access control

=head1 VERSION

version 0.80

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::SetObjectAccessControl->new(
    s3        => $s3,
    bucket    => $bucket,
    key       => $key,
    acl_short => $acl_short,
    acl_xml   => $acl_xml,
  )->http_request;

=head1 DESCRIPTION

This module sets an object's access control.

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
