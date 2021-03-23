# PODNAME: Shared::Examples::Net::Amazon::S3::Fixture::response::bucket_objects_delete_quiet_without_errors
# ABSTRACT: Shared::Examples providing response fixture

use strict;
use warnings;

package
	Shared::Examples::Net::Amazon::S3::Fixture::bucket::objects::delete::quiet_without_errors;

use HTTP::Status;
use Shared::Examples::Net::Amazon::S3::Fixture qw[ fixture ];

fixture content => <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<DeleteResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
</DeleteResult>
XML

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::Fixture::response::bucket_objects_delete_quiet_without_errors - Shared::Examples providing response fixture

=head1 VERSION

version 0.98

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
