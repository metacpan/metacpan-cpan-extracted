package PDF::Haru;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PDF::Haru ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'const' => [ qw(
HPDF_PAGE_SIZE_LETTER
HPDF_PAGE_SIZE_LEGAL
HPDF_PAGE_SIZE_A3
HPDF_PAGE_SIZE_A4
HPDF_PAGE_SIZE_A5
HPDF_PAGE_SIZE_B4
HPDF_PAGE_SIZE_B5
HPDF_PAGE_SIZE_EXECUTIVE
HPDF_PAGE_SIZE_US4x6
HPDF_PAGE_SIZE_US4x8
HPDF_PAGE_SIZE_US5x7
HPDF_PAGE_SIZE_COMM10

HPDF_PAGE_PORTRAIT 
HPDF_PAGE_LANDSCAPE

HPDF_PAGE_LAYOUT_SINGLE
HPDF_PAGE_LAYOUT_ONE_COLUMN
HPDF_PAGE_LAYOUT_TWO_COLUMN_LEFT
HPDF_PAGE_LAYOUT_TWO_COLUMN_RIGHT

HPDF_PAGE_MODE_USE_NONE
HPDF_PAGE_MODE_USE_OUTLINE
HPDF_PAGE_MODE_USE_THUMBS
HPDF_PAGE_MODE_FULL_SCREEN

HPDF_TRUE
HPDF_FALSE

HPDF_PAGE_NUM_STYLE_DECIMAL
HPDF_PAGE_NUM_STYLE_UPPER_ROMAN
HPDF_PAGE_NUM_STYLE_LOWER_ROMAN
HPDF_PAGE_NUM_STYLE_UPPER_LETTERS
HPDF_PAGE_NUM_STYLE_LOWER_LETTERS

HPDF_INFO_CREATION_DATE
HPDF_INFO_MOD_DATE
HPDF_INFO_AUTHOR
HPDF_INFO_CREATOR
HPDF_INFO_TITLE
HPDF_INFO_SUBJECT
HPDF_INFO_KEYWORDS
HPDF_INFO_PRODUCER

HPDF_ENABLE_READ
HPDF_ENABLE_PRINT
HPDF_ENABLE_EDIT_ALL
HPDF_ENABLE_COPY
HPDF_ENABLE_EDIT

HPDF_ENCRYPT_R2
HPDF_ENCRYPT_R3

HPDF_COMP_NONE
HPDF_COMP_TEXT
HPDF_COMP_IMAGE
HPDF_COMP_METADATA
HPDF_COMP_ALL

HPDF_BUTT_END
HPDF_ROUND_END
HPDF_PROJECTING_SCUARE_END

HPDF_MITER_JOIN
HPDF_ROUND_JOIN
HPDF_BEVEL_JOIN
		
HPDF_FILL
HPDF_STROKE
HPDF_FILL_THEN_STROKE
HPDF_INVISIBLE
HPDF_FILL_CLIPPING
HPDF_STROKE_CLIPPING
HPDF_FILL_STROKE_CLIPPING
HPDF_CLIPPING
		
HPDF_TALIGN_LEFT
HPDF_TALIGN_RIGHT
HPDF_TALIGN_CENTER
HPDF_TALIGN_JUSTIFY

HPDF_BM_NORMAL
HPDF_BM_MULTIPLY
HPDF_BM_SCREEN
HPDF_BM_OVERLAY
HPDF_BM_DARKEN
HPDF_BM_LIGHTEN
HPDF_BM_COLOR_DODGE
HPDF_BM_COLOR_BUM
HPDF_BM_HARD_LIGHT
HPDF_BM_SOFT_LIGHT
HPDF_BM_DIFFERENCE
HPDF_BM_EXCLUSHON

HPDF_CS_DEVICE_GRAY
HPDF_CS_DEVICE_RGB
HPDF_CS_DEVICE_CMYK
HPDF_CS_CAL_GRAY
HPDF_CS_CAL_RGB
HPDF_CS_LAB
HPDF_CS_ICC_BASED
HPDF_CS_SEPARATION
HPDF_CS_DEVICE_N
HPDF_CS_INDEXED
HPDF_CS_PATTERN

HPDF_TS_WIPE_RIGHT
HPDF_TS_WIPE_UP
HPDF_TS_WIPE_LEFT
HPDF_TS_WIPE_DOWN
HPDF_TS_BARN_DOORS_HORIZONTAL_OUT
HPDF_TS_BARN_DOORS_HORIZONTAL_IN
HPDF_TS_BARN_DOORS_VERTICAL_OUT
HPDF_TS_BARN_DOORS_VERTICAL_IN
HPDF_TS_BOX_OUT
HPDF_TS_BOX_IN
HPDF_TS_BLINDS_HORIZONTAL
HPDF_TS_BLINDS_VERTICAL
HPDF_TS_DISSOLVE
HPDF_TS_GLITTER_RIGHT
HPDF_TS_GLITTER_DOWN
HPDF_TS_GLITTER_TOP_LEFT_TO_BOTTOM_RIGHT
HPDF_TS_REPLACE

HPDF_ANNOT_NO_HIGHTLIGHT
HPDF_ANNOT_INVERT_BOX
HPDF_ANNOT_INVERT_BORDER
HPDF_ANNOT_DOWN_APPEARANCE

HPDF_ANNOT_ICON_COMMENT
HPDF_ANNOT_ICON_KEY
HPDF_ANNOT_ICON_NOTE
HPDF_ANNOT_ICON_HELP
HPDF_ANNOT_ICON_NEW_PARAGRAPH
HPDF_ANNOT_ICON_PARAGRAPH
HPDF_ANNOT_ICON_INSERT 

HPDF_BS_SOLID
HPDF_BS_DASHED
HPDF_BS_BEVELED
HPDF_BS_INSET
HPDF_BS_UNDERLINED	
) ] );

our @EXPORT_OK = ();

our @EXPORT = ( @{ $EXPORT_TAGS{'const'} } );

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('PDF::Haru', $VERSION);

# Preloaded methods go here.

