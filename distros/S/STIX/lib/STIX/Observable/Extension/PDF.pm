package STIX::Observable::Extension::PDF;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str Num Bool HashRef);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    version
    is_optimized
    document_info_dict
    pdfid0
    pdfid1
]);

use constant EXTENSION_TYPE => 'pdf-ext';

has version            => (is => 'rw', isa => Num);
has is_optimized       => (is => 'rw', isa => Bool);
has document_info_dict => (is => 'rw', isa => HashRef);
has pdfid0             => (is => 'rw', isa => Str);
has pdfid1             => (is => 'rw', isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Extension::PDF - STIX Cyber-observable Object (SCO) - PDF File Extension

=head1 SYNOPSIS

    use STIX::Observable::Extension::PDF;

    my $pdf_ext = STIX::Observable::Extension::PDF->new();


=head1 DESCRIPTION

The PDF file extension specifies a default extension for capturing properties
specific to PDF files.


=head2 METHODS

L<STIX::Observable::Extension::PDF> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Extension::PDF->new(%properties)

Create a new instance of L<STIX::Observable::Extension::PDF>.

=item $pdf_ext->version

Specifies the decimal version number of the string from the PDF header that
specifies the version of the PDF specification to which the PDF file conforms. E.g., '1.4'.

=item $pdf_ext->is_optimized

Specifies whether the PDF file has been optimized.

=item $pdf_ext->document_info_dict

Specifies details of the PDF document information dictionary (DID), which
includes properties like the document creation data and producer, as a dictionary.

=item $pdf_ext->pdfid0

Specifies the first file identifier found for the PDF file.

=item $pdf_ext->pdfid1

Specifies the second file identifier found for the PDF file.

=back


=head2 HELPERS

=over

=item $pdf_ext->TO_JSON

Helper for JSON encoders.

=item $pdf_ext->to_hash

Return the object HASH.

=item $pdf_ext->to_string

Encode the object in JSON.

=item $pdf_ext->validate

Validate the object using JSON Schema (see L<STIX::Schema>).

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
