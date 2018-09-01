package Shared::Examples::Net::Amazon::S3::Operation::Bucket::Create;
$Shared::Examples::Net::Amazon::S3::Operation::Bucket::Create::VERSION = '0.85';
use strict;
use warnings;

use parent qw[ Exporter::Tiny ];

our @EXPORT_OK = (
    qw[ create_bucket_in_ca_central_1_content_xml ],
);

sub create_bucket_in_ca_central_1_content_xml {
    <<'EOXML';
<CreateBucketConfiguration>
  <LocationConstraint>ca-central-1</LocationConstraint>
</CreateBucketConfiguration>
EOXML
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::Operation::Bucket::Create

=head1 VERSION

version 0.85

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