use constant {

HPDF_PAGE_SIZE_LETTER => 0,
HPDF_PAGE_SIZE_LEGAL => 1,
HPDF_PAGE_SIZE_A3 => 2,
HPDF_PAGE_SIZE_A4 => 3,
HPDF_PAGE_SIZE_A5 => 4,
HPDF_PAGE_SIZE_B4 => 5,
HPDF_PAGE_SIZE_B5 => 6,
HPDF_PAGE_SIZE_EXECUTIVE => 7,
HPDF_PAGE_SIZE_US4x6 => 8,
HPDF_PAGE_SIZE_US4x8 => 9,
HPDF_PAGE_SIZE_US5x7 => 10,
HPDF_PAGE_SIZE_COMM10 => 11,

HPDF_PAGE_PORTRAIT => 0,
HPDF_PAGE_LANDSCAPE => 1,

HPDF_PAGE_LAYOUT_SINGLE => 0,
HPDF_PAGE_LAYOUT_ONE_COLUMN => 1,
HPDF_PAGE_LAYOUT_TWO_COLUMN_LEFT => 2,
HPDF_PAGE_LAYOUT_TWO_COLUMN_RIGHT => 3,

HPDF_PAGE_MODE_USE_NONE => 0,
HPDF_PAGE_MODE_USE_OUTLINE => 1,
HPDF_PAGE_MODE_USE_THUMBS => 2,
HPDF_PAGE_MODE_FULL_SCREEN => 3,

HPDF_TRUE => 1,
HPDF_FALSE => 0,

HPDF_PAGE_NUM_STYLE_DECIMAL => 0,
HPDF_PAGE_NUM_STYLE_UPPER_ROMAN => 1,
HPDF_PAGE_NUM_STYLE_LOWER_ROMAN => 2,
HPDF_PAGE_NUM_STYLE_UPPER_LETTERS => 3,
HPDF_PAGE_NUM_STYLE_LOWER_LETTERS => 4,

HPDF_INFO_CREATION_DATE => 0,
HPDF_INFO_MOD_DATE => 1,
HPDF_INFO_AUTHOR => 2,
HPDF_INFO_CREATOR => 3,
HPDF_INFO_PRODUCER => 4,
HPDF_INFO_TITLE => 5,
HPDF_INFO_SUBJECT => 6,
HPDF_INFO_KEYWORDS => 7,

HPDF_ENABLE_READ => 0,
HPDF_ENABLE_PRINT => 4,
HPDF_ENABLE_EDIT_ALL => 8,
HPDF_ENABLE_COPY => 16,
HPDF_ENABLE_EDIT => 32,

HPDF_ENCRYPT_R2 => 2,
HPDF_ENCRYPT_R3 => 3,

HPDF_COMP_NONE => 0x00,
HPDF_COMP_TEXT => 0x01,
HPDF_COMP_IMAGE => 0x02,
HPDF_COMP_METADATA => 0x04,
HPDF_COMP_ALL => 0x0F,

HPDF_BUTT_END => 0,
HPDF_ROUND_END => 1,
HPDF_PROJECTING_SCUARE_END => 2,

HPDF_MITER_JOIN => 0,
HPDF_ROUND_JOIN => 1,
HPDF_BEVEL_JOIN => 2,
		
HPDF_FILL => 0,
HPDF_STROKE => 1,
HPDF_FILL_THEN_STROKE => 2,
HPDF_INVISIBLE => 3,
HPDF_FILL_CLIPPING => 4,
HPDF_STROKE_CLIPPING => 5,
HPDF_FILL_STROKE_CLIPPING => 6,
HPDF_CLIPPING => 7,
		
HPDF_TALIGN_LEFT => 0,
HPDF_TALIGN_RIGHT => 1,
HPDF_TALIGN_CENTER => 2,
HPDF_TALIGN_JUSTIFY => 3,

HPDF_BM_NORMAL => 0,
HPDF_BM_MULTIPLY => 1,
HPDF_BM_SCREEN => 2,
HPDF_BM_OVERLAY => 3,
HPDF_BM_DARKEN => 4,
HPDF_BM_LIGHTEN => 5,
HPDF_BM_COLOR_DODGE => 6,
HPDF_BM_COLOR_BUM => 7,
HPDF_BM_HARD_LIGHT => 8,
HPDF_BM_SOFT_LIGHT => 9,
HPDF_BM_DIFFERENCE => 10,
HPDF_BM_EXCLUSHON => 11,

HPDF_CS_DEVICE_GRAY => 0,
HPDF_CS_DEVICE_RGB => 1,
HPDF_CS_DEVICE_CMYK => 2,
HPDF_CS_CAL_GRAY => 3,
HPDF_CS_CAL_RGB => 4,
HPDF_CS_LAB => 5,
HPDF_CS_ICC_BASED => 6,
HPDF_CS_SEPARATION => 7,
HPDF_CS_DEVICE_N => 8,
HPDF_CS_INDEXED => 9,
HPDF_CS_PATTERN => 10,

HPDF_TS_WIPE_RIGHT => 0,
HPDF_TS_WIPE_UP => 1,
HPDF_TS_WIPE_LEFT => 2,
HPDF_TS_WIPE_DOWN => 3,
HPDF_TS_BARN_DOORS_HORIZONTAL_OUT => 4,
HPDF_TS_BARN_DOORS_HORIZONTAL_IN => 5,
HPDF_TS_BARN_DOORS_VERTICAL_OUT => 6,
HPDF_TS_BARN_DOORS_VERTICAL_IN => 7,
HPDF_TS_BOX_OUT => 8,
HPDF_TS_BOX_IN => 9,
HPDF_TS_BLINDS_HORIZONTAL => 10,
HPDF_TS_BLINDS_VERTICAL => 11,
HPDF_TS_DISSOLVE => 12,
HPDF_TS_GLITTER_RIGHT => 13,
HPDF_TS_GLITTER_DOWN => 14,
HPDF_TS_GLITTER_TOP_LEFT_TO_BOTTOM_RIGHT => 15,
HPDF_TS_REPLACE => 16,

HPDF_ANNOT_NO_HIGHTLIGHT => 0,
HPDF_ANNOT_INVERT_BOX => 1,
HPDF_ANNOT_INVERT_BORDER => 2,
HPDF_ANNOT_DOWN_APPEARANCE => 3,

HPDF_ANNOT_ICON_COMMENT => 0,
HPDF_ANNOT_ICON_KEY => 1,
HPDF_ANNOT_ICON_NOTE => 2,
HPDF_ANNOT_ICON_HELP => 3,
HPDF_ANNOT_ICON_NEW_PARAGRAPH => 4,
HPDF_ANNOT_ICON_PARAGRAPH => 5,
HPDF_ANNOT_ICON_INSERT  => 6,

HPDF_BS_SOLID => 0,
HPDF_BS_DASHED => 1,
HPDF_BS_BEVELED => 2,
HPDF_BS_INSET => 3,
HPDF_BS_UNDERLINED  => 4,

};

