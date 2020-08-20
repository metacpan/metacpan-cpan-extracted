package Net::Amazon::S3::Request::PutPart;
$Net::Amazon::S3::Request::PutPart::VERSION = '0.91';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
extends 'Net::Amazon::S3::Request::Object';

with 'Net::Amazon::S3::Request::Role::Query::Param::Upload_id';
with 'Net::Amazon::S3::Request::Role::Query::Param::Part_number';
with 'Net::Amazon::S3::Request::Role::HTTP::Header::Acl_short';
with 'Net::Amazon::S3::Request::Role::HTTP::Header::Copy_source';
with 'Net::Amazon::S3::Request::Role::HTTP::Method::PUT';

has 'value'         => ( is => 'ro', isa => 'Str|CodeRef|ScalarRef',     required => 0 );
has 'headers' =>
    ( is => 'ro', isa => 'HashRef', required => 0, default => sub { {} } );

__PACKAGE__->meta->make_immutable;

sub _request_headers {
    my ($self) = @_;

    return %{ $self->headers };
}

sub http_request {
    my $self    = shift;

    return $self->_build_http_request(
        content => scalar( defined( $self->value ) ? $self->value : '' ),
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::PutPart - An internal class to put part of a multipart upload

=head1 VERSION

version 0.91

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::PutPart->new(
    s3          => $s3,
    bucket      => $bucket,
    key         => $key,
    value       => $value,
    acl_short   => $acl_short,
    headers     => $conf,
    part_number => $part_number,
    upload_id   => $upload_id
  )->http_request;

=head1 DESCRIPTION

This module puts an object.

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

__END__

# ABSTRACT: An internal class to put part of a multipart upload

