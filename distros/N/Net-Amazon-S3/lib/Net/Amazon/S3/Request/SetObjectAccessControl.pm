package Net::Amazon::S3::Request::SetObjectAccessControl;
$Net::Amazon::S3::Request::SetObjectAccessControl::VERSION = '0.86';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
extends 'Net::Amazon::S3::Request::Object';

# ABSTRACT: An internal class to set an object's access control

has 'acl_xml'   => ( is => 'ro', isa => 'Maybe[Str]',      required => 0 );

with 'Net::Amazon::S3::Request::Role::Query::Action::Acl';
with 'Net::Amazon::S3::Request::Role::HTTP::Header::Acl_short';
with 'Net::Amazon::S3::Request::Role::HTTP::Method::PUT';

__PACKAGE__->meta->make_immutable;

sub _request_content {
    my ($self) = @_;

    return $self->acl_xml || '';
}

sub BUILD {
    my ($self) = @_;

    unless ( $self->acl_xml || $self->acl_short ) {
        confess "need either acl_xml or acl_short";
    }

    if ( $self->acl_xml && $self->acl_short ) {
        confess "can not provide both acl_xml and acl_short";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::SetObjectAccessControl - An internal class to set an object's access control

=head1 VERSION

version 0.86

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

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