my %errors_list = (
0x1001 => 'Internal error. Data consistency was lost',
0x1002 => 'Internal error. Data consistency was lost',
0x1003 => 'Internal error. Data consistency was lost',
0x1004 => 'Data length > HPDF_LIMIT_MAX_STRING_LEN',
0x1005 => 'Cannot get pallet data from PNG image',
0x1007 => 'Dictionary elements > HPDF_LIMIT_MAX_DICT_ELEMENT',
0x1008 => 'Internal error. Data consistency was lost',
0x1009 => 'Internal error. Data consistency was lost',
0x100A => 'Internal error. Data consistency was lost',
0x100B => 'SetEncryptMode() or SetPermission() called before password set',
0x100C => 'Internal error. Data consistency was lost',
0x100E => 'Tried to re-register a registered font',
0x100F => 'Cannot register a character to the Japanese word wrap characters list',
0x1011 => '1. Tried to set the owner password to undef. 2. Owner and user password are the same',
0x1013 => 'Internal error. Data consistency was lost',
0x1014 => 'Stack depth > HPDF_LIMIT_MAX_GSTATE',
0x1015 => 'Memory allocation failed',
0x1016 => 'File processing failed',
0x1017 => 'Cannot open a file',
0x1019 => 'Tried to load a font that has been registered',
0x101A => '1. Font-file format is invalid',
0x101B => 'Cannot recognize header of afm file',
0x101C => 'Specified annotation handle is invalid',
0x101E => 'Bit-per-component of a image which was set as mask-image is invalid',
0x101F => 'Cannot recognize char-matrics-data of afm file',
0x1020 => '1. Invalid color_space parameter of LoadRawImage. 2. Color-space of a image which was set as mask-image is invalid. 3. Invoked function invalid in present color-space',
0x1021 => 'Invalid value set when invoking SetCommpressionMode()',
0x1022 => 'An invalid date-time value was set',
0x1023 => 'An invalid destination handle was set',
0x1025 => 'An invalid document handle was set',
0x1026 => 'Function invalid in the present state was invoked',
0x1027 => 'An invalid encoder handle was set',
0x1028 => 'Combination between font and encoder is wrong',
0x102B => 'An Invalid encoding name is specified',
0x102C => 'Encryption key length is invalid',
0x102D => '1. An invalid font handle was set. 2. Unsupported font format',
0x102E => 'Internal error. Data consistency was lost',
0x102F => 'Font with the specified name is not found',
0x1030 => 'Unsupported image format',
0x1031 => 'Unsupported image format',
0x1032 => 'Cannot read a postscript-name from an afm file',
0x1033 => '1. An invalid object is set. 2. Internal error. Data consistency was lost',
0x1034 => 'Internal error. Data consistency was lost',
0x1035 => 'Invoked HPDF_Image_SetColorMask() against the image-object which was set a mask-image',
0x1036 => 'An invalid outline-handle was specified',
0x1037 => 'An invalid page-handle was specified',
0x1038 => 'An invalid pages-handle was specified (internal error)',
0x1039 => 'An invalid value is set',
0x103B => 'Invalid PNG image format',
0x103C => 'Internal error. Data consistency was lost',
0x103D => 'Internal error. "_FILE_NAME" entry for delayed loading is missing',
0x103F => 'Invalid .TTC file format',
0x1040 => 'Index parameter > number of included fonts',
0x1041 => 'Cannot read a width-data from an afm file',
0x1042 => 'Internal error. Data consistency was lost',
0x1043 => 'Error returned from PNGLIB while loading image',
0x1044 => 'Internal error. Data consistency was lost',
0x1045 => 'Internal error. Data consistency was lost',
0x1049 => 'Internal error. Data consistency was lost',
0x104A => 'Internal error. Data consistency was lost',
0x104B => 'Internal error. Data consistency was lost',
0x104C => 'There are no graphics-states to be restored',
0x104D => 'Internal error. Data consistency was lost',
0x104E => 'The current font is not set',
0x104F => 'An invalid font-handle was specified',
0x1050 => 'An invalid font-size was set',
0x1051 => 'See Graphics mode',
0x1052 => 'Internal error. Data consistency was lost',
0x1053 => 'Specified value is not multiple of 90',
0x1054 => 'An invalid page-size was set',
0x1055 => 'An invalid image-handle was set',
0x1056 => 'The specified value is out of range',
0x1057 => 'The specified value is out of range',
0x1058 => 'Unexpected EOF marker was detected',
0x1059 => 'Internal error. Data consistency was lost',
0x105B => 'The length of the text is too long',
0x105C => 'Function not executed because of other errors',
0x105D => 'Font cannot be embedded (license restriction)',
0x105E => 'Unsupported ttf format (cannot find unicode cmap)',
0x105F => 'Unsupported ttf format',
0x1060 => 'Unsupported ttf format (cannot find a necessary table)',
0x1061 => 'Internal error. Data consistency was lost',
0x1062 => '1. Library not configured to use PNGLIB. 2. Internal error. Data consistency was lost',
0x1063 => 'Unsupported JPEG format',
0x1064 => 'Failed to parse .PFB file',
0x1065 => 'Internal error. Data consistency was lost',
0x1066 => 'Error while executing ZLIB function',
0x1067 => 'An error returned from Zlib',
0x1068 => 'An invalid URI was set',
0x1069 => 'An invalid page-layout was set',
0x1070 => 'An invalid page-mode was set',
0x1071 => 'An invalid page-num-style was set',
0x1072 => 'An invalid icon was set',
0x1073 => 'An invalid border-style was set',
0x1074 => 'An invalid page-direction was set',
0x1075 => 'An invalid font-handle was specified',
);

sub _ErrorHandler {
	croak($errors_list{$_[0]} || 'libharu error no '.$_[0]);
}

1;

__END__

=head1 NAME

PDF::Haru - Perl interface to Haru Free PDF Library. Haru is a free, cross platform, open-sourced software library for generating PDF.

=head1 SYNOPSIS

	use PDF::Haru;

	# create new document
	my $pdf = PDF::Haru::New();

	# add page
	my $page = $pdf->AddPage();

	# set page size and orientation
	$page->SetSize(HPDF_PAGE_SIZE_A4, HPDF_PAGE_PORTRAIT);

	my $font = $pdf->GetFont("Helvetica", "StandardEncoding");
	$page->BeginText();
	$page->SetFontAndSize($font, 20);
	$page->TextOut(40, 781, "text");
	$page->EndText();

	$page->Rectangle (30, 30, $page->GetWidth() - 60, $page->GetHeight() - 60);
	$page->Stroke();

	# save the document to a file
	$pdf->SaveToFile("filename.pdf");

	# cleanup
	$pdf->Free();

=head1 METHODS

=head2 B<my $pdf = PDF::Haru::New()>

Create an instance of a document object and initialize it. 

=head2 B<$pdf-E<gt>Free()>

Revokes a document object and all resources. 

=head2 B<$pdf-E<gt>NewDoc()>

Creates new document. If document object already has a document, the current document is revoked.

=head2 B<$pdf-E<gt>FreeDoc()>

Revokes the current document. 
Keeps loaded resource (such as fonts and encodings) and these resources 
are recycled when new document required these resources. 

=head2 B<$pdf-E<gt>FreeDocAll()>

Revokes the current document and all resources.

=head2 B<$pdf-E<gt>SaveToFile("filename.pdf")>

Saves the current document to a file.

=head2 B<$pdf-E<gt>SaveAsString()>

Returns PDF document as string.

=head2 B<$pdf-E<gt>SetPagesConfiguration($page_per_pages)>

In the default setting, a PDF::Haru object has one "Pages" object as root of pages. All "Page" objects are 
created as a kid of the "Pages" object.
Since a "Pages" object can own only 8191 kids objects, the maximum number of pages are 8191 page.

Additionally, the state that there are a lot of  "Page" object under one "Pages" object is not good, 
because it causes performance degradation of  a viewer application.

An application can change the setting of a pages tree by invoking SetPagesConfiguration(). 
If $page_per_pages parameter is set to more than zero, a two-tier pages tree is created. 
A root "Pages" object can own 8191 "Pages" object, and each lower "Pages" object can own 
$page_per_pages "Page" objects. As a result, the maximum number of pages becomes 8191 * $page_per_pages page.

An application cannot invoke SetPageConfiguration() after a page is added to document.

=head2 B<$pdf-E<gt>SetPageLayout(layout)>

Sets how the page should be displayed. If this attribute is not set, the setting of a viewer application is used.

B<layout> is one of following constants

=over 4

=item HPDF_PAGE_LAYOUT_SINGLE

Only one page is displayed.

=item HPDF_PAGE_LAYOUT_ONE_COLUMN

Display the pages in one column.

=item HPDF_PAGE_LAYOUT_TWO_COLUMN_LEFT

Display the pages in two column. The page of the odd number is displayed left. 

=item HPDF_PAGE_LAYOUT_TWO_COLUMN_RIGHT

Display the pages in two column. The page of the odd number is displayed right. 

=item Example:

$pdf-E<gt>SetPageLayout(HPDF_PAGE_LAYOUT_ONE_COLUMN)

=back

=head2 B<$pdf-E<gt>GetPageLayout()>

Returns the current setting for page layout.

=head2 B<$pdf-E<gt>SetPageMode(mode)>

Sets how the document should be displayed. 

B<mode> is one of following constants

=over 4

=item HPDF_PAGE_MODE_USE_NONE

Display the document with neither outline nor thumbnail.

=item HPDF_PAGE_MODE_USE_OUTLINE

Display the document with outline pain.

=item HPDF_PAGE_MODE_USE_THUMBS

Display the document with thumbnail pain.

=item HPDF_PAGE_MODE_FULL_SCREEN

Display the document with full screen mode. 

=item Example:

$pdf-E<gt>SetPageMode(HPDF_PAGE_MODE_FULL_SCREEN)

=back

=head2 B<$pdf-E<gt>GetPageLayout()>

Returns the current setting for page mode.

=head2 B<$pdf-E<gt>SetOpenAction($destination)>

