package Net::Amazon::S3::Request::InitiateMultipartUpload;
$Net::Amazon::S3::Request::InitiateMultipartUpload::VERSION = '0.82';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
extends 'Net::Amazon::S3::Request';

with 'Net::Amazon::S3::Role::Bucket';

has 'key'        => ( is => 'ro', isa => 'Str',             required => 1 );
has 'acl_short'  => ( is => 'ro', isa => 'Maybe[AclShort]', required => 0 );
has 'headers' =>
    ( is => 'ro', isa => 'HashRef', required => 0, default => sub { {} } );
has 'encryption' => ( is => 'ro', isa => 'Maybe[Str]',      required => 0 );

__PACKAGE__->meta->make_immutable;

sub http_request {
    my $self    = shift;
    my $headers = $self->headers;

    if ( $self->acl_short ) {
        $headers->{'x-amz-acl'} = $self->acl_short;
    }
    if ( defined $self->encryption ) {
        $headers->{'x-amz-server-side-encryption'} = $self->encryption;
    }

    return $self->_build_http_request(
        method  => 'POST',
        path    => $self->_uri( $self->key ).'?uploads',
        headers => $self->headers,
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::InitiateMultipartUpload - An internal class to begin a multipart upload

=head1 VERSION

version 0.82

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::InitiateMultipartUpload->new(
    s3                  => $s3,
    bucket              => $bucket,
    keys                => $key,
  )->http_request;

=head1 DESCRIPTION

This module begins a multipart upload

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

__END__

#ABSTRACT: An internal class to begin a multipart upload

