package PDF::Builder::Docs;

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

# originally part of Builder.pm, it was split out due to its length
#
# WARNING: be sure to keep in synch with changes to POD elsewhere, especially
#   for column() markup! (also list in #195 and in Content::Text)

=head1 NAME

PDF::Builder::Docs - Additional documentation for Builder module

=head1 SOME SPECIAL NOTES

=head2 Software Development Kit

There are four levels of involvement with PDF::Builder. Depending on what you
want to do, different kinds of installs are recommended.

=over

=item 1.

Simply installing PDF::Builder as a prerequisite for running some other
package. All you need to do is install the CPAN package for PDF::Builder, and
it will load the .pm files into your Perl library. If the other package prereqs
PDF::Builder, its installer may download and install PDF::Builder automatically.

=item 2.

You want to write a Perl program that uses PDF::Builder functions. In 
addition to installing PDF::Builder from CPAN, you will want documentation on
it. Obtain a copy of the product from GitHub 
(https://github.com/PhilterPaper/Perl-PDF-Builder) or as a gzipped tar file from CPAN. 
This includes a utility to 
build (from POD) a library of HTML documents, as well as examples (examples/ 
directory) and contributed sample programs (contrib/ directory).

=item 3.

You want to modify PDF::Builder files. In addition to the CPAN and GitHub
distributions, you I<may> choose to keep a local Git repository for tracking
your changes. Depending on whether or not your PDF::Builder copy is being used
for production purposes, you may want to do your editing and testing in the Perl
library installation (I<live>) or in a different place. The "t" tests (t/
directory) and examples provide good regression tests to ensure that you haven't
broken anything. If you do your editing on the live code, don't forget when done
to copy the changes back into the master version you keep!

=item 4.

You want to contribute to the development of PDF::Builder. You will need a
local Git repository (and a GitHub account), so that when you've got it all 
done, you can issue a "Pull Request" to bring it to our attention. We can't 
guarantee that your work will be incorporated into the project, but at least we
will look at it. From time to time, a new CPAN version will be issued.

=back

If you want to make substantial changes for public use, and can't come to a 
meeting of minds with us, you can even start your own GitHub project and 
register a new CPAN project (that's what we did, I<forking> PDF::API2). Please 
don't just assume that we don't want your changes -- at least propose what you 
want to do in writing, so we can consider it. We're always looking for people to
help out and expand PDF::Builder.

=head2 Optional Libraries

PDF::Builder can make use of some optional libraries, which are not I<required>
for a successful installation. If you want improved speed and capabilities for
certain functions, you may want to install and use these libraries:

=over

=item * 

Graphics::TIFF

PDF::Builder inherited a rather slow, buggy, and limited 
TIFF image library from PDF::API2. If Graphics::TIFF (available on CPAN, uses 
libtiff.a) is installed, PDF::Builder will use that instead, unless you specify 
that it is to use the old, pure Perl library. The only time you might want to 
consider this is when you need to pass an open filehandle to C<image_tiff> 
instead of a file name. See resolved bug reports RT 84665 and RT 118047, as well
as C<image_tiff>, for more information.

=item * 

Image::PNG::Libpng

PDF::Builder inherited a rather slow and buggy pure 
Perl PNG image library from PDF::API2. If Image::PNG::Libpng (available on 
CPAN, uses libpng.a) is installed, PDF::Builder will use that instead, unless 
you specify that it is to use the old, pure Perl library. Using the new library 
will give you improved speed, the ability to use 16 bit samples, and the 
ability to read interlaced PNG files. See resolved bug report RT 124349, as well
as C<image_png>, for more information.

=item * 

HarfBuzz::Shaper

This library enables PDF::Builder to handle complex
scripts (Arabic, Devanagari, etc.) as well as non-LTR writing systems. It is
also useful for Latin and other simple scripts, for ligatures and improved
kerning. HarfBuzz::Shaper is based on a set of HarfBuzz libraries, which it
will attempt to build if they are not found. See C<textHS> for more 
information.

=item * 

Text::Markdown

This library is used if you want to format "Markdown"
style code in PDF::Builder, via the C<column()> method. It translates a certain
dialect of Markdown into HTML, which is then further processed.

=item * 

HTML::TreeBuilder

This library is used to format HTML input into a 
data structure which PDF::Builder can interpret, via the C<column()> method.
Note that if Markdown input is used, it will also need HTML::TreeBuilder to
handle the HTML the Markdown is translated to.

=item * 

Pod::Simple::XHTML

This library is used if you wish to generate the HTML documentation from the
POD and PM source, using C<docs/buildDoc.pl>. Note that the full set of
documentation can also be found online at 
https://www.catskilltech.com/FreeSW/product/PDF-Builder/title/PDF%3A%3ABuilder/freeSW_full 
under the "Documentation" link. This online documentation is updated at 
every CPAN release, but not necessarily when the GitHub repository is updated.

=back

Note that the installation process will B<not> attempt to install these 
libraries automatically. If you don't wish to use one or more of them, you are
free to not install the optional librarie(s). If you may want to make use of
one or more, consider installing them I<before> installing PDF::Builder, so
that any t-tests and/or examples that make use of these libraries may be run
during installation and checkout of PDF::Builder. Remember, you can I<always>
install an optional library later, if you want to make use of it.

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
See L</Core Fonts>, L</PS Fonts> and L</TrueType Fonts> in L</FONT METHODS> 
for additional information.

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
(using C<Encode::encode>), which may need to be declared with C<encode> (for 
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

Note that some operating systems and Perl flavors are reputed to be strict
about encoding names. For example, B<latin1> (an alias) may be rejected as 
invalid, while B<iso-8859-1> (a canonical value) will work.

By the way, it is recommended that you be using I<at least> Perl 5.10 if you
are going to be using any non-ASCII characters. Perl 5.8 may be a little
unpredictable in handling such text.

=head2 Rendering Order

For better or worse, for compatibility purposes, PDF::Builder continues the 
same rendering model as used by PDF::API2 (and possibly its predecessors). That 
is, all graphics I<for one graphics object> are put into one record, and all 
text output I<for one text object> goes into another 
record. Which one is output first, is whichever is declared first. This can 
lead to unexpected results, where items are rendered in (apparently) the 
wrong order. That is, text and graphics items are not necessarily output 
(rendered) in the same order as they were created in code. Two items in the 
same object (e.g., C<$text>) I<will> be rendered in the same order as they were 
coded, but items from different objects may not be rendered in the expected 
order. The following example (source code and annotated PDF excerpts) will 
hopefully illustrate the issue:

 use strict;
 use warnings;
 use PDF::Builder;

 # demonstrate text and graphics object order
 # 
 my $fname = "objorder";

 my $paper_size = "Letter";

 # see the text and graphics stream contents
 my $pdf = PDF::Builder->new(compress => 'none');
 $pdf->mediabox($paper_size);
 my $page = $pdf->page();
 # adjust path for your operating system
 my $fontTR = $pdf->ttfont('C:\\Windows\\Fonts\\timesbd.ttf');

For the first group, you might expect the "under" line to be output, then the
filled circle (disc) partly covering it, then the "over" line covering the
disc, and finally a filled rectangle (bar) over both lines. What actually
happened is that the C<$grfx> graphics object was declared first, so everything
in that object (the disc and bar) is output first, and the text object C<$text> 
(both lines) comes afterwards. The result is that the text lines are on I<top> 
of the graphics drawings.
 
 # ----------------------------
 # 1. text, orange ball over, text over, bar over

 my $grfx1 = $page->gfx();
 my $text1 = $page->text();
 $text1->font($fontTR, 20);  # 20 pt Times Roman bold

 $text1->fillcolor('black');
 $grfx1->strokecolor('blue');
 $grfx1->fillcolor('orange');

 $text1->translate(50,700);
 $text1->text_left("This text should be under everything.");

 $grfx1->circle(100,690, 30);
 $grfx1->fillstroke();

 $text1->translate(50,670);
 $text1->text_left("This text should be over the ball and under the bar.");

 $grfx1->rect(160,660, 20,70);
 $grfx1->fillstroke();

 % ---------------- group 1: define graphics object first, then text
 11 0 obj << /Length 690 >> stream   % obj 11 is graphics for (1)
  0 0 1 RG    % stroke blue
 1 0.647059 0 rg   % fill orange
 130 690 m ... c h B   % draw and fill circle
 160 660 20 70 re B   % draw and fill bar
 endstream endobj

 12 0 obj << /Length 438 >> stream   % obj 12 is text for (1)
   BT  
 /TiCBA 20 Tf   % Times Roman Bold 20pt
 0 0 0 rg   % fill black
 1 0 0 1 50 700 Tm   % position text
 <0037 ... 0011> Tj   % "under" line
 1 0 0 1 50 670 Tm   % position text
 <0037 ... 0011> Tj   % "over" line
   ET   
 endstream endobj

The second group is the same as the first, with the only difference being
that the text object was declared first, and then the graphics object. The
result is that the two text lines are rendered first, and then the disc and
bar are drawn I<over> them.

 # ----------------------------
 # 2. (1) again, with graphics and text order reversed

 my $text2 = $page->text();
 my $grfx2 = $page->gfx();
 $text2->font($fontTR, 20);  # 20 pt Times Roman bold

 $text2->fillcolor('black');
 $grfx2->strokecolor('blue');
 $grfx2->fillcolor('orange');

 $text2->translate(50,600);
 $text2->text_left("This text should be under everything.");

 $grfx2->circle(100,590, 30);
 $grfx2->fillstroke();

 $text2->translate(50,570);
 $text2->text_left("This text should be over the ball and under the bar.");

 $grfx2->rect(160,560, 20,70);
 $grfx2->fillstroke();

 % ---------------- group 2: define text object first, then graphics
 13 0 obj << /Length 438 >> stream    % obj 13 is text for (2)
   BT  
 /TiCBA 20 Tf   % Times Roman Bold 20pt
 0 0 0 rg   % fill black
 1 0 0 1 50 600 Tm   % position text
 <0037 ... 0011> Tj   % "under" line
 1 0 0 1 50 570 Tm   % position text
 <0037 ... 0011> Tj   % "over" line
   ET   
 endstream endobj

 14 0 obj << /Length 690 >> stream   % obj 14 is graphics for (2)
  0 0 1 RG   % stroke blue
 1 0.647059 0 rg   % fill orange
 130 590 m ... h B   % draw and fill circle
 160 560 20 70 re B   % draw and fill bar
 endstream endobj

The third group defines two text and two graphics objects, in the order that
they are expected in. The "under" text line is output first, then the orange
disc graphics is output, partly covering the text. The "over" text line is now
output -- it's actually I<over> the disc, but is orange because the previous
object stream (first graphics object) left the fill color (also used for text) 
as orange, because we didn't explicitly set the fill color before outputting 
the second text line. This is not "inheritance" so much as it is whatever the 
graphics (drawing) state (used for both "graphics" and "text") is left in at 
the end of one object, it's the state at the beginning of the next object. 
If you wish to control this, consider surrounding the graphics or text calls
with C<save()> and C<restore()> calls to save and restore (push and pop) the
graphics state to what it was at the C<save()>. Finally, the bar is drawn over 
everything.

 # ----------------------------
 # 3. (2) again, with two graphics and two text objects

 my $text3 = $page->text();
 my $grfx3 = $page->gfx();
 $text3->font($fontTR, 20);  # 20 pt Times Roman bold
 my $text4 = $page->text();
 my $grfx4 = $page->gfx();
 $text4->font($fontTR, 20);  # 20 pt Times Roman bold

 $text3->fillcolor('black');
 $grfx3->strokecolor('blue');
 $grfx3->fillcolor('orange');
 # $text4->fillcolor('yellow');
 # $grfx4->strokecolor('red');
 # $grfx4->fillcolor('purple');

 $text3->translate(50,500);
 $text3->text_left("This text should be under everything.");

 $grfx3->circle(100,490, 30);
 $grfx3->fillstroke();

 $text4->translate(50,470);
 $text4->text_left("This text should be over the ball and under the bar.");

 $grfx4->rect(160,460, 20,70);
 $grfx4->fillstroke();

 % ---------------- group 3: define text1, graphics1, text2, graphics2
 15 0 obj << /Length 206 >> stream   % obj 15 is text1 for (3)
   BT  
 /TiCBA 20 Tf   % Times Roman Bold 20pt
 0 0 0 rg  % fill black
 1 0 0 1 50 500 Tm   % position text
 <0037 ... 0011> Tj   % "under" line
   ET   
 endstream endobj

 16 0 obj << /Length 671 >> stream   % obj 16 is graphics1 for (3) circle
  0 0 1 RG   % stroke blue
 1 0.647059 0 rg   % fill orange
 130 490 m ... h B   % draw and fill circle
 endstream endobj

 17 0 obj << /Length 257 >> stream   % obj 17 is text2 for (3)
   BT  
 /TiCBA 20 Tf   % Times Roman Bold 20pt
 1 0 0 1 50 470 Tm   % position text
 <0037 ... 0011> Tj   % "over" line
   ET   
 endstream endobj

 18 0 obj << /Length 20 >> stream   % obj 18 is graphics for (3) bar
  160 460 20 70 re B   % draw and fill bar
 endstream endobj

The fourth group is the same as the third, except that we define the fill color
for the text in the second line. This makes it clear that the "over" line (in
yellow) was written I<after> the orange disc, and still before the bar.

 # ----------------------------
 # 4. (3) again, a new set of colors for second group

 my $text3 = $page->text();
 my $grfx3 = $page->gfx();
 $text3->font($fontTR, 20);  # 20 pt Times Roman bold
 my $text4 = $page->text();
 my $grfx4 = $page->gfx();
 $text4->font($fontTR, 20);  # 20 pt Times Roman bold

 $text3->fillcolor('black');
 $grfx3->strokecolor('blue');
 $grfx3->fillcolor('orange');
 $text4->fillcolor('yellow');
 $grfx4->strokecolor('red');
 $grfx4->fillcolor('purple');

 $text3->translate(50,400);
 $text3->text_left("This text should be under everything.");

 $grfx3->circle(100,390, 30);
 $grfx3->fillstroke();

 $text4->translate(50,370);
 $text4->text_left("This text should be over the ball and under the bar.");

 $grfx4->rect(160,360, 20,70);
 $grfx4->fillstroke();

 % ---------------- group 4: define text1, graphics1, text2, graphics2 with colors for 2
 19 0 obj << /Length 206 >> stream   % obj 19 is text1 for (4)
   BT  
 /TiCBA 20 Tf   % Times Roman Bold 20pt
 0 0 0 rg  % fill black
 1 0 0 1 50 400 Tm   % position text
 <0037 ... 0011> Tj   % "under" line
   ET   
 endstream endobj

 20 0 obj << /Length 671 >> stream   % obj 20 is graphics1 for (4) circle
  0 0 1 RG   % stroke blue
 1 0.647059 0 rg   % fill orange
 130 390 m ... h B   % draw and fill circle
 endstream endobj

 21 0 obj << /Length 266 >> stream   % obj 21 is text2 for (4)
   BT  
 /TiCBA 20 Tf   % Times Roman Bold 20pt
 1 1 0 rg   % fill yellow
 1 0 0 1 50 370 Tm   % position text
 <0037 ... 0011> Tj   % "over" line
   ET   
 endstream endobj

 22 0 obj << /Length 52 >> stream   % obj 22 is graphics for (4) bar
  1 0 0 RG   % stroke red
 0.498039 0 0.498039 rg   % fill purple
 160 360 20 70 re B   % draw and fill rectangle (bar)
 endstream endobj

 # ----------------------------
 $pdf->saveas("$fname.pdf");

The separation of text and graphics means that only some text methods are
available in a graphics object, and only some graphics methods are available
in a text object. There is much overlap, but they differ. There's really no
reason the code couldn't have been written (in PDF::API2, or earlier) as
outputting to a single object, which would keep everything in the same order as
the method calls. An advantage would be less object and stream overhead in the
PDF file. The only drawback might be that an object might more easily 
overflow and require splitting into multiple objects, but that should be rare.

You should always be able to manually split an object by simply ending output
to the first object, and picking up with output to the second object, I<so long
as it was created immediately after the first object.> The graphics state at
the end of the first object should be the initial state at the beginning of the
second object. B<However,> use caution when dealing with text objects -- the
PDF specification states that the Text matrices are I<not> carried over from
one object to the next (B<BT> resets them), so you may need to reset some
settings.

 $grfx1 = $page->gfx();
 $grfx2 = $page->gfx();
 # write a huge amount of stuff to $grfx1
 # write a huge amount of stuff to $grfx2, picking up where $grfx1 left off

In any case, now that you understand the rendering order and how the order
of object declarations affects it, how text and graphics are drawn can now be
completely controlled as desired. There is really no need to add another "both"
type object that will handle all graphics and text objects, as that would
probably be a major code bloat for very little benefit. However, it could be
considered in the future if there is a demonstrated need for it, such as 
serious PDF file size bloat due to the extra object overhead when interleaving
text and graphics output.

There is not currently a general facility for mixed-use objects, but a limited 
example is the current implementation of underline, line-through, and overline 
text (within C<column()> markup); which are performed within the text object, 
temporarily exiting (ET) to graphics mode to draw the lines, and then returning 
(BT) to text mode. This was done so that baseline coordinate adjustments could
be easily made. Since "BT" resets some text settings, this needs to be done
with care!

=head2 Notes on Reader support of features

PDF Readers are complex pieces of software, written by different groups at
different times. Thus, they may differ in how they support features and handle
non-standard (i.e., not quite meeting standards) content! Most Readers out 
there support all or most features up through PDF 1.7, and some support PDF 2.x
features. Note that PDF::Builder supports PDF 1.4 for the most part, with a few
PDF 1.5 features added. Most any Reader out there I<should> (in theory) support 
any PDF produced with PDF::Builder.

There is no official I<reference implementation> of a Reader, although Adobe's
Acrobat Reader (I<AAR>, a free download) is so prevalent that it is almost a 
I<de facto> standard. At least, we I<try> to get PDF::Builder and its tests and 
examples to run on AAR. Sometimes it can be difficult, as, for example, the 
handling of save (B<q>) and restore (B<Q>) operators (commands) within a text 
stream. The PDF standard sort of suggests that these apply only to the Graphics 
Stream, and possibly shouldn't appear in a Text Stream. Most Readers appear to 
just ignore q and Q within a text stream, and AAR usually seems to, but certain 
combinations of stream size and compression seem to trigger a warning in AAR 
upon load! This particular case is now a moot point, as C<save()> and 
C<restore()> have been reverted to being no-ops (with a single warning message 
given if found) in a Text Stream.

We have been advised that certain stream operators may not be strictly allowed
within certain parts of a stream (particularly certain graphics state operators
after path construction has started). No Reader seems to give problems with 
this at the moment, but users should be aware that the ordering of their 
PDF::Builder calls I<may> need to be updated at some point, to get PDFs usable 
on all Readers. If necessary, we will add code to enforce this (or at least, 
warn of potential problems). Please feel free to report if you find such
restrictions are necessary.

Also note that not all I<filters> (including compression methods) may be
supported on all Readers. For example, at this time, AAR (and a number of other
Readers) apparently do not support CCITT Group 4 Fax compression (for some TIFF
images). This remains under investigation.

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
schedule of new features and bug fixes than Simms was providing, although some 
of Simms's work I<has> been ported from PDF::API2.

According to Alfred Reibenschuh's 2005 presentation 
"pdfapi2_for_fun_and_profit_APW2005.pdf" (on 
http://pdfapi2.sourceforge.net, an unmaintained site), the history of PDF::API2
(the predecessor to PDF::Builder) goes as such:

=over

=item * 

First Code implemented based on PDFlib-0.6 (AFPL)

=item * 

Changed to Text::PDF with a total rewrite as Text::PDF::API (procedural)

=item * 

Unmaintainable Code triggered rewrite into new Namespace PDF::API2 (object-oriented, LGPL)

=item * 

Object-Structure streamlined in 0.4x

=back

At Simms's request, the name of the new offering was changed from PDF::API4
to PDF::Builder, to reduce the chance of confusion due to parallel development.
Perry's intent is to keep all internal methods as upwardly compatible with
PDF::API2 as possible, although it is likely that there will be some drift
(incompatibilities) over time. At least initially, any program written based on 
PDF::API2 should be convertible to PDF::Builder simply by changing "API2" 
anywhere it occurs to "Builder". See the INFO/KNOWN_INCOMP known 
incompatibilities file for further information.

=head3 Thanks...

Many users have helped out by reporting bugs and requesting enhancements. A
special shout out goes to those who have contributed code and tests, or
coordinated their package development with the needs of PDF::Builder:
Ben Bullock, Cary Gravel, Gregor Herrmann, Petr Pisar, Jeffrey Ratcliffe,
Steve Simms (via PDF::API2 fixes), and Johan Vromans.
Drop me a line if I've overlooked your contribution!

=head1 DETAILED NOTES ON METHODS

B<Note:> older versions of this package named various (hash element) options
with leading dashes (hyphens) in the name, e.g., '-encode'. The use of a dash
is now optional, and options are documented with names I<not> using dashes. At
some point in the future, it is possible that support for dashed names will be
deprecated (and eventually withdrawn), so it would be good practice to start
using undashed names in new and revised code.

=head2 After saving a file...

Note that a PDF object such as C<$pdf> cannot continue to be used after saving
an output PDF file or string with $pdf->C<save()>, C<saveas()>, or 
C<stringify()>. There is some cleanup and other operations done internally 
which make the object unusable for further operations. You will likely receive
an error message about B<can't call method new_obj on an undefined value> if
you try to keep using a PDF object.

=head2 IntegrityCheck 

The PDF::Builder methods that open an existing PDF file, pass it by the
integrity checker method, C<$self-E<gt>IntegrityCheck(level, content)>. This method
servers two purposes: 1) to find any C</Version> settings that override the
PDF version found in the PDF heading, and 2) perform some basic validations on
the contents of the PDF.

The C<level> parameter accepts the following values:

=over

=item Z<>0

Do not output any diagnostic messages; just return any version override.

=item Z<>1 

Output error-level (serious) diagnostic messages, as well as returning any version override.

Errors include, in no place was the /Root object specified, or if it was, the indicated object was not found. An object claims another object as its child (/Kids list), but another object has already claimed that child. An object claims a child, but that child does not list a Parent, or the child lists a different Parent.

=item Z<>2

Output error- (serious) and warning- (less serious) level diagnostic messages, as well as returning any version override. B<This is the default.>

=item Z<>3

Output error- (serious), warning- (less serious), and note- (informational) level diagnostic messages, as well as returning any version override.

Notes include, in no place was the (optional) /Info object specified, or if it was, the indicated object was not found. An object was referenced, but no entry for it was found among the objects. (This may be OK if the object is not defined, or is on the free list, as the reference will then be ignored.) An object is defined, but it appears that no other object is referencing it.

=item Z<>4

Output error-, warning-, and note-level diagnostic messages, as well as returning any version override. Also dump the diagnostic data structure.

=item Z<>5

Output error-, warning-, and note-level diagnostic messages, as well as returning any version override. Also dump the diagnostic data structure and the C<$self> data structure (generally useful only if you have already read in the PDF file).

=back

The version is a string (e.g., '1.5') if found, otherwise C<undef> (undefined value) is returned.

For controlling the "automatic" call to IntegrityCheck (via opens), the level 
may be given with the option (flag) C<diaglevel =E<gt> I<n>>, where C<n> is between 0 and 5.

=head2 Preferences - set user display preferences

=over

=item $pdf->preferences(%options)

Controls viewing preferences for the PDF.

=back

=head3 Page Mode Options

=over

=item fullscreen

Full-screen mode, with no menu bar, window controls, or any other window visible.

=item thumbs

Thumbnail images visible.

=item outlines

Document outline visible.

=back

=head3 Page Layout Options

=over

=item singlepage

Display one page at a time.

=item onecolumn

Display the pages in one column.

=item twocolumnleft

Display the pages in two columns, with odd-numbered pages on the left.

=item twocolumnright

Display the pages in two columns, with odd-numbered pages on the right.

=back

=head3 Viewer Options

=over

=item hidetoolbar

Specifying whether to hide tool bars.

=item hidemenubar

Specifying whether to hide menu bars.

=item hidewindowui

Specifying whether to hide user interface elements.

=item fitwindow

Specifying whether to resize the document's window to the size of the displayed page.

=item centerwindow

Specifying whether to position the document's window in the center of the screen.

=item displaytitle

Specifying whether the window's title bar should display the
document title taken from the Title entry of the document information
dictionary.

=item afterfullscreenthumbs

Thumbnail images visible after Full-screen mode.

=item afterfullscreenoutlines

Document outline visible after Full-screen mode.

=item printscalingnone

Set the default print setting for page scaling to none.

=item simplex

Print single-sided by default.

=item duplexflipshortedge

Print duplex by default and flip on the short edge of the sheet.

=item duplexfliplongedge

Print duplex by default and flip on the long edge of the sheet.

=back

=head3 Page Fit Options

These options are used for the C<firstpage> layout, as well as for 
Annotations, Named Destinations and Outlines.

=over

=item 'fit' => 1

Display the page designated by C<$page>, with its contents magnified just
enough to fit the entire page within the window both horizontally and
vertically. If the required horizontal and vertical magnification
factors are different, use the smaller of the two, centering the page
within the window in the other dimension.

=item 'fith' => $top

Display the page designated by C<$page>, with the vertical coordinate C<$top>
positioned at the top edge of the window and the contents of the page
magnified just enough to fit the entire width of the page within the
window.

=item 'fitv' => $left

Display the page designated by C<$page>, with the horizontal coordinate
C<$left> positioned at the left edge of the window and the contents of the
page magnified just enough to fit the entire height of the page within
the window.

=item 'fitr' => [ $left, $bottom, $right, $top ]

Display the page designated by C<$page>, with its contents magnified just
enough to fit the rectangle specified by the coordinates C<$left>, C<$bottom>,
C<$right>, and C<$top> entirely within the window both horizontally and
vertically. If the required horizontal and vertical magnification
factors are different, use the smaller of the two, centering the
rectangle within the window in the other dimension.

=item 'fitb' => 1

Display the page designated by C<$page>, with its contents magnified just
enough to fit its bounding box entirely within the window both
horizontally and vertically. If the required horizontal and vertical
magnification factors are different, use the smaller of the two,
centering the bounding box within the window in the other dimension.

=item 'fitbh' => $top

Display the page designated by C<$page>, with the vertical coordinate C<$top>
positioned at the top edge of the window and the contents of the page
magnified just enough to fit the entire width of its bounding box
within the window.

=item 'fitbv' => $left

Display the page designated by C<$page>, with the horizontal coordinate
C<$left> positioned at the left edge of the window and the contents of the
page magnified just enough to fit the entire height of its bounding
box within the window.

=item 'xyz' => [ $left, $top, $zoom ]

Display the page designated by C<$page>, with the coordinates C<$[$left, $top]>
positioned at the top-left corner of the window and the contents of
the page magnified by the factor C<$zoom>. A zero (0) value for any of the
parameters C<$left>, C<$top>, or C<$zoom> specifies that the current value of 
that parameter is to be retained unchanged.

=back

=head3 Initial Page Options

=over

=item firstpage => [ $page, %options ]

Specifying the page (either a page number or a page object) to be
displayed, plus one of the location options listed above in L<Page Fit Options>.

=back

=head3 Example

    $pdf->preferences(
        fullscreen => 1,
        onecolumn => 1,
        afterfullscreenoutlines => 1,
        firstpage => [$page, fit => 1],
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

=head2 "BOX" METHODS

B<A general note:> Use care if specifying a different Media Box (or other "box")
for a page, than the global "box" setting, to define the whole "chain" of boxes
on the page, to avoid surprises. For example, to define a global Media Box 
(paper size) and a global Crop Box, and then define a new page-level Media Box 
I<without> defining a new page-level Crop Box, may give odd results in the
resultant cropping. Such combinations are not well defined.

All dimensions in boxes default to the default User Unit, which is points (1/72 
inch). Note that the PDF specification limits sizes and coordinates to 14400
User Units (200 inches, for the default User Unit of one point), and Adobe 
products (so far) follow this limit for Acrobat and Distiller. It is worth 
noting that other PDF writers and readers may choose to ignore the 14400 unit 
limit, with or without the use of a specified User Unit. Therefore, PDF::Builder
does not enforce any limits on coordinates -- it's I<your> responsibility to
consider what readers and other PDF tools may be used with a PDF you produce!
Also note that earlier Acrobat readers had coordinate limits as small as 3240
User Units (45 inches), and I<minimum> media size of 72 or 3 User Units.

=head3 User Units (userunit)

    $pdf->userunit($number)

=over

The default User Unit in the PDF coordinate system is one point (1/72 inch). You
can think of it as a scale factor to enable larger (or even, smaller) documents.
This method may be used (for PDF 1.6 and higher) to set the User Unit to some
number of points. For example, C<userunit(72)> will set the scale multiplier to
72.0 points per User Unit, or 1 inch to the User Unit. Any number greater than
zero is acceptable, although some readers and tools may not handle User Units of
less than 1.0 very well.

Not all readers respect the User Unit, if you give one, or handle it in exactly
the same way. Adobe Distiller, for one, does not use it. How User Units are 
handled may vary from reader to reader. Adobe Acrobat, at this writing, respects
User Unit in version 7.0 and up, but limits it to 75000 (giving a maximum
document size of 15 million inches or 236.7 miles or 381 km). Other readers and
PDF tools may allow a larger (or smaller) limit. 

B<Your Mileage May Vary:> Some readers ignore a global
User Unit setting and do I<not> have pages inherit it (PDF::Builder duplicates 
it on each page to simulate inheritance). Some readers may give spurious
warnings about truncated content when a Media Box is changed while User Units
are being used. Some readers do strange things with Crop Boxes when a User Unit 
is in effect.

Depending on the reader used, the effect of a larger User Unit (greater than 1)
may mean lower resolution (chunkier or coarser appearance) in the rendered 
document. If you're printing something the size of a highway billboard, this may
not matter to you, but you should be aware of the possibility (even with 
fractional coordinates). Conversely, a User Unit of less than 1.0 (if permitted)
reduces the allowable size of your document, but I<may> result in greater
resolution.

A global (PDF level) User Unit setting is inherited by each page (an action by
PDF::Builder, not necessarily automatically done by the reader), or can be 
overridden by calling userunit in the page. Do not give more than one global 
userunit setting, as only the last one will be used.
Setting a page's User Unit (if C<< $page-> >> instead) is permitted (overriding
the global setting for this page). However, many sources recommend against 
doing this, as results may not be as expected (once again, depending on the
quirks of the reader).

Remember to call C<userunit> I<before> calling anything having to do with page
or box sizes, or coordinates. Especially when setting 'named' box sizes, the 
methods need to know the current User Unit so that named page sizes (in points)
may be scaled down to the current User Unit.

=back

=head3 Media Box (mediabox)

    $pdf->mediabox($name)

    $pdf->mediabox($name, orient => 'orientation' )

    $pdf->mediabox($w,$h)

    $pdf->mediabox($llx,$lly, $urx,$ury)

    ($llx,$lly, $urx,$ury) = $pdf->mediabox()

=over

Sets the global Media Box (or page's Media Box, if C<< $page-> >> instead). 
This defines the width and height (or by corner
coordinates, or by standard name) of the output page itself, such as the
physical paper size. This is normally the largest of the "boxes". If any
subsidiary box (within it) exceeds the media box, the portion of the material 
or boxes outside of the Media Box will be ignored. That is, the Media Box is
the One Box to Rule Them All, and is the overall limit for other boxes (some
documentation refers to the Media Box as "clipping" other boxes). In
addition, the Media Box defines the overall I<coordinate system> for text and
graphics operations.

If no arguments are given, the current Media Box (global or page) coordinates
are returned instead. The former C<get_mediabox> (page only) function was 
B<deprecated> and has been removed. In addition,
when I<setting> the Media Box, the resulting coordinates are returned. This 
permits you to specify the page size by a name (alias) and get the dimensions 
back, all in one call.

Note that many printers can B<not> print all the way to the
physical edge of the paper, so you should plan to leave some blank margin,
even outside of any crop marks and bleeds. Printers and on-screen readers are 
free to discard any content found outside the Media Box, and printers may 
discard some material just inside the Media Box.

A I<global> Media Box is B<required> by the PDF spec; if not explicitly given, 
PDF::Builder will set the global Media Box to US Letter size (8.5in x 11in).
This is the media size that will be used for all pages if you do not specify 
a C<mediabox> call on a page. That is,
a global (PDF level) mediabox setting is inherited by each page, or can be 
overridden by setting mediabox in the page. Do not give more than one global 
mediabox setting, as only the last one will be used.

If you give a single string name (e.g., 'A4'), you may optionally add an
orientation to turn the page 90 degrees into Landscape mode: 
C<< orient => 'L' >> or C<< orient => 'l' >>. C<orient> is the only option
recognized, and a string beginning with an 'L' or 'l' (for Landscape) is the 
only value of interest (anything else is treated as Portrait mode). The I<y>
axis still runs from 0 at the bottom of the page to what used to be the page
I<width> (now, I<height>) at the top, and likewise for the I<x> axis: 0 at left 
to (former) I<height> at the right. That is, the coordinate system is the same 
as before, except that the height and width are different.

The lower left corner does not I<have> to be 0,0. It can be any values you want,
including negative values (so long as the resulting media's sides are at least 
one point long). C<mediabox> sets the coordinate system (including the origin) 
of the graphics and text that will be drawn, as well as for subsequent "boxes". 
It's even possible to give any two opposite corners (such as upper left and 
lower right). The coordinate system will be rearranged (by the Reader) to 
still be the conventional minimum C<x> and C<y> in the lower left (i.e., you 
can't make C<y> I<increase> from top to bottom!).

B<Example:>

=back

    $pdf = PDF::Builder->new();
    $pdf->mediabox('A4'); # A4 size (595 Pt wide by 842 Pt high)
    ...
    $pdf->saveas('our/new.pdf');

    $pdf = PDF::Builder->new();
    $pdf->mediabox(595, 842); # A4 size, with implicit 0,0 LL corner
    ...
    $pdf->saveas('our/new.pdf');

    $pdf = PDF::Builder->new;
    $pdf->mediabox(0, 0, 595, 842); # A4 size, with explicit 0,0 LL corner
    ...
    $pdf->saveas('our/new.pdf');

=over

See the L<PDF::Builder::Resource::PaperSizes> source code for the full list of
supported names (aliases) and their dimensions in points. You are free to add
additional paper sizes to this file, if you wish. You might want to do this if
you frequently use a standard page size in rotated (Landscape) mode. See also 
the C<getPaperSizes> call in L<PDF::Builder::Util>. These names (aliases) are 
also usable in other "box" calls, although useful only if the "box" is the same 
size as the full media (Media Box), and you don't mind their starting at 0,0.

=back

=head3 Crop Box (cropbox)

    $pdf->cropbox($name)

    $pdf->cropbox($name, orient => 'orientation')

    $pdf->cropbox($w,$h)

    $pdf->cropbox($llx,$lly, $urx,$ury)

    ($llx,$lly, $urx,$ury) = $pdf->cropbox()

=over

Sets the global Crop Box (or page's Crop Box, if C<< $page-> >> instead). 
This will define the media size to which the output will 
later be I<clipped>. Note that this does B<not> itself output any crop marks 
to guide cutting of the paper! PDF Readers should consider this to be the 
I<visible> portion of the page, and anything found outside it I<may> be clipped 
(invisible). By default, it is equal to the Media Box, but may be defined to be 
smaller, in the coordinate system set by the Media Box. A global setting will 
be inherited by each page, but can be overridden on a per-page basis.

A Reader or Printer may choose to discard any clipped (invisible) part of the
page, and show only the area I<within> the Crop Box. For example, if your page
Media Box is A4 (0,0 to 595,842 Points), and your Crop Box is (100,100 to
495,742), a reader such as Adobe Acrobat Reader may show you a page 395 by
642 Points in size (i.e., just the visible area of your page). Other Readers 
may show you the full media size (Media Box) and a 100 Point wide blank area 
(in this example) around the visible content.

If no arguments are given, the current Crop Box (global or page) coordinates
are returned instead. The former C<get_cropbox> (page only) function was 
B<deprecated> and has been removed. If a Crop Box
has not been defined, the Media Box coordinates (which always exist) will be
returned instead. In addition,
when I<setting> the Crop Box, the resulting coordinates are returned. This 
permits you to specify the crop box by a name (alias) and get the dimensions 
back, all in one call.

Do not confuse the Crop Box with the C<Trim Box>, which shows where printed 
paper is expected to actually be I<cut>. Some PDF Readers may reduce the 
visible "paper" background to the size of the crop box; others may simply omit 
any content outside it. Either way, you would lose any trim or crop marks, 
printer instructions, color alignment dots, or other content outside the Crop 
Box. I<A good use of the Crop Box> would be limit printing to the area where a 
printer I<can> reliably put down ink, and leave white the edge areas where 
paper-handling mechanisms prevent ink or toner from being applied. This would
keep you from accidentally putting valuable content in an area where a printer
will refuse to print, yet permit you to include a bleed area and space for
printer's marks and instructions. Needless to say, if your printer cannot print
to the very edge of the paper, you will need to trim (cut) the printed sheets
to get true bleeds.

A global (PDF level) cropbox setting is inherited by each page, or can be 
overridden by setting cropbox in the page.
As with C<mediabox>, only one crop box may be set at this (PDF) level.
As with C<mediabox>, a named media size may have an orientation (l or L) for 
Landscape mode. 
Note that the PDF level global Crop Box will be used I<even if> the page gets
its own Media Box. That is, the page's Crop Box inherits the global Crop Box,
not the page Media Box, even if the page has its own media size! If you set the
page's own Media Box, you should consider also explicitly setting the page
Crop Box (and other boxes).

=back

=head3 Bleed Box (bleedbox)

    $pdf->bleedbox($name)

    $pdf->bleedbox($name, orient => 'orientation')

    $pdf->bleedbox($w,$h)

    $pdf->bleedbox($llx,$lly, $urx,$ury)

    ($llx,$lly, $urx,$ury) = $pdf->bleedbox()

=over

Sets the global Bleed Box (or page's Bleed Box, if C<< $page-> >> instead). 
This is typically used in printing on paper, where you want 
ink or color (such as thumb tabs) to be printed a bit beyond the final paper 
size, to ensure that the cut paper I<bleeds> (the cut goes I<through> the ink), 
rather than accidentally leaving some white paper visible outside.  Allow 
enough "bleed" over the expected trim line to account for minor variations in 
paper handling, folding, and cutting; to avoid showing white paper at the edge. 
The Bleed Box is where I<printing> could actually extend to; the Trim Box is 
normally within it, where the paper would actually be I<cut>. The default 
value is equal to the Crop Box, but is often a bit smaller. The space between
the Bleed Box and the Crop Box is available for printer instructions, color
alignment dots, etc., while crop marks (trim guides) are at least partly within
the bleed area (and should be printed after content is printed).

If no arguments are given, the current Bleed Box (global or page) coordinates
are returned instead. The former C<get_bleedbox> (page only) function was 
B<deprecated> and has been removed. If a Bleed Box
has not been defined, the Crop Box coordinates (if defined) will be returned,
otherwise the Media Box coordinates (which always exist) will be returned. 
In addition, when I<setting> the Bleed Box, the resulting coordinates are 
returned. This permits you to specify the bleed box by a name (alias) and get 
the dimensions back, all in one call.

A global (PDF level) bleedbox setting is inherited by each page, or can be 
overridden by setting bleedbox in the page.
As with C<mediabox>, only one bleed box may be set at this (PDF) level.
As with C<mediabox>, a named media size may have an orientation (l or L) for 
Landscape mode. 
Note that the PDF level global Bleed Box will be used I<even if> the page gets
its own Crop Box. That is, the page's Bleed Box inherits the global Bleed Box,
not the page Crop Box, even if the page has its own media size! If you set the
page's own Media Box or Crop Box, you should consider also explicitly setting 
the page Bleed Box (and other boxes).

=back

=head3 Trim Box (trimbox)

    $pdf->trimbox($name)

    $pdf->trimbox($name, orient => 'orientation')

    $pdf->trimbox($w,$h)

    $pdf->trimbox($llx,$lly, $urx,$ury)

    ($llx,$lly, $urx,$ury) = $pdf->trimbox()

=over

Sets the global Trim Box (or page's Trim Box, if C<< $page-> >> instead). 
This is supposed to be the actual dimensions of the 
finished page (after trimming of the paper). In some production environments, 
it is useful to have printer's instructions, cut marks, and so on outside of 
the trim box. The default value is equal to Crop Box, but is often a bit 
smaller than any Bleed Box, to allow the desired "bleed" effect.

If no arguments are given, the current Trim Box (global or page) coordinates
are returned instead. The former C<get_trimbox> (page only) function was 
B<deprecated> and has been removed. If a Trim Box
has not been defined, the Crop Box coordinates (if defined) will be returned,
otherwise the Media Box coordinates (which always exist) will be returned. 
In addition, when I<setting> the Trim Box, the resulting coordinates are 
returned. This permits you to specify the trim box by a name (alias) and get 
the dimensions back, all in one call.

A global (PDF level) trimbox setting is inherited by each page, or can be 
overridden by setting trimbox in the page.
As with C<mediabox>, only one trim box may be set at this (PDF) level.
As with C<mediabox>, a named media size may have an orientation (l or L) for 
Landscape mode. 
Note that the PDF level global Trim Box will be used I<even if> the page gets
its own Crop Box. That is, the page's Trim Box inherits the global Trim Box,
not the page Crop Box, even if the page has its own media size! If you set the
page's own Media Box or Crop Box, you should consider also explicitly setting 
the page Trim Box (and other boxes).

=back

=head3 Art Box (artbox)

    $pdf->artbox($name)

    $pdf->artbox($name, orient => 'orientation')

    $pdf->artbox($w,$h)

    $pdf->artbox($llx,$lly, $urx,$ury)

    ($llx,$lly, $urx,$ury) = $pdf->artbox()

=over

Sets the global Art Box (or page's Art Box, if C<< $page-> >> instead). 
This is supposed to define "the extent of the page's 
I<meaningful> content (including [margins])". It might exclude some content, 
such as Headlines or headings. Any binding or punched-holes margin would 
typically be outside of the Art Box, as would be page numbers and running 
headers and footers. The default value is equal to the Crop Box, although 
normally it would be no larger than any Trim Box. The Art Box may often be
used for defining "important" content (e.g., I<excluding> advertisements) that 
may or may not be brought over to another page (e.g., N-up printing).

If no arguments are given, the current Art Box (global or page) coordinates
are returned instead. The former C<get_artbox> (page only) function was 
B<deprecated> and has been removed. If an Art Box
has not been defined, the Crop Box coordinates (if defined) will be returned,
otherwise the Media Box coordinates (which always exist) will be returned. 
In addition, when I<setting> the Art Box, the resulting coordinates are 
returned. This permits you to specify the art box by a name (alias) and get 
the dimensions back, all in one call.

A global (PDF level) artbox setting is inherited by each page, or can be 
overridden by setting artbox in the page.
As with C<mediabox>, only one art box may be set at this (PDF) level.
As with C<mediabox>, a named media size may have an orientation (l or L) for 
Landscape mode. 
Note that the PDF level global Art Box will be used I<even if> the page gets
its own Crop Box. That is, the page's Art Box inherits the global Art Box,
not the page Crop Box, even if the page has its own media size! If you set the
page's own Media Box or Crop Box, you should consider also explicitly setting 
the page Art Box (and other boxes).

=back

=head3 Suggested Box Usage

See C<examples/Boxes.pl> for an example of using boxes.

How you define your boxes (or let them default) is up to you, depending on 
whether you're duplex printing US Letter or A4 on your laser printer, to be 
spiral bound on the bind margin, or engaging a professional printer. In the 
latter case, discuss in advance with the print firm what capabilities (and
limitations) they have 
and what information they need from a PDF file. For instance, they may not want 
a Crop Box defined, and may call for very specific box sizes. For large press
runs, they may print multiple pages (N-up) duplexed on large web roll 
"signatures", which are then intricately folded and guillotined (trimmed) and 
bound together into books or magazines. You would usually just supply a PDF
with all the pages; they would take care of the signature layout (which 
includes offsets and 180 degree rotations). 

(As an aside, don't count on a commercial printer having
any particular font available, so be sure to ask. Usually they will want you
to embed all fonts used, but ask first, and double-check before handing over
the print job! TTF/OTF fonts (C<ttfont()>) are embedded by default, but other 
fonts (core, ps, bdf, cjk) are not! A printer I<may> have a core font 
collection, but they are free to substitute a "workalike" font for any given 
core font, and the results may not match what you saw on your PC!)

On the assumption that you're using a single sheet (US Letter or A4) laser or
inkjet printer, are you planning to trim each sheet down to a smaller final 
size? If so, you can do true bleeds by defining a Trim Box and a slightly 
larger Bleed Box. You would print bleeds (all the way to the finished edge)
out to the Bleed Box, but nothing is enforced about the Bleed Box. At the other 
end of the spectrum, you would define the Media 
Box to be the physical paper size being printed on. Most printers reserve a
little space on the sides (and possibly top and bottom) for paper handling, so
it is often good to define your Crop Box as the printable area. Remember that
the Media Box sets the coordinate system used, so you still need to avoid 
going outside the Crop Box with content (most readers and printers will not
show any ink outside of the Crop Box). Whether or not you define a Crop Box,
you're going to almost always end up with white paper on at least the sides.

For small in-house jobs, you probably won't need color alignment dots and other 
such professional instructions and information between the Bleed Box and the 
Crop Box, but crop marks for trimming (if used) should go just outside the Trim 
Box (partly or wholly within the Bleed Box), and
be drawn I<after> all content. If you're I<not> trimming the paper, don't try 
to do any bleed effects (including solid background color pages/covers), as 
you will usually have a white edge around the sheet anyway (printers leave a 
clean, dry route for the feed rollers). Don't count on a PDF document I<never> 
being physically printed,
and not just displayed (where you can do things like bleed all the way to the
media edge). Finally, for single sheet printing, an Art Box is 
probably unnecessary, but if you're combining pages into N-up prints, or doing 
other manipulations, it may be useful.

=head3 Box Inheritance

What Media, Crop, Bleed, Trim, and Art Boxes a page gets can be a little
complicated. Note that usually, only the Media and Crop Boxes will have a 
clear visual effect. The visual effect of the other boxes (if any) may be
very subtle.

First, everything is set at the global (PDF) level. The Media Box is always 
defined, and defaults to US Letter (8.5 inches wide by 11 inches high). The
global Crop Box inherits the Media Box, unless explicitly defined. The Bleed,
Trim, and Art Boxes inherit the Crop Box, unless explicitly defined. A global
box should only be defined once, as the last one defined is the one that will
be written to the PDF!

Second, a page inherits the global boxes, for its initial settings. You may
call any of the box set methods (C<cropbox>, C<trimbox>, etc.) to explicitly
set (override) any box for I<this> page. Note that setting a new Media Box for
the page does B<not> reset the page's Crop Box -- it still uses whatever it 
inherited from the global Crop Box. You would need to explicitly set the page's 
Crop Box if you want a different setting. Likewise, the page's Bleed, Trim, and
Art Boxes will not be reset by a new page Crop Box -- they will still inherit
from the global (PDF) settings.

Third, the page Media Box (the one actually used for output pages), clips or
limits all the other boxes to extend no larger than its size. For example, if
the Media Box is US Letter, and you set a Crop Box of A4 size, the smaller of
the two heights (11 inches) would be effective, and the smaller of the two
widths (8.26 inches, 595 Points) would be effective.
The I<given> dimensions of a box are returned on query (get), not the 
I<effective> dimensions clipped by the Media Box.

=head2 Outlines (Bookmarks)

It is possible to create I<outlines> (a.k.a. I<bookmarks>) in a PDF document.
You are not limited to entire pages as targets, but can adjust the destination 
C<dest()> to bring up a specific part of a page.

=head3 Simple Single-Level set of Outline

Inserts three outlines (at the same level) in a simple list of 12 pages
(055_outlines example):

    my $doc = PDF::Builder-> open($infile);

    $doc-> outlines
        -> outline
            -> dest( $doc-> openpage( 1 ))
            -> title( '1st page (i)' );

    $doc-> outlines
        -> outline
            -> dest( $doc-> openpage( 4 ))
            -> title( '4th page (1)' );

    $doc-> outlines
        -> outline
            -> dest( $doc-> openpage( 11 ))
            -> title( '11th page (7)' );

C<dest()> by default is a link to an entire page (given as the ordinal page
number, I<not> the document's formatted page number). The C<title()> is what
you see in the Outline or Bookmark section of your PDF Reader.

=head3 A Multi-level example Outline

It is also possible to define nested (multiple level) outlines. For the same 
set of pages as above, we will add two pages nested under B<page i> and three
pages nested under B<page 1>. Note that it is common practice to make the top
level I<sections> (e.g., I<preface, body, end matter>) and put all the real 
pages under them, but you still need to have each section "heading" map to a 
real page. Thus I<preface> might point to page B<i>, and have outlines to 
B<i, ii,> and B<iii> nested below it.

    my $doc = PDF::Builder-> open($infile);
    my $root =  # Outlines object (root of whole thing)
        $doc-> outlines();

    my $top0 =  # Outline object at top level, initially collapsed (closed)
    $root -> outline($root)
            -> is_open(0)        
            -> dest( $doc-> openpage( 1 ))
            -> title( '1st page (i)' );

    my $top1 =  # Outline object at top level
    $root -> outline($root)
            -> dest( $doc-> openpage( 4 ))
            -> title( '4th page (1)' );

    my $top2 =  # Outline object at top level. no children
    $root -> outline($root)
            -> dest( $doc-> openpage( 11 ))
            -> title( '11th page (7)' );

    # add lower level bookmarks here. there's no reason that they couldn't be
    # mixed in with the higher levels above, provided that they come after
    # their parent is defined.

    # two pages under the first top-level page (i)
    $top0 -> outline($top0)
              -> dest( $doc-> openpage( 2 ))
              -> title( '2nd page (ii)' );
 
    $top0 -> outline($top0)
              -> dest( $doc-> openpage( 3 ))
              -> title( '3rd page (iii)' );

    # three pages under the second top-level page (1). the third is
    # inserted after the first and before the second.
    my $first =
    $top1 -> outline($top1)
              -> dest( $doc-> openpage( 5 ))
              -> title( '5th page (2)' );
 
    $top1 -> outline($top1)
              -> dest( $doc-> openpage( 6 ))
              -> title( '6th page (3)' );
 
    $first -> insert_after()
              -> dest( $doc-> openpage( 7 ))
              -> title( '7th page (4)' );
 
It is possible to define a single outline (link) as B<closed>, in which case
all the outlines nested under it will be hidden (with a "closed" twistor). 
Try to avoid going more than two levels deep (one level of nesting), as the
Outlines/Bookmarks column is usually fairly narrow.

=head2 FONT METHODS

=head3 Core Fonts

These are the "built-in" fonts, in the sense that any PDF Reader is guaranteed
to supply and support them. The I<metrics> for the supported fonts are 
shipped with PDF::Builder, but not the fonts themeselves.

Core fonts are limited to B<single byte encodings>. The default encoding for 
the core fonts is WinAnsiEncoding (roughly the CP-1252/Windows-1252 superset of 
ISO-8859-1/Latin-1). See the C<encode> option below to change this encoding.

There are some 14 core fonts (regular, I<italic>, B<bold>, and B<I<bold-italic>>
variants) for Times [serif], Helvetica [sans serif], Courier [fixed pitch]; 
plus two symbol fonts, Symbol and Zapf Dingbats) that are supposed to be 
available on any PDF Reader, B<although other fonts with very similar metrics 
are often substituted.> 

Windows machines have an additional 14 "core" fonts (15 if you count Bank 
Gothic): Georgia [serif], Verdana [sans serif], and Trebuchet [sans serif] in 
4 variants each, along with Webdings and Wingdings). These are
I<usually> available on a Windows platform (but not guaranteed!). They are 
usually not installed by default on Linux, Mac, and other non-Windows 
platforms, so use caution if specifying these fonts.

=head4 Examples

    $font1 = $pdf->corefont('Times-Roman', encode => 'latin2');
    $font2 = $pdf->corefont('Times-Bold');
    $font3 = $pdf->corefont('Helvetica');
    $font4 = $pdf->corefont('ZapfDingbats');

Core fonts can also be requested via the C<font()> method

    $font5 = $pdf->font('Courier-Oblique');

as well as being built into FontManager

    $font6 = $pdf->get_font('face'=>'Times', 'italic'=>1, 'bold'=>0);

=head4 Notes and Limitations

=over

=item *

You B<cannot> use UTF-8 or other multibyte encodings with core fonts, I<only>
single byte encodings (256 characters maximum). A PDF Reader simply does not
know what to do with a multibyte character, and likely will render it as a
sequence of single characters (producing garbage). Although most single-byte 
encodings, at least for European languages, are supported, it is possible that 
you might encounter an encoding that includes a character I<not> found in a 
given font file, or vice-versa (the font includes characters that the encoding 
does not give you access to).

=item *

Do not confuse Unicode character points (such as given with an HTML entity) 
with single byte values or multibyte characters. The only way to access a
character defined for a given encoding is with a I<single> byte value in the 
range 0 to 255. For example, if you can't directly type a "Euro" symbol, it is 
C<\x80> in many encodings -- you would use that instead of the Unicode 
C<\x{20AC}> code point or C<x\{E282AC}> UTF-8 byte string. It's a matter of 
giving a single byte value that the PDF Reader can look up in its font 
definition to get the desired glyph. If the "Euro" symbol is not found in the 
encoding you're using, well, you're out of luck.

=item *

Be aware of what a given platform (operating system) and editor is using for 
its code page when it creates a file with your text to be turned into a PDF!
If you typed a "Euro" but it's, say, a UTF-8 byte string in the file, you 
probably won't get a "Euro" in your PDF.

=item *

Note that core fonts use fixed lists of expected glyphs, along with metrics
such as their widths. This may not exactly match up with whatever local font
file is used by the PDF Reader. It's usually pretty close, but many cases have
been found where the list of glyphs is different between the core fonts and
various local font files, so be aware of this. There is no guarantee that all
glyphs (code points) found in one single-byte encoding will be found in
another, nor that font metrics are available for all glyphs covered by a given
singe-byte encoding. If you are writing in English, or even in most Western
European languages, this is usually not a problem with core fonts, but for 
other languages and alphabets, it might be.

=item *

Also be aware that a PDF Reader is free to substitute another font which is
similar (but not necessarily identical) to the requested core font. For example,
Windows machines often substitute I<Arial> for the requested I<Helvetica>. The
metrics (widths) are the same, but the glyphs are a little different.

=item *

Core fonts are supposed to be available on all PDF Readers, so they are not
embeddable in the PDF (as TTF fonts are). This is not believed to be a problem
for archival (PDF/A) documents, but may become one at some point, so you should
be aware.

=back

See L<PDF::Builder::Resource::Font/font automap> method for information on
accessing more than 256 glyphs in a font, using B<planes>, I<although there is 
no guarantee that future changes to font files will permit consistent results>.

=head4 Should you use TTF instead?

If you need to reliably access certain characters not found in common 
encodings, please consider using TrueType (TTF) or OpenType (OTF) fonts via the 
C<ttfont()> method. Note that you will be responsible for specifying the exact 
path and full file name of the TTF file, and making sure the font file is
available on the PDF Writer, and possibly on the Reader (if not embedded).

This would enable you to use UTF-8 text, with extended glyph usability, as well
as permitting the font itself to be embedded in the PDF, ensuring that you get
I<exactly> the glyphs you want, without any substitutions. Kerning and
ligature support (via HarfBuzz::Shaper) may be more available for TTF fonts.
There are tools, such as I<FontForge>, which can do a fairly good
(though, not perfect) job of converting a Type1 font library (if that's what
your core fonts are, internally) to OTF.

See also L<PDF::Builder::Resource::Font::CoreFont>.

=head3 PS Fonts

PostScript fonts are also known as "Type 1" fonts. These are not "built-in" 
fonts, and both the PDF Writer and any PDF Reader would need to provide the 
desired font files. PostScript fonts used to be very commonly used, but have
fallen out of favor.

PS (Type 1) fonts are I<not> shipped with PDF::Builder, but are 
expected to be found on the machine with the PDF reader. Most PDF readers do 
I<not> install PS fonts, and it is up to the user of the PDF reader to install
the needed fonts. Unlike TrueType fonts, PS (T1) fonts are not embedded in the 
PDF, and must be supplied on the Reader end.

PS fonts are limited to B<single byte encodings>. The default encoding for 
the PS fonts is WinAnsiEncoding (roughly the CP-1252/Windows-1252 superset of 
ISO-8859-1/Latin-1). See the C<encode> option below to change this encoding.

One characteristic of PS font usage is that I<two> files are used for each
font: a glyph file (C<.pfa> for ASCII format, C<.pfb> for binary format, or
C<.t1> for an extended format), and a metrics file (C<.afm> for an ASCII 
format, or C<.pfm> for binary format). A binary glyph file may be used with
an ASCII metrics file, and vice-versa, if desired or needed. The ASCII and 
binary files have the same content, just in different formats.

B<Caution:> the file name given for the glyph file (first argument to C<psfont>)
I<must> have a file extension of .pfa, .pfb, or .t1; as the extension will
be checked to see how to parse the file.

=head4 WARNING: End of Adobe Support

B<Adobe has announced an end to support for Type 1 (Postscript/T1) fonts in its 
products. The announcement wordings are a bit vague, sometimes referring to 
"all products" and other times just to "authoring software". Presumably, Adobe 
PDF Readers (as well as Readers supplied by other parties) will continue to 
display PDFs with Type 1 fonts for quite some time, although this is by no 
means absolutely certain. Note that this does NOT mean that PDF::Builder or 
other Third Party authoring tools may not continue to support Type 1 fonts. 
This termination by Adobe of support of a now old and obsolete font format does 
not affect the use of PDF::Builder for authoring PDFs, nor is it binding on 
other non-Adobe readers and authoring tools. However, using Adobe products for 
editing of PDFs with Type 1 fonts, and possibly of displaying them, may no 
longer be possible. At any rate, users may want to consider starting to move 
away from Type 1 font usage and switch to TTF/OTF or even core fonts, although 
it is unknown how long Type 1 Reader support will continue.>

=head4 Examples

    $font1 = $pdf->psfont('Times-Book.pfa', afmfile => 'Times-Book.afm');
    $font2 = $pdf->psfont('/fonts/Synest-FB.pfb', pfmfile => '/fonts/Synest-FB.pfm');

PS fonts can also be requested via the C<font()> method

    $font3 = $pdf->font('/fonts/Times-Book.t1', afmfile => '/fonts/Times-Book.afm');

as well as being capable of being loaded into FontManager

    $font4 = $pdf->get_font('face'=>'Times-Book', 'italic'=>0, 'bold'=>0);

=head4 Notes and Limitations

=over

=item *

You B<cannot> use UTF-8 or other multibyte encodings with PS fonts, I<only>
single byte encodings (256 characters maximum). A PDF Reader (or Writer!) 
simply does not know what to do with a multibyte character, and likely will 
render it as a sequence of single characters (producing garbage). Although most 
single-byte encodings, at least for European languages, are supported, it is 
possible that you might encounter an encoding that includes a character I<not> 
found in a given font file, or vice-versa (the font includes characters that 
the encoding does not give you access to).

=item *

Do not confuse Unicode character points (such as given with an HTML entity) 
with single byte values or multibyte characters. The only way to access a
character defined for a given encoding is with a I<single> byte value in the 
range 0 to 255. For example, if you can't directly type a "Euro" symbol, it is 
C<\x80> in many encodings -- you would use that instead of the Unicode 
C<\x{20AC}> code point or C<x\{E282AC}> UTF-8 byte string. It's a matter of 
giving a single byte value that the PDF Reader can look up in its font 
definition to get the desired glyph. If the "Euro" symbol is not found in the 
encoding you're using, well, you're out of luck.

=item *

Be aware of what a given platform (operating system) and editor is using for 
its code page when it creates a file with your text to be turned into a PDF!
If you typed a "Euro" but it's, say, a UTF-8 byte string in the file, you 
probably won't get a "Euro" in your PDF.

=back

See L<PDF::Builder::Resource::Font/font automap> method for information on
accessing more than 256 glyphs in a font, using B<planes>, I<although there is 
no guarantee that future changes to font files will permit consistent results>.

=head4 Should you use TTF instead?

If you need to reliably access certain characters not found in common 
encodings, please consider using TrueType (TTF) or OpenType (OTF) fonts via the 
C<ttfont()> method. Note that you will be responsible for specifying the exact 
path and full file name of the TTF file, and making sure the font file is
available on the PDF Writer, and possibly on the Reader (if not embedded).

This would enable you to use UTF-8 text, with extended glyph usability, as well
as permitting the font itself to be embedded in the PDF, ensuring that you get
I<exactly> the glyphs you want, without any substitutions or failures due to 
lack of the desired files on the Reader. Kerning and
ligature support (via HarfBuzz::Shaper) may be more available for TTF fonts.
There are tools, such as I<FontForge>, which can do a fairly good
(though, not perfect) job of converting a Type1 font library to OTF.

See also L<PDF::Builder::Resource::Font::Postscript>.

=head3 TrueType Fonts

TrueType (TTF) fonts and their close cousins, OpenType (OTF) fonts, are widely
used. These are often included with many operating systems, although they are
not "built-in" to PDF, and both the PDF Writer and any PDF Reader (if the font
is B<not> embedded) would need to provide the desired font files.

TTF and OTF fonts are I<not> shipped with PDF::Builder, but are expected to be 
found on the machine with the PDF Writer (and if needed, the Reader). Most PDF 
readers do I<not> install TTF/OTF fonts, and it is up to the user of the PDF 
reader to install the needed fonts (if they were not embedded). Note that the 
default behavior I<is> to embed the font subset (glyphs actually used) into the 
PDF file, so that there is no chance of not having the correct font available 
on the reader.

TTF and OTF fonts are B<not> limited to single byte encodings, but can use
multibyte encodings such as UTF-8. The default encoding for these fonts is 
WinAnsiEncoding (roughly the CP-1252/Windows-1252 superset of 
ISO-8859-1/Latin-1). See the C<encode> option below to change this encoding.

=head4 Examples

    $font1 = $pdf->ttfont('Times.ttf');
    $font2 = $pdf->ttfont('Georgia.otf');

TTF/OTF fonts can also be requested via the C<font()> method

    $font3 = $pdf->font('/fonts/Sanskrit.ttf');

as well as being capable of being loaded into FontManager

    $font4 = $pdf->get_font('face'=>'BrushScript', 'italic'=>0, 'bold'=>0);

=head4 Notes and Limitations

=over

=item *

B<CAUTION:> There is a "gotcha" with TrueType fonts that you need to be aware
of when using them. PDF::Builder outputs to the text stream a list of I<glyph
IDs> as four-digit hex codes, rather than the list of character byte codes 
used by other font types. The intent is to allow more than the standard Unicode
points (alternate glyphs for ligatures and other uses). Don't count on it as 
encryption to hide your content (the PDF Reader will just display it anyway!), 
even though it I<does> make it hard to find specific text in a PDF using a text 
editor.

=item *

The B<Tw> operator, if used (C<$text-E<gt>wordspace(n)>) to adjust
inter-word spacing, B<will be ignored> by most, if not all, PDF Readers
(including Adobe products). This is because this operator is looking for actual
ASCII spaces (x20 bytes) in the stream, to apply the width change to. Note that 
only ASCII spaces are affected (not other spaces), and not at all for TrueType 
and OpenType fonts (because they have 4-digit glyph IDs, not x20 bytes)! 
PDF::Builder has been updated to attempt to respect the B<Tw> operator when
using TTF/OTF fonts. If the C<Tw> amount is non-zero, it will split up 
sentences on ASCII spaces (x20) and individually place words on the page. This 
necessarily bloats the PDF file size, but is the only way to adjust word 
spacing via the C<wordspace()> method. Note that again, I<only> ASCII spaces
(x20) are affected (to match the behavior of the B<Tw> operator for other font
types), and other spaces (xA0 required/non-breaking space, thin space, etc.)
are not handled.

=item *

B<Warning:> BaseEncoding is I<not> set by default for TrueType fonts, so 
B<text in the PDF isn't searchable> (by the PDF reader) unless a ToUnicode 
CMap is included. A ToUnicode CMap I<is> included by default (unicodemap set 
to 1) by PDF::Builder, but allows it to be disabled (for performance and file 
size reasons) by setting unicodemap to 0. This will produce non-searchable 
text, which, besides being annoying to users, may prevent screen readers and 
other aids to disabled users from working correctly!

=item *

Do not confuse Unicode character points (such as given with an HTML entity) 
with single byte values or multibyte characters. The only way to access a
character defined for a given encoding is with a I<single> code value in the 
allowable range. For example, if you can't directly type a "Euro" symbol, it is 
C<\x80> in many encodings -- you would use that for a single-byte encoding, or
for UTF-8, the Unicode C<\x{20AC}> code point. You would never give the UTF-8
byte string C<x\{E282AC}>. It needs to be understandable in the context of the
current encoding, so that the 4-digit glyph code can be output.

=item *

Be aware of what a given platform (operating system) and editor is using for 
its code page when it creates a file with your text to be turned into a PDF!
If you typed a "Euro" but it's, say, a UTF-8 byte string in the file, and you 
are using a single-byte encoding, you probably won't get a "Euro" in your PDF.

=back

=head4 Where is the font I just added?

Well, sometimes you get lucky and can
specify the exact directory that the C<.ttf> or C<.otf> file will reside in,
making it easy to specify the path to the font file (for uses such as 
C<ttfont()>, C<font()>, or Font Manager calls). Other times, the operating
system will play hide and seek with you, leaving you to expend much time and
energy to track down where the file is. Linux distributions tend to have their
own favorite hiding places for font files, but at least they tend to be
consistent! On the other hand, Windows often decides that it knows better than
you, and will put files in an unexpected place, and under an unexpected name!

To find out where your TTF or OTF file ended up, if you don't see an obvious 
entry in /Windows/Fonts (even if you drag and dropped the font file there), 
you need to look in /Users/XXXX/AppData/Local/Microsoft/Windows/Fonts, 
depending on what user name you were signed on as when you installed the font. 
Even then, you may not be done, as the name may have been changed to something 
unrecognizable. You may need to look at Windows' mapping of font name to 
filename.

In the command shell (command line), or whatever equivalent you like to use, 
enter "regedit" to bring up the registry editor. For the top level, choose 
(click on) either C<HKEY_LOCAL_MACHINE> (for global font settings, in 
/Windows/Fonts) or C<HKEY_CURRENT_USER> (for fonts installed by whoever is 
currently signed on, in /Users/XXXX/AppData...). From there, both have the same 
path: C<SOFTWARE E<gt> Microsoft E<gt> Windows NT E<gt> CurrentVersion E<gt> 
Fonts>. This should bring up a listing of all the installed fonts (full name, 
e.g. "Papyrus Regular") and their actual filename ("PAPYRUS.TTF"). For 
instance, I just installed (drag and drop into /Windows/Fonts) a blackletter 
"Gothic" font named I<English Towne Medium>. It ended up in my /Users/XXXX... 
directory as C<EnglishTowne.ttf>.

You don't need to change anything in the registry, just look. You I<do> have 
the capability to change things, including hiding/showing the font, if you 
care to get into those things.

See also L<PDF::Builder::Resource::CIDFont::TrueType>

=head3 CJK Fonts

B<Examples:>

    $font = $pdf->cjkfont('korean');
    $font = $pdf->cjkfont('traditional');

B<Warning:> Unlike C<ttfont()>, the font file is I<not> embedded in the output 
PDF file. This is
evidently behavior left over from the early days of CJK fonts, where the 
C<Cmap> and C<Data> were always external files, rather than internal tables.
If you need a CJK-using PDF file to embed the font, for portability, you can
create a PDF using C<cjkfont>, and then use an external utility (e.g.,
C<pdfcairo>) to embed the font in the PDF. It may also be possible to use 
C<ttfont()> instead, to produce the PDF, provided you can deduce the correct 
font file name from examining the PDF file (e.g., on my Windows system, the 
"Ming" font would be C<< $font = $pdf->ttfont("C:/Program Files/Adobe/Acrobat DC/Resource/CIDFont/AdobeMingStd-Light.otf") >>.
Of course, the font file used would have to be C<.ttf> or C<.otf>.
It may act a little differently than C<cjkfont> (due a a different Cmap), but 
you I<should> be able to embed the font file into the PDF.

See also L<PDF::Builder::Resource::CIDFont::CJKFont>

Due to the lack of ongoing support for CJK fonts, and the apparent "arrested 
development" of PDF support for them at an early stage of life, we I<strongly> 
recommend that you attempt to directly use TTF or OTF fonts for Far-Eastern 
(CJK) text support (via C<ttfont()>) before resorting to C<cjkfont()> usage!
Also, CJK fonts appear to be unusable as input for synthetic fonts, and 
normally aren't embedded in the PDF file (requiring the font file to be 
installed on the Reader).

=head3 Synthetic Fonts

B<Warning:> BaseEncoding is I<not> set by default for these fonts, so text 
in the PDF isn't searchable (by the PDF reader) unless a ToUnicode CMap is 
included. A ToUnicode CMap I<is> included by default (unicodemap set to 1) by
PDF::Builder, but allows it to be disabled (for performance and file size 
reasons) by setting unicodemap to 0. This will produce non-searchable text, 
which, besides being annoying to users, may prevent screen 
readers and other aids to disabled users from working correctly!

B<Examples:>

    $cf  = $pdf->corefont('Times-Roman', encode => 'latin1');
    $sf  = $pdf->synfont($cf, condense => 0.85);   # compressed 85%
    $sfb = $pdf->synfont($cf, bold => 1);          # embolden by 10em
    $sfi = $pdf->synfont($cf, oblique => -12);     # italic at -12 degrees

Note that I<CJK> fonts (created with the C<cjkfont> method) do B<not> work
properly with C<synfont>. This is due to a different internal structure of the
I<CJK> fonts, as compared to I<corefont>, I<ttfont>, and I<psfont> base fonts.
If you require a synthesized (modified) CJK font, you might try finding the
TTF or OTF original, use C<ttfont> to create the base font, and running
C<synfont> against that, in the manner described for embedding L</CJK Fonts>.

See also L<PDF::Builder::Resource::Font::SynFont>

=head2 IMAGE METHODS

This is additional information on enhanced libraries available for TIFF and
PNG images. See specific information listings for GD, GIF, JPEG, and PNM image
formats. In addition, see C<examples/Content.pl> for an example of placing an
image on a page, as well as using in a "Form".

=head3 Why is my image flipped or rotated?

Something not uncommonly seen when using JPEG photos in a PDF is that the 
images will be rotated and/or mirrored (flipped). This may happen when using
TIFF images too. What happens is that the camera stores an image just as it
comes off the CCD sensor, regardless of the camera orientation, and does not
rotate it to the correct orientation! It I<does> store a separate 
"orientation" flag to suggest how the image might be corrected, but not all
image processing obeys this flag (PDF::Builder does B<not>.). For example, if
you take a "portrait" (tall) photo of a tree (with the phone held vertically), 
and then use it in a PDF, the tree may appear to have been cut down! (appears 
in landscape mode)

I have found some code that should allow the C<image_jpeg> or C<image> routine
to auto-rotate to (supposedly) the correct orientation, by looking for the Exif
metadata "Orientation" tag in the file. However, three problems arise: 

=over

=item 1.

If a photo has been edited, and rotated or flipped in the process, there is no guarantee that the Orientation tag has been corrected. 

=item 2.

More than one Orientation tag may exist (e.g., in the binary APP1/Exif header, I<and> in XML data), and they may not agree with each other -- which should be used? 

=item 3.

The code would need to uncompress the raster data, swap and/or transpose rows and/or columns, and recompress the raster data for inclusion into the PDF. This is costly and error-prone.
In any case, the user would need to be able to override any auto-rotate function.

=back

For the time being, PDF::Builder will simply leave it up to the user of the
library to take care of rotating and/or flipping an image which displays 
incorrectly. It is possible that we will consider adding some sort of query or warning that the image appears to I<not> be "normally" oriented (Orientation value 1 or "Top-left"), according to the Orientation flag. You can consider either (re-)saving the photo in an editor such as PhotoShop or GIMP, or using PDF::Builder code similar to the following (for images rotated 180 degrees):

    $pW = 612; $pH = 792;  # page dimensions (US Letter)
    my $img = $pdf->image_jpeg("AliceLake.jpeg");
    # raw size WxH 4032x3024, scaled down to 504x378
    $sW = 4032/8; $sH = 3024/8;
    # intent is to center on US Letter sized page (LL at 54,207)
    # Orientation flag on this image is 3 (rotated 180 degrees). 
    # if naively displayed (just $gfx->image call), it will be upside down

    $gfx->save();
    
    ## method 0: simple display, is rotated 180 degrees!
    #$gfx->image($img, ($pW-$sW)/2,($pH-$sH)/2, $sW,$sH);

    ## method 1: translate, then rotate
    #$gfx->translate($pW,$pH);             # to new origin (media UR corner)
    #$gfx->rotate(180);                    # rotate around new origin
    #$gfx->image($img, ($pW-$sW)/2,($pH-$sH)/2, $sW,$sH); 
                                           # image's UR corner, not LL

    # method 2: rotate, then translate
    $gfx->rotate(180);                     # rotate around current origin
    $gfx->translate(-$sW,-$sH);            # translate in rotated coordinates
    $gfx->image($img, -($pW-$sW)/2,-($pH-$sH)/2, $sW,$sH); 
                                           # image's UR corner, not LL

    ## method 3: flip (mirror) twice
    #$scale = 1;  # not rescaling here
    #$size_page = $pH/$scale;
    #$invScale = 1.0/$scale;
    #$gfx->add("-$invScale 0 0 -$invScale 0 $size_page cm");
    #$gfx->image($img, -($pW-$sW)/2-$sW,($pH-$sH)/2, $sW,$sH);

    $gfx->restore();

If your image is also mirrored (flipped about an axis), simple rotation will
not suffice. You could do something with a reversal of the coordinate system, as in "method 3" above (see L<PDF::Builder::Content/Advanced Methods>). To mirror only left/right, the second C<$invScale> would be positive; to mirror only top/bottom, the first would be positive. If all else fails, you could save a mirrored copy in a photo editor. 
90 or 270 degree rotations will require a C<rotate> call, possibly with "cm" usage to reverse mirroring.
Incidentally, do not confuse this issue with the coordinate flipping performed 
by some Chrome browsers when printing a page to PDF.

Note that TIFF images may have the same rotation/mirroring problems as JPEG,
which is not surprising, as the Exif format was lifted from TIFF for use in
JPEG. The cure will be similar to JPEG's.

=head3 TIFF Images

Note that the Graphics::TIFF support library does B<not> currently permit a 
filehandle for C<$file>.

PDF::Builder will use the Graphics::TIFF support library for TIFF functions, if
it is available, unless explicitly told not to. Your code can test whether
Graphics::TIFF is available by examining C<< $tiff->usesLib() >> or
C<< $pdf->LA_GT() >>.

Note that the first query is only available once the C<$tiff> object has been
created. This may or may not be too late for your purposes.

=over

=item = -1 

Graphics::TIFF I<is> installed, but your code has specified C<nouseGT>, to 
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

=item nouseGT => 1

Do B<not> use the Graphics::TIFF library, even if it's available. Normally
you I<would> want to use this library, but there may be cases where you don't,
such as when you want to use a file I<handle> instead of a I<name>.

=item silent => 1

Do not give the message that Graphics::TIFF is not B<installed>. This message
will be given only once, but you may want to suppress it, such as during 
t-tests.

=back

=head3 PNG Images

PDF::Builder will use the Image::PNG::Libpng support library for PNG functions, 
if it is available, unless explicitly told not to. Your code can test whether
Image::PNG::Libpng is available by examining C<< $png->usesLib() >> or
C<< $pdf->LA_IPL() >>.

Note that the first query is only available once the C<$png> object has been
created. This may or may not be too late for your purposes.

=over

=item = -1 

Image::PNG::Libpng I<is> installed, but your code has specified C<nouseIPL>, 
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

=item nouseIPL => 1

Do B<not> use the Image::PNG::Libpng library, even if it's available. Normally
you I<would> want to use this library, when available, but there may be cases 
where you don't.

=item silent => 1

Do not give the message that Image::PNG::Libpng is not B<installed>. This 
message will be given only once, but you may want to suppress it, such as 
during t-tests.

=item notrans => 1

No transparency -- ignore tRNS chunk if provided, ignore Alpha channel if
provided.

=back

=head2 USING SHAPER (HarfBuzz::Shaper library)

    # if HarfBuzz::Shaper is not installed, either bail out, or try to
    # use regular TTF calls instead
    my $rc;
    $rc = eval {
        require HarfBuzz::Shaper;
	1;
    };
    if (!defined $rc) { $rc = 0; }
    if ($rc == 0) {
        # bail out in some manner
    } else {
        # can use Shaper
    }

    my $fontfile = '/WINDOWS/Fonts/times.ttf'; # used by both Shaper and textHS
    my $fontsize = 15;                         # used by both Shaper and textHS
    my $font = $pdf->ttfont($fontfile);
    $text->font($font, $fontsize);
    
    my $hb = HarfBuzz::Shaper->new(); # only need to set up once
    my %settings; # for textHS(), not Shaper
    $settings{'dump'} = 1; # see the diagnostics
    $settings{'script'} = 'Latn';
    $settings('dir'} = 'L';  # LTR
    $settings{'features'} = ();  # required

    # -- set language (override automatic setting)
    #$settings{'language'} = 'en';
    #$hb->set_language( 'en_US' );
    # -- turn OFF ligatures
    #push @{ $settings{'features'} }, 'liga';
    #$hb->add_features( 'liga' );
    # -- turn OFF kerning
    #push @{ $settings{'features'} }, 'kern'; 
    #$hb->add_features( 'kern' );
    $hb->set_font($fontfile);
    $hb->set_size($fontsize);
    $hb->set_text("Let's eat waffles in the field for brunch.");
      # expect ffl and fi ligatures, and perhaps some kerning

    my $info = $hb->shaper();
    $text->textHS($info, \%settings); # strikethru, underline allowed

The package HarfBuzz::Shaper may be optionally installed in order to use the
text-shaping capabilities of the HarfBuzz library. These include kerning and
ligatures in Western scripts (such as the Latin alphabet). More complex scripts
can be handled, such as Arabic family and Indic scripts, where multiple forms
of a character may be automatically selected, characters may be reordered, and
other modifications made. The examples/HarfBuzz.pl script gives some examples
of what may be done.

Keep in mind that HarfBuzz works only with TrueType (.ttf) and OpenType (.otf)
font files. It will not work with PostScript (Type1), core, bitmapped, or CJK
fonts. Not all .ttf fonts have the instructions necessary to guide HarfBuzz,
but most proper .otf fonts do. In other words, there are no guarantees that a
particular font file will work with Shaper!

The basic idea is to break up text into "chunks" which are of the same script
(alphabet), language, direction, font face, font size, and variant (italic, 
bold, etc.). These could range from a single character to paragraph-length 
strings of text. These are fed to HarfBuzz::Shaper, along with flags, the font
file to be used, and other supporting
information, to create an array of output glyphs. Each element is a hash 
describing the glyph to be output, including its name (if available), its glyph
ID (number) in the selected font, its x and y displacement (usually 0), and
its "advance" x and y values, all in points. For horizontal languages (LTR and
RTL), the y advance is normally 0 and the x advance is the font's character
width, less any kerning amount.

Shaper will attempt to figure out the script used and the text direction, based on the Unicode range; and a reasonable guess at the language used. The language
can be overridden, but currently the script and text direction cannot be
overridden.

B<An important note:> the number of glyphs (array elements) may not be equal to 
the number of Unicode points (characters) given in the chunk's text string! 
Sometimes a character will be decomposed into several pieces (multiple glyphs); 
sometimes multiple characters may be combined into a single ligature glyph; and
characters may be reordered (especially in Indic and Southeast Asian languages).
As well, for Right-to-Left (bidirectional) scripts such as Hebrew and Arabic
families, the text is output in Left-to-Right order (reversed from the input).

With due care, a Shaper array can be manipulated in code. The elements are more
or less independent of each other, so elements can be modified, rearranged,
inserted, or deleted. You might adjust the position of a glyph with 'dx' and 
'dy' hash elements. The 'ax' value should be left alone, so that the wrong 
kerning isn't calculated, but you might need to adjust the "advance x" value by
means of one of the following:

=over

=item B<axs> 

is a value to be I<substituted> for 'ax' (points)

=item B<axsp> 

is a I<substituted> value (I<percentage>) of the original 'ax'

=item B<axr> 

I<reduces> 'ax' by the value (points). If negative, increase 'ax'

=item B<axrp> 

I<reduces> 'ax' by the given I<percentage>. Again, negative increases 'ax'

=back

B<Caution:> a given character's glyph ID is I<not> necessarily going to be the 
same between any two fonts! For example, an ASCII space (U+0020) might be 
C<E<lt>0001E<gt>> in one font, and C<E<lt>0003E<gt>> in another font (even one 
closely related!). A U+00A0 required blank (non-breaking space) may be output
as a regular ASCII space U+0020. Take care if you need to find a particular
glyph in the array, especially if the number of elements don't match. Consider
making a text string of "marker" characters (space, nbsp, hyphen, soft hyphen,
etc.) and processing it through HarfBuzz::Shaper to get the corresponding
glyph numbers. You may have to count spaces, say, to see where you could break
a glyph array to fit a line.

The C<advancewidthHS()> method uses the same inputs as does C<textHS()>.
Like C<advancewidth()>, it returns the chunk length in points. Unlike
C<advancewidth()>, you cannot override the glyph array's font, font size, etc.

Once you have your (possibly modified) array of glyphs, you feed it to the
C<textHS()> method to render it to the page. Remember that this method handles
only a single line of text; it does not do line splitting or fitting -- that
I<you> currently need to do manually. For Western scripts (e.g., Latin), that
might not be too difficult, but for other scripts that involve extensive
modification of the raw characters, it may be quite difficult to split 
I<words>, but you still may be able to split at inter-word spaces.

A useful, but not exhaustive, set of functions are allowed by C<textHS()> use.
Support includes direction setting (top-to-bottom and bottom-to-top directions,
e.g., for Far Eastern languages in traditional orientation), and explicit 
script names and language (depending on what support HarfBuzz itself gives).
B<Not yet> supported are features such as discretionary ligatures and manual 
selection of glyphs (e.g., swashes and alternate forms). 

Currently, C<textHS()> can only handle a single text string. We are looking at
how fitting to a line length (splitting up an array) could be done, as well as 
how words might be split on hard and soft hyphens. At some point, full paragraph
and page shaping could be possible.

=head2 MARKUP

This section documents the markup capabilities of the C<column()> method.
It is expected to be updated over time as more functionality is added.

A certain flavor of I<Markdown> is supported, as translated by the 
Text::Markdown package into HTML. That I<HTML> (and more, as direct input), 
along with a subset of CSS, is 
supported by C<column()>. This is I<not> the full Markdown or HTML languages, 
by any stretch of the imagination, so check before using! Also, a small I<none> 
markup which only does paragraphs (separated by empty lines) is provided.

In all markup cases, certain CSS settings can be given as parameters or options
to the C<column()> call, including a CSS <style> section which applies to both
'none' and Markdown source input.

=head3 Other input formats

PDF::Builder currently only supports the markup languages described above.
If you want to use something else (e.g., Perl's POD, or I<man> format, or even 
MS Word or some other WYSIWYG format), you will need to find a converter 
utility to convert it to a supported flavor of Markdown or HTML. Many such 
converters already exist, so take a look (although you may well have to do some 
cleanup before C<column()> accepts it). 

Perhaps in the future, PDF::Builder will directly support additional formats, 
but no promises. You will probably never see TeX/LaTeX input, as these already 
have excellent PDF output (and would be a massive undertaking to process).

=head3 Current HTML/Markdown supported

=over

=item * 

B<<iE<gt>> and B<<emE<gt>> tags (Markdown B<_>, B<*>) as italic font style

=item * 

B<<bE<gt>> and B<<strongE<gt>> tags (Markdown B<**>) as bold font weight

=item * 

B<<pE<gt>> tag (Markdown empty line) as a paragraph

=item * 

B<<font face="font-family" color="color" size="font-size"E<gt>> as selecting face, color and size

=item * 

B<<spanE<gt>> needs style= attribute with CSS to do anything useful

=item * 

B<<ulE<gt>> tag (Markdown B<->) unordered (bulleted) list. type to override marker supported

=item * 

B<<olE<gt>> tag (Markdown B<1.>) ordered (numbered) list. start and type supported.

=item *

B<<_markerE<gt>> tag (I<not> standard HTML) provide a place to specify, on a
I<per list item basis>, overrides to default marker settings (see C<_marker-*>
CSS extensions below). If omitted, the same HTML list markers and CSS properties are used for each list item (per usual practice)

=item * 

B<<liE<gt>> tag list item. value to override ordered list counter, and type to override marker type supported

=item * 

B<<a href="URL"E<gt>> tag (Markdown B<[]()>) anchor/link, web page URL or this document target C<#p[-x-y[-z]]>

=item * 

B<<h1E<gt>> through B<<h6E<gt>> tags (Markdown B<#> through B<######>) headings

=item * 

B<<hr width="length" size="length"E<gt>> tag (Markdown B<--->) horizontal rule. currently no B<align> property (left alignment only). Default is C<width> = full column, and C<size> = 0.5pt.

=item * 

B<<sE<gt>>, B<<strikeE<gt>>, B<<delE<gt>> tags (Markdown B<~~>) text line-through

=item * 

B<<uE<gt>>, B<<insE<gt>> tags text underline

=item * 

B<<blockquoteE<gt>> tag (Markdown B<E<gt>>) indented both sides block of smaller text

=item * 

B<<_markerE<gt>> tag (non-standard) to explicitly set list marker properties (_marker-*) for one specific (immediately following) E<lt>liE<gt> list item

=item * 

B<<_moveE<gt>> tag (non-standard) to explicitly move current write point left or right. C<x="value"> is an absolute move (in points), while C<dx="value"> is a relative move

=back

I<Numbered> (decimal and hexadecimal) entities are supported, as well as I<named> entities (e.g., C<E<amp>mdash;>). Both lists get a "gutter" (for the marker) of I<marker_width> points wide, so list alignments are consistent over the call.

=head3 Current CSS supported

Note that the default CSS also applies to Markdown, unless you give a C<style =E<gt>> entry to the column() call to revise the CSS.

In HTML, you can define B<<styleE<gt>> tags, but B<caution:> these are pulled out into a global style block (cumulative and global, as though they had all been given in the B<<headE<gt>>), applied after the CSS property defaults are defined and then any column() global C<style =E<gt> 'CSS list'> has been applied.

CSS Selectors are very primitive:: a simple tag name (including B<body>), such as B<ol>; a class name such as B<.error>; or an ID such as B<#myID>. There are no hierarchies or combinations supported (e.g., nothing like B<p.abstract> or B<li E<gt> p>). The (decreasing) order of precedence follows a browser's: in a B<style => attribute, as a tag attribute (which may have a different name from the CSS's), an ID, a class, or a tag name. Comments /* and */ are B<NOT> currently supported in CSS.

=over

=item color

foreground color, in standard PDF::Builder formats

=item display 

I<inline> or I<block>

=item font-family

as defined to Font Manager, e.g., I<Times>

=item font-size

I<n> points, I<n>pt, I<n%> of current font size. more units in future

=item font-style

I<normal> or I<italic>

=item font-weight

I<normal> or I<bold>

=item height

I<n> points or I<n>pt, thickness/size of horizontal rule B<ONLY>

=item list-style-position

I<outside> or I<inside>, or (CSS extension) C<Npt> or C<N%> (percentage of C<marker_width>) indent from inside position

=item list-style-type

marker description, per standard CSS, plus "box" (I<extension> for unordered list to give a box I<outline> marker (an unfilled "square"))

=item margin-top/right/bottom/left

per standard CSS. combined B<margin> in the future

=item _marker-*

I<extensions>: these are CSS property overides to the appearance of list item markers (the formatted counter or bullet in front of the item). These may be applied to an entire list by placing them in CSS <styleE<gt> or a style= attribute within <olE<gt> or <ulE<gt>, or to override a single list item's entry by placing it in an optional <_markerE<gt> tag. 

The corresponding CSS attributes (color, font-family, font-style, font-size, font-weight) are cascaded as usual, and the _marker-* attributes are cascaded as usual. When outputting a list's marker, if the final C<_marker-*> property is not empty (''), it overrides the corresponding CSS property. C<_marker-text>, if not '', overrides whatever text the list would have otherwise used (formatted counter or bullet).

If you are I<nesting> lists, C<_marker-*> properties will be inherited, as is the usual practice. If you want a nested list to use standard properties, you will need to cancel the current state of inherited C<_marker-*> propertie(s) by setting it/them to '' in the <olE<gt> or <ulE<gt> tag

=over

=item _marker-before

text to insert I<before> ordered list marker

=item _marker-after

text to insert I<after> ordered list marker

=item _marker-text

define a text string to use as the list item marker that is different from the defaut. It may include multi-character text (e.g., '=>' or an entity), but don't use multi-byte (e.g., UTF-8) characters unless your selected font (see C<_marker-font>) supports it

=item _marker-color

override the default text color for this (or all) markers, e.g., 'blue' to set bullets or counters blue (as opposed to the normal black text). An example of using this color override would be a bulleted list with red bullets indicating a problem, yellow bullets indicating an area of concern, and green bullets indicating that all is well

=item _marker-font

override the standard font family used for a list item I<_marker>. The standard is to use whatever font-family was in effect at the list tag, for ordered lists (formatted counters), or ZapfDingbats for unordered (bulleted) lists

=item _marker-style

override the styling ('normal' or 'italic') for a list item marker. The standard is to use whatever styling was in effect at the list tag

=item _marker-size

override the font size ('font-size' property) for a list item marker. The standard is to use whatever font-size was in effect at the list tag for ordered lists, and 50% of that for bulleted lists. You can choose to modify the marker's font size to make it more or less conspicuous, as desired

=item _marker-weight

override the font weight (boldness, 'normal' or 'bold') for a list item marker. The standard is to use 'bold' for both ordered and unordered lists

=item _marker-align

override the list marker alignment or justification (default: 'right') within the 'marker_width' gutter. 'left' and 'center' alignment are permitted

=back

B<Caution:> a I<nested> list will inherit the settings of its parent list, including any C<_marker-*> settings. You may need to explicitly cancel unwanted settings by making them ''

=item text-decoration

per standard CSS

=item text-height

change leading, ratio of baseline-to-baseline to font size. future: set as a length or % of font size

=item text-indent

paragraph etc. indentation, I<n> points, I<npt>, I<n%> of font size

=item text-align

align a string of text to I<start> at the current position (left-aligned, 'left'), be I<centered> at the current position ('center'), or I<end> at the current position ('right' align). You will normally need to first set the current position to write at, before outputting aligned text, using the C<<_moveE<gt>> tag. For 'center' or 'right' alignment, use care to stay within the bounds of the column and not unsuccessfully try to wrap to the next line!

=item width

I<n> point or, I<npt>, width of horizontal rule B<ONLY>

=back

=head3 Global Settings

There are a number of global settings either required or available for tuning the behavior of C<column()>. In the parameter list you can set

=over

=item font_size

default initial font size (points) to be used, but can be overridden by CSS or C<<font sizeE<gt>>. Initially C<12>.

=item leading

default leading (text-height) ratio. Initially C<1.125>.

=item marker_width

points, set width of gutter where a list's marker goes. Initially C<2 * <font sizeE<gt>> (2 em).

=item marker_gap

points, set width of additional space between the marker and the start of the list item text. Initially C<<font sizeE<gt>> (1 em).

=item para

list of indentation (text-indent) and inter-paragraph spacing (margin-top), both in points. These are the defaults for all formatting modes, unless overridden by a style => entry. Initially C<[ <font sizeE<gt>, 0 ]>.

=item color

initial text and graphics color setting, in standard PDF::Builder formats. Initially C<'black'>.

=item style

CSS declarations to be applied after CSS properties initialization and before any global <style> tags, Initially C<''>.

=back

The Font Manager system is used to supply the requested fonts, so it is up to
the application to pre-load the desired font information I<before> C<column()>
is called. Any request to change the encoding within C<column()> will be
ignored, as the fonts have already been specified for a specific encoding.
Needless to say, the encoding used in creating the input text needs to match
the specified font encoding.

Absent any markup changing the font face or styling, whatever is defined by
Font Manager as the I<current> font will be what is used. This way, you may
inherit the font from the previous C<column()>, or call 
C<$text->font($pdf-E<gt>get_font(), size)> to set both the font and size, or 
just call C<$pdf->get_font()> to set only the font, relying on the C<font_size> 
option or CSS markup to set the size.

Line fitting (paragraph shaping) is currently quite primitive. Words will
not be split (hyphenated).  I<It is planned to eventually add Knuth-Plass 
paragraph shaping, along with proper language-dependent hyphenation.>

Each change of font automatically supplies its maximum ascender and minimum
descender, the B<extents> above and below the text line's baseline. Each block
of text with a given face and variant, or change of font size, will be given
the same I<vertical> extents -- the extents are font-wide, and not determined 
on a per-glyph basis. So, unfortunately, a block of text "acemnorsuvwz" will 
have the same vertical extents as a block of text "bdfghijklpqty". For a given
line of text, the highest ascender and the lowest descender (plus leading) will
be used to position the line at the appropriate distance below the previous 
line (or the top of the column). No attempt is made to "fit" projections into
recesses (jigsaw-puzzle like). If there is an inset into the side of a column,
or it is otherwise not a straight vertical line,
so long as the baseline fits within the column outline, no check is made 
whether descenders or ascenders will fall outside the defined column (i.e., 
project into the inset). We suggest that you try to keep font sizes fairly
consistent, to keep reasonably consistent text vertical extents.

=cut

sub _docs {
	# dummy stub
} 

1;