Set the first page appears when a document is opened. B<$destination> 
is a destination object created by $page-E<gt>CreateDestination() function.

=head2 B<my $page = $pdf-E<gt>GetCurrentPage()>

Returns the handle of current page object.

=head2 B<my $page = $pdf-E<gt>AddPage()>

Creates a new page and adds it after the last page of a document. 

=head2 B<my $page = $pdf-E<gt>InsertPage($target)>

Creates a new page and inserts it just B<before> the specified page. 

=head2 B<$pdf-E<gt>LoadType1FontFromFile($afmfilename, $pfmfilename)>

Loads a type1 font from an external file and register it to a document object. Returns the name of a font.

=over

=item $afmfilename

A path of an AFM file.

=item $pfmfilename

A path of a PFA/PFB file. If it is I<undef>, the gryph data of font file is not embedded to a PDF file.

=back

=head2 B<$pdf-E<gt>LoadTTFontFromFile ($file_name, embedding)>

Loads a TrueType font from an external file and register it to a document object. Returns the name of a font.

=over

=item $file_name

A path of a TrueType font file (.ttf). 

=item embedding

If this parameter is set to HPDF_TRUE, the glyph data of the font is embedded, otherwise only the matrix data is included in PDF file.

=back

=head2 B<$pdf-E<gt>LoadTTFontFromFile2 ($file_name, $index, embedding)>

Loads a TrueType font from an TrueType collection file and register it to a document object. Returns the name of a font.

=over

=item $file_name

A path of a TrueType font collection file (.ttc). 

=item $index

The index of font that wants to be loaded. 

=item embedding

If this parameter is set to HPDF_TRUE, the glyph data of the font is embedded, otherwise only the matrix data is included in PDF file.

=back

=head2 B<$pdf-E<gt>AddPageLabel($page_num, style, $first_page, $prefix)>

Adds a page labeling range for the document.

=over

=item $page_num

The first page that applies this labeling range. 

=item style

The numbering style:

=over

=item HPDF_PAGE_NUM_STYLE_DECIMAL

Page label is displayed by Arabic numerals.

=item HPDF_PAGE_NUM_STYLE_UPPER_ROMAN

Page label is displayed by Uppercase roman numerals.

=item HPDF_PAGE_NUM_STYLE_LOWER_ROMAN

Page label is displayed by Lowercase roman numerals.

=item HPDF_PAGE_NUM_STYLE_UPPER_LETTERS

Page label is displayed by Uppercase letters (using A to Z).

=item HPDF_PAGE_NUM_STYLE_LOWER_LETTERS

Page label is displayed by Lowercase letters (using a to z).

=back

=item $first_page

The first page number in this range.

=item $prefix

The prefix for the page label.

=back

=head2 B<my $font = $pdf-E<gt>GetFont($font_name, $encoding_name)>

Gets the handle of a corresponding font object by specified name and encoding.

=head2 B<$pdf-E<gt>UseJPFonts()>

Enables Japanese fonts. After UseJPFonts() is involed, an application can use the following Japanese fonts.

    * MS-Mincyo
    * MS-Mincyo,Bold
    * MS-Mincyo,Italic
    * MS-Mincyo,BoldItalic
    * MS-Gothic
    * MS-Gothic,Bold
    * MS-Gothic,Italic
    * MS-Gothic,BoldItalic
    * MS-PMincyo
    * MS-PMincyo,Bold
    * MS-PMincyo,Italic
    * MS-PMincyo,BoldItalic
    * MS-PGothic
    * MS-PGothic,Bold
    * MS-PGothic,Italic
    * MS-PGothic,BoldItalic

=head2 B<$pdf-E<gt>UseKRFonts()>

Enables Korean fonts. After UseKRFonts() is involed, an application can use the following Korean fonts.

    * DotumChe
    * DotumChe,Bold
    * DotumChe,Italic
    * DotumChe,BoldItalic
    * Dotum
    * Dotum,Bold
    * Dotum,Italic
    * Dotum,BoldItalic
    * BatangChe
    * BatangChe,Bold
    * BatangChe,Italic
    * BatangChe,BoldItalic
    * Batang
    * Batang,Bold
    * Batang,Italic
    * Batang,BoldItalic

=head2 B<$pdf-E<gt>UseCNSFonts()>

Enables simplified Chinese fonts. After UseCNSFonts() is involed, an application can use the following simplified Chinese fonts.

    * SimSun
    * SimSun,Bold
    * SimSun,Italic
    * SimSun,BoldItalic
    * SimHei
    * SimHei,Bold
    * SimHei,Italic
    * SimHei,BoldItalic

=head2 B<$pdf-E<gt>UseCNTFonts()>

Enables traditional Chinese fonts. After UseCNTFonts() is involed, an application can use the following traditional Chinese fonts.

    * MingLiU
    * MingLiU,Bold
    * MingLiU,Italic
    * MingLiU,BoldItalic

=head2 B<my $encoder = $pdf-E<gt>GetEncoder($encoding_name)>

Gets the handle of a corresponding encoder object by specified encoding name. 

=head2 B<my $encoder = $pdf-E<gt>GetCurrentEncoder()>

Gets the handle of the current encoder of the document object. The current encoder is set by invoking B<SetCurrentEncoder()> and it is used to processing a text when an application invoks B<Info_SetInfoAttr()>. The default value of it is undef. 

=head2 B<$pdf-E<gt>SetCurrentEncoder($encoding_name)>

Sets the current encoder for the document.

=head2 B<$pdf-E<gt>UseJPEncodings()>

Enables Japanese encodings. After UseJPEncodings() is involed, an application can use the following Japanese encodings.

    * 90ms-RKSJ-H
    * 90ms-RKSJ-V
    * 90msp-RKSJ-H
    * EUC-H
    * EUC-V

=head2 B<$pdf-E<gt>UseKREncodings()>

Enables Korean encodings. After UseKREncodings() is involed, an application can use the following Korean encodings.

    * KSC-EUC-H
    * KSC-EUC-V
    * KSCms-UHC-H
    * KSCms-UHC-HW-H
    * KSCms-UHC-HW-V

=head2 B<$pdf-E<gt>UseCNSEncodings()>

Enables simplified Chinese encodings. After UseCNSEncodings() is involed, an application can use the following simplified Chinese encodings.

    * GB-EUC-H
    * GB-EUC-V
    * GBK-EUC-H
    * GBK-EUC-V

=head2 B<$pdf-E<gt>UseCNTEncodings()>

Enables traditional Chinese encodings. After UseCNTEncodings() is involed, an application can use the following traditional Chinese encodings.

    * GB-EUC-H
    * GB-EUC-V
    * GBK-EUC-H
    * GBK-EUC-V

=head2 B<my $outline = $pdf-E<gt>CreateOutline($parent,$title,$encoder)>

Creates a new outline object. 

=over

=item $parent

The handle of an outline object which comes to the parent of the created outline object. If undef, the outline is created as a root outline.

=item $title

The caption of the outline object.

=item $encoder

The handle of an encoding object applied to the title. If undef, PDFDocEncoding is used. 

=back

=head2 B<my $image = $pdf-E<gt>LoadPngImageFromFile($filename)>

Loads an external png image file and returns image object.

=head2 B<my $image = $pdf-E<gt>LoadPngImageFromFile2($filename)>

Loads an external png image file and returns image object.
Unlike  LoadPngImageFromFile(),  LoadPngImageFromFile2() does not load whole data immediately. (only size and color properties is loaded).
The main data is loaded just before the image object is written to PDF, and the loaded data is deleted immediately. 

=head2 B<my $image = $pdf-E<gt>LoadJpegImageFromFile($filename)>

Loads an external Jpeg image file and returns image object.

