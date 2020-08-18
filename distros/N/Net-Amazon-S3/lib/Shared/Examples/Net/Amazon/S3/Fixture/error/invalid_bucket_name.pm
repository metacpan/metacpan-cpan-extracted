# PODNAME: Shared::Examples::Net::Amazon::S3::Fixture::error::invalid_bucket_name
# ABSTRACT: Shared::Examples providing error fixture

use strict;
use warnings;

use HTTP::Status;
use Shared::Examples::Net::Amazon::S3::Fixture;

Shared::Examples::Net::Amazon::S3::Fixture::error_fixture
    InvalidBucketName => HTTP::Status::HTTP_BAD_REQUEST;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::Fixture::error::invalid_bucket_name - Shared::Examples providing error fixture

=head1 VERSION

version 0.90

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
