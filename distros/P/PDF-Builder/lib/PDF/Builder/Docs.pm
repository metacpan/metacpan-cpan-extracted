package PDF::Builder::Docs;

use strict;
use warnings;

our $VERSION = '3.012'; # VERSION
my $LAST_UPDATE = '3.011'; # manually update whenever code is changed

# originally part of Builder.pm, it was split out due to its length

=head1 NAME

PDF::Builder::Docs - additional documentation for Builder module

=head1 SOME SPECIAL NOTES

=head2 Software Development Kit

There are four levels of involvement with PDF::Builder. Depending on what you
want to do, different kinds of installs are recommended.

B<1.> Simply installing PDF::Builder as a prerequisite for running some other
package. All you need to do is install the CPAN package for PDF::Builder, and
it will load the .pm files into your Perl library. If the other package prereqs
PDF::Builder, its installer may download and install PDF::Builder automatically.

B<2.> You want to write a Perl program that uses PDF::Builder functions. In 
addition to installing PDF::Builder from CPAN, you will want documentation on
it. Obtain a copy of the product from GitHub (https://github.com/PhilterPaper/Perl-PDF-Builder) or as a gzipped tar file from CPAN. This includes a utility to 
build (from POD) a library of HTML documents, as well as examples (examples/ 
directory) and contributed sample programs (contrib/ directory).

B<3.> You want to modify PDF::Builder files. In addition to the CPAN and GitHub
distributions, you I<may> choose to keep a local Git repository for tracking
your changes. Depending on whether or not your PDF::Builder copy is being used
for production purposes, you may want to do your editing and testing in the Perl
library installation (I<live>) or in a different place. The "t" tests (t/
directory) and examples provide good regression tests to ensure that you haven't
broken anything. If you do your editing on the live code, don't forget when done
to copy the changes back into the master version you keep!

B<4.> You want to contribute to the development of PDF::Builder. You will need a
local Git repository (and a GitHub account), so that when you've got it all 
done, you can issue a "Pull Request" to bring it to our attention. We can't 
guarantee that your work will be incorporated into the project, but at least we
will look at it. From time to time, a new CPAN version will be issued.

If you want to make substantial changes for public use, and can't come to a 
meeting of minds with us, you can even start your own GitHub project and 
register a new CPAN project (that's what we did, I<forking> PDF::API2). Please 
don't just assume that we don't want your changes -- at least propose what you 
want to do in writing, so we can consider it. We're always looking for people to
help out and expand PDF::Builder.

=head2 Strings (Character Text)

Perl, and hence PDF::Builder, use strings that support the full range of
Unicode characters. When importing strings into a Perl program, for example
by reading text from a file, you must be aware of what their character encoding
is. Single-byte encodings (default is 'latin1'), represented as bytes of value
0x00 through 0xFF (0..255), will produce different results if you do something 
that depends on the encoding, such as sorting, searching, or comparing any
two non-ASCII characters. This also applies to any characters (text) hard 
coded into the Perl program.

You can always decode the text from external encoding (ASCII, UTF-8, Latin-3, 
etc.) into the Perl (internal) UTF-8 multibyte encoding. This uses one to four 
bytes to represent each character. See pragma C<utf8> and module C<Encode> for 
details about decoding text. Note that only TrueType fonts (C<ttfont>) can 
make direct use of UTF-8-encoded text. Other font types (core, T1, etc.) can
only use single-byte encoded text. If your text is ASCII, Latin-1, or CP-1252,
you I<can> just leave the Perl strings as the default single-byte encoding.

Then, there is the matter of encoding the I<output> to match up with available 
font character sets. You're not actually I<translating> the text on output, but
are telling the output system (and Reader) what encoding the output byte stream
represents, and what character glyphs they should generate. 

If you confine your text to plain ASCII (0x00 .. 0x7F byte values) or even
Latin-1 or CP-1252 (0x00 .. 0xFF byte values), you can
use default (non-UTF-8) Perl strings and use the default output encoding
(WinAnsiEncoding), which is more-or-less Windows CP-1252 (a superset 
in turn, of ISO-8859-1 Latin-1). If your text uses any other characters, you
will need to be aware of what encoding your text strings are (in the Perl string
and for declaring output glyph generation).
See C<corefont>, C<psfont>, and C<ttfont> in L<FONT METHODS> for additional 
information.

=head3 Some Internal Details

Some of the following may be a bit scary or confusing to beginners, so don't 
be afraid to skip over it until you're ready for it...

Perl (and PDF::Builder) internally use strings which are either single-byte 
(ISO-8859-1/Latin-1) or multibyte UTF-8 encoded (there is an internal flag 
marking the string as UTF-8 or not). 
If you work I<strictly> in ASCII or Latin-1 or CP-1252 (each a superset of the
previous), you should be OK in not doing anything special about your string 
encoding. You can just use the default Perl single byte strings (internally
marked as I<not> UTF-8) and the default output encoding (WinAnsiEncoding).

If you intend to use input from a variety of sources, you should consider 
decoding (converting) your text to UTF-8, which will provide an internally
consistent representation (and your Perl code itself should be saved in UTF-8, 
in case you want to use any hard coded non-ASCII characters). In any string,
non-ASCII characters (0x80 or higher) would be converted to the Perl UTF-8
internal representation, via C<$string = Encode::decode(MY_ENCODING, $input);>.
C<MY_ENCODING> would be a string like 'latin1', 'cp-1252', 'utf8', etc. Similar 
capabilities are available for declaring a I<file> to be in a certain encoding.

Be aware that if you use UTF-8 encoding for your text, that only TrueType font
output (C<ttfont>) can handle it directly. Corefont and Type1 output will 
require that the text will have to be converted back into a single-byte encoding
(using C<Encode::encode>), which may need to be declared with C<-encode> (for 
C<corefont> or C<psfont>). If you have any characters I<not> found in the 
selected single-byte I<encoding> (but I<are> found in the font itself), you 
will need to use C<automap> to break up the font glyphs into 256 character 
planes, map such characters to 0x00 .. 0xFF in the appropriate plane, and 
switch between font planes as necessary.

Core and Type1 fonts (output) use the byte values in the string (single-byte 
encoding only!) and provide a byte-to-glyph mapping record for each plane. 
TrueType outputs a group of four hexadecimal digits representing the "CId" 
(character ID) of each character. The CId does not correspond to either the 
single-byte or UTF-8 internal representations of the characters.

The bottom line is that you need to know what the internal representation of
your text is, so that the output routines can tell the PDF reader about it 
(via the PDF file). The text will not be translated upon output, but the PDF 
reader needs to know what the encoding in use is, so it knows what glyph to 
associate with each byte (or byte sequence).

By the way, it is recommended that you be using I<at least> Perl 5.10 if you
are going to be using any non-ASCII characters. Perl 5.8 may be a little
unpredictable in handling such text.

=head2 PDF Versions Supported

When creating a PDF file using the functions in PDF::Builder, the output is
marked as PDF 1.4. This does not mean that all I<PDF> functionality up through 
1.4 is supported! There are almost surely features missing as far back as the
PDF 1.0 standard. 

The big problem is when a PDF of version 1.5 or higher is imported or opened
in PDF::Builder. If it contains content that is actually unsupported by this
software, there is a chance that something will break. This does not guarantee
that a PDF marked as "1.7" will go down in flames when read by PDF::Builder,
or that a PDF written back out will break in a Reader, but the possibility is
there. Much PDF writer software simply marks its output as the highest version
of PDF at the time (usually 1.7), even if there is no content beyond, say, 1.2.
There is I<some> handling of PDF 1.5 items in PDF::Builder, such as cross 
reference streams, but support beyond 1.4 is very limited. All we can say is to 
be careful when handling PDFs whose version is above 1.4, and test thoroughly, 
as they may break at some point.

PDF::Builder includes a simple version control mechanism, where the initial
PDF version to be output (default 1.4) can be set by the programmer. Input
PDFs greater than 1.4 (current output level) will receive a warning (can be
suppressed) that the output level will be raised to that level. The use of PDF
features greater than the current output level will likewise trigger a warning
that the output level is to be raised to the necessary level. If this is not
desired, you should avoid using those PDF features which are higher than the
desired PDF output level.

=head2 History

PDF::API2 was originally written by Alfred Reibenschuh, derived from Martin
Hosken's Text::PDF via the Text::PDF::API wrapper. 
In 2009, Otto Hirr started the PDF::API3 fork, but it never went anywhere.
In 2011, PDF::API2 maintenance was taken over by Steve Simms. 
In 2017, PDF::Builder was forked by Phil M. Perry, who desired a more aggressive
schedule of new features and bug fixes than Simms was providing. 

At Simms's request, the name of the new offering was changed from PDF::API4
to PDF::Builder, to reduce the chance of confusion due to parallel development.
Perry's intent is to keep all internal methods as upwardly compatible with
PDF::API2 as possible, although it is likely that there will be some drift
(incompatibilities) over time. At least initially, any program written based on 
PDF::API2 should be convertable to PDF::Builder simply by changing "API2" 
anywhere it occurs to "Builder". See the KNOWN_INCOMP known incompatibilities
file for further information.

=head1 DETAILED NOTES ON METHODS

=head2 Preferences - set user display preferences

=over

=item $pdf->preferences(%options)

Controls viewing preferences for the PDF.

=back

=head3 Page Mode Options

=over

=item -fullscreen

Full-screen mode, with no menu bar, window controls, or any other window visible.

=item -thumbs

Thumbnail images visible.

=item -outlines

Document outline visible.

=back

=head3 Page Layout Options

=over

=item -singlepage

Display one page at a time.

=item -onecolumn

Display the pages in one column.

=item -twocolumnleft

Display the pages in two columns, with oddnumbered pages on the left.

=item -twocolumnright

Display the pages in two columns, with oddnumbered pages on the right.

=back

=head3 Viewer Options

=over

=item -hidetoolbar

Specifying whether to hide tool bars.

=item -hidemenubar

Specifying whether to hide menu bars.

=item -hidewindowui

Specifying whether to hide user interface elements.

=item -fitwindow

Specifying whether to resize the document's window to the size of the displayed page.

=item -centerwindow

Specifying whether to position the document's window in the center of the screen.

=item -displaytitle

Specifying whether the window's title bar should display the
document title taken from the Title entry of the document information
dictionary.

=item -afterfullscreenthumbs

Thumbnail images visible after Full-screen mode.

=item -afterfullscreenoutlines

Document outline visible after Full-screen mode.

=item -printscalingnone

Set the default print setting for page scaling to none.

=item -simplex

Print single-sided by default.

=item -duplexflipshortedge

Print duplex by default and flip on the short edge of the sheet.

=item -duplexfliplongedge

Print duplex by default and flip on the long edge of the sheet.

=back

=head3 Initial Page Options

=over

=item -firstpage => [ $page, %options ]

Specifying the page (either a page number or a page object) to be
displayed, plus one of the following options:

=over

=item -fit => 1

Display the page designated by page, with its contents magnified just
enough to fit the entire page within the window both horizontally and
vertically. If the required horizontal and vertical magnification
factors are different, use the smaller of the two, centering the page
within the window in the other dimension.

=item -fith => $top

Display the page designated by page, with the vertical coordinate top
positioned at the top edge of the window and the contents of the page
magnified just enough to fit the entire width of the page within the
window.

=item -fitv => $left

Display the page designated by page, with the horizontal coordinate
left positioned at the left edge of the window and the contents of the
page magnified just enough to fit the entire height of the page within
the window.

=item -fitr => [ $left, $bottom, $right, $top ]

Display the page designated by page, with its contents magnified just
enough to fit the rectangle specified by the coordinates left, bottom,
right, and top entirely within the window both horizontally and
vertically. If the required horizontal and vertical magnification
factors are different, use the smaller of the two, centering the
rectangle within the window in the other dimension.

=item -fitb => 1

Display the page designated by page, with its contents magnified just
enough to fit its bounding box entirely within the window both
horizontally and vertically. If the required horizontal and vertical
magnification factors are different, use the smaller of the two,
centering the bounding box within the window in the other dimension.

=item -fitbh => $top

Display the page designated by page, with the vertical coordinate top
positioned at the top edge of the window and the contents of the page
magnified just enough to fit the entire width of its bounding box
within the window.

=item -fitbv => $left

Display the page designated by page, with the horizontal coordinate
left positioned at the left edge of the window and the contents of the
page magnified just enough to fit the entire height of its bounding
box within the window.

=item -xyz => [ $left, $top, $zoom ]

Display the page designated by page, with the coordinates (left, top)
positioned at the top-left corner of the window and the contents of
the page magnified by the factor zoom. A zero (0) value for any of the
parameters left, top, or zoom specifies that the current value of that
parameter is to be retained unchanged.

=back

=back

=head3 Example

    $pdf->preferences(
        -fullscreen => 1,
        -onecolumn => 1,
        -afterfullscreenoutlines => 1,
        -firstpage => [$page, -fit => 1],
    );

=head2 info Example

    %h = $pdf->info(
        'Author'       => "Alfred Reibenschuh",
        'CreationDate' => "D:20020911000000+01'00'",
        'ModDate'      => "D:YYYYMMDDhhmmssOHH'mm'",
        'Creator'      => "fredos-script.pl",
        'Producer'     => "PDF::Builder",
        'Title'        => "some Publication",
        'Subject'      => "perl ?",
        'Keywords'     => "all good things are pdf"
    );
    print "Author: $h{'Author'}\n";

=head2 XMP XML example

    $xml = $pdf->xmpMetadata();
    print "PDFs Metadata reads: $xml\n";
    $xml=<<EOT;
    <?xpacket begin='' id='W5M0MpCehiHzreSzNTczkc9d'?>
    <?adobe-xap-filters esc="CRLF"?>
    <x:xmpmeta
      xmlns:x='adobe:ns:meta/'
      x:xmptk='XMP toolkit 2.9.1-14, framework 1.6'>
        <rdf:RDF
          xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
          xmlns:iX='http://ns.adobe.com/iX/1.0/'>
            <rdf:Description
              rdf:about='uuid:b8659d3a-369e-11d9-b951-000393c97fd8'
              xmlns:pdf='http://ns.adobe.com/pdf/1.3/'
              pdf:Producer='Acrobat Distiller 6.0.1 for Macintosh'></rdf:Description>
            <rdf:Description
              rdf:about='uuid:b8659d3a-369e-11d9-b951-000393c97fd8'
              xmlns:xap='http://ns.adobe.com/xap/1.0/'
              xap:CreateDate='2004-11-14T08:41:16Z'
              xap:ModifyDate='2004-11-14T16:38:50-08:00'
              xap:CreatorTool='FrameMaker 7.0'
              xap:MetadataDate='2004-11-14T16:38:50-08:00'></rdf:Description>
            <rdf:Description
              rdf:about='uuid:b8659d3a-369e-11d9-b951-000393c97fd8'
              xmlns:xapMM='http://ns.adobe.com/xap/1.0/mm/'
              xapMM:DocumentID='uuid:919b9378-369c-11d9-a2b5-000393c97fd8'/></rdf:Description>
            <rdf:Description
              rdf:about='uuid:b8659d3a-369e-11d9-b951-000393c97fd8'
              xmlns:dc='http://purl.org/dc/elements/1.1/'
              dc:format='application/pdf'>
                <dc:description>
                  <rdf:Alt>
                    <rdf:li xml:lang='x-default'>Adobe Portable Document Format (PDF)</rdf:li>
                  </rdf:Alt>
                </dc:description>
                <dc:creator>
                  <rdf:Seq>
                    <rdf:li>Adobe Systems Incorporated</rdf:li>
                  </rdf:Seq>
                </dc:creator>
                <dc:title>
                  <rdf:Alt>
                    <rdf:li xml:lang='x-default'>PDF Reference, version 1.6</rdf:li>
                  </rdf:Alt>
                </dc:title>
            </rdf:Description>
        </rdf:RDF>
    </x:xmpmeta>
    <?xpacket end='w'?>
    EOT

    $xml = $pdf->xmpMetadata($xml);
    print "PDF metadata now reads: $xml\n";

=head2 FONT METHODS

=head3 Core Fonts

Core fonts are limited to single byte encodings. You cannot use UTF-8 or other
multibyte encodings with core fonts. The default encoding for the core fonts is
WinAnsiEncoding (roughly the CP-1252 superset of ISO-8859-1). See the 
C<-encode> option below to change this encoding.
See L<PDF::Builder::Resource::Font> C<automap> method for information on
accessing more than 256 glyphs in a font, using planes, I<although there is no
guarantee that future changes to font files will permit consistent results>.

Note that core fonts use fixed lists of expected glyphs, along with metrics
such as their widths. This may not exactly match up with whatever local font
file is used by the PDF reader. It's usually pretty close, but many cases have
been found where the list of glyphs is different between the core fonts and
various local font files, so be aware of this.

To allow UTF-8 text and extended glyph counts, you should 
consider replacing your use of core fonts with TrueType (.ttf) and OpenType
(.otf) fonts. There are tools, such as I<FontForge>, which can do a fairly good
(though, not perfect) job of converting a Type1 font library to OTF.

B<Examples:>

    $font1 = $pdf->corefont('Times-Roman', -encode => 'latin2');
    $font2 = $pdf->corefont('Times-Bold');
    $font3 = $pdf->corefont('Helvetica');
    $font4 = $pdf->corefont('ZapfDingbats');

Valid %options are:

=over

=item -encode

Changes the encoding of the font from its default. Notice that the encoding
(I<not> the entire font's glyph list) is shown in a PDF object (record), listing
256 glyphs associated with this encoding (I<and> that are available in this 
font). 

=item -dokern

Enables kerning if data is available.

=back

B<Note:> even though these are called "core" fonts, they are I<not> shipped
with PDF::Builder, but are expected to be found on the machine with the PDF
reader. Most core fonts are installed with a PDF reader, and thus are not
coordinated with PDF::Builder. PDF::Builder I<does> ship with core font 
I<metrics> files (width, glyph names, etc.), but these cannot be guaranteed to 
be in sync with what the PDF reader has installed!

See also L<PDF::Builder::Resource::Font::CoreFont>.

=head3 PS Fonts

PS (T1) fonts are limited to single byte encodings. You cannot use UTF-8 or 
other multibyte encodings with T1 fonts.
The default encoding for the T1 fonts is
WinAnsiEncoding (roughly the CP-1252 superset of ISO-8859-1). See the 
C<-encode> option below to change this encoding.
See L<PDF::Builder::Resource::Font> C<automap> method for information on
accessing more than 256 glyphs in a font, using planes, I<although there is no
guarantee that future changes to font files will permit consistent results>.
B<Note:> many Type1 fonts are limited to 256 glyphs, but some are available
with more than 256 glyphs. Still, a maximum of 256 at a time are usable.

C<psfont> accepts both ASCII (.pfa) and binary (.pfb) Type1 glyph files.
Font metrics can be supplied in either ASCII (.afm) or binary (.pfm) format,
as can be seen in the examples given below. It is possible to use .pfa with .pfm
and .pfb with .afm if that's what's available. The ASCII and binary files have
the same content, just in different formats.

To allow UTF-8 text and extended glyph counts in one font, you should 
consider replacing your use of Type1 fonts with TrueType (.ttf) and OpenType
(.otf) fonts. There are tools, such as I<FontForge>, which can do a fairly good
(though, not perfect) job of converting your font library to OTF.

B<Examples:>

    $font1 = $pdf->psfont('Times-Book.pfa', -afmfile => 'Times-Book.afm');
    $font2 = $pdf->psfont('/fonts/Synest-FB.pfb', -pfmfile => '/fonts/Synest-FB.pfm');

Valid %options are:

=over

=item -encode

Changes the encoding of the font from its default. Notice that the encoding
(I<not> the entire font's glyph list) is shown in a PDF object (record), listing
256 glyphs associated with this encoding (I<and> that are available in this 
font). 

=item -afmfile

Specifies the location of the I<ASCII> font metrics file (.afm). It may be used
with either an ASCII (.pfa) or binary (.pfb) glyph file.

=item -pfmfile

Specifies the location of the I<binary> font metrics file (.pfm). It may be used
with either an ASCII (.pfa) or binary (.pfb) glyph file.

=item -dokern

Enables kerning if data is available.

=back

B<Note:> these T1 (Type1) fonts are I<not> shipped with PDF::Builder, but are 
expected to be found on the machine with the PDF reader. Most PDF readers do 
not install T1 fonts, and it is up to the user of the PDF reader to install
the needed fonts.

See also L<PDF::Builder::Resource::Font::Postscript>.

=head3 TrueType Fonts

B<Warning:> BaseEncoding is I<not> set by default for TrueType fonts, so B<text 
in the PDF isn't searchable> (by the PDF reader) unless a ToUnicode CMap is 
included. A ToUnicode CMap I<is> included by default (-unicodemap set to 1) by
PDF::Builder, but allows it to be disabled (for performance and file size 
reasons) by setting -unicodemap to 0. This will produce non-searchable text, 
which, besides being annoying to users, may prevent screen 
readers and other aids to disabled users from working correctly!

B<Examples:>

    $font1 = $pdf->ttfont('Times.ttf');
    $font2 = $pdf->ttfont('Georgia.otf');

Valid %options are:

=over

=item -encode

Changes the encoding of the font from its default (WinAnsiEncoding).

Note that for a single byte encoding (e.g., 'latin1'), you are limited to 256
characters defined for that encoding. 'automap' does not work with TrueType.
If you want more characters than that, use 'utf8' encoding with a UTF-8
encoded text string.

=item -isocmap

Use the ISO Unicode Map instead of the default MS Unicode Map.

=item -unicodemap

If 1 (default), output ToUnicode CMap to permit text searches and screen
readers. Set to 0 to save space by I<not> including the ToUnicode CMap, but
text searching and screen reading will not be possible.

=item -dokern

Enables kerning if data is available.

=item -noembed

Disables embedding of the font file.

=back

=head3 CJK Fonts

B<Examples:>

    $font = $pdf->cjkfont('korean');
    $font = $pdf->cjkfont('traditional');

Valid %options are:

=over

=item -encode

Changes the encoding of the font from its default.

=back

See also L<PDF::Builder::Resource::CIDFont::CJKFont>

=head3 Synthetic Fonts

B<Warning:> BaseEncoding is I<not> set by default for these fonts, so text 
in the PDF isn't searchable (by the PDF reader) unless a ToUnicode CMap is 
included. A ToUnicode CMap I<is> included by default (-unicodemap set to 1) by
PDF::Builder, but allows it to be disabled (for performance and file size 
reasons) by setting -unicodemap to 0. This will produce non-searchable text, 
which, besides being annoying to users, may prevent screen 
readers and other aids to disabled users from working correctly!

B<Examples:>

    $cf  = $pdf->corefont('Times-Roman', -encode => 'latin1');
    $sf  = $pdf->synfont($cf, -slant => 0.85);  # compressed 85%
    $sfb = $pdf->synfont($cf, -bold => 1);      # embolden by 10em
    $sfi = $pdf->synfont($cf, -oblique => -12); # italic at -12 degrees

Valid %options are:

=over

=item -slant

Slant/expansion factor (0.1-0.9 = slant, 1.1+ = expansion).

=item -oblique

Italic angle (+/-)

=item -bold

Emboldening factor (0.1+, bold = 1, heavy = 2, ...)

=item -space

Additional character spacing in ems (0-1000)

=item -caps

0 for normal text, 1 for small caps. Note that not all lower case letters
appear to have small caps equivalents defined for them. These include, but are
not limited to, 'n U+0149, fi ligature U+FB01, fl ligature U+FB02, German eszet
(sharp s) U+00DF, and doubtless others. In such cases, you may want to consider
replacing these ligatures with separate characters: '+n, f+i, f+l, s+s, etc.

=back

See also L<PDF::Builder::Resource::Font::SynFont>

=head2 IMAGE METHODS

=head3 TIFF Images

Note that the Graphics::TIFF support library does B<not> currently permit a 
filehandle for C<$file>.

PDF::Builder will use the Graphics::TIFF support library for TIFF functions, if
it is available, unless explicitly told not to. Your code can test whether
Graphics::TIFF is available by examining C<< $tiff->usesLib() >> or
C<< $pdf->LA_GT() >>.

=over

=item = -1 

Graphics::TIFF I<is> installed, but your code has specified C<-nouseGT>, to 
I<not> use it. The old, pure Perl, code (buggy!) will be used instead, as if 
Graphics::TIFF was not installed.

=item = 0

Graphics::TIFF is I<not> installed. Not all systems are able to successfully
install this package, as it requires libtiff.a.

=item = 1

Graphics::TIFF is installed and is being used.

=back

Options:

=over

=item -nouseGT => 1

Do B<not> use the Graphics::TIFF library, even if it's available. Normally
you I<would> want to use this library, but there may be cases where you don't,
such as when you want to use a file I<handle> instead of a I<name>.

=item -silent => 1

Do not give the message that Graphics::TIFF is not B<installed>. This message
will be given only once, but you may want to suppress it, such as during 
t-tests.

=back

=head3 PNG Images

PDF::Builder will use the Image::PNG::Libpng support library for PNG functions, 
if it is available, unless explicitly told not to. Your code can test whether
Image::PNG::Libpng is available by examining C<< $png->usesLib() >> or
C<< $pdf->LA_IPL() >>.

=over

=item = -1 

Image::PNG::Libpng I<is> installed, but your code has specified C<-nouseIPL>, 
to I<not> use it. The old, pure Perl, code (slower and less capable) will be 
used instead, as if Image::PNG::Libpng was not installed.

=item = 0

Image::PNG::Libpng is I<not> installed. Not all systems are able to successfully
install this package, as it requires libpng.a.

=item = 1

Image::PNG::Libpng is installed and is being used.

=back

Options:

=over

=item -nouseIPL => 1

Do B<not> use the Image::PNG::Libpng library, even if it's available. Normally
you I<would> want to use this library, when available, but there may be cases 
where you don't.

=item -silent => 1

Do not give the message that Image::PNG::Libpng is not B<installed>. This 
message will be given only once, but you may want to suppress it, such as 
during t-tests.

=item -notrans => 1

No transparency -- ignore tRNS chunk if provided, ignore Alpha channel if
provided.

=back

=cut

sub _docs {
	# dummy stub
} 

1;