=head2 B<$pdf-E<gt>SetInfoAttr (type, $value)>

SetInfoAttr() sets the text of the info dictionary. SetInfoAttr() uses the current encoding of the document.

=over

=item type

The following values are available.

    HPDF_INFO_AUTHOR
    HPDF_INFO_CREATOR
    HPDF_INFO_TITLE
    HPDF_INFO_SUBJECT
    HPDF_INFO_KEYWORDS

=item $value

A text to set the infomation. 

=back

=head2 B<$pdf-E<gt>GetInfoAttr (type)>

Gets an attribute value from info dictionary. 

=over

=item type

The following values are available.

    HPDF_INFO_CREATION_DATE
    HPDF_INFO_MOD_DATE
    HPDF_INFO_AUTHOR
    HPDF_INFO_CREATOR
    HPDF_INFO_TITLE
    HPDF_INFO_SUBJECT
    HPDF_INFO_KEYWORDS 

=back

=head2 B<$pdf-E<gt>SetInfoDateAttr(type,$year,$month,$day,$hour,$minutes,$seconds,$ind,$off_hour,$off_minutes)>

Sets a datetime attribute in the info dictionary. 

=over

=item type

One of the following attributes:

    HPDF_INFO_CREATION_DATE
    HPDF_INFO_MOD_DATE 

=item $year,$month,$day,$hour,$minutes,$seconds,$ind,$off_hour,$off_minutes

The new value for the attribute. 

	$year 	
	$month 	Between 1 and 12.
	$day 	Between 1 and 28, 29, 30, or 31. (Depends on the month.)
	$hour 	0 to 23
	$minutes 	0 to 59
	$seconds 	0 to 59
	$ind 	Relationship of local time to Universal Time (" ", +, −, or Z).
	$off_hour 	If "ind" is not space, 0 to 23 is valid. Otherwise, ignored.
	$off_minutes 	If "ind" is not space, 0 to 59 is valid. Otherwise, ignored. 

=back

=head2 B<$pdf-E<gt>SetPassword  ($owner_passwd, $user_passwd)>

Sets the pasword for the document.
If the password is set, contents in the document are encrypted.

=over

=item $owner_password

The password for the owner of the document. The owner can change the permission of the document.
Zero length string and the same value as user password are not allowed. 

=item $user_password

The password for the user of the document. The B<$user_password> is allowed to be set to zero length string.

=back

=head2 B<$pdf-E<gt>SetPermission(permission)>

Set the flags of the permission for the document.

B<permission> flags specifying which operations are permitted. This parameter is set by logical addition of the following values.

=over

=item HPDF_ENABLE_READ

user can read the document.

=item HPDF_ENABLE_PRINT

user can print the document.

=item HPDF_ENABLE_EDIT_ALL

user can edit the contents of the document other than annotations, form fields.

=item HPDF_ENABLE_COPY

user can copy the text and the graphics of the document.

=item HPDF_ENABLE_EDIT

user can add or modify the annotations and form fields of the document.

=item Example:

$pdf-E<gt>SetPermission(PDF_ENABLE_READ+PDF_ENABLE_PRINT)

=back

=head2 B<$pdf-E<gt>SetEncryptionMode(mode, $key_len)>

Set the type of encryption.
As the side effect, SetEncryptionMode() ups the version of PDF to 1.4 when the mode is set to PDF_ENCRYPT_R3.

=over

=item mode

The flags specifying which operations are permitted. This parameter is set by logical addition of the following values.

=over

=item HPDF_ENCRYPT_R2

Use "Revision 2" algorithm.
The length of key is automatically set to 5(40bit).

=item HPDF_ENCRYPT_R3

Use "Revision 3" algorithm.
Between 5(40bit) and 16(128bit) can be specified for length of the key.

=back

=item $key_len

Specify the byte length of an encryption key. This parameter is valid only when "mode" parameter is set to PDF_ENCRYPT_R3.
Between 5(40bit) and 16(128bit) can be specified for length of the key.

=back

=head2 B<$pdf-E<gt>SetCompressionMode(mode)>

B<mode> flags specifying which type of contents should be compressed. 

=over

=item HPDF_COMP_NONE

All contents are not compressed. 

=item HPDF_COMP_TEXT

Compress the contents stream of the page.  

=item HPDF_COMP_IMAGE

Compress the streams of the image objects.  

=item HPDF_COMP_METADATA

Other stream datas (fonts, cmaps and so on)  are compressed.

=item HPDF_COMP_ALL

All stream datas are compressed. (The same as "PDF_COMP_TEXT + PDF_COMP_IMAGE + PDF_COMP_METADATA")

=item Example:

$pdf-E<gt>SetCompressionMode(PDF_COMP_TEXT+PDF_COMP_METADATA)

=back

=head2 B<$page-E<gt>SetWidth($value)>

Changes the width of a page. The valid value is between 3 and 14400.

=head2 B<$page-E<gt>SetHeight($value)>

Changes the height of a page. The valid value is between 3 and 14400.

=head2 B<$page-E<gt>SetSize(size, direction)>

Changes the size and direction of a page to a predefined size.

=over

=item size

Specify a predefined page-size value. The following values are available.

	HPDF_PAGE_SIZE_LETTER
	HPDF_PAGE_SIZE_LEGAL
	HPDF_PAGE_SIZE_A3
	HPDF_PAGE_SIZE_A4
	HPDF_PAGE_SIZE_A5
	HPDF_PAGE_SIZE_B4
	HPDF_PAGE_SIZE_B5
	HPDF_PAGE_SIZE_EXECUTIVE
	HPDF_PAGE_SIZE_US4x6
	HPDF_PAGE_SIZE_US4x8
	HPDF_PAGE_SIZE_US5x7
	HPDF_PAGE_SIZE_COMM10

=item direction

Specify the direction of the page.

	HPDF_PAGE_PORTRAIT
	HPDF_PAGE_LANDSCAPE

=back

=head2 B<$page-E<gt>SetRotate($angle)>

Sets rotation angle of the page. Angle must be a multiple of 90 Degrees.

=head2 B<$page-E<gt>GetWidth()>

Gets the width of a page. 

=head2 B<$page-E<gt>GetHeight()>

Gets the height of a page. 

=head2 B<my $destination = $page-E<gt>CreateDestination() >

Creates a new destination object for the page. 

=head2 B<my $annotation = $page-E<gt>CreateTextAnnot($text,$encoder,$left,$bottom,$right,$top)>

Creates a new text annotation object for the page. 

=over

=item $text

The text to be displayed. 

=item $encoder

An encoder handle which is used to encode the text. If it is undef, PDFDocEncoding is used. 

=item $left,$bottom,$right,$top

A Rectangle where the annotation is displayed. 

=back

=head2 B<my $annotation = $page-E<gt>CreateLinkAnnot($dst,$left,$bottom,$right,$top)>

Creates a new link annotation object for the page. 

=over

=item $dst

A handle of destination object to jump to.

=item $left,$bottom,$right,$top

Rectangle of clickable area.

=back

=head2 B<my $annotation = $page-E<gt>CreateURILinkAnnot($uri,$left,$bottom,$right,$top)>

Creates a new link annotation object for the page. 

=over

=item $uri

URL of destination to jump to. 

=item $left,$bottom,$right,$top

Rectangle of clickable area.

=back

=head2 B<$page-E<gt>TextWidth($text)>

Gets the width of the text in current fontsize, character spacing and word spacing. 

=head2 B<$page-E<gt>MeasureText  ($text, $width, wordwrap)>

Calculates the byte length which can be included within the specified width.

=over

=item $text

The text to get width.

=item $width

The width of the area to put the text.

=item wordwrap

