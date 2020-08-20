package Net::Amazon::S3::Request::CreateBucket;
$Net::Amazon::S3::Request::CreateBucket::VERSION = '0.91';
use Moose 0.85;
extends 'Net::Amazon::S3::Request::Bucket';

# ABSTRACT: An internal class to create a bucket

with 'Net::Amazon::S3::Request::Role::HTTP::Header::Acl_short';
with 'Net::Amazon::S3::Request::Role::HTTP::Method::PUT';

has 'location_constraint' =>
    ( is => 'ro', isa => 'MaybeLocationConstraint', coerce => 1, required => 0 );

__PACKAGE__->meta->make_immutable;

sub _request_content {
    my ($self) = @_;

    my $content = '';
    if ( defined $self->location_constraint &&
         $self->location_constraint ne 'us-east-1') {
        $content
            = "<CreateBucketConfiguration><LocationConstraint>"
            . $self->location_constraint
            . "</LocationConstraint></CreateBucketConfiguration>";
    }
}

sub http_request {
    my $self = shift;

    return $self->_build_http_request(
        region  => 'us-east-1',
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::CreateBucket - An internal class to create a bucket

=head1 VERSION

version 0.91

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::CreateBucket->new(
    s3                  => $s3,
    bucket              => $bucket,
    acl_short           => $acl_short,
    location_constraint => $location_constraint,
  )->http_request;

=head1 DESCRIPTION

This module creates a bucket.

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
