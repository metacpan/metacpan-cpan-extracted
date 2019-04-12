package Shared::Examples::Net::Amazon::S3::Operation::Bucket::Objects::Delete;
# ABSTRACT: used for testing and as example
$Shared::Examples::Net::Amazon::S3::Operation::Bucket::Objects::Delete::VERSION = '0.86';
use strict;
use warnings;

use parent qw[ Exporter::Tiny ];

our @EXPORT_OK = (
    qw[ fixture_response_quiet_without_errors ],
);

sub fixture_response_quiet_without_errors {
    with_response_data => <<'EOXML';
<?xml version="1.0" encoding="UTF-8"?>
<DeleteResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
</DeleteResult>
EOXML
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::Operation::Bucket::Objects::Delete - used for testing and as example

=head1 VERSION

version 0.86

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
