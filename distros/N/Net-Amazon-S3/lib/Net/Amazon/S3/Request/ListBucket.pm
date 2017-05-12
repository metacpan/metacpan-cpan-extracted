package Net::Amazon::S3::Request::ListBucket;
$Net::Amazon::S3::Request::ListBucket::VERSION = '0.80';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
use URI::Escape qw(uri_escape_utf8);
extends 'Net::Amazon::S3::Request';

# ABSTRACT: An internal class to list a bucket

has 'bucket'    => ( is => 'ro', isa => 'BucketName', required => 1 );
has 'prefix'    => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'delimiter' => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'max_keys' =>
    ( is => 'ro', isa => 'Maybe[Int]', required => 0, default => 1000 );
has 'marker' => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );

__PACKAGE__->meta->make_immutable;

sub http_request {
    my $self = shift;

    my $path = $self->bucket . "/";

    my @post;
    foreach my $method ( qw(prefix delimiter max_keys marker) ) {
        my $value = $self->$method;
        next unless $value;
        my $key = $method;
        $key = 'max-keys' if $method eq 'max_keys';
        push @post, $key . "=" . $self->_urlencode($value);
    }
    if (@post) {
        $path .= '?' . join( '&', @post );
    }

    return Net::Amazon::S3::HTTPRequest->new(
        s3     => $self->s3,
        method => 'GET',
        path   => $path,
    )->http_request;
}

sub _urlencode {
    my ( $self, $unencoded ) = @_;
    return uri_escape_utf8( $unencoded, '^A-Za-z0-9_-' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::ListBucket - An internal class to list a bucket

=head1 VERSION

version 0.80

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::ListBucket->new(
    s3        => $s3,
    bucket    => $bucket,
    delimiter => $delimiter,
    max_keys  => $max_keys,
    marker    => $marker,
  )->http_request;

=head1 DESCRIPTION

This module lists a bucket.

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
