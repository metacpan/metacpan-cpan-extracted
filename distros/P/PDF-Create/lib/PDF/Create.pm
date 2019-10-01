package PDF::Create;

our $VERSION = '1.46';

=head1 NAME

PDF::Create - Create PDF files.

=head1 VERSION

Version 1.46

=cut

use 5.006;
use strict; use warnings;

use Carp qw(confess croak cluck carp);
use Data::Dumper;
use FileHandle;
use Scalar::Util qw(weaken);

use PDF::Image::GIF;
use PDF::Image::JPEG;
use PDF::Create::Page;
use PDF::Create::Outline;

my $DEBUG = 0;

=encoding utf8

=head1 DESCRIPTION

C<PDF::Create> allows you to create PDF document using a number of primitives.The
result is as a PDF file or stream. PDF stands for Portable Document Format.

Documents can have several pages, a  table of content, an information section and
many other PDF elements.

=head1 SYNOPSIS

C<PDF::Create> provides an easy module to create PDF output from your perl script.
It is designed to be easy to use and simple to install and maintain. It provides a
couple of subroutines to handle text, fonts, images and drawing primitives. Simple
documents are easy to create with the supplied routines.

In addition to be reasonable simple C<PDF::Create> is written in pure Perl and has
no external  dependencies  (libraries,  other modules, etc.). It should run on any
platform where perl is available.

For complex  stuff  some understanding of the underlying Postscript/PDF format is
necessary. In this case it might be better go with the more complete L<PDF::API2>
modules to gain more features at the expense of a steeper learning curve.

Example PDF creation with C<PDF::Create> (see L<PDF::Create::Page> for details
of methods available on a page):

    use strict; use warnings;
    use PDF::Create;

    my $pdf = PDF::Create->new(
        'filename'     => 'sample.pdf',
        'Author'       => 'John Doe',
        'Title'        => 'Sample PDF',
        'CreationDate' => [ localtime ]
    );

    # Add a A4 sized page
    my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));

    # Add a page which inherits its attributes from $root
    my $page1 = $root->new_page;

    # Prepare a font
    my $font = $pdf->font('BaseFont' => 'Helvetica');

    # Prepare a Table of Content
    my $toc = $pdf->new_outline('Title' => 'Title Page', 'Destination' => $page1);

    # Write some text
    $page1->stringc($font, 40, 306, 426, 'PDF::Create');
    $page1->stringc($font, 20, 306, 396, "version $PDF::Create::VERSION");
    $page1->stringc($font, 20, 306, 300, 'by John Doe <john.doe@example.com>');

    # Add another page
    my $page2 = $root->new_page;

    # Draw some lines
    $page2->line(0, 0,   592, 840);
    $page2->line(0, 840, 592, 0);

    $page2->string($font, 20, 50, 400, "default á é í ó ú ñ  Á É Í Ó Ú Ñ ¿ ¡ a e i o u n'");
    $page2->string_underline($font, 20, 50, 400, "default á é í ó ú ñ  Á É Í Ó Ú Ñ ¿ ¡ a e i o u n'");

    use utf8;
    $page2->string($font, 20, 50, 350, "use utf8 á é í ó ú ñ  Á É Í Ó Ú Ñ ¿ ¡ a e i o u n'");
    $page2->string_underline($font, 20, 50, 350, "use utf8 á é í ó ú ñ  Á É Í Ó Ú Ñ ¿ ¡ a e i o u n'");

    no utf8;
    $page2->string($font, 20, 50, 300, "no utf8 á é í ó ú ñ  Á É Í Ó Ú Ñ ¿ ¡ a e i o u n'");
    $page2->string_underline($font, 20, 50, 300, "no utf8 á é í ó ú ñ  Á É Í Ó Ú Ñ ¿ ¡ a e i o u n'");

    $toc->new_outline('Title' => 'Second Page', 'Destination' => $page2);

    # Close the file and write the PDF
    $pdf->close;

=head1 CONSTRUCTOR

