package Net::Amazon::S3::Request::PutObject;
$Net::Amazon::S3::Request::PutObject::VERSION = '0.80';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
extends 'Net::Amazon::S3::Request';

# ABSTRACT: An internal class to put an object

has 'bucket'    => ( is => 'ro', isa => 'BucketName',      required => 1 );
has 'key'       => ( is => 'ro', isa => 'Str',             required => 1 );
has 'value'     => ( is => 'ro', isa => 'Str|CodeRef|ScalarRef',     required => 1 );
has 'acl_short' => ( is => 'ro', isa => 'Maybe[AclShort]', required => 0 );
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

    return Net::Amazon::S3::HTTPRequest->new(
        s3      => $self->s3,
        method  => 'PUT',
        path    => $self->_uri( $self->key ),
        headers => $self->headers,
        content => $self->value,
    )->http_request;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::PutObject - An internal class to put an object

=head1 VERSION

version 0.80

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::PutObject->new(
    s3        => $s3,
    bucket    => $bucket,
    key       => $key,
    value     => $value,
    acl_short => $acl_short,
    headers   => $conf,
  )->http_request;

=head1 DESCRIPTION

This module puts an object.

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
