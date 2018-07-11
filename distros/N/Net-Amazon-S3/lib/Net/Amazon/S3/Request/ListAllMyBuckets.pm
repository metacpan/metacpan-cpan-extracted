package Net::Amazon::S3::Request::ListAllMyBuckets;
$Net::Amazon::S3::Request::ListAllMyBuckets::VERSION = '0.82';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
extends 'Net::Amazon::S3::Request';

# ABSTRACT: An internal class to list all buckets

__PACKAGE__->meta->make_immutable;

sub http_request {
    my $self    = shift;
    return $self->_build_http_request(
        method => 'GET',
        path   => '',
        use_virtual_host => 0,
        authorization_method => 'Net::Amazon::S3::Signature::V2',
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::ListAllMyBuckets - An internal class to list all buckets

=head1 VERSION

version 0.82

=head1 SYNOPSIS

  my $http_request
    = Net::Amazon::S3::Request::ListAllMyBuckets->new( s3 => $s3 )
    ->http_request;

=head1 DESCRIPTION

This module lists all buckets.

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
