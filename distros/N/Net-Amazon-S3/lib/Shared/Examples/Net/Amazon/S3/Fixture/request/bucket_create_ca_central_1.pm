# PODNAME: Shared::Examples::Net::Amazon::S3::Fixture::request::bucket_create_ca_central_1
# ABSTRACT: Shared::Examples providing request fixture

use strict;
use warnings;

use Shared::Examples::Net::Amazon::S3::Fixture;

Shared::Examples::Net::Amazon::S3::Fixture::fixture content => <<'XML';
<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
	<LocationConstraint>ca-central-1</LocationConstraint>
</CreateBucketConfiguration>
XML

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::Fixture::request::bucket_create_ca_central_1 - Shared::Examples providing request fixture

=head1 VERSION

version 0.991

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
