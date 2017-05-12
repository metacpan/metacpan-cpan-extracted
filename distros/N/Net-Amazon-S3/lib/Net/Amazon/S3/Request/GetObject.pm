package Net::Amazon::S3::Request::GetObject;
$Net::Amazon::S3::Request::GetObject::VERSION = '0.80';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
extends 'Net::Amazon::S3::Request';

has 'bucket' => ( is => 'ro', isa => 'BucketName', required => 1 );
has 'key'    => ( is => 'ro', isa => 'Str',        required => 1 );
has 'method' => ( is => 'ro', isa => 'HTTPMethod', required => 1 );

# ABSTRACT: An internal class to get an object

__PACKAGE__->meta->make_immutable;

sub http_request {
    my $self = shift;

    return Net::Amazon::S3::HTTPRequest->new(
        s3     => $self->s3,
        method => $self->method,
        path   => $self->_uri( $self->key ),
    )->http_request;
}

sub query_string_authentication_uri {
    my ( $self, $expires ) = @_;

    return Net::Amazon::S3::HTTPRequest->new(
        s3     => $self->s3,
        method => $self->method,
        path   => $self->_uri( $self->key ),
    )->query_string_authentication_uri($expires);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::GetObject - An internal class to get an object

=head1 VERSION

version 0.80

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::GetObject->new(
    s3     => $s3,
    bucket => $bucket,
    key    => $key,
    method => 'GET',
  )->http_request;

=head1 DESCRIPTION

This module gets an object.

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method returns a HTTP::Request object.

=head2 query_string_authentication_uri

This method returns query string authentication URI.

=head1 AUTHOR

Rusty Conover <rusty@luckydinosaur.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