When there are three words of "ABCDE", "FGH", and "IJKL", and the substring until "J" can be 
included within the width, if wordwrap parameter is HPDF_FALSE it returns 12,  
and if wordwrap parameter is HPDF_TRUE it returns 10 (the end of the previous word).

=back

=head2 B<$page-E<gt>GetGMode()>

Gets the current graphics mode.

=head2 B<my ($x, $y) = $page-E<gt>GetCurrentPos()>

Gets the current position for path painting.

=head2 B<my ($x, $y) = $page-E<gt>GetCurrentTextPos()>

Gets the current position for text showing.

=head2 B<my $font = $page-E<gt>GetCurrentFont()>

Gets the handle of the page's current font.

=head2 B<$page-E<gt>GetCurrentFontSize()>

Gets the size of the page's current font.

=head2 B<my ($a,$b,$c,$d,$x,$y) = $page-E<gt>GetTransMatrix()>

Gets the current transformation matrix of the page. 

=head2 B<$page-E<gt>GetLineWidth()>

Gets the current line width of the page. 

=head2 B<$page-E<gt>GetLineCap()>

Gets the current line cap style of the page. 

=head2 B<$page-E<gt>GetLineJoin()>

Gets the current line join style of the page. 

=head2 B<$page-E<gt>GetMiterLimit()>

Gets the current value of the page's miter limit. 

=head2 B<my ($dash_pattern,$phase) = $page-E<gt>GetDash()>

Gets the current pattern of the page.

=head2 B<$page-E<gt>GetFlat()>

Gets the current value of the page's flatness. 

=head2 B<$page-E<gt>GetCharSpace()>

Gets the the current value of the page's character spacing.

=head2 B<$page-E<gt>GetWordSpace()>

Returns the current value of the page's word spacing. 

=head2 B<$page-E<gt>GetHorizontalScalling()>

Returns the current value of the page's horizontal scalling for text showing. 

=head2 B<$page-E<gt>GetTextLeading()>

Returns the current value of the page's line spacing. 

=head2 B<$page-E<gt>GetTextRenderingMode()>

Returns the current value of the page's text rendering mode. 

=head2 B<$page-E<gt>GetTextRise()>

Returns the current value of the page's text rising. 

=head2 B<my ($r, $g, $b) = $page-E<gt>GetRGBFill()>

Returns the current value of the page's filling color.

=head2 B<my ($r, $g, $b) = $page-E<gt>GetRGBStroke()>

Returns the current value of the page's stroking color.

=head2 B<my ($c, $m, $y, $k) = $page-E<gt>GetCMYKFill()>

Returns the current value of the page's filling color.

=head2 B<my ($c, $m, $y, $k) = $page-E<gt>GetCMYKStroke()>

Returns the current value of the page's stroking color.

=head2 B<$page-E<gt>GetGrayFill()>

Returns the current value of the page's filling color.

=head2 B<$page-E<gt>GetGrayStroke()>

Returns the current value of the page's stroking color.

=head2 B<$page-E<gt>GetStrokingColorSpace()>

Returns the current value of the page's stroking color space. 

=head2 B<$page-E<gt>GetFillingColorSpace()>

Returns the current value of the page's stroking color space. 

=head2 B<$page-E<gt>GetTextMatrix()>

Gets the current text transformation matrix of the page. 

=head2 B<$page-E<gt>GetGStateDepth()>

Returns the number of the page's graphics state stack. 

=head2 B<$page-E<gt>SetSlideShow(type,$disp_time,$trans_time)>

Configures the setting for slide transition of the page. 

=over

=item type

The transition style. The following values are available.

    HPDF_TS_WIPE_RIGHT
    HPDF_TS_WIPE_UP
    HPDF_TS_WIPE_LEFT
    HPDF_TS_WIPE_DOWN
    HPDF_TS_BARN_DOORS_HORIZONTAL_OUT
    HPDF_TS_BARN_DOORS_HORIZONTAL_IN
    HPDF_TS_BARN_DOORS_VERTICAL_OUT
    HPDF_TS_BARN_DOORS_VERTICAL_IN
    HPDF_TS_BOX_OUT
    HPDF_TS_BOX_IN
    HPDF_TS_BLINDS_HORIZONTAL
    HPDF_TS_BLINDS_VERTICAL
    HPDF_TS_DISSOLVE
    HPDF_TS_GLITTER_RIGHT
    HPDF_TS_GLITTER_DOWN
    HPDF_TS_GLITTER_TOP_LEFT_TO_BOTTOM_RIGHT
    HPDF_TS_REPLACE 

=item $disp_time

The display duration of the page. (in seconds)

=item $trans_time

The duration of the transition effect. Default value is 1(second). 

=back

=head2 B<$page-E<gt>Arc($x, $y, $ray, $ang1, $ang2)>

Appends a circle to the current path.

=over

=item $x, $y

The center point of the circle.

=item $ray

The ray of the circle.

=item $ang1

The angle of the begining of the arc.

=item $ang2

The angle of the end of the arc. It must be greater than ang1.

=back

=head2 B<$page-E<gt>BeginText()>

Begins a text object and sets the current text position to the point (0, 0).

=head2 B<$page-E<gt>Circle($x,$y,$ray)>

Appends a circle to the current path.

=over

=item $x, $y

The center point of the circle.

=item $ray

The ray of the circle.

=back

=head2 B<$page-E<gt>Clip()>

=head2 B<$page-E<gt>ClosePath()>

Appends a strait line from the current point to the start point of sub path.
The current point is moved to the start point of sub path. 

=head2 B<$page-E<gt>ClosePathStroke()>

Closes the current path, then it paints the path.

=head2 B<$page-E<gt>ClosePathEofillStroke()>

Closes the current path, fills the current path using the even-odd rule, then it paints the path. 

=head2 B<$page-E<gt>ClosePathFillStroke()>

Closes the current path, fills the current path using the nonzero winding number rule, then it paints the path. 

=head2 B<$page-E<gt>Concat($a, $b, $c, $d, $x, $y)>

Concat() concatenates the page's current transformation matrix and specified matrix.

	# save the current graphics states
	$page->GSave ();

	# concatenate the transformation matrix
	$page->Concat (0.7, 0.3, -0.4, 0.6, 220, 350);

	# show text on the translated coordinates
	$page->BeginText ();
	$page->MoveTextPos (50, 100);
	$page->ShowText ("Text on the translated coordinates");
	$page->EndText ();

	# restore the graphics states 
	$page->GRestore ();

=over

=item $a, $b, $c, $d, $x, $y

The transformation matrix to concatenate.

=back

=head2 B<$page-E<gt>CurveTo($x1,$y1,$x2,$y2,$x3,$y3)>

Appends a Bézier curve to the current path using two spesified points.
The point ($x1, $y1) and the point ($x2, $y2) are used as the control points for a Bézier curve and current point is moved to the point ($x3, $y3)

=head2 B<$page-E<gt>CurveTo2($x2,$y2,$x3,$y3)>

Appends a Bézier curve to the current path using two spesified points.
The current point and the point ($x2, $y2) are used as the control points for a Bézier curve and current point is moved to the point ($x3, $y3)

=head2 B<$page-E<gt>CurveTo3($x1,$y1,$x3,$y3)>

Appends a Bézier curve to the current path using two spesified points.
The point ($x1, $y1) and the point ($x3, $y3) are used as the control points for a Bézier curve and current point is moved to the point ($x3, $y3)

=head2 B<$page-E<gt>DrawImage($image,$x,$y,$width,$height)>

Shows an image in one operation.

=over

=item $image

The handle of an image object.

=item $x, $y

The lower-left point of the region where image is displayed.

=item $width

The width of the region where image is displayed.

=item $height

The width of the region where image is displayed.

=back

