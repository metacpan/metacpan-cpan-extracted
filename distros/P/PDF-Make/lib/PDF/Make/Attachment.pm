package PDF::Make::Attachment;

use strict;
use warnings;

our $VERSION = '0.05';

use PDF::Make ();

1;

__END__

=head1 NAME

PDF::Make::Attachment - Embed file attachments in PDF documents

=head1 SYNOPSIS

    use PDF::Make::Document;
    use PDF::Make::Attachment;

    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);

    # Attach from in-memory data
    my $att = PDF::Make::Attachment->attach($doc,
        name        => 'config.json',
        data        => '{"key":"value"}',
        mime        => 'application/json',
        description => 'Application config',
    );

    # Attach from file on disk
    my $att2 = PDF::Make::Attachment->attach($doc,
        name => 'report.xlsx',
        path => '/path/to/report.xlsx',
    );

    # Inspect
    print $att->name, "\n";         # config.json
    print $att->filename, "\n";     # config.json
    print $att->mime_type, "\n";    # application/json
    print $att->size, " bytes\n";   # 15 bytes

    # Extract back to bytes or file
    my $bytes = $att->data;
    $att->extract_to_file('/tmp/extracted.json');

    $doc->to_file('with_attachments.pdf');

=head1 DESCRIPTION

C<PDF::Make::Attachment> embeds files into a PDF document as EmbeddedFile
streams with Filespec dictionaries. Attachments appear in the PDF viewer's
attachment panel and can be extracted by readers.

MIME types are auto-detected from the file extension when not specified
(e.g. C<.json> maps to C<application/json>).

=head1 CLASS METHODS

=head2 attach($doc, %args)

    my $att = PDF::Make::Attachment->attach($doc,
        name        => 'data.csv',       # required
        data        => $csv_string,      # provide data or path
        path        => '/path/to/file',  # alternative to data
        filename    => 'data.csv',       # display name (defaults to name)
        mime        => 'text/csv',       # auto-detected if omitted
        description => 'Raw data',       # optional
    );

Create and attach a file to the document. Returns the attachment object.
Either C<data> (in-memory bytes) or C<path> (file on disk) must be provided.

=head1 INSTANCE METHODS

=head2 name()

    my $name = $att->name;

Returns the attachment name (the key in the EmbeddedFiles name tree).

=head2 filename()

    my $fn = $att->filename;

Returns the display filename shown in the PDF viewer.

=head2 mime_type()

    my $mime = $att->mime_type;

Returns the MIME type string.

=head2 size()

    my $bytes = $att->size;

Returns the size of the embedded data in bytes.

=head2 data()

    my $raw = $att->data;

Returns the raw embedded file data as a byte string, or C<undef> if empty.

=head2 extract_to_file($path)

    $att->extract_to_file('/tmp/output.csv');

Writes the embedded data to a file on disk. Croaks on failure.

=head2 write_to_doc($doc)

    my $obj_num = $att->write_to_doc($doc);

Writes the attachment's PDF objects (Filespec + EmbeddedFile stream) into the
document. Returns the object number. This is called automatically by
C<to_bytes>/C<to_file> for attachments created via C<attach()>.

=head1 SEE ALSO

L<PDF::Make::Document>, L<PDF::Make::Builder>

=cut
