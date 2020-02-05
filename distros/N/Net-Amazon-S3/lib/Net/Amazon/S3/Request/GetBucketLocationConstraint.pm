package Net::Amazon::S3::Request::GetBucketLocationConstraint;
$Net::Amazon::S3::Request::GetBucketLocationConstraint::VERSION = '0.88';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
extends 'Net::Amazon::S3::Request::Bucket';

# ABSTRACT: An internal class to get a bucket's location constraint

with 'Net::Amazon::S3::Request::Role::Query::Action::Location';
with 'Net::Amazon::S3::Request::Role::HTTP::Method::GET';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::GetBucketLocationConstraint - An internal class to get a bucket's location constraint

=head1 VERSION

version 0.88

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::GetBucketLocationConstraint->new(
    s3     => $s3,
    bucket => $bucket,
  )->http_request;

=head1 DESCRIPTION

This module gets a bucket's location constraint.

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