=head2 B<$page-E<gt>Ellipse($x, $y, $xray, $yray)>

Appends an ellipse to the current path.

=over

=item $x, $y

The center point of the circle.

=item $xray, $yray

The radius in the x and y direction.

=back

=head2 B<$page-E<gt>EndPath()>

Ends the path object without filling and painting operation.

=head2 B<$page-E<gt>EndText()>

Ends a text object.

=head2 B<$page-E<gt>Eoclip()>

=head2 B<$page-E<gt>Eofill()>

Fills the current path using the even-odd rule.

=head2 B<$page-E<gt>EofillStroke()>

Fills the current path using the even-odd rule, then it paints the path. 

=head2 B<$page-E<gt>Fill()>

Fills the current path using the nonzero winding number rule.

=head2 B<$page-E<gt>FillStroke()>

Fills the current path using the nonzero winding number rule, then it paints the path. 

=head2 B<$page-E<gt>GRestore()>

Restore the graphics state which is saved by GSave().

=head2 B<$page-E<gt>GSave()>

Saves the page's current graphics parameter to the stack. An application can invoke GSave() up to 28 
and can restore the saved parameter by invoking GRestore().

The parameters that are saved by GSave() is as follows.

    * Transformation Matrix
    * Line Width
    * Line Cap Style
    * Line Join Style
    * Miter Limit
    * Dash Mode
    * Flatness
    * Character Spacing
    * Word Spacing
    * Horizontal Scalling
    * Text Leading
    * Rendering Mode
    * Text Rise
    * Filling Color
    * Stroking Color
    * Font
    * Font Size

=head2 B<$page-E<gt>LineTo($x,$y)>

Appends a path from the current point to the specified point.

=head2 B<$page-E<gt>MoveTextPos($x,$y)>

Moves the current text position to the start of the next line with using specified offset values. 
If the start position of the current line is (x1, y1), the start of the next line is (x1 + $x, y1 + $y). 

=head2 B<$page-E<gt>MoveTextPos2($x,$y)>

Moves the current text position to the start of the next line with using specified offset values, and sets the text-leading to -y. 
If the start position of the current line is (x1, y1), the start of the next line is (x1 + $x, y1 + $y).

=head2 B<$page-E<gt>MoveTo($x,$y)>

Sets the start point for the path to the point.

=head2 B<$page-E<gt>MoveToNextLine()>

Moves the current text position to the start of the next line. 
If the start position of the current line is (x1, y1), the start of the next line is (x1, y1 - text leading).
NOTE:
Since the default value of Text Leading is 0,  an application have to invoke 
SetTextLeading() before MoveToNextLine() to set text leading.

=head2 B<$page-E<gt>Rectangle($x,$y,$width,$height)>

Appends a rectangle to the current path.

=over

=item $x,$y

The lower-left point of the rectangle.

=item $width

The width of the rectangle.

=item $height

The height of the rectangle.

=back

=head2 B<$page-E<gt>SetCharSpace($value)>

Sets the character spacing for text showing.
The initial value of character spacing is 0.

=head2 B<$page-E<gt>SetCMYKFill($c,$m,$y,$k)>

Sets the filling color. B<$c,$m,$y,$k> - the level of each color element. They must be between 0 and 1.

=head2 B<$page-E<gt>SetCMYKStroke($c,$m,$y,$k)>

Sets the stroking color. B<$c,$m,$y,$k> - the level of each color element. They must be between 0 and 1.

=head2 B<$page-E<gt>SetDash(\@dash_pattern,$phase)>

Sets the line dash pattern in the page.

=over

=item \@dash_pattern

Pattern of dashes and gaps used to stroke paths.

=item $phase 

The phase in which the pattern begins (default is 0). 

=item Example:

$page->SetDash([8, 7, 2, 7], 0);

=back

=head2 B<$page-E<gt>SetExtGState($ext_gstate)>

Applys the graphics state to the page.

=over

=item $ext_gstate

The handle of a extended graphics state object. 

=back

=head2 B<$page-E<gt>SetGrayFill($gray)>

Sets the filling color. The value of the gray level between 0 and 1.

=head2 B<$page-E<gt>SetGrayStroke($gray)>

Sets the stroking color. The value of the gray level between 0 and 1.

=head2 B<$page-E<gt>SetFontAndSize($font,$size)>

Sets the type of font and size leading.

=over

=item $font

The handle of a font object.

=item $size

The size of a font.

=back

=head2 B<$page-E<gt>SetHorizontalScalling($value)>

Sets the horizontal scalling for text showing.
The initial value of horizontal scalling is 100.

=head2 B<$page-E<gt>SetLineCap(line_cap)>

B<line_cap> The style of line-cap:

=over

=item PDF_BUTT_END

The line is squared off at the endpoint of the path.

=item PDF_ROUND_END

The end of a line becomes a semicircle whose center is the end point of the path.

=item PDF_PROJECTING_SCUARE_END

The line continues to the point that exceeds half of the stroke width the end
point. 

=back

=head2 B<$page-E<gt>SetLineJoin(line_join)>

Sets the line join style in the page.
B<line_join> The style of line-join.

	HPDF_MITER_JOIN
	HPDF_ROUND_JOIN
	HPDF_BEVEL_JOIN

=head2 B<$page-E<gt>SetLineWidth($line_width)>

Sets the width of the line used to stroke a path.

=head2 B<$page-E<gt>SetMiterLimit($miter_limit)>

=head2 B<$page-E<gt>SetRGBFill($r, $g, $b)>

Sets the filling color. B<$r, $g, $b> - the level of each color element. They must be between 0 and 1.

=head2 B<$page-E<gt>SetRGBStroke($r, $g, $b)>

Sets the stroking color. B<$r, $g, $b> - the level of each color element. They must be between 0 and 1.

=head2 B<$page-E<gt>SetTextLeading($value)>

Sets the text leading (line spacing) for text showing.
The initial value of leading is 0.

=head2 B<$page-E<gt>SetTextMatrix($a,$b,$c,$d,$x,$y)>

=head2 B<$page-E<gt>SetTextRenderingMode(mode)>

Sets the text rendering mode.
The initial value of text rendering mode is HPDF_FILL.

B<mode> one of the following values

	HPDF_FILL
	HPDF_STROKE
	HPDF_FILL_THEN_STROKE
	HPDF_INVISIBLE
	HPDF_FILL_CLIPPING
	HPDF_STROKE_CLIPPING
	HPDF_FILL_STROKE_CLIPPING
	HPDF_CLIPPING

=head2 B<$page-E<gt>SetTextRise($value)>

Moves the text position in vertical direction by the amount of value. Useful for making subscripts or superscripts. 

=over

=item $value

Text rise, in user space units. 

=back

=head2 B<$page-E<gt>SetWordSpace($value)>

Sets the word spacing for text showing.
The initial value of word spacing is 0.

=head2 B<$page-E<gt>ShowText($text)>

Prints the text at the current position on the page.

=head2 B<$page-E<gt>ShowTextNextLine($text)>

Moves the current text position to the start of the next line, then prints the text at the current position on the page.

=head2 B<$page-E<gt>ShowTextNextLineEx($word_space, $char_space, $text)>

Moves the current text position to the start of the next line, 
then sets the word spacing, character spacing and 
prints the text at the current position on the page.

=head2 B<$page-E<gt>Stroke()>

Paints the current path.

=head2 B<$page-E<gt>TextOut($xpos, $ypos, $text)>

Prints the text on the specified position.

=over

=item $xpos, $ypos

The point position where the text is displayed.

=item $text

The text to show.

=back

=head2 B<$page-E<gt>TextRect($left, $top, $right, $bottom, $text, align)>

Print the text inside the specified region.

=over

