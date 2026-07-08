package PDF::Make::Document;

use strict;
use warnings;

our $VERSION = '0.06';

# Load the XS code from PDF::Make
use PDF::Make ();

1;

__END__

=head1 NAME

PDF::Make::Document - PDF document structure and file emission

=head1 SYNOPSIS

    use PDF::Make::Document;

    my $doc = PDF::Make::Document->new;

    # Get the arena for creating objects
    my $arena = $doc->arena;

    # Create a Pages dictionary
    my $pages = $arena->dict;
    $pages->set('Type', $arena->name('Pages'));
    $pages->set('Kids', $arena->array);
    $pages->set('Count', $arena->int(0));
    my $pages_num = $doc->add($pages);

    # Create a Catalog dictionary
    my $catalog = $arena->dict;
    $catalog->set('Type', $arena->name('Catalog'));
    $catalog->set('Pages', $doc->ref($pages_num));
    my $cat_num = $doc->add($catalog);

    # Set the document root
    $doc->set_root($cat_num);

    # Write to bytes or file
    my $bytes = $doc->to_bytes;
    $doc->to_file('/tmp/test.pdf');

=head1 DESCRIPTION

C<PDF::Make::Document> manages a PDF document structure and emits
complete PDF files per ISO 32000-2:2020.

A document owns:

=over 4

=item * An arena for object allocation

=item * A table of indirect objects

=item * Trailer references (Root, Info, ID)

=back

The C<to_bytes> method emits a complete PDF file including:

=over 4

=item * C<%PDF-2.0> header with binary comment

=item * Body of indirect objects (C<N G obj ... endobj>)

=item * Classic cross-reference table

=item * Trailer dictionary with C<startxref> and C<%%EOF>

=back

=head1 METHODS

=head2 new

    my $doc = PDF::Make::Document->new;

Create a new empty document.

=head2 add

    my $num = $doc->add($obj);

Add an object to the document as an indirect object. Returns the
object number (1-based). The generation number is always 0.

=head2 set_root

    $doc->set_root($num);

Set the document root (catalog) reference. This is required.

=head2 set_info

    $doc->set_info($num);

Set the document information dictionary reference. This is optional.

=head2 to_bytes

    my $bytes = $doc->to_bytes;

Write the complete PDF file to a byte string.

=head2 to_file

    $doc->to_file($path);

Write the complete PDF file to the specified path.

=head2 Metadata Accessors

    $doc->title('My Document');
    my $title = $doc->title;

Get/set metadata fields. Available: C<title>, C<author>, C<subject>,
C<keywords>, C<creator>, C<producer>.

=head2 get_meta / set_meta

    $doc->set_meta($key, $value);
    my $val = $doc->get_meta($key);

Get/set arbitrary metadata fields by key.

=head2 add_page

    my $page = $doc->add_page;
    my $page = $doc->add_page($width, $height);

Add a page to the document. Defaults to US Letter size.

=head1 FILE STRUCTURE

The emitted PDF follows E<sect>7.5 of ISO 32000-2:2020:

=over 4

=item * Header: C<%PDF-2.0> followed by binary comment

=item * Body: Indirect objects as C<N G obj ... endobj>

=item * Cross-reference table: Classic xref format

=item * Trailer: Dictionary with /Size, /Root, /Info, /ID

=back

=head1 SEE ALSO

L<PDF::Make>, L<PDF::Make::Writer>, L<PDF::Make::Obj>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by LNATION

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