The method C<new(%params)> create a new pdf structure for your PDF. It returns an
object handle which can be used to add more stuff to the PDF. The  parameter keys
to the constructor are detailed as below:

    +--------------+------------------------------------------------------------+
    | Key          | Description                                                |
    +--------------+------------------------------------------------------------+
    |              |                                                            |
    | filename     | Destination file that will contain resulting PDF or '-' for|
    |              | stdout. If neither filename or fh are specified, the       |
    |              | content will be stored in memory and returned when calling |
    |              | close().                                                   |
    |              |                                                            |
    | fh           | Already opened filehandle that will contain resulting PDF. |
    |              | See comment above regarding close().                       |
    |              |                                                            |
    | Version      | PDF Version to claim, can be 1.0 to 1.3 (default: 1.       |
    |              |                                                            |
    | PageMode     | How the document should appear when opened.Possible values |
    |              | UseNone (Default), UseOutlines, UseThumbs and FullScreen   |
    |              |                                                            |
    | Author       | The name of the person who created this document.          |
    |              |                                                            |
    | Creator      | If the document was converted into a PDF document from     |
    |              | another form, this is the name of the application that     |
    |              | created the document.                                      |
    |              |                                                            |
    | Title        | The title of the document.                                 |
    |              |                                                            |
    | Subject      | The subject of the document.                               |
    |              |                                                            |
    | Keywords     | Keywords associated with the document.                     |
    |              |                                                            |
    | CreationDate | The date the document was created.This is passed as an     |
    |              | anonymous array in the same format as localtime returns.   |
    |              |                                                            |
    | Debug        | The debug level, defaults to 0. It can be any positive     |
    |              | integers.                                                  |
    |              |                                                            |
    +--------------+------------------------------------------------------------+

Example:

    my $pdf = PDF::Create->new(
        'filename'     => 'sample.pdf',
        'Version'      => 1.2,
        'PageMode'     => 'UseOutlines',
        'Author'       => 'John Doe',
        'Title'        => 'My Title',
        'CreationDate' => [ localtime ]
    );

If you are writing a CGI you can send your PDF on the fly to stdout / directly to
the browser using '-' as filename.

CGI Example:

  use CGI;
  use PDF::Create;

  print CGI::header(-type => 'application/x-pdf', -attachment => 'sample.pdf');
  my $pdf = PDF::Create->new(
      'filename'     => '-',
      'Author'       => 'John Doe',
      'Title'        => 'My title',
      'CreationDate' => [ localtime ]
  );

=cut

sub new {
    my ($this, %params) = @_;

    # validate constructor keys
    my %valid_constructor_keys = (
        'fh'           => 1,
        'filename'     => 1,
        'Version'      => 1,
        'PageMode'     => 1,
        'Author'       => 1,
        'Creator'      => 1,
        'Title'        => 1,
        'Subject'      => 1,
        'Keywords'     => 1,
        'Debug'        => 1,
        'CreationDate' => 1,
    );
    foreach (keys %params) {
        croak "Invalid constructor key '$_' received."
            unless (exists $valid_constructor_keys{$_});
    }

    if (exists $params{PageMode} && defined $params{PageMode}) {
        # validate PageMode key value
        my %valid_page_mode_values = (
            'UseNone'     => 1,
            'UseOutlines' => 1,
            'UseThumbs'   => 1,
            'FullScreen'  => 1);
        croak "Invalid value for key 'PageMode' received '". $params{PageMode} . "'"
            unless (exists $valid_page_mode_values{$params{PageMode}});
    }

    if (exists $params{Debug} && defined $params{Debug}) {
        # validate Debug key value
        croak "Invalid value for key 'Debug' received '". $params{Debug} . "'"
            unless (($params{Debug} =~ /^\d+$/) && ($params{Debug} >= 0));
    }

    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;

    $self->{'data'}    = '';
    $self->{'version'} = $params{'Version'} || "1.2";
    $self->{'trailer'} = {};

    $self->{'pages'}          = PDF::Create::Page->new();
    $self->{'current_page'}   = $self->{'pages'};
    # circular reference
    $self->{'pages'}->{'pdf'} = $self;
    weaken $self->{pages}{pdf};
    $self->{'page_count'}     = 0;
    $self->{'outline_count'}  = 0;

    # cross-reference table start address
    $self->{'crossreftblstartaddr'} = 0;
    $self->{'generation_number'}    = 0;
    $self->{'object_number'}        = 0;

    if ( defined $params{'fh'} ) {
        $self->{'fh'} = $params{'fh'};
    } elsif ( defined $params{'filename'} ) {
        $self->{'filename'} = $params{'filename'};
        my $fh = FileHandle->new( "> $self->{'filename'}" );
        carp "PDF::Create.pm: $self->{'filename'}: $!\n" unless defined $fh;
        binmode $fh;
        $self->{'fh'} = $fh;
    }

    $self->{'catalog'} = {};
    $self->{'catalog'}{'PageMode'} = $params{'PageMode'} if defined $params{'PageMode'};

    # Header: add version
    $self->add_version;

    # Info
    $self->{'Author'}   = $params{'Author'}   if defined $params{'Author'};
    $self->{'Creator'}  = $params{'Creator'}  if defined $params{'Creator'};
    $self->{'Title'}    = $params{'Title'}    if defined $params{'Title'};
    $self->{'Subject'}  = $params{'Subject'}  if defined $params{'Subject'};
    $self->{'Keywords'} = $params{'Keywords'} if defined $params{'Keywords'};

    # TODO: Default creation date from system date
    if ( defined $params{'CreationDate'} ) {
        $self->{'CreationDate'} =
            sprintf "D:%4u%0.2u%0.2u%0.2u%0.2u%0.2u",
            $params{'CreationDate'}->[5] + 1900, $params{'CreationDate'}->[4] + 1,
            $params{'CreationDate'}->[3], $params{'CreationDate'}->[2],
            $params{'CreationDate'}->[1], $params{'CreationDate'}->[0];
    }
    if ( defined $params{'Debug'} ) {
        $DEBUG = $params{'Debug'};

        # Enable stack trace for PDF::Create internal routines
        $Carp::Internal{ ('PDF::Create') }++;
    }
    debug( 1, "Debugging level $DEBUG" );
    return $self;
}

=head1 METHODS

=head2 new_page(%params)

Add a page to the document using the given parameters. C<new_page> must be called
first to initialize a root page, used as model for further pages.Returns a handle
to the newly created page. Parameters can be:

    +-----------+---------------------------------------------------------------+
    | Key       | Description                                                   |
    +-----------+---------------------------------------------------------------+
    |           |                                                               |
    | Parent    | The parent of this page in the pages tree.This is page object.|
    |           |                                                               |
    | Resources | Resources required by this page.                              |
    |           |                                                               |
    | MediaBox  | Rectangle specifying the natural size of the page,for example |
    |           | the dimensions of an A4 sheet of paper. The coordinates are   |
    |           | measured in default user space units It must be the reference |
    |           | of 4 values array.You can use C<get_page_size> to get to get  |
    |           | the size of standard paper sizes.C<get_page_size> knows about |
    |           | A0-A6, A4L (landscape), Letter, Legal, Broadsheet, Ledger,    |
    |           | Tabloid, Executive and 36x36.                                 |
    | CropBox   | Rectangle specifying the default clipping region for the page |
    |           | when displayed or printed. The default is the value of the    |
    |           | MediaBox.                                                     |
    |           |                                                               |
    | ArtBox    | Rectangle specifying  an area  of the page to be used when    |
    |           | placing PDF content into another application. The default is  |
    |           | the value of the CropBox. [PDF 1.3]                           |
    |           |                                                               |
    | TrimBox   | Rectangle specifying the  intended finished size of the page  |
    |           | (for example, the dimensions of an A4 sheet of paper).In some |
    |           | cases,the MediaBox will be a larger rectangle, which includes |
    |           | printing instructions, cut marks or other content.The default |
    |           | is the value of the CropBox. [PDF 1.3].                       |
    |           |                                                               |
    | BleedBox  | Rectangle specifying the region to which all page content     |
    |           | should be clipped if the page is being output in a production |
    |           | environment. In such environments, a bleed area is desired,   |
    |           | to accommodate physical limitations of cutting, folding, and  |
    |           | trimming  equipment. The actual  printed page may  include    |
    |           | printer's marks that fall outside the bleed box. The default  |
    |           | is the value of the CropBox.[PDF 1.3]                         |
    |           |                                                               |
    | Rotate    | Specifies the number of degrees the page should be rotated    |
    |           | clockwise when it is displayed or printed. This value must be |
    |           | zero (the default) or a multiple of 90. The entire page,      |
    |           | including contents is rotated.                                |
    |           |                                                               |
    +-----------+---------------------------------------------------------------+

Example:

    my $a4 = $pdf->new_page( 'MediaBox' => $pdf->get_page_size('A4') );

    my $page1 = $a4->new_page;
    $page1->string($f1, 20, 306, 396, "some text on page 1");

    my $page2 = $a4->new_page;
    $page2->string($f1, 20, 306, 396, "some text on page 2");

=cut

sub new_page {
    my ($self, %params) = @_;

    my %valid_new_page_parameters = map { $_ => 1 } (qw/Parent Resources MediaBox CropBox ArtBox TrimBox BleedBox Rotate/);
    foreach my $key (keys %params) {
        croak "PDF::Create.pm - new_page(): Received invalid key [$key]"
            unless (exists $valid_new_page_parameters{$key});
    }

    my $parent = $params{'Parent'} || $self->{'pages'};
    my $name   = "Page " . ++$self->{'page_count'};
    my $page   = $parent->add( $self->reserve( $name, "Page" ), $name );
    $page->{'resources'} = $params{'Resources'} if defined $params{'Resources'};
    $page->{'mediabox'}  = $params{'MediaBox'}  if defined $params{'MediaBox'};
    $page->{'cropbox'}   = $params{'CropBox'}   if defined $params{'CropBox'};
    $page->{'artbox'}    = $params{'ArtBox'}    if defined $params{'ArtBox'};
    $page->{'trimbox'}   = $params{'TrimBox'}   if defined $params{'TrimBox'};
    $page->{'bleedbox'}  = $params{'BleedBox'}  if defined $params{'BleedBox'};
    $page->{'rotate'}    = $params{'Rotate'}    if defined $params{'Rotate'};

    $self->{'current_page'} = $page;

    $page;
}

=head2 font(%params)

Prepare a font using the given arguments. This font will be added to the document
only if it is used at least once before the close method is called.Parameters are
listed below:

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | Subtype  | Type of font. PDF defines some types of fonts. It must be one  |
    |          | of the predefined type Type1, Type3, TrueType or Type0.In this |
    |          | version, only Type1 is supported. This is the default value.   |
    |          |                                                                |
    | Encoding | Specifies the  encoding  from which the new encoding differs.  |
    |          | It must be one of the predefined encodings MacRomanEncoding,   |
    |          | MacExpertEncoding or WinAnsiEncoding. In this version, only    |
    |          | WinAnsiEncoding is supported. This is the default value.       |
    |          |                                                                |
    | BaseFont | The PostScript name of the font. It can be one of the following|
    |          | base fonts: Courier, Courier-Bold, Courier-BoldOblique,        |
    |          | Courier-Oblique, Helvetica, Helvetica-Bold,                    |
    |          | Helvetica-BoldOblique, Helvetica-Oblique, Times-Roman,         |
    |          | Times-Bold, Times-Italic, Times-BoldItalic or Symbol.          |
    +----------+----------------------------------------------------------------+

The ZapfDingbats font is not supported in this version.Default font is Helvetica.

    my $f1 = $pdf->font('BaseFont' => 'Helvetica');

=cut

sub font {
    my ($self, %params) = @_;

    my %valid_font_parameters = (
        'Subtype'  => { map { $_ => 1 } qw/Type0 Type1 Type3 TrueType/ },
        'Encoding' => { map { $_ => 1 } qw/MacRomanEncoding MacExpertEncoding WinAnsiEncoding Symbol/ },
        'BaseFont' => { map { $_ => 1 } qw/Courier Courier-Bold Courier-BoldOblique Courier-Oblique
                                           Helvetica Helvetica-Bold Helvetica-BoldOblique Helvetica-Oblique
                                           Times-Roman Times-Bold Times-Italic Times-BoldItalic Symbol/ },
        );

    foreach my $key (keys %params) {
        croak "PDF::Create.pm - font(): Received invalid key [$key]"
            unless (exists $valid_font_parameters{$key});
        my $value = $params{$key};
        croak "PDF::Create.pm - font(): Received invalid value [$value] for key [$key]"
            if (defined $value && !(exists $valid_font_parameters{$key}->{$value}));
    }

    my $num    = 1 + scalar keys %{ $self->{'fonts'} };
    $self->{'fonts'}{$num} = {
        'Subtype'  => $self->name( $params{'Subtype'}  || 'Type1' ),
        'Encoding' => $self->name( $params{'Encoding'} || 'WinAnsiEncoding' ),
        'BaseFont' => $self->name( $params{'BaseFont'} || 'Helvetica' ),
        'Name'     => $self->name("F$num"),
        'Type'     => $self->name("Font"),
    };

    $num;
}

=head2 new_outline(%params)

Adds  an  outline  to  the  document using the given parameters. Return the newly
created outline. Parameters can be:

    +-------------+-------------------------------------------------------------+
    | Key         | Description                                                 |
    +-------------+-------------------------------------------------------------+
    |             |                                                             |
    | Title       | The title of the outline. Mandatory.                        |
    |             |                                                             |
    | Destination | The Destination of this outline item. In this version,it is |
    |             | only possible to give a page as destination. The default    |
    |             | destination is the current page.                            |
    |             |                                                             |
    | Parent      | The parent of this outline in the outlines tree. This is an |
    |             | outline object. This way you represent the tree of your     |
    |             | outlines.                                                   |
    |             |                                                             |
    +-------------+-------------------------------------------------------------+

Example:

    my $outline = $pdf->new_outline('Title' => 'Item 1');
    $pdf->new_outline('Title' => 'Item 1.1', 'Parent' => $outline);
    $pdf->new_outline('Title' => 'Item 1.2', 'Parent' => $outline);
    $pdf->new_outline('Title' => 'Item 2');

=cut

sub new_outline {
    my ($self, %params) = @_;

    croak "PDF::Create - new_outline(): Missing required key [Title]."
        unless (exists $params{'Title'});
    croak "PDF::Create - new_outline(): Required key [Title] undefined."
        unless (defined $params{'Title'});

    if (defined $params{Destination}) {
        croak "PDF::Create - new_outline(): Invalid value for key [Destination]."
            unless (ref($params{Destination}) eq 'PDF::Create::Page');
    }

    if (defined $params{Parent}) {
        croak "PDF::Create - new_outline(): Invalid value for key [Parent]."
            unless (ref($params{Parent}) eq 'PDF::Create::Outline');
    }

    unless ( defined $self->{'outlines'} ) {
        $self->{'outlines'}             = PDF::Create::Outline->new();
        # circular reference
        $self->{'outlines'}->{'pdf'}    = $self;
        weaken $self->{'outlines'}->{'pdf'};
        $self->{'outlines'}->{'Status'} = 'opened';
    }

    my $parent = $params{'Parent'} || $self->{'outlines'};
    my $name = "Outline " . ++$self->{'outline_count'};
    $params{'Destination'} = $self->{'current_page'}  unless defined $params{'Destination'};
    my $outline = $parent->add( $self->reserve( $name, "Outline" ), $name, %params );
    $outline;
}

=head2 get_page_size($name)

Returns the  size of standard paper used for MediaBox-parameter  of  C<new_page>.
C<get_page_size> has  one  optional parameter to specify the paper name. Possible
values are a0-a6, a4l,letter,broadsheet,ledger,tabloid,legal,executive and 36x36.
Default is a4.

    my $root = $pdf->new_page( 'MediaBox' => $pdf->get_page_size('A4') );

=cut

sub get_page_size {
    my ($self, $name) = @_;

    my %pagesizes = (
        'A0'         => [ 0, 0, 2380, 3368 ],
        'A1'         => [ 0, 0, 1684, 2380 ],
        'A2'         => [ 0, 0, 1190, 1684 ],
        'A3'         => [ 0, 0, 842,  1190 ],
        'A4'         => [ 0, 0, 595,  842  ],
        'A4L'        => [ 0, 0, 842,  595  ],
        'A5'         => [ 0, 0, 421,  595  ],
        'A6'         => [ 0, 0, 297,  421  ],
        'LETTER'     => [ 0, 0, 612,  792  ],
        'BROADSHEET' => [ 0, 0, 1296, 1584 ],
        'LEDGER'     => [ 0, 0, 1224, 792  ],
        'TABLOID'    => [ 0, 0, 792,  1224 ],
        'LEGAL'      => [ 0, 0, 612,  1008 ],
        'EXECUTIVE'  => [ 0, 0, 522,  756  ],
        '36X36'      => [ 0, 0, 2592, 2592 ],
    );
    if (defined $name) {
        $name = uc($name);
        # validate page size
        croak "Invalid page size name '$name' received." unless (exists $pagesizes{$name});
    }
    else {
        $name = 'A4';
    }

    return $pagesizes{$name};
}

=head2 version($number)

Set and return version number. Valid version numbers are 1.0, 1.1, 1.2 and 1.3.

=cut

sub version {
    my ($self, $v) = @_;

    if (defined $v) {
        croak "ERROR: Invalid version number $v received.\n"
            unless ($v =~ /^1\.[0,1,2,3]$/);
        $self->{'version'} = $v;
    }
    $self->{'version'};
}

=head2 close(%params)

Close does the work of creating the PDF data from the objects collected before.
You must call C<close()> after you have added all the contents as most of the
real work building the  PDF is performed there. If omit calling close you get
no PDF output. Returns the raw content of the PDF.
If C<fh> was provided when creating object of C<PDF::Create> then it does not
try to close the file handle. It is, therefore, advised you call C<flush()>
rather than C<close()>.

=cut

sub close {
    my ($self, %params) = @_;

    debug( 2, "Closing PDF" );
    my $raw_data = $self->flush;

    if (defined $self->{'fh'} && defined $self->{'filename'}) {
        $self->{'fh'}->close;
    }

    return $raw_data;
}

=head2 flush()

Generate the PDF content and returns the raw content as it is.

=cut

sub flush {
    my ($self) = @_;

    debug( 2, "Flushing PDF" );
    $self->page_stream;
    $self->add_outlines if defined $self->{'outlines'};
    $self->add_catalog;
    $self->add_pages;
    $self->add_info;
    $self->add_crossrefsection;
    $self->add_trailer;

    return $self->{data};
}

=head2 reserve($name, $type)

Reserve the next object number for the given object type.

=cut

sub reserve {
    my ($self, $name, $type) = @_;;

    $type = $name unless defined $type;

    confess "Error: an object has already been reserved using this name '$name' "
        if defined $self->{'reservations'}{$name};
    $self->{'object_number'}++;
    debug( 2, "reserve(): name=$name type=$type number=$self->{'object_number'} generation=$self->{'generation_number'}" );
    $self->{'reservations'}{$name} = [ $self->{'object_number'}, $self->{'generation_number'}, $type ];


    # Annotations added here by Gary Lieberman.
    #
    # Store the Object ID and the Generation Number for later use when we write
    # out the /Page object.
    if ($type eq 'Annotation') {
        $self->{'Annots'}{ $self->{'object_number'} } = $self->{'generation_number'};
    }

    [ $self->{'object_number'}, $self->{'generation_number'} ];
}

=head2 add_comment($message)

Add comment to the document.The string will show up in the PDF as postscript-style
comment:

    % this is a postscript comment

=cut

sub add_comment {
    my ($self, $comment) = @_;

    $comment = '' unless defined $comment;
    debug( 2, "add_comment(): $comment" );
    $self->add( "%" . $comment );
    $self->cr;
}

=head2 annotation(%params)

Adds an annotation object, for the time being we only do the  'Link' - 'URI' kind
This is a  sensitive area in the PDF document where text annotations are shown or
links launched. C<PDF::Create> only supports URI links at this time.

URI links  have two components,the text or graphics object and the area where the
mouseclick should occur.

For the object  to be clicked  on you'll use standard text of drawing methods. To
define the click-sensitive area and the destination URI.

Example:

    # Draw a string and underline it to show it is a link
    $pdf->string($f1, 10, 450, 200, 'http://www.cpan.org');

    my $line = $pdf->string_underline($f1, 10, 450, 200, 'http://www.cpan.org');

    # Create the hot area with the link to open on click
    $pdf->annotation(
        Subtype => 'Link',
        URI     => 'http://www.cpan.org',
        x       => 450,
        y       => 200,
        w       => $l,
        h       => 15,
        Border  => [0,0,0]
    );

The point (x, y) is  the  bottom  left corner of the rectangle containing hotspot
rectangle, (w, h) are  the  width and height of the hotspot rectangle. The Border
describes the thickness of the border surrounding the rectangle hotspot.

The function C<string_underline> returns the width of the string, this can be used
directly for the width of the hotspot rectangle.

=cut

sub annotation {
    my ($self, %params) = @_;

    debug( 2, "annotation(): Subtype=$params{'Subtype'}" );

    if ( $params{'Subtype'} eq 'Link' ) {
        confess "Must specify 'URI' for Link" unless defined $params{'URI'};
        confess "Must specify 'x' for Link"   unless defined $params{'x'};
        confess "Must specify 'y' for Link"   unless defined $params{'y'};
        confess "Must specify 'w' for Link"   unless defined $params{'w'};
        confess "Must specify 'h' for Link"   unless defined $params{'h'};

        my $num = 1 + scalar keys %{ $self->{'annotations'} };

        my $action = {
            'Type' => $self->name('Action'),
            'S'    => $self->name('URI'),
            'URI'  => $self->string( $params{'URI'} ),
        };
        my $x2 = $params{'x'} + $params{'w'};
        my $y2 = $params{'y'} + $params{'h'};

        $self->{'annotations'}{$num} = {
            'Subtype' => $self->name('Link'),
            'Rect' => $self->verbatim( sprintf "[%f %f %f %f]", $params{'x'}, $params{'y'}, $x2, $y2 ),
            'A'    => $self->dictionary(%$action),
        };

        if ( defined $params{'Border'} ) {
            $self->{'annotations'}{$num}{'Border'} =
                $self->verbatim( sprintf "[%f %f %f]", $params{'Border'}[0], $params{'Border'}[1], $params{'Border'}[2] );
        }
        $self->{'annot'}{$num}{'page_name'} = "Page " . $self->{'page_count'};
        debug( 2, "annotation(): annotation number: $num, page name: $self->{'annot'}{$num}{'page_name'}" );
        1;
    } else {
        confess "Only Annotations with Subtype 'Link' are supported for now\n";
    }
}

=head2 image($filename)

Prepare an XObject (image) using the given arguments. This image will be added to
the document if it is referenced at least once before the close method is called.
In this version GIF,interlaced GIF and JPEG is supported. Usage of interlaced GIFs
are slower because they are decompressed, modified and  compressed again. The gif
support is limited to images with a LZW minimum code size of 8. Small images with
few colors can have a smaller minimum code size and will not work. If you get
errors regarding JPEG compression, then the compression method used in your
JPEG file is not supported by C<PDF::Image::JPEG>. Try resaving the JPEG file
with different compression options (for example, disable progressive
compression).

Example:

    my $img = $pdf->image('image.jpg');

    $page->image(
        image  => $img,
        xscale => 0.25, # scale image for better quality
        yscale => 0.25,
        xpos   => 50,
        ypos   => 60,
        xalign => 0,
        yalign => 2,
    );

=cut

sub image {
    my ($self, $filename) = @_;

    my $num = 1 + scalar keys %{ $self->{'xobjects'} };

    my $image;
    my $colorspace;
    my @a;

    if ( $filename =~ /\.gif$/i ) {
        $self->{'images'}{$num} = PDF::Image::GIF->new();
    } elsif ( $filename =~ /\.jpg$/i || $filename =~ /\.jpeg$/i ) {
        $self->{'images'}{$num} = PDF::Image::JPEG->new();
    }

    $image = $self->{'images'}{$num};
    if ( !$image->Open($filename) ) {
        print $image->{error} . "\n";
        return 0;
    }

    $self->{'xobjects'}{$num} = {
        'Subtype'          => $self->name('Image'),
        'Name'             => $self->name("Image$num"),
        'Type'             => $self->name('XObject'),
        'Width'            => $self->number( $image->{width} ),
        'Height'           => $self->number( $image->{height} ),
        'BitsPerComponent' => $self->number( $image->{bpc} ),
        'Data'             => $image->ReadData(),
        'Length'           => $self->number( $image->{imagesize} ),
    };

    # Indexed colorspace?
    if ($image->{colorspacesize}) {
        $colorspace = $self->reserve("ImageColorSpace$num");

        $self->{'xobjects_colorspace'}{$num} = {
            'Data'   => $image->{colorspacedata},
            'Length' => $self->number( $image->{colorspacesize} ),
        };

        $self->{'xobjects'}{$num}->{'ColorSpace'} = $self->array( $self->name('Indexed'), $self->name( $image->{colorspace} ),
                                                                  $self->number(255),     $self->indirect_ref(@$colorspace) );
    } else {
        $self->{'xobjects'}{$num}->{'ColorSpace'} = $self->array( $self->name( $image->{colorspace} ) );
    }

    # Set Filter
    $#a = -1;
    foreach my $s ( @{ $image->{filter} } ) {
        push @a, $self->name($s);
    }
    if ( $#a >= 0 ) {
        $self->{'xobjects'}{$num}->{'Filter'} = $self->array(@a);
    }

    # Set additional DecodeParms
    $#a = -1;
    foreach my $s ( keys %{ $image->{decodeparms} } ) {
        push @a, $s;
        push @a, $self->number( $image->{decodeparms}{$s} );
    }
    $self->{'xobjects'}{$num}->{'DecodeParms'} = $self->array( $self->dictionary(@a) );

    # Transparent?
    if ( $image->{transparent} ) {
        $self->{'xobjects'}{$num}->{'Mask'} = $self->array( $self->number( $image->{mask} ), $self->number( $image->{mask} ) );
    }

    return { 'num' => $num, 'width' => $image->{width}, 'height' => $image->{height} };
}

sub add_outlines {
    my ($self, %params) = @_;

    debug( 2, "add_outlines" );
    my $outlines = $self->reserve("Outlines");

    my ($First, $Last);
    my @list = $self->{'outlines'}->list;
    my $i    = -1;
    for my $outline (@list) {
        $i++;
        my $name = $outline->{'name'};
        $First = $outline->{'id'} unless defined $First;
        $Last = $outline->{'id'};
        my $content = { 'Title' => $self->string( $outline->{'Title'} ) };
        if ( defined $outline->{'Kids'} && scalar @{ $outline->{'Kids'} } ) {
            my $t = $outline->{'Kids'};
            $$content{'First'} = $self->indirect_ref( @{ $$t[0]->{'id'} } );
            $$content{'Last'}  = $self->indirect_ref( @{ $$t[$#$t]->{'id'} } );
        }
        my $brothers = $outline->{'Parent'}->{'Kids'};
        my $j        = -1;
        for my $brother (@$brothers) {
            $j++;
            last if $brother == $outline;
        }
        $$content{'Next'} = $self->indirect_ref( @{ $$brothers[ $j + 1 ]->{'id'} } )
            if $j < $#$brothers;
        $$content{'Prev'} = $self->indirect_ref( @{ $$brothers[ $j - 1 ]->{'id'} } )
            if $j;
        $outline->{'Parent'}->{'id'} = $outlines
            unless defined $outline->{'Parent'}->{'id'};
        $$content{'Parent'} = $self->indirect_ref( @{ $outline->{'Parent'}->{'id'} } );
        $$content{'Dest'} =
            $self->array( $self->indirect_ref( @{ $outline->{'Dest'}->{'id'} } ),
                          $self->name('Fit'), $self->null, $self->null, $self->null );
        my $count = $outline->count;
        $$content{'Count'} = $self->number($count) if $count;
        my $t = $self->add_object( $self->indirect_obj( $self->dictionary(%$content), $name ) );
        $self->cr;
    }

    # Type (required)
    my $content = { 'Type' => $self->name('Outlines') };

    # Count
    my $count = $self->{'outlines'}->count;
    $$content{'Count'} = $self->number($count) if $count;
    $$content{'First'} = $self->indirect_ref(@$First);
    $$content{'Last'}  = $self->indirect_ref(@$Last);
    $self->add_object( $self->indirect_obj( $self->dictionary(%$content) ) );
    $self->cr;
}

sub add_pages {
    my ($self) = @_;

    debug( 2, "add_pages():" );

    # Type (required)
    my $content = { 'Type' => $self->name('Pages') };

    # Kids (required)
    my $t = $self->{'pages'}->kids;
    confess "Error: document MUST contains at least one page. Abort."
        unless scalar @$t;

    my $kids = [];
    map { push @$kids, $self->indirect_ref(@$_) } @$t;
    $$content{'Kids'}  = $self->array(@$kids);
    $$content{'Count'} = $self->number( $self->{'pages'}->count );
    $self->add_object( $self->indirect_obj( $self->dictionary(%$content) ) );
    $self->cr;

    for my $font ( sort keys %{ $self->{'fonts'} } ) {
        debug( 2, "add_pages(): font: $font" );
        $self->{'fontobj'}{$font} = $self->reserve('Font');
        $self->add_object( $self->indirect_obj( $self->dictionary( %{ $self->{'fonts'}{$font} } ), 'Font' ) );
        $self->cr;
    }

    for my $xobject (sort keys %{$self->{'xobjects'}}) {
        debug( 2, "add_pages(): xobject: $xobject" );
        $self->{'xobj'}{$xobject} = $self->reserve('XObject');
        $self->add_object( $self->indirect_obj( $self->stream( %{ $self->{'xobjects'}{$xobject} } ), 'XObject' ) );
        $self->cr;

        if ( defined $self->{'reservations'}{"ImageColorSpace$xobject"}) {
            $self->add_object(
                $self->indirect_obj( $self->stream( %{ $self->{'xobjects_colorspace'}{$xobject} } ), "ImageColorSpace$xobject" ) );
            $self->cr;
        }
    }

    for my $annotation (sort keys %{$self->{'annotations'}}) {
        $self->{'annot'}{$annotation}{'object_info'} = $self->reserve('Annotation');
        $self->add_object( $self->indirect_obj( $self->dictionary( %{ $self->{'annotations'}{$annotation} } ), 'Annotation' ) );
        $self->cr;
    }

    for my $page ($self->{'pages'}->list) {
        my $name = $page->{'name'};
        debug( 2, "add_pages: page: $name" );
        my $type = 'Page' . ( defined $page->{'Kids'} && scalar @{ $page->{'Kids'} } ? 's' : '' );

        # Type (required)
        my $content = { 'Type' => $self->name($type) };

        # Resources (required, may be inherited). See page 195.
        my $resources = {};
        for my $k ( keys %{ $page->{'resources'} } ) {
            my $v = $page->{'resources'}{$k};
            ( $k eq 'ProcSet' ) && do {
                my $l = [];
                if ( ref($v) eq 'ARRAY' ) {
                    map { push @$l, $self->name($_) } @$v;
                } else {
                    push @$l, $self->name($v);
                }
                $$resources{'ProcSet'} = $self->array(@$l);
            }
            || ( $k eq 'fonts' ) && do {
                my $l = {};
                map { $$l{"F$_"} = $self->indirect_ref( @{ $self->{'fontobj'}{$_} } ); } keys %{ $page->{'resources'}{'fonts'} };
                $$resources{'Font'} = $self->dictionary(%$l);
            }
            || ( $k eq 'xobjects' ) && do {
                my $l = {};
                map { $$l{"Image$_"} = $self->indirect_ref( @{ $self->{'xobj'}{$_} } ); }
                keys %{ $page->{'resources'}{'xobjects'} };
                $$resources{'XObject'} = $self->dictionary(%$l);
            };
        }
        if ( defined( $$resources{'Annotation'} ) ) {
            my $r = $self->add_object( $self->indirect_obj( $self->dictionary(%$resources) ) );
            $self->cr;
            $$content{'Resources'} = [ 'ref', [ $$r[0], $$r[1] ] ];
        }
        if ( defined( $$resources{'XObject'} ) ) {
            my $r = $self->add_object( $self->indirect_obj( $self->dictionary(%$resources) ) );
            $self->cr;
            $$content{'Resources'} = [ 'ref', [ $$r[0], $$r[1] ] ];
        } else {
            $$content{'Resources'} = $self->dictionary(%$resources)
                if scalar keys %$resources;
        }
        for my $K ( 'MediaBox', 'CropBox', 'ArtBox', 'TrimBox', 'BleedBox' ) {
            my $k = lc $K;
            if ( defined $page->{$k} ) {
                my $l = [];
                map { push @$l, $self->number($_) } @{ $page->{$k} };
                $$content{$K} = $self->array(@$l);
            }
        }
        $$content{'Rotate'} = $self->number( $page->{'rotate'} ) if defined $page->{'rotate'};
        if ( $type eq 'Page' ) {
            $$content{'Parent'} = $self->indirect_ref( @{ $page->{'Parent'}{'id'} } );

            # Content
            if ( defined $page->{'contents'} ) {
                my $contents = [];
                map { push @$contents, $self->indirect_ref(@$_); } @{ $page->{'contents'} };
                $$content{'Contents'} = $self->array(@$contents);
            }

            # Annotations added here by Gary Lieberman
            #
            # Tell the /Page object that annotations need to be drawn.
            if ( defined $self->{'annot'} ) {
                my $Annots    = '[ ';
                my $is_annots = 0;
                foreach my $annot_number ( keys %{ $self->{'annot'} } ) {
                    next if ( $self->{'annot'}{$annot_number}{'page_name'} ne $name );
                    $is_annots = 1;
                    debug( 2,
                           sprintf "annotation number:  $annot_number, page name: $self->{'annot'}{$annot_number}{'page_name'}" );
                    my $object_number     = $self->{'annot'}{$annot_number}{'object_info'}[0];
                    my $generation_number = $self->{'annot'}{$annot_number}{'object_info'}[1];
                    debug( 2, sprintf "object_number: $object_number, generation_number: $generation_number" );
                    $Annots .= sprintf( "%s %s R ", $object_number, $generation_number );
                }
                $$content{'Annots'} = $self->verbatim( $Annots . ']' ) if ($is_annots);
            }
        } else {
            my $kids = [];
            map { push @$kids, $self->indirect_ref(@$_) } @{ $page->kids };
            $$content{'Kids'}   = $self->array(@$kids);
            $$content{'Parent'} = $self->indirect_ref( @{ $page->{'Parent'}{'id'} } )
                if defined $page->{'Parent'};
            $$content{'Count'} = $self->number( $page->count );
        }
        $self->add_object( $self->indirect_obj( $self->dictionary(%$content), $name ) );
        $self->cr;
    }
}

sub add_crossrefsection {
    my ($self) = @_;

    debug( 2, "add_crossrefsection():" );

    # <cross-reference section> ::=
    #   xref
    # <cross-reference subsection>+
    $self->{'crossrefstartpoint'} = $self->position;
    $self->add('xref');
    $self->cr;
    confess "Fatal error: should contains at least one cross reference subsection."
        unless defined $self->{'crossrefsubsection'};
    for my $subsection ( sort keys %{ $self->{'crossrefsubsection'} } ) {
        $self->add_crossrefsubsection($subsection);
    }
}

sub add_crossrefsubsection {
    my ($self, $subsection) = @_;

    debug( 2, "add_crossrefsubsection():" );

    # <cross-reference subsection> ::=
    #   <object number of first entry in subsection>
    #   <number of entries in subsection>
    #   <cross-reference entry>+
    #
    # <cross-reference entry> ::= <in-use entry> | <free entry>
    #
    # <in-use entry> ::= <byte offset> <generation number> n <end-of-line>
    #
    # <end-of-line> ::= <space> <carriage return>
    #   | <space> <linefeed>
    #   | <carriage return> <linefeed>
    #
    # <free entry> ::=
    #   <object number of next free object>
    #   <generation number> f <end-of-line>

    $self->add( 0, ' ', 1 + scalar @{ $self->{'crossrefsubsection'}{$subsection} } );
    $self->cr;
    $self->add( sprintf "%010d %05d %s ", 0, 65535, 'f' );
    $self->cr;
    for my $entry ( sort { $$a[0] <=> $$b[0] } @{ $self->{'crossrefsubsection'}{$subsection} } ) {
        $self->add( sprintf "%010d %05d %s ", $$entry[1], $subsection, $$entry[2] ? 'n' : 'f' );

        # printf "%010d %010x %05d n\n", $$entry[1], $$entry[1], $subsection;
        $self->cr;
    }
}

sub add_trailer {
    my $self = shift;

    debug( 2, "add_trailer():" );

    # <trailer> ::= trailer
    #   <<
    #   <trailer key value pair>+
    #   >>
    #   startxref
    #   <cross-reference table start address>
    #   %%EOF

    my @keys = (
        'Size',   # integer (required)
        'Prev',   # integer (req only if more than one cross-ref section)
        'Root',   # dictionary (required)
        'Info',   # dictionary (optional)
        'ID',     # array (optional) (PDF 1.1)
        'Encrypt' # dictionary (req if encrypted) (PDF 1.1)
    );

    # TODO: should check for required fields
    $self->add('trailer');
    $self->cr;
    $self->add('<<');
    $self->cr;
    $self->{'trailer'}{'Size'} = 1;
    map { $self->{'trailer'}{'Size'} += scalar @{ $self->{'crossrefsubsection'}{$_} } } keys %{ $self->{'crossrefsubsection'} };
    $self->{'trailer'}{'Root'} = &encode( @{ $self->indirect_ref( @{ $self->{'catalog'} } ) } );
    $self->{'trailer'}{'Info'} = &encode( @{ $self->indirect_ref( @{ $self->{'info'} } ) } )
        if defined $self->{'info'};

    for my $k (@keys) {
        next unless defined $self->{'trailer'}{$k};
        $self->add( "/$k ",
                    ref $self->{'trailer'}{$k} eq 'ARRAY' ? join( ' ', @{ $self->{'trailer'}{$k} } ) : $self->{'trailer'}{$k} );
        $self->cr;
    }
    $self->add('>>');
    $self->cr;
    $self->add('startxref');
    $self->cr;
    $self->add( $self->{'crossrefstartpoint'} );
    $self->cr;
    $self->add('%%EOF');
    $self->cr;
}

sub cr {
    my ($self) = @_;

    debug( 3, "cr():" );
    $self->add( &encode('cr') );
}

sub page_stream {
    my ($self, $page) = @_;

    debug( 2, "page_stream():" );

    if (defined $self->{'reservations'}{'stream_length'}) {
        ## If it is the same page, use the same stream.
        $self->cr, return
            if defined $page
            && defined $self->{'stream_page'}
        && $page == $self->{'current_page'}
        && $self->{'stream_page'} == $page;

        # Remember the position
        my $len = $self->position - $self->{'stream_pos'} + 1;

        # Close the stream and the object
        $self->cr;
        $self->add('endstream');
        $self->cr;
        $self->add('endobj');
        $self->cr;
        $self->cr;

        # Add the length
        $self->add_object( $self->indirect_obj( $self->number($len), 'stream_length' ) );
        $self->cr;
    }

    # open a new stream if needed
    if (defined $page) {

        # get an object id for the stream
        my $obj = $self->reserve('stream');

        # release it
        delete $self->{'reservations'}{'stream'};

        # get another one for the length of this stream
        my $stream_length = $self->reserve('stream_length');
        push @$stream_length, 'R';
        push @{ $page->{'contents'} }, $obj;

        # write the beginning of the object
        push @{ $self->{'crossrefsubsection'}{ $$obj[1] } }, [ $$obj[0], $self->position, 1 ];
        $self->add("$$obj[0] $$obj[1] obj");
        $self->cr;
        $self->add('<<');
        $self->cr;
        $self->add( '/Length ', join( ' ', @$stream_length ) );
        $self->cr;
        $self->add('>>');
        $self->cr;
        $self->add('stream');
        $self->cr;
        $self->{'stream_pos'}  = $self->position;
        $self->{'stream_page'} = $page;
    }
}

=head2 get_data()

If you did not ask the $pdf object to write its output to a file, you can pick up
the  pdf  code  by calling this method. It returns a big string. You need to call
C<close> first.

=cut

sub get_data {
    shift->{'data'};
}

sub uses_font {
    my ($self, $page, $font) = @_;

    $page->{'resources'}{'fonts'}{$font} = 1;
    $page->{'resources'}{'ProcSet'} = [ 'PDF', 'Text' ];
    $self->{'fontobj'}{$font} = 1;
}

sub uses_xobject {
    my ($self, $page, $xobject) = @_;

    $page->{'resources'}{'xobjects'}{$xobject} = 1;
    $page->{'resources'}{'ProcSet'} = [ 'PDF', 'Text' ];
    $self->{'xobj'}{$xobject} = 1;
}

sub debug {
    my ($level, $msg) = @_;

    return unless ( $DEBUG >= $level );
    my $s = scalar @_ ? sprintf $msg, @_ : $msg;

    warn "DEBUG ($level): $s\n";
}

sub add {
    my $self = shift;
    my $data = join '', @_;

    $self->{'size'} += length $data;
    if ( defined $self->{'fh'} ) {
        my $fh = $self->{'fh'};
        print $fh $data;
    } else {
        $self->{'data'} .= $data;
    }
}

sub position {
    my ($self) = @_;

    $self->{'size'};
}

sub add_version {
    my ($self) = @_;

    debug( 2, "add_version(): $self->{'version'}" );
    $self->add( "%PDF-" . $self->{'version'} );
    $self->cr;
}

sub add_object {
    my ($self, $v) = @_;

    my $val = &encode(@$v);
    $self->add($val);
    $self->cr;
    debug( 3, "add_object(): $v -> $val" );
    [ $$v[1][0], $$v[1][1] ];
}

sub null {
    my ($self) = @_;;

    [ 'null', 'null' ];
}

sub boolean {
    my ($self, $val) = @_;

    [ 'boolean', $val ];
}

sub number {
    my ($self, $val) = @_;;

    [ 'number', $val ];
}

sub name {
    my ($self, $val) = @_;

    [ 'name', $val ];
}

sub string {
    my ($self, $val) = @_;

    [ 'string', $val ];
}

sub verbatim {
    my ($self, $val) = @_;

    [ 'verbatim', $val ];
}

sub array {
    my $self = shift;

    [ 'array', [@_] ];
}

sub dictionary {
    my $self = shift;

    [ 'dictionary', {@_} ];
}

sub indirect_obj {
    my $self = shift;

    my ($id, $gen, $type, $name);
    $name = $_[1];
    $type = $_[0][1]{'Type'}[1]
        if defined $_[0][1] && ref $_[0][1] eq 'HASH' && defined $_[0][1]{'Type'};

    if ( defined $name && defined $self->{'reservations'}{$name} ) {
        ( $id, $gen ) = @{ $self->{'reservations'}{$name} };
        delete $self->{'reservations'}{$name};
    } elsif ( defined $type && defined $self->{'reservations'}{$type} ) {
        ( $id, $gen ) = @{ $self->{'reservations'}{$type} };
        delete $self->{'reservations'}{$type};
    } else {
        $id  = ++$self->{'object_number'};
        $gen = $self->{'generation_number'};
    }
    debug( 3, "indirect_obj(): " . $self->position );
    push @{ $self->{'crossrefsubsection'}{$gen} }, [ $id, $self->position, 1 ];
    [ 'object', [ $id, $gen, @_ ] ];
}

sub indirect_ref {
    my $self = shift;

    [ 'ref', [@_] ];
}

sub stream {
    my $self = shift;

    [ 'stream', {@_} ];
}

sub add_info {
    my $self = shift;

    debug( 2, "add_info():" );
    my %params = @_;
    $params{'Author'}   = $self->{'Author'}   if defined $self->{'Author'};
    $params{'Creator'}  = $self->{'Creator'}  if defined $self->{'Creator'};
    $params{'Title'}    = $self->{'Title'}    if defined $self->{'Title'};
    $params{'Subject'}  = $self->{'Subject'}  if defined $self->{'Subject'};
    $params{'Keywords'} = $self->{'Keywords'} if defined $self->{'Keywords'};
    $params{'CreationDate'} = $self->{'CreationDate'}
    if defined $self->{'CreationDate'};

    $self->{'info'} = $self->reserve('Info');
    my $content = {
        'Producer' => $self->string("PDF::Create version $VERSION"),
        'Type'     => $self->name('Info')
    };
    $$content{'Author'} = $self->string( $params{'Author'} )
        if defined $params{'Author'};
    $$content{'Creator'} = $self->string( $params{'Creator'} )
        if defined $params{'Creator'};
    $$content{'Title'} = $self->string( $params{'Title'} )
        if defined $params{'Title'};
    $$content{'Subject'} = $self->string( $params{'Subject'} )
        if defined $params{'Subject'};
    $$content{'Keywords'} = $self->string( $params{'Keywords'} )
        if defined $params{'Keywords'};
    $$content{'CreationDate'} = $self->string( $params{'CreationDate'} )
        if defined $params{'CreationDate'};

    $self->add_object( $self->indirect_obj( $self->dictionary(%$content) ), 'Info' );
    $self->cr;
}

sub add_catalog {
    my $self = shift;

    debug( 2, "add_catalog" );
    my %params = %{ $self->{'catalog'} };

    # Type (mandatory)
    $self->{'catalog'} = $self->reserve('Catalog');
    my $content = { 'Type' => $self->name('Catalog') };

    # Pages (mandatory) [indirected reference]
    my $pages = $self->reserve('Pages');
    $$content{'Pages'} = $self->indirect_ref(@$pages);
    $self->{'pages'}{'id'} = $$content{'Pages'}[1];

    # Outlines [indirected reference]
    $$content{'Outlines'} = $self->indirect_ref( @{ $self->{'outlines'}->{'id'} } )
        if defined $self->{'outlines'};

    # PageMode
    $$content{'PageMode'} = $self->name($params{'PageMode'}) if defined $params{'PageMode'};

    $self->add_object( $self->indirect_obj( $self->dictionary(%$content) ) );
    $self->cr;
}

sub encode {
    my ($type, $val) = @_;

    if ($val) {
        debug( 4, "encode(): $type $val" );
    } else {
        debug( 4, "encode(): $type (no val)" );
    }

    if (!$type) {
        cluck "PDF::Create::encode: empty argument, called by ";
        return 1;
    }

    ( $type eq 'null' || $type eq 'number' ) && do {
        1; # do nothing
    }
    || $type eq 'cr' && do {
        $val = "\n";
    }
    || $type eq 'boolean' && do {
        $val =
            $val eq 'true'  ? $val
            : $val eq 'false' ? $val
            : $val eq '0'     ? 'false'
            :                   'true';
    }
    || $type eq 'verbatim' && do {
        $val = "$val";
    }
    || $type eq 'string' && do {
        $val = '' if not defined $val;
        # TODO: split it. Quote parentheses.
        $val = "($val)";
    }
    || $type eq 'number' && do {
        $val = "$val";
    }
    || $type eq 'name' && do {
        $val = '' if not defined $val;
        $val = "/$val";
    }
    || $type eq 'array' && do {

        # array, encode contents individually
        my $s = '[';
        for my $v (@$val) {
            $s .= &encode( $$v[0], $$v[1] ) . " ";
        }
        # remove the trailing space
        chop $s;
        $val = $s . "]";
    }
    || $type eq 'dictionary' && do {
        my $s = '<<' . &encode('cr');
        for my $v ( keys %$val ) {
            $s .= &encode( 'name',            $v ) . " ";
            $s .= &encode( ${ $$val{$v} }[0], ${ $$val{$v} }[1] );    #  . " ";
            $s .= &encode('cr');
        }
        $val = $s . ">>";
    }
    || $type eq 'object' && do {
        my $s = &encode( 'number', $$val[0] ) . " " . &encode( 'number', $$val[1] ) . " obj";
        $s .= &encode('cr');
        $s .= &encode( $$val[2][0], $$val[2][1] );                    #  . " ";
        $s .= &encode('cr');
        $val = $s . "endobj";
    }
    || $type eq 'ref' && do {
        my $s = &encode( 'number', $$val[0] ) . " " . &encode( 'number', $$val[1] ) . " R";
        $val = $s;
    }
    || $type eq 'stream' && do {
        my $data = delete $$val{'Data'};
        my $s    = '<<' . &encode('cr');
        for my $v ( keys %$val ) {
            $s .= &encode( 'name',            $v ) . " ";
            $s .= &encode( ${ $$val{$v} }[0], ${ $$val{$v} }[1] );    #  . " ";
            $s .= &encode('cr');
        }
        $s .= ">>" . &encode('cr') . "stream" . &encode('cr');
        $s .= $data . &encode('cr');
        $val = $s . "endstream" . &encode('cr');
    }
    || confess "Error: unknown type '$type'";

    # TODO: add type 'text';
    $val;
}

=head1 LIMITATIONS

C<PDF::Create> comes with a couple of limitations or known caveats:

=head2 PDF Size / Memory

Unless using a filehandle, C<PDF::Create> assembles the entire PDF in memory.
If you create very large documents on a machine with a small amount of memory
your program can fail because it runs out of memory. If using a filehandle,
data will be written immediately to the filehandle after each method.

=head2 Small GIF images

Some gif images get created with a minimal lzw code size of less than 8. C<PDF::Create>
can not decode those and they must be converted.

=head1 SUPPORT

I support C<PDF::Create> in my spare time between work and  family, so the amount
of work I put in is limited.

If you experience a problem make sure you are at the latest version first many of
things have already been fixed.

Please register  bug  at the CPAN bug tracking system at L<http://rt.cpan.org> or
send email to C<bug-PDF-Create [at] rt.cpan.org>

Be sure to include the following information:

=over 4

=item - PDF::Create Version you are running

=item - Perl version (perl -v)

=item - Operating System vendor and version

=item - Details about your operating environment that might be related to the issue
        being described

=item - Exact cut and pasted error or warning messages

=item - The shortest, clearest  code  you  can manage to write which reproduces the
        bug described.

=back

I  appreciate patches against the latest released version of C<PDF::Create> which
fix the bug.

B<Feature request> can be submitted like bugs. If you provide patch for a feature
which does not go against the C<PDF::Create> philosophy (keep it simple) then you
have a good chance for it to be accepted.

=head1 SEE ALSO

L<Adobe PDF|http://www.adobe.com/devnet/pdf/pdf_reference.html>

L<PDF::Labels> Routines to produce formatted pages of mailing labels in PDF, uses L<PDF::Create> internally.

L<PDF::Haru> Perl interface to Haru Free PDF Library.

L<PDF::EasyPDF> PDF creation from a one-file module, similar to L<PDF::Create>.

L<PDF::CreateSimple> Yet another PDF creation module

L<PDF::Report> A wrapper written for L<PDF::API2>.

=head1 AUTHORS

Fabien Tassin

GIF and JPEG-support: Michael Gross (info@mdgrosse.net)

Maintenance since 2007: Markus Baertschi (markus@markus.org)

Currently maintained by Mohammad S Anwar (MANWAR) C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/pdf-create>

=head1 COPYRIGHT

Copyright 1999-2001,Fabien Tassin.All rights reserved.It may be used and modified
freely, but I do  request that this copyright notice remain attached to the file.
You may modify this module as you wish,but if you redistribute a modified version
, please attach a note listing the modifications you have made.

Copyright 2007 Markus Baertschi

Copyright 2010 Gary Lieberman

=head1 LICENSE

This is free software; you can redistribute it and / or modify it under the same
terms as Perl 5.6.0.

=cut

1;