=item $left, $top, $right, $bottom

Coordinates of corners of the region to output text.

=item $text

The text to show.

=item align

The alignment of the text. One of the following values

	HPDF_TALIGN_LEFT
	HPDF_TALIGN_RIGHT
	HPDF_TALIGN_CENTER
	HPDF_TALIGN_JUSTIFY

=back

=head2 B<$font-E<gt>GetFontName() >

Gets the name of the font. 

=head2 B<$font-E<gt>GetEncodingName() >

Gets the encoding name of the font. 

=head2 B<$font-E<gt>GetUnicodeWidth($code) >

Gets the width of a Unicode character in a specific font.

=head2 B<my ($left, $bottom, $right, $top) = $font-E<gt>GetBBox($code) >

Gets the bounding box of the font. 

=head2 B<$font-E<gt>GetAscent() >

Gets the vertical ascent of the font. 

=head2 B<$font-E<gt>GetDescent() >

Gets the vertical descent of the font. 

=head2 B<$font-E<gt>GetXHeight() >

Gets the distance from the baseline of lowercase letters. 

=head2 B<$font-E<gt>GetCapHeight() >

Gets the distance from the baseline of uppercase letters. 

=head2 B<my ($numchars, $numwords, $width, $numspace) = $font-E<gt>TextWidth($text,$len)>

Gets total width of the text, number of characters, and number of words. 

=over

=item $text

The text to get width.

=item $len

The byte length of the text. 

=back

=head2 B<$font-E<gt>MeasureText($text,$len,$width,$font_size,$char_space,$word_space,$wordwrap)>

Calculates the byte length which can be included within the specified width.  

=over

=item $text

The text to use for calculation.

=item $len

The length of the text.

=item $width

The width of the area to put the text.

=item $font_size

The size of the font.

=item $char_space

The character spacing.

=item $word_space

The word spacing.

=item $wordwrap

Suppose there are three words: "ABCDE", "FGH", and "IJKL". Also, suppose the substring until "J" can be included within the width (12 bytes). If word_wrap is B<HPDF_TRUE> the function returns 12. If word_wrap parameter is B<HPDF_FALSE>, it returns 10 (the end of the previous word).

=back

=head2 B<$annotation-E<gt>LinkAnnot_SetHighlightMode(mode) >

Defines the appearance when a mouse clicks on a link annotation.

mode - One of the following values: 

	HPDF_ANNOT_NO_HIGHTLIGHT 	No highlighting.
	HPDF_ANNOT_INVERT_BOX 	Invert the contents of the area of annotation.
	HPDF_ANNOT_INVERT_BORDER 	Invert the annotation's border.
	HPDF_ANNOT_DOWN_APPEARANCE 	Dent the annotation. 

=head2 B<$annotation-E<gt>LinkAnnot_SetBorderStyle($width,$dash_on,$dash_off) >

Defines the style of the annotation's border. 

=over

=item $width

The width of an annotation's border.

=item $dash_on,$dash_off

The dash style. 

=back

=head2 B<$annotation-E<gt>TextAnnot_SetIcon(icon) >

Defines the appearance when a mouse clicks on a link annotation.

icon - The style of icon. The following values are available. 

    HPDF_ANNOT_ICON_COMMENT
    HPDF_ANNOT_ICON_KEY
    HPDF_ANNOT_ICON_NOTE
    HPDF_ANNOT_ICON_HELP
    HPDF_ANNOT_ICON_NEW_PARAGRAPH
    HPDF_ANNOT_ICON_PARAGRAPH
    HPDF_ANNOT_ICON_INSERT 

=head2 B<$annotation-E<gt>TextAnnot_SetOpened($open) >

Defines whether the text-annotation is initially open. 

=over

=item $open

HPDF_TRUE means the annotation initially displayed open. 

=back

=head2 B<$outline-E<gt>SetOpened($opened) >

Sets whether this node is opened or not when the outline is displayed for the first time. B<$opened> specify whether the node is opened or not. 

=head2 B<$outline-E<gt>SetDestination($dst) >

Sets a destination object which becomes to a target to jump when the outline is clicked. B<$dst> specify the handle of an destination object. 

=head2 B<$destination-E<gt>SetXYZ($left,$top,$zoom) >

Defines the appearance of a page with three parameters which are left, top and zoom. 

=over

=item $left

The left coordinates of the page.

=item $top

The top coordinates of the page.

=item $zoom

The page magnified factor. The value must be between 0.08(8%) to 32(%). 

=back

=head2 B<$destination-E<gt>SetFit() >

Sets the appearance of the page to displaying entire page within the window. 

=head2 B<$destination-E<gt>SetFitH($top) >

Defines the appearance of a page to magnifying to fit the width of the page within the window and setting the top position of the page to the value of the "top" parameter. 

=over

=item $top

The top coordinates of the page. 

=back

=head2 B<$destination-E<gt>SetFitV($left) >

Defines the appearance of a page to magnifying to fit the height of the page within the window and setting the left position of the page to the value of the "top" parameter. 

=over

=item $left

The left coordinates of the page. 

=back

=head2 B<$destination-E<gt>SetFitR($left,$bottom,$right,$top) >

Defines the appearance of a page to magnifying the page to fit a rectangle specified by left, bottom, right and top. 

=over

=item $left

The left coordinates of the page. 

=item $bottom

The bottom coordinates of the page.

=item $right

The right coordinates of the page.

=item $top

The top coordinates of the page. 

=back

=head2 B<$destination-E<gt>SetFitB() >

Sets the appearance of the page to magnifying to fit the bounding box of the page within the window. 

=head2 B<$destination-E<gt>SetFitBH($top) >

Defines the appearance of a page to magnifying to fit the width of the bounding box of the page within the window and setting the top position of the page to the value of the "top" parameter. 

=over

=item $top

The top coordinates of the page. 

=back

=head2 B<$destination-E<gt>SetFitBV($top) >

Defines the appearance of a page to magnifying to fit the height of the bounding box of the page within the window and setting the top position of the page to the value of the "top" parameter. 

=over

=item $top

The top coordinates of the page. 

=back

=head2 B<my ($x,$y) = $image-E<gt>GetSize() >

Gets the size of the image of an image object. 

=head2 B<$image-E<gt>GetWidth() >

Gets the width of the image of an image object.

=head2 B<$image-E<gt>GetHeight()>

Gets the height of the image of an image object.

=head2 B<$image-E<gt>GetBitsPerComponent()>

Gets the number of bits used to describe each color component.

=head2 B<$image-E<gt>GetColorSpace()>

Gets the name of the image's color space. It returns the following values

	"DeviceGray"
	"DeviceRGB"
	"DeviceCMYK"
	"Indexed"

=head2 B<$image-E<gt>SetColorMask ($rmin, $rmax, $gmin, $gmax, $bmin, $bmax)>

Sets the transparent color of the image by the RGB range values.
The color within the range is displayed as a transparent color.
The Image must be RGB color space. 

=over

=item $rmin

The lower limit of Red. It must be between 0 and 255.

=item $rmax

The upper limit of Red. It must be between 0 and 255.

=item $gmin

The lower limit of Green. It must be between 0 and 255.

=item $gmax

The upper limit of Green. It must be between 0 and 255.

=item $bmin

The lower limit of Blue. It must be between 0 and 255.

=item $bmax

The upper limit of Blue. It must be between 0 and 255.

=back 

=head2 B<$image-E<gt>SetMaskImage($mask_image)> 

Sets the mask image. 

B<$mask_image> specify the handle of an image object which is used as image-mask. This image must be 1bit gray-scale color image.

=head1 SEE ALSO

http://libharu.org/

=head1 AUTHOR

Ilya Butakov, butilw@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ilya Butakov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
