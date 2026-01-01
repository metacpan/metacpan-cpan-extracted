package PDF::Builder::Content::Column_docs;

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.028'; # manually update whenever code is changed

# originally mostly part of Content/Text.pm, it was split out due to its length
#
# WARNING: be sure to keep in synch with changes to code and POD elsewhere
#
#   do not attempt to use Unicode entities, such as E<euro> -- the POD to
#   HTML converter will barf on them!

=head1 NAME

PDF::Builder::Content::Column_docs -- column text formatting system

=head1 PDF::Builder::Content::Text/column and related routines

These routines form a sub-library for support of complex columnar output with 
high level markup languages. Currently, a single rectangular layout may be 
defined on a page, to be filled by user-defined content. Any content which
could not be fit within the column confines is returned in an internal array
format, and may be passed to the next C<column()> call to finish the
formatting.

Future plans call for non-rectangular columns to be definable, as well as
flow from one column to another on a page, and column balancing. Other 
possible enhancements call for support of non-Western writing systems 
(e.g., bidirectional text, using the HarfBuzz library), proper 
word-splitting and paragraph shaping (possibly using the Knuth-Plass 
algorithm), and additional markup languages.

=head2 column

    ($rc, $next_y, $unused) = $text->column($page, $text, $grfx, $markup, $txt, %opts)

=over

This method fills out a column of text on a page, returning any unused portion
that could not be fit, and where it left off on the page.

Tag names, CSS entries, markup type, etc. are case-sensitive (usually 
lower-case letters only). For example, you cannot give a <P> paragraph in
HTML or a B<P> selector in CSS styling.

B<$page> is the page context. Currently, its only use is for page annotations
for links ('md1' []() and 'html' E<lt>aE<gt>), so if you're not using those, 
you may pass anything such as C<undef> for C<$page> if you wish.

B<$text> is the text context, so that various font and text-output operations
may be performed. It is often, but not necessarily always, the same as the
object containing the "column" method.

B<$grfx> is the graphics (gfx) context. It may be a dummy (e.g., undef) if
I<no> graphics are to be drawn, but graphical items such as the column outline 
('outline' option) and horizontal rule (<hr> in HTML markup) use it. 
Currently, I<text-decoration> underline (default for links, 'md1' C<[]()> and 
'html' C<E<lt>aE<gt>>) or line-through or overline use the text context, but
may in the future require a valid graphics context. Images (when implemented)
will require a graphics context.

B<$markup> is information on what sort of I<markup> is being used to format
and lay out the column's text:

=over

=item  'pre'

The input material has already been processed and is already in the desired
form. C<$txt> is an array reference to the list of hashes. This I<must> be used 
when you are calling C<column()> a second (or later)
time to output material left over from the first call. It may also be used when
the caller application has already processed the text into the appropriate
format, and other markup isn't being used.

=item  'none'

If I<none> is specified, there is no markup in use. At most, a blank line or
a new text array element specifies a new paragraph, and that's it. C<$txt> may
be a single string, or an array (list) of strings.

The input B<txt> is a list (anonymous array reference) of strings, each 
containing one or more paragraphs. A single string may also be given. An empty 
line between paragraphs may be used to separate the paragraphs. Paragraphs may 
not span array elements.  

=item  'md1'

This specifies a certain flavor of Markdown compatible with Text::Markdown. 
See the full description below.

There are other flavors of Markdown, so other mdI<n> flavors I<may> be defined 
in the future, such as POD from Perl code.

=item  'html'

This specifies that a large subset of HTML markup is used, along with some 
attributes and CSS. 

Numeric entities (decimal &#nnn; and hexadecimal &#xnnn;) are supported, 
as well as named entities (&mdash; for example).

The input B<txt> is a list (anonymous array reference) of strings, each 
containing one or more paragraphs and other markup. A single string may also be 
given. Per normal HTML practice, paragraph tags should be used to mark
paragraphs. I<Note that HTML::TreeBuilder is configured to automatically
mark top body-level text with paragraph tags, in case you forget to do so,
although it is probably better to do it yourself, to maintain more control
over the processing.>
Separate array elements will first be glued together into a single string 
before processing, permitting paragraphs to span array elements if desired.  

=item Other input formats

There are other markup languages out there, such as HTML-like Pango, 
nroff-like man page, Markdown-like wikimedia, and Perl's POD, that 
might be supported in the future (provided there are supported Perl libraries
for them). It is very unlikely that TeX or LaTeX will 
ever be supported, as they both already have excellent PDF output.

PDF::Builder currently only supports the markup languages described above.
If you want to use something else (e.g., Perl's POD, or I<man> format, or even 
MS Word or some other WYSIWYG format), you will need to find a converter 
utility to convert it to a supported flavor of Markdown or HTML. Many such 
converters already exist, so take a look (although you may well have to do some 
cleanup before C<column()> accepts the resulting HTML as input). 

Perhaps in the future, PDF::Builder will directly support additional formats, 
but no promises.

=back

B<$txt> is the input text: a string, an array reference to multiple strings,
or an array reference to hashes. See C<$markup> for details.

B<%opts> Options -- a number of these are, despite the name, mandatory.

=over

=item 'rect' => [x, y, width, height]

This defines a column as a rectangular area of a given width and height (both
in points) on the current page. I<In the future, it is expected that more
elaborate non-rectangular areas will be definable, but for now, a simple
rectangle is all that is permitted.> The column's upper left coordinate is
C<x, y>.

The top text baseline is assumed to be relative to the UL corner (based on the
determined line height), and the column outline
clips that baseline, as it does additional baselines down the page (interline
spacing is C<leading> multiplied by the largest C<font_size> or image height
needed on that line).

I<Currently, 'rect' is required, as it is the only column shape supported.>

=item 'relative' => [ x, y, scale(s) ]

C<'relative'> defaults to C<[ 0, 0, 1, 1 ]>, and allows a column outline
(currently only 'rect') to be either absolute or relative. C<x> and C<y> are
added to each C<x,y> coordinate pair, I<after> scaling. Scaling values:

=over

=item (none)  The scaling defaults to 1 in both x and y dimensions (no change).

=item scale (one value)  The scaling in both the x (width) and y (height)
dimensions uses this value.

=item scale_x, scale_y (two values)  There are two separate scaling factors
for the x dimension (width) and y dimension (height).

=back

This permits a generically-shaped outline to be defined, scaled (perhaps
not preserving the aspect ratio) and placed anywhere on the page. This could
save you from having to define similarly-shaped columns from scratch multiple 
times.
If you want to define a relative outline, the lower left corner (whether or
not it contains a point, and whether or not it's the first one listed) would 
usually be C<0, 0>, to have scaling work as expected. In other works, your
outline template should be in the lower left corner of the page.

=item 'start_y' => $start_y

If omitted, it is assumed that you want to start at the top of the defined
column (the maximum C<y> value minus the maximum vertical extent of this line).
If used, the normal value is the C<next_y> returned from the previous 
C<column()> call. It is the deepest extent reached by the previous line (plus
leading), and is the top-most point of the new first line of this C<column()>
call.

Note that the C<x> position will be determined by the column shape and size
(the left-most point of the baseline), so there is no place to explicitly set 
an C<x> position to start at.

=item 'font_size' => $font_size

This is the starting font size (in points) to be used. Over the course of
the text, it may be modified by markup. The default is 12pt. It is in turn
overridden by any CSS or HTML font size-settings.

The starting font size may be set in a number of ways. It may be inherited from
a previous C<$text-E<gt>font(..., font-size)> statement; it may be set via the
C<font_size> option (overriding any font method inheritance); it may default to 
12pt (if neither explicit way is given). For HTML markup, it may of course be 
modified by the C<font> tag or by CSS styling C<font-size>. For Markdown, it
may be modified by CSS styling.

=item 'font_info' => $string

This permits the user to specify the starting font used in C<column()> (body
font-family, font-style, font-weight, color). C<column()> will pick up any 
font already
loaded (C<$text-E<gt>font($font, $size);>, or using FontManager), and use that 
as the "current" font. If no font has been loaded, and no other instructions
are given, the FontManager default (core Times-Roman) will be used.

The C<font_info> option for C<column()> may be given to override either of the
two above methods. You may specify a C<$string> of B<'-fm-'> to instruct
C<column()> to use the FontManager "default" font (Times face core font).
Or, you may pick a font
face I<known> to FontManager (added by user code if not one of the 28 core 
fonts), and optionally give it style and weight: C<$string> of 
B<'face:style:weight:color'>. The style defaults to 'normal' (non-italic), or 
'normal' or '0' may be given. For italics, use 'italic' or '1'. The weight 
defaults to 'normal' (unbolded weight), or 'normal' or '0' may be given. For 
bold (heavy) text, use 'bold' or '1'. Finally, a color may be given.

Finally, the C<style> option for C<column()> may be given to override any of 
the above settings, e.g., B<'style'=E<gt>{ body { font-family:... }> and set
the initial current font. Remember that, as with anything font-related that
C<column()> does, the 'face' (family) used must already be known to FontManager
(explicitly loaded with C<add_font()> if not one of the 28 core fonts). 
Remember that the first 14 fonts are standard PDF, and the second 14 are 
normally supplied with Windows (but not always with other operating systems).

=item 'marker_width' => $marker_width

=item 'marker_gap' => $marker_gap

This is the width of the gutter to the left of a list item, where (for the
first line of the item) the marker lives. The marker contains the symbol (for
bulleted/unordered lists) or formatted number and "before" and "after" text
(for numbered/ordered lists). Both have a single space (marker_gap = 1em)
before the item text starts. The number is a length, in points.

The default is 1 em (1 times the font_size passed to C<column()>), and is not 
adjusted for any changes of font_size in the markup, so that lists are indented
I<consistently>. This is usually fine for unordered (bulleted) lists and single
digit ordered (numbered) lists, although you may need to make it wider for 
two or three digit numbered lists. An explicit value passed 
in is also not changed -- the gutter width for the marker will be the same in 
all lists (keeping them aligned). If you plan to have exceptionally long 
markers, such as an ordered list of years in Roman numerals, e.g., 
B<(MCMXCIX)>, you may want to make this gutter a bit wider.

A value may be given for the marker_gap, which is the gap between the 
(C<$marker_width> wide) I<marker> and the start of the list item's text. 
The default is $fs points (1 em), set by the font_size in the markup. 

The C<list-style-position> CSS property may be given as the standard 'outside'
(the default) or 'inside', or (extension to CSS) to indent the left side of
second, third, etc. E<lt>liE<gt> lines to somewhere between the 'inside' and
'outside' positions. Be sure to consider the C<_marker-align> extended 
property to left, center, or right (default) align the marker within the 
C<marker_gutter>.

=item 'leading' => $leading

This is the leading I<ratio> used throughout the column text.
The C<$x, $y> position through C<$x + width> is assumed to be the first
text baseline. The next line down will be C<$y - $leading*$font_size>. If the
font_size changes for any reason over the course of the column, the baseline
spacing (leading * font_size) will also change. The B<default> leading ratio
is 1.125 (12.5% added to font).

=item 'para' => [ $indent, $top-margin ]

When starting a new paragraph, these are the I<default> indentation (in points),
and the extra vertical spacing for a top margin on a paragraph. Otherwise, the 
default is
C<[ 1*$font_size, 0 ]> (1em indent, 0 additional vertical space). Either may 
be overridden by the appropriate CSS settings. An I<outdent> may be defined 
with a negative indentation value. These apply to all C<$markup> types.

At the top of a column, any top margin (not just for paragraphs) is ignored.

=item 'outline' => "color string"

You may optionally request that the column be outlined in a given color, to aid
in debugging fitting problems. This will require that the graphics context be
provided to C<column()>.

=item 'color' => "color string"

The color to draw the text (or rule or other graphic) in. The default is 
black (#000000).

=item 'style' => "CSS styling"

You may define CSS (selectors and properties lists) to override the built-in
CSS defaults. These will be applied for the entire C<column()> call. You can
use this, or C<style> tags in 'html', but for 'none' or 'md1', you will need to
use this method to set styling. See also the C<font_info=E<gt>> option to set
initial font settings.

Note that, unlike the C<style=> I<attribute> in HTML tags, the C<style=E<gt>>
option is formatted like a E<lt>style> I<tag> -- that is, with B<selector {>
I<property>: I<value>;... B<}>. If you want to set I<global> values, use the
B<body> selector.

=item 'substitute' => [ [ 'char or string', 'before', 'replace', 'after'],... ]

When a certain Unicode code point (character) or string is found, insert 
I<before> text before the character, replace the character or string with
I<replace> text, and insert I<after> text after the character. This may make
it easier to insert HTML code (font, color, etc.) into Markdown text, if the
desired settings and character can not be produced by your Markdown editor.
This applies both to 'md1' and 'html' markup. Multiple substitutions may be 
defined via multiple array elements.
If you want to leave the original character or string I<itself> unchanged, you
should define the I<replace> text to be the same as C<'char or string'>. 
'before' and/or 'after' text may be empty strings if you don't want to insert
some sort of markup there.

Example: to insert a red cross (X-out) and green tick (check) mark

    'substitute' => [
      [ '%cross%', '<font face="ZapfDingbats" color="red">', '8', '</font>' ],
      [ '%tick%', '<font face="ZapfDingbats" color="green">', '4', '</font>' ],
    ]

should change C<%cross%> in Markdown text ('md1') or HTML text ('html')
to C<E<lt>font face="ZapfDingbats" color="green"E<gt>8E<lt>/fontE<gt>> 
and similarly for C<%tick%>. This is done I<after> the Markdown is converted 
to HTML (but before HTML is parsed), so make sure that your macro text (e.g., 
C<%tick%>) isn't something that Markdown will try to interpret by itself! Also, 
Perl's regular expression parser seems to get upset with some characters, such 
as C<|>, so don't use them as delimiters (e.g., C<|cross|>). You don't I<have> 
to wrap your macro name in delimiters, but it can make the text structure
clearer, and may be necessary in order not to do substitutions in the wrong 
place.

=item 'state' => \%state

This is the state of processing, including (in particular), information on all
the requested references (<a>, <_ref>) and targets (<_reft> and specific id's). 
Before use, it must be created and initialized. During multiple passes across
multiple column() calls, 'state' preserves all the link information. It can
even preserve information across the creation of multiple related PDFs, though
this may require writing and reading back from a file. There is no information
in 'state' that is likely to be of interest to a user (i.e., all internal data).
If 'state' is not given, it will (in most cases) be impossible to define various
kinds of links (including cross references). A URL link to a browser does not
need C<'state'>, but all other kinds of links to this or other PDF files do.

=item 'page' => [ $ppn, $extfile, $fpn, $LR, $bind ]

This array of values gives C<column()> information needed for generating links
(both I<goto> and I<pdf> annotations), and (TBD) left- and right-hand page
processing, including how much to shift C<column()> definitions to the outside
of the page for binding purposes (TBD). The link information is as follows:

=over

=item $ppn

This is the Physical Page Number of the page currently being generated. It is 
always an integer greater than 0, and takes a value 1,2,3,... It is needed if
this page is used as the target for an external (across PDFs) link, using a
physical page number and not a Named Destination. 
Remember to increment it every time the code calls the C<page()> method. 
It may be left undefined if you are sure you're never going to generate a link 
(via C<pdf> call, not using a Named Destination) to this PDF file from another 
PDF.

=item $extfile

This describes the external path, filename, and extension of B<this> PDF being
created. It is needed if this page is used as the target for an external 
(across PDFs) link. Remember that this is the I<final> location and name of
where this file will live when in use, not necessarily where it is being
I<created> at this moment!
It may be left undefined or a random name if you are sure you're never going to 
generate a link (via C<pdf> call) to I<this> PDF file from another PDF.

=item $fpn

This is the I<Formatted> Page Number of the page being generated. In the 
simplest case, it is equal to the Physical Page Number, but often you will want
to "get fancy" with numbering, such as a prefix for an appendix ('C-2',
'Glossary-5', etc.), lowercase Roman numerals in the front matter, etc. You
might even want to carry one single sequence of decimal page numbers across 
multiple PDFs, thus starting at other than "1". If you leave it undefined,
certain kinds of links and cross reference formats (where the formatted page
number is shown) will not be possible.

=item $LR

This says whether it's a left-hand page or a right-hand page, for purposes of
formatting layout and shifting the C<column()> outline left or right (towards
the "outside" of the page) to allow binding space. If undefined, it defaults
to an 'R' right-hand page. This ability is currently unused.

=item $bind

This is the number of points to shift the C<column()> coordinates towards the
"outside" of the page for purposes of binding multiple pages together, whether
left-right alternation or all right-hand pages (e.g., punched for a notebook or
spiral binding, or just stapled on the inside, or glued or sewn into a 
paperback or hard-cover binding). If undefined, the default is 0. This ability 
is currently unused.

=back

=item 'restore' => flag

This integer flag determines what sort of cleanup C<column()> will do upon
exit, to restore (or not) the font state (face, bold or normal weight, 
italic or normal style, size, and color).

=over

=item for rc = 0 (all input markup was used up, without running out of column)

=over

=item restore => 0

This is the B<default>. Upon exiting, C<column()> will attempt to restore the 
state to what one would see if there was yet more text to be output. Note that
this is I<not> necessarily what one would see if the entire state was restored
to entry conditions. The intent is that another C<column()> call can be 
immediately made, using whatever font state was left by the previous call, as
though the two calls' markup inputs were concatenated.

=item restore => 1

This value of C<restore> commands that I<no> change be made to the font state,
that is, C<column()> exits with the font state left in the last text output.
This may or may not be desirable, especially if the last text output left the
text in an unexpected state.

=item restore => 2

This value of C<restore> attempts to bring the font state all the way back to
what it was upon I<entry> to the routine, as if it had never been called. Note
that if C<column()> was called with no global font settings, that can not be
undone, although the color I<can> be changed back to its original state, 
usually black.

B<CAUTION:> The Font Manager is not synchronized with whatever state the font
is returned to. You should not request the 'current' font, but should instead
explicitly set it to a specific face, etc., which resets 'current'.

=back

=item for rc = 1 (ran out of column space before all the input markup was used up)

=over

=item restore => 0

This is the B<default>. Upon exiting, no changes will be made to the font
state. As the code will be in the middle of some output, the font state is
kept the same, so the next C<column()> call (for the overflow) can pick up 
where the previous call left off, with regards to the font state.

It is equivalent to C<restore = 1>.

=item restore => 1

This is the same as C<restore = 0>.

=item restore => 2

This value of C<restore> attempts to bring the font state all the way back to
what it was upon I<entry> to the routine, as if it had never been called. Note
that if C<column()> was called with no global font settings, that can not be
undone, although the color I<can> be changed back to its original state, 
usually black.

B<CAUTION:> The Font Manager is not synchronized with whatever state the font
is returned to. You should not request the 'current' font, but should instead
explicitly set it to a specific face, etc., which resets 'current'.

=back

=back

=back

B<Data returned by this call>

If there is more text than can be accommodated by the column size, the unused
portion is returned, with a return code of 1. It is an empty list if all the 
text could be formatted, and the return code is 0.
C<next_y> is the y coordinate where any additional text (C<column()> call) 
could be added to a column (as C<start_y>) that wasn't completely filled.
This would be at the starting point of a new column (i.e., the
last paragraph is ended). Note that the application code should check if this
position is too far down the page (in the bottom margin) and not blindly use
it! Also, as 'md1' is first converted to HTML, any unused portion will be 
returned as 'pre' markup, rather than Markdown or HTML. Be sure to specify 
'pre' for any continuation of the column (with one or more additional 
C<column()> calls), rather than 'none', 'md1', or 'html'.

=over

=item $rc

The return code.

=over

=item '0'

A return code of 0 indicates that the call completed, while using up all the
input C<$txt>. It did I<not> run out of defined column space.

B<NOTE:> if C<restore> has a value of 1, the C<column()> call makes no effort 
to "restore" conditions to any
starting values. If your last bit of text left the "current" font with some
"odd" face/family, size, I<italicized>, B<bolded>, or colored; that will be
what is used by the next column call (or other PDF::Builder text calls). This
is done in order to allow you to easily chain from one column to the next,
without having to manually tell the system what font, color, etc. you want
to return to. On the other hand, in some cases you may want to start from the
same initial conditions as usual. You
may want to add C<get_font()>, C<font()>, C<fillcolor()>, and
C<strokecolor()> calls as necessary before the next text output, to get the
expected text characteristics. Or, you can simply let C<restore> default to
0 to get the same effect.

=item '1'

A return code of 1 indicates that the call completed by filling up the defined
column space. It did I<not> run out of input C<$txt>. You will need to make
one or more calls with empty column space (to fill), to use up the remaining
input text (with "pre" I<$markup>).

If C<restore> defaults to 0 (or is set to 1), the text settings in the 
"current" font are left as-is, so that whatever you
were doing when you ran out of defined column (as regards to font face/family,
size, italic and bold states, and color) should automatically be the same when 
you make the next C<column()> call to make more output.

=back

Additional return codes I<may> be added in the future, to indicate failures
of one sort or another.

=item $next_y

The next page "y" coordinate to start at, if using the same column definition
as the previous C<column()> definition did (i.e., you didn't completely fill
the column, and received a return code of 0). In that case, C<$next_y> would
give the page "y" coordinate to pass to C<column()> (as C<start_y>) to start a 
new paragraph at.

If the return code C<$rc> was 1 (column was used up), the C<$next_y> returned
will be -1, as it would be meaningless to use it.

=item $unused

This is the unused portion of the input text (return code C<$rc> is 1), in a 
format ("pre" C<$markup>) suitable for input as C<$txt>. It will be a
I<reference> to an array of hashes.

If C<$rc> is 0 (all input was used up), C<$unused> is an empty anonymous array.
It contains nothing to be used.

=back

=back

=head3 Special notes on saving and restoring the font

It is important to let C<column()> know what font face (font-family), weight,
and style to use, so it can switch between normal, bold, and italic as desired.
There are several methods to I<explicitly select> a font face (font-family) and
its variants (weight, style) upon entry to C<column()>. One is to use the
C<font_info> option to C<column>, including "-fm-" (default) to use 
FontManager's default font (core Times-Roman). Another is to use the C<style> 
option to C<column()> to override the B<body> default CSS. A third, if using 
HTML or Markdown, is to add a E<lt>styleE<gt> tag to the beginning of the text 
markup, in order to set the B<body> CSS (as with C<style>). All of these 
methods will set the B<body>'s font.

If nothing special is done, the font selection upon entry to C<column()> will 
default to using the default FontManager settings (core Times-Roman, equivalent
to C<'font_info'=E<gt>'-fm-'>). C<font_info> may also be explicitly set to 
specify the body text font-family (optionally also style, weight, and color). 
C<'font_info'=E<gt>'-ext-'> may be given to tell FontManager to pick up an 
already-loaded font in this text context. It will label that font 
B<-external-> and use it as the current font. I<However>, be aware that if 
doing this, C<column()> will B<not> know the actual face (font-family) of 
whatever font this is, and thus can not change the font-weight (bold) or 
font-style (italic). These change requests will be ignored. If no font is 
already loaded, the FontManager's default font (C<-fm-> core Times-Roman) will 
be selected (and no "-external-" font defined). Whatever way is used to specify
he body font-family on the command line, it may be overridden by a 
C<E<lt>styleE<gt>> tag or C<'style'=E<gt>> command line CSS specification. 

Once C<column()> has already been called within a given text context, whatever
font is in force at the end of the call will be preserved by the text context,
available to be picked up by the next C<column()> call with 
C<'font_info'=E<gt>'-ext'> within I<this> text context. I<column() will still
B<not> know the font-family, since this information is not carried in the text
context!> Note that a text context is limited to a single page of a PDF, at 
most (it must be defined by the C<$page-E<gt>text()> call, and is reset with
each new page). The user code may of course choose to load a 
new font externally to C<column()>, in order to use that one upon entry. An
C<-external-> font still cannot change style or weight.

Any font "face" used must be first registered with FontManager. The standard
core fonts (as well as Windows extensions) are preregistered. If user code
loads an arbitrary font outside of C<column()>, it will only be known as
"-external-" (as described above). C<column()> calls (including CSS font-family)
only recognize registered faces, so it knows where to find the font file and
other information, and can cache the loaded font. It can keep track of which
font is currently being used, and know how to set bold and italic variants.

When the end of the defined column is reached (before the text source is
exhausted), all open tags are preserved, so that the next C<column()> call 
(with I<pre> formatting) can pick up with the same font settings as before.
However, this works only as long as the complete font description is set in
the tags (including the face). If the font face is not given in the tags, it
will not be known, and bold and italic will likely not work at the next change. 
If the text is in the middle of a highlighted phrase (e.g., bold or italic, or 
a different font), that particular font should be picked up again. However, the 
B<body> font face and variant may not be correctly resumed if it is assumed 
that the proper font has been inherited by the next C<column()> call. 
Explicitly setting the B<body> font should allow the font to return to a known 
starting condition, although it is possible that (based on nesting of font 
changes at the column break) other aspects might be incorrect.

To summarize, the best practice is to register (C<add_font>) to FontManager any
fonts you wish to use, and then explicitly use C<font_info> or C<style> to
let C<column()> know what the base font is for your text. This is better than
externally loading a font, and depending on its being inherited from the text
context, which may in turn may leave it in some other state after a C<column()>
call, as well as not being able to change bold and italic.

=head2 Markup supported

=head3 pre (already formatted from another format)

This is an internal format, essentially the output from HTML::TreeBuilder.
As this data is consumed by output, it is removed from the array. If any is
left over when the column is filled, it is returned to the user, and may be
used in a 'pre' format call to C<column()> to finish the job.

If you wish to manually generate 'pre' format data, you may do so, although it
is usually easier to use a higher level markup such as 'md1' or 'html'.

=head3 none

This format simply has empty lines separating paragraphs. Otherwise it has no
markup.

=head3 md1 (Markdown)

This is the version of the Markdown language supported by the Text::Markdown 
library. It is converted into the equivalent HTML and then processed by
HTML::TreeBuilder.

=head4 Standard Markdown

=over

=item *

* or _ produces italic text

=item *

** produces bold text

=item *

*** produces bold+italic text

=item *

* (in column 1) produces a bulleted list

=item *

1. (2., 3., etc. if desired) in column 1 produces a numbered list 1., 2., etc.

=item *

# produces a level 1 heading.
## produces a level 2 heading, etc. (up to ###### level 6 heading)

=item *

---, ===, or ___ produces a horizontal rule

=item *

~~ enclose a section of text to be line-through'd (strike-out)

=item *

[label](URL) external links (to HTML page or within this document, see '<a>' for URL/href formats)

=item *

[label][n] reference-style links B<NOT> currently supported

=item *

[label][^n] footnote-style links B<NOT> currently supported

=item *

` (backticks) enclose a "code" format phrase

=item *

``` (backticks) enclose a "code" format I<block>, B<NOT> currently supported

=item *

![alt text](path_to_image) image, B<NOT> currently supported

=item *

table entries with | and - (or HTML tags) B<NOT> currently supported

=item *

superscripts (^) and subscripts (~) (or HTML tags) B<NOT> currently supported

=item *

definition lists with : B<NOT> currently supported

=item *

task lists - [ ] B<NOT> currently supported

=item *

emojis will B<NEVER> be supported. We have a perfectly good alphabet.

=item *

highlighting (inline == or HTML E<lt>mark>) B<NOT> currently supported

=back

HTML (see below) may be mixed in as desired (although not within "code" blocks 
marked by backticks, where E<lt>, E<gt>, and E<amp> get turned into HTML 
entities, disabling the intended tags).
Markdown will be converted into HTML, which will then be interpreted into PDF.
I<Note that Text::Markdown may produce HTML for certain features, that is not 
yet supported by HTML processing (see 'html' section below). Let us know if 
you need such a feature!>

The input B<txt> is a list (anonymous array reference) of strings, each 
containing one or more paragraphs and other markup. A single string may also be 
given. Per Markdown formatting, an empty line between paragraphs may be used to 
separate the paragraphs. Separate array elements will first be glued together 
into a single string before processing, permitting paragraphs to span array 
elements if desired.  

=head4 Extended Markdown

CSS (Cascading Style Sheets) may be defined for resulting HTML tags (or "body" 
for global settings), via the C<style=E<gt>> C<column()> option. You may also
prepend a C<E<lt>styleE<gt>> HTML tag, with CSS markup, to your Markdown source.

Standard Markdown permits an 'id' to be defined in a heading, by suffixing the
text with C<{#id_name}>. This is equivalent to C<id="id_name"> in HTML markup.
Although Text::Markdown does not currently support it, C<column()> implements
this way of defining a target's id, and in fact extends it to permit an id to 
be defined for any tag with child text.

Markdown is further extended by C<column()> to permit a 'title' to be defined
for any tag with child text, by use of C<{^title_text}>. Note that this 'title'
is the I<link title> to be used, B<not> browser style "hover" popup text. It is
the equivalent of C<title="title_text"> in E<lt>a> or E<lt>_ref> HTML markup. 
Any link tag may define the PDF "fit" to use at the target, by 
C<{%fit_type,parm(s)}> or C<fit="fit_type,parm(s)"> in E<lt>a> or E<lt>_ref> 
HTML markup.

There are other HTML equivalents defined by Standard Markdown which may not
be implemented (converted) by Text::Markdown. Among these are C<~~> line-through
(strike-out) and C<===> horizontal rule, which have been fixed with 
post-processing of the generated HTML. Let us know if you find any more such
cases, and we may be able to extend the functionality of 'md1' formatting, or 
if necessary, implement 'md2' format to use a different library. By default, 
Text::Markdown disables extended E<lt>_tagname> calls, but these all should be
handled properly in post-processing. There are also Markdown features that may
be implemented by Text::Markdown, but the resulting HTML is not supported by
C<column()> (yet). If you are missing a needed feature, ask about our moving it
up on the priority list.

=head3 html (HTML)

This is the HTML language to be processed by the HTML::TreeBuilder library. It 
is processed into an array of tags and text strings ('pre' format), which is 
interpreted by C<column()>. A substantial subset of CSS (Cascading Style Sheets)
is also interpreted by C<column()>, although selectors are primitive compared
to what a browser supports.

=head4 Standard HTML tags

A good many HTML tags are implemented, although not all of them:

=over

=item *

B<E<lt>iE<gt> or E<lt>emE<gt>>
produces italic or slanted/oblique text, where available through FontManager

=item *

B<E<lt>bE<gt> or E<lt>strongE<gt>>
produces bold text, where available through FontManager

=item *

B<E<lt>sE<gt>, E<lt>strikeE<gt>, and E<lt>delE<gt>>
produce text line-through (strike-out or strike-through)

=item *

B<E<lt>uE<gt> and E<lt>insE<gt>>
produce underlined text

=item *

B<E<lt>codeE<gt>>
produce 'code'-style fixed-pitch text

=item *

B<E<lt>h1E<gt> through E<lt>h6E<gt>>
produce level 1 through 6 headings and subheadings

=item *

B<E<lt>hrE<gt>> 
produce a horizontal rule

The C<width="length"> attribute gives a length (width, in pixels) less than the full column width, and C<size="height"> attribute gives the height (thickness) of the rule. CSS properties C<width> and C<height> are the equivalent, permitting other units of measure. 

The default C<width> is the full column, and C<size> (thickness) of the line is 0.5pt.

Note that most browsers default to I<center> alignment if the width is less than the full column, which is the default here. 
The B<align> attribute is available here to specify I<left> alignment of the rule, I<center> alignment (default), or I<right>
alignment. Note that this attribute is deprecated in the HTML standard, however, PDF::Builder does not yet support the suggested
CSS methods (properties) for doing this.

=item *

B<E<lt>blockquoteE<gt>>
produces a quotation block, a paragraph indented on both sides and of smaller font size

=item *

B<E<lt>pE<gt>>
produces a paragraph

=item *

B<E<lt>font face="font-family" color="color" size="font-size"E<gt>>
as selecting font face, color, and size (considered better to use CSS)

=item *

B<E<lt>spanE<gt>>
needs a style= attribute with CSS to do anything useful

=item *

B<E<lt>ulE<gt>>
produces an unordered (bulleted) list. The C<type> attribute to override the default marker is supported

=item *

B<E<lt>olE<gt>>
produces an ordered (numbered) list. C<start=>, C<type=>, and C<reverse=> attributes are supported to override the default starting count, format, and direction

=item *

B<E<lt>liE<gt>>
adds a list item to a list (ul, ol, or _sl). The C<value=> attribute may be given to override the ordered list counter, and the C<type=> attribute may be given to override the default marker type

=item *

B<E<lt>a href="URL"E<gt>> 
produces a link to a browser URL or to this or another PDF document. "URL" is anchor/link, web page URL or this document target C<#p[-x-y[-z]]> (p is physical page number), or path to external PDF document before the #. ##NamedDest and extPDF##NamedDest are supported. Otherwise treat as an "id" (id=).

=over

=item *

B<href="protocol://...">
a link will be generated to an HTML browser or (for protocol "mailto") an email client. The tag remains E<lt>a> and a's CSS properties are used. Otherwise, internally the tag will be changed to E<lt>_ref>, whose CSS properties will be used

=item *

B<href="#p" or "#p-x-y" or "#p-x-y-zoom">
a link will be generated to a physical page number "p" in this document. Optionally, an x-y location on the page (for fit="xyz") may be given with an optional zoom factor

=item *

B<"PDF_document_path#p" etc.>
a link will be generated to a physical page number "p" in an external document. Note that the path and filename must point to either an absolute address or to one relative to where this PDF will be located

=item *

B<"##Named_destination">
a link will be generated to a Named Destination in this document (see E<lt>_nameddest>). Note that the Named Destination itself will define the "fit" to be used

=item *

B<"PDF_document_path##Named_destination">
a link will be generated to a Named Destination defined in an external document. Note that the path and filename must point to either an absolute address or to one relative to where this PDF will be located, and that the Named Destination itself will define the "fit" to be used

=item *

B<"#id_name" or "id_name">
a link will be generated to the "id" of given name, which may be in this PDF document or another (if processed in the same run). If a "#" is used, the name must B<not> be all decimal digits, or all decimal digits followed by a "-" and other parts, as this will be interpreted as a "#p" physical page link!

=back

The link's child text, if not empty, will be used for the resulting link. If there is none, any "title" attribute or C<{^title text}> provided with the target (such as E<lt>_reft>) will be used. Finally, any native "child text" (e.g., a heading's text content) will be used.

If using HTML markup, any tag with an id= may be a target. Especially for Markdown use, any tag with child text (not just a heading's text) may include C<{#idname}> to be parsed out as C<id="idname"> (and thus usable as a target). 

An explicit "fit=" attribute may be given in the E<lt>a> tag, to specify the page fit used by the PDF Reader at the target location. For example, fit="xyz,45,600,1.5" to place the window upper left corner at 45,600 and 150% zoom factor. For Markdown usage, {%xyz,45,600,1.5} in the link text (title) would be the equivalent (xyz fit, at 45,600, zoom 1.5). For a page number target (#p), -x-y (and optionally -zoom) may be added for the same effect (xyz fit). "null" or "undef" 
may be used for undefined items. For any fit, %x and %y may be used for the 
target's x and y location, to use the actual target location and not a fixed 
location on a page.

=item *

B<In plan, but not yet implemented>

=over

=item *

'pre' (preformatted blocks),

=item *

'cite', 'q', 'samp', 'var', 'kbd' (various highlights),

=item *

'big', 'bigger', 'small', 'smaller' (various font sizes),

=item *

'img' (image display),

=item *

'br', 'nobr' (line break, line break suppression),

=item *

'sup', 'sub' (superscript and subscript),

=item *

'dl', 'dt', 'dd' (definition lists),

=item *

'table', 'thead', 'tbody', 'tfoot', 'tr', 'th', 'td' (tables),

=item *

'mark' (highlighting... requires ability to set background color),

=item *

'div' (handle div's in some manner),

=item *

'center',

=item *

'caption', 'figure', 'figcap' (optional sub- and super-sections)

=item *

'nav', 'header', 'footer', 'address', 'article', 'aside', 'canvas', 'section', 'summary' (possibly some sectioning)

=back
    
=back

I<Numbered> (decimal and hexadecimal) entities are supported, as well as I<named> entities (e.g., C<E<amp>mdash;>). Lists get a "gutter" (for the marker) of I<marker_width> points wide, and a "gap" between the marker's field and the start of the item's text (I<marker_gap> points wide), so list alignments are consistent over the call.


=head4 Extended HTML tags

A number of HTML-like tags, whose names start with an underscore "_", have
been implemented to perform various tasks. These include:

=over

=item *

B<E<lt>_refE<gt>>
defines an I<alternative> form of a link to this or another PDF document (not for URLs to HTML or email; for that, use E<lt>a>). The attribute C<tgtid=> is required, and equivalent to E<lt>a>'s C<href=>. The attribute C<title=> is optional, and provides title text for the link. The attribute C<fit=> is optional, and provides a non-default "fit" for the target page (note that a Named Destination target provides its own "fit"). For a 'fit' of 'xyz', you may use '%x' for the x value and '%y' for the y value to use the current positions, rather than fixed values. Note that any E<lt>a> link I<not> to a browser or email client will be internally converted to E<lt>_ref>, so CSS for formatting the link text (title) will be defined under '_ref'

=item *

B<E<lt>_reftE<gt>>
defines a target id for a link (via the C<id=> attribute), especially if an existing id is not conveniently at hand. See C<id=> attributes in most HTML tags, and C<{#id_name}> for many Markdown "tags". An optional attribute C<title=> may be given to provide a default link text for the link (E<lt>a> or E<lt>_ref>) referring to this id

=item *

B<E<lt>_nameddestE<gt>>
defines a Named Destination within this document, accessible via a "##" format link href, or from some PDF Readers on the command line (one or more of C<#ND_name>, C<#name=ND_name>, or C<#nameddest=ND_name> will usually work, when appended to the PDF file path and name, just like with HTML anchor id's). The attribute C<name="ND_name"> is required, to globally name this Destination (the character set allowed and maximum length vary among Readers!). The optional attribute C<fit="fit_info"> may be give to specify a non-default "fit" when invoked. It is the type of fit (e.g., "xyz", "fith", etc.) followed by any location values required by that fit, all separated by commas. C<xyz,%x-100,$y+100,null> is the default fit

=item *

B<E<lt>_markerE<gt>>
provides a place to specify, via CSS, on a I<per list item basis>, overrides to default marker settings (see also C<_marker-*> CSS extensions below). If omitted, the same HTML list markers and CSS properties are used for each list item (per usual practice). The intent of this tag is to permit styling changes such as font, color, and alignment to an individual list item (E<lt>li>). This tag is placed immediately I<before> the <li> it applies to

=item *

B<E<lt>_moveE<gt>>
provides a way to explicitly move the current write point left or right. Attribute C<x="value"> is an absolute move (in points), while attribute C<dx="value"> is a relative move from the current write point. Along with the "text-align" CSS property, this can provide a way to fine tune text position within a column line.

An x value that is a bare number (no units) is assumed to specify I<points>, equivalent to units of C<pt>. The unit may also be C<%>, where 0% is the left end of the column, 50% is the center, and 100% is the right end.
A dx value that is a bare number (no units) is assumed to specify I<points>, equivalent to units of C<pt>. The unit may also be C<%>, a fraction of the column width to move (+ right, - left). Note that results are unpredictable if you move beyond the edge of the column in either direction

=item *

B<E<lt>_slE<gt>>
provides a I<simple list>, very similar to an I<unordered list>, except for no list markers

=item *

B<In plan, but not yet implemented>

=over

=item *

'_k' (manual kerning control)

=item *

'_ovl' (overline, similar to underline and line-through)

=item *

'_lig' (specify a particular ligature to use here)

=item *

'_nolig' (suppress ligatures by HarfBuzz)

=item *

'_swash' and '_altg' (specify a particular alternate glyph to use here)

=item *

'_sc' (specify "small caps" font variant, with forced end after N words)

=item *

'_pc' (specify "petite caps" font variant, with forced end after N words)

=item *

'_dc' (specify "dropped cap" font variant in some manner, also CSS)

=item *

? (specify conditional and unconditional page breaks)

=back

=back

=head4 Standard CSS properties and values

CSS (Cascading Style Sheets) may be defined for HTML tags (or "body" 
for global settings), via the C<style=E<gt>> C<column()> option. You may also
add one or more C<E<lt>styleE<gt>> HTML tags, with CSS markup, to your HTML 
source. Such entries will be combined into a global style section.

E<lt>styleE<gt> tags may be placed in an optional E<lt>headE<gt> section, or
within the E<lt>bodyE<gt>. In the latter case, style tags will be pulled out
of the body and added (in order) on to the end of any style tag(s) defined in 
a head section. Multiple style tags will be condensed into a single collection 
(later definitions of equal precedence overriding earlier). These stylings will
have global effect, as though they were defined in the head. As with normal CSS,
the hierarchy of a given property (in decreasing precedence) is

    appearance in a style= tag attribute
    appearance in a tag attribute (possibly a different name than the property)
    appearance in a #IDname selector in a <style>
    appearance in a .classname selector in a <style>
    appearance in a tag name selector in a <style>

Selectors are quite simple: a single tag name (e.g., B<body>),
a single class (.cname), or a single ID (#iname). 
There are I<no> combinations (e.g., 
C<p.abstract> or C<ol, ul>), hierarchies (e.g., C<ol E<gt> li>), specified 
number of appearance, pseudotags, or other such complications as found in a 
browser's CSS. Sorry!

=head4 Length Measures

Property values which are lengths (including C<font-size>) may have units of B<pt> 
(points, 72 to the inch), B<px> (pixels, currently fixed at 78 to the inch), 
B<in> (inches), B<cm>, B<mm>, B<em> (equal to font-size), B<en> (0.5em), and B<ex> (currently 
0.5em, but in the future may be able to query the font's actual x-height). 
% (percentage) of the current font-size (in most cases, unless otherwise noted) is allowed, although
some properties may in the future support % of the enclosing object size. 
Sizes may be negative numbers (useful only for margins).

=over

=item * 

For property 
I<list-style-position>, % is relative to the marker width+gap, not font-size (and pt values may
be given, where "inside" = 0% and "outside" = 100% of marker width+gap). The standard 'outside'
(default) and 'inside' values may also be given.

=item *

For the I<E<lt>hr>> tag, the "width" and "size" attributes are in points. For the CSS "width" 
property, absolute units may be given, or % of available column width. For the CSS "height"
property, absolute units may be given.

=back

B<Note> that eventually we may support C<li::marker>, which is now standard CSS,
but there does not appear to be a way to support changes via C<style=>, because
the same property names (e.g., I<color>) would apply to both the marker and the
list item text. This will require extensive changes to CSS style to permit 
complex selectors, which C<column()> does not currently offer. Even doing that,
we may retain the current "marker" tags and CSS introduced here. I think W3C
may have missed the boat by not doing something like an optional C<_marker> to 
permit normal properties for markers alone, but configurable in-line with
C<style=>.

Supported CSS properties: 

=over

=item *

B<color> (foreground color, in standard PDF::Builder formats)

=item *

B<display> (I<inline> or I<block>)

=item *

B<font-family> (name as defined to FontManager, e.g. Times)

=item *

B<font-size> (length measure)

Note that B<body> C<font-size> is the starting point, and so if given,
must be a bare number (greater than 0) or number + 'pt'. C<font-size>s for
other tags may be given as % of inherited font-size or em (100% of font-size),
en (50%), or ex (currently fixed at 50%).

Unless otherwise prohibited, any tag's CSS may first change the font-size,
and then properties such as margins defined as % of font-size will be
calculated using the new font-size, rather than the inherited one.

=item *

B<font-style> (I<normal> or I<italic>) 

=item *

B<font-weight> (I<normal> or I<bold>)

=item *

B<height> (pt, bare number) 

Thickness (height) of B<horizontal rule>. The HTML attribute is C<size>.

=item *

B<list-style-position> (outside, inside, B<extension:> number pt or % to indent)

=item *

B<list-style-type> (marker description, see also _marker-text/before/after)

=item *

B<margin-top/right/bottom/left> (length measure)

Note that adjacent bottom and top margins will be collapsed to use the 
I<larger> amount of the two. Negative margin values ("pulling" objects towards
each other) are allowed, and positive margin values "push" objects away from
each other.

=item *

B<text-decoration> (none, underline, line-through, overline)

May use more than one value (except 'none') separated by spaces. 

B<Note 1:> various HTML tags (such as I<u>, I<ins>, I<del>, I<s>) make use of 
this CSS property, and may of course be changed in the styling.

B<Note 2:> both I<underline> and I<overline> are solid lines, which will collide with
glyph descenders and ascenders respectively. We are investigating means of
implementing something like the CSS I<text-decoration-skip-ink: auto> property. 
PDF does not appear to currently define a way of doing this (to be handled by
the Reader). I<line-through> is 
also a solid line that collides with glyph strokes, but the usual intent I<is> 
to obscure the text, so there are no plans to change this default behavior.

B<Note 3:> these decorations are made as escapes within the text object, rather
than within the graphics object. We reserve the right to (in the future) change 
this to require a graphics object to draw them. Some lead time will be given so
that you have a chance to update your code.

B<Note 4:> I<line-through> uses a fixed % of ascender height, rather than of I<ex>
height. In some fonts, this may result in a I<line-through> "floating" above the
bulk of the characters (intersecting only ascenders), i.e., it is above the x-height.
It's on the "to do" list to address this.

=item *

B<line-height> (leading, as ratio of baseline-spacing to font-size). 

Currently, percentage of font-size and absolute units (e.g., pt) are B<not> supported. 
The default value is 1.125 (18pt line-to-line for font-size 16).

B<Note:> B<text-height>, the former I<incorrect> name for this property, is 
still supported (as an alias for B<line-height>) through release 3.029, but may 
be withdrawn as soon as release 3.030. Update your code if you use it!

=item *

B<text-indent> (length measure)

For paragraph indentation.

=item *

B<text-align> (left/center/right justify at current text position)

B<Note:> if center or right justified, you should keep the text short enough
to fit within the left and right bounds of the column. Center and right
justification need an explicit position defined (usually via <_move>) and will 
not properly wrap to a new line.

=item *

B<width> (length measure) width (length) of B<horizontal rule>

Currently only used for E<lt>hr>. In the future it may be expanded to other
object types. E<lt>hr> may be permitted in the future to be a percentage
of the enclosing parent's width.

=item *

B<height> (length measure) height (thickness) of B<horizontal rule>

Currently only used for E<lt>hr>. In the future it may be expanded to other
object types. E<lt>hr> may be permitted in the future to be a percentage
of the enclosing parent's height.

The equivalent HTML attribute is C<size>.

=item *

B<In plan, but not yet implemented>

=over

=item *

white-space (treatment of line-ends and various spaces),

=item *

/* and */ comments in CSS

=item *

border and border-* (border properties),

=item *

padding and padding-* (padding properties),

=item *

list-style-image (use an image as a list bullet),

=item *

margin (update the four C<margin-*> properties in one setting, add 'auto' value)

=item *

background-color (also for <mark> tag),

=back

=back

See the L</Length Measures> section to see what measurements are allowed.

B<CAUTION:> comments /* and */ are NOT
currently supported in CSS -- perhaps in the future.

=head4 Extended CSS properties and values

A number of additional (non-standard) CSS properties and/or values have been
defined for additional functionality for C<column()>. Note that if you set
_marker-* properties in a list, all nested lists will, as usual, inherit these
properties. If you don't want that, you will need to cancel the new settings by
resetting them to standard values in the nested <ul> or <ol> tag's style.

=over

=item *

B<_marker-before> (constant text to insert I<before> an E<lt>ol> marker, default nothing)

=item *

B<_marker-after> (constant text to insert I<after> an E<lt>ol> marker, default period ".")

=item *

B<_marker-text> (define text to use as marker instead of the system-generated text)

=item *

B<_marker-color> (change color from default, such as color-coded E<gt>ul> bullets)

=item *

B<_marker-font> (change marker font face (font-family))

=item *

B<_marker-style> (change marker font style, e.g., italic)

=item *

B<_marker-size> (change marker font size)

=item *

B<_marker-weight> (change marker font weight)

=item *

B<_marker-align> (left/center/right justify within marker_width gutter)

=item *

B<list-style-position> standard (inside or outside) or numeric (points or percentage of marker_width gutter + marker_gap)

=back

There are additional non-standard CSS "properties" that you would normally 
B<not> set in CSS. They are internal state trackers:

=over

=item *

B<_parent-fs> (current running font size, in points)

This is actually the parent of this tag's font-size, which the current tag inherits
and may set to a new value if desired (with C<font-size> property).

=item *

B<_href> (URL for <a>, normally provided by href= attribute)

=item *

B<_left> (running number of points to indent on the left, from margin-left and list nesting)

=item *

B<_left_nest> (amount to indent next nested list)

=item *

B<_right> (running number of points to indent on the right, from margin-right)

=back

=head2 General Comments

The Font Manager system is used to supply the requested fonts, so it is up to
the application to preload the desired font information I<before> C<column()>
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

# ---------------------------------------------------------------------------
# function defined in Builder.pm
=head2 init_state

    %state = PDF::Builder->init_state(%lists)

    %state = PDF::Builder->init_state()

This method is used in L<PDF::Builder::Content::Text> to create and initialize 
the hash structure that permits transfer of data between
C<column()> calls, as well as accumulating link information to build
intra- and inter-PDF file jumps for a variety of uses.

B<%lists> is optional, and allows the user to define tags (which have an id= )
lists for various purposes. These are anonymous lists. Element '_reft' is 
predefined for cross reference targets, and already includes the <_reft> tag 
as '_reft'. B<Do not add '_reft' to the '_reft' list!> The user may wish to add 
other tags (which have id= ) to be used, and define other lists to be 
accumulated. For example, 

    {'_reft' => [ 'h1', 'h2', 'h3', 'h4' ],
     'TOC'   => [ '_part', '_chap', 'h1', 'h2', 'h3' ], }

adds the top 4 heading levels to cross references ('_reft' is already there), 
and creates a 5-level list of tags to build a Table of Contents. Additional
lists might include for an Index, glossary, List of Tables, List of Figures
(Illustrations, Photos), List of Equations, etc. I<TOC, Index, etc. have not
yet been implemented, but are planned for the near future!>

If no C<%lists> parameter is given, you will be limited to cross references
from <_reft> only, and no entries specifically for TOC etc. will be defined.
Remember, only tags with C<id=>s in your markup will be used as link targets.

If you are using **markdown** for your source, you may not be able to define
C<id=>s for all your "tags" (HTML tags produced after translation from 
markdown), and thus will need to use C<E<lt>_reftE<gt>>s as link targets, which 
should be passed through to HTML. For applications such as a TOC, you I<may> 
be able to postprocess the _reft list to separate out (based on id given) this 
large group of target ids into groups for specific purposes, such as a TOC.

    %state = PDF::Builder->init_state(%lists)

This creates the state structure (hash) to be passed to C<column()> calls, and
it saves information from invocation to invocation. It must be initialized
I<before> the first pass of the loop which invokes one or more C<column()> 
formatting calls at each pass (for a different part of the document).

It is defined in PDF::Builder (Builder.pm) as L<PDF::Builder::init_state>, 
rather than here in PDF::Builder::Content::Text, because C<$text> does not 
yet exist when it needs to be called.

=cut

# ---------------------------------------------------------------------------
# function defined in Builder.pm
=head2 pass_start_state

    $rc = $pdf->pass_start_state($pass_count, $max_passes, \%state)

This does whatever is necessary at the I<start> of a pass (number $pass_count).
Currently, this is resetting the 'changed_target' hash list.

It is defined in PDF::Builder (Builder.pm) as 
L<PDF::Builder::pass_start_state>, rather than here in 
PDF::Builder::Content::Text, because C<$text> does not yet exist when it 
needs to be called.

=cut

# ---------------------------------------------------------------------------
# function in Content::Text
=head2 pass_end_state

    $rc = $text->pass_end_state($pass_count, $max_passes, $pdf, $state, %opts)

This examines the state structure (hash), resolves any content changes that
need to be made, and builds a list of all refs (by target id C<tgtid>) which
are still changing at this pass. If any have changed, a non-zero return code
(number of cases) is returned, but if everything has settled down, the return
code is 0. 

=over

=item $pass_count

What pass number we are on. Start at 1, and must be no greater than 
C<max_passes>.

=item $max_passes

The pass number of the last permitted pass, if reached. We may exit before
this if things settle down quickly enough. If 

=over

=item 1.

page numbers are not output in link text (C<page_numbers == 0>) _and_

=item 2.

C<title=> is given in all '_ref' tags, _or_ all _ref's without title 
attributes are backwards references (all forward _ref's have a title)

=back

you may often be able to get away with a single pass (C<max_passes == 1>).
You still may be informed that not all cross references have settled.

=item $pdf

The PDF object.

=item $state

Hashref to state structure, which includes, among other things, lists of
link sources (_ref tags) and link targets (_reft and other listed tags).

=item %opts

Options.

=over

=item 'debug' => 1

Draw a border around the link text (the source, not the target), so you can
see where a click would take effect.

=item 'deltas' => [ 20, 20 ]

To show some context around the target text (if I<xyz> fit is used without a
specific x and y), the upper left corner of the target window is placed these
amounts (units I<points>) from the left (delta x) and top (delta y) edges of 
the target text. The default is 20 (points) each, roughly a couple of lines' 
worth. The left side is limited to the page edge, and the top side is limited
to the page top.

Note that the upper edge of the text is where the I<previous> line left off, 
so if there is a top margin on the target text (e.g., it's a heading), the
offset will be from there, not the text itself, and the view window may 
therefore be up higher on the page than you would otherwise expect. This has
been known to confuse users with a PDF Reader which displays a fixed-size popup 
window showing the target a link will go to, which might even miss the target 
text entirely if the deltas are too large.

=back

=back

If all references include their own title string and do B<not> show a page 
(only the title string as the annotation link text), a document should take 
only one pass. Often two passes are enough to resolve even forward references
which need to pick up text from later in the document,
but sometimes (especially if special formatting of page numbers is involved),
a target may move back and forth between two pages and not settle down. In
such cases, you may need to simplify or rearrange the text, such as moving a
target back from the end of a page, or changing from specialty formats (such
as "on following page" to a fixed "on page N".

B<Fields in %state structure:>

    settings       = hold settings between column() calls
      TBD

    xrefs          = source of link (<_ref>) info needed
      [  ]           = array of each link source
        id             = target's id, tag that defines a target
	fit            = any fit information provided
        tfn            = target filename (FINAL position and name) used for 
                         external links
        tppn           = target physical page number (integer > 0)
        sppn           = source physical page number (integer > 0)
	other_pg       = text for "other page" if page_numbers > 0
	 prev_other_pg  = previous value (to detect change)
        tfpn           = formatted page number (string, may be '')
        tx,ty          = coordinates of target on page (used for fit)
        title          = text for link. if not defined in <_ref>, use one
                         in <_reft> (if defined), else "natural text" such
                         as heading <hX> child text
	 prev_title     = previous value (to detect change)
        tag            = tag that produced this target (useful for formatting,
                         e.g., indenting TOC entries based on hX level)
	click          = [ ] of one or more click areas, each element is
	                 [sppn, [x,y, x,y]]

    xreft          = tag that created a target for a link (<_reft> et al.)
      _reft          = entries for cross reference targets (_reft list)
        id
	  tfn        = filepath for external links
	  tppn       = target physical page number
	  tfpn       = target formatted page number
	  tx,ty      = coordinates of target on page
	  title      = title, defaulting to "natural text", to update source
	  tag        = tag type that produced this entry
      $another_list  = other tag list name list of targets (e.g., TOC)
        id...
      etc.

    changed_target = hash of tgtids (in xrefs id) that changed AFTER link text
                     and page text output, requiring another pass

    tag_lists      = anon list of tags (with id) to put in various lists.
                     see 'init_state()' for building tag lists
      _reft          = [ ] predefined for cross references, may add more (such
                       as hX heading tags)
      TOC            = [ ] NOT predefined, add if desired ...TBD
      Index          = [ ] NOT predefined, add if desired, etc. ...TBD

   nameddest = hash of named destinations to be defined
      $name  = name of the destination
        fit  = fit information (location, parms)
	ppn  = physical page number in this PDF
        x,y  = x and y coordinates on page  

Note that the link text ('title') and any page information ('on page X') need
to be output at each pass, to determine where everything is, while other
information is stored until the last pass, to actually generate the annotation
links. The "last pass" will be either when it is found that all link information
has "settled down", or the C<max_passes> limit is reached.

=cut

# ---------------------------------------------------------------------------
# function in Content::Text
=head2 unstable_state

    @list = $text->unstable_state(\%state)

This returns a list (array) of string target ids (tgtid) which appear to still
be changing at the end of the loop, i.e., have not settled down.

If this method is called when C<check_state()> returned a 0, the list will
be empty. It may also be called at each pass, for diagnostic purposes.

=cut

# ---------------------------------------------------------------------------
sub _cdocs {
	# dummy stub
} 

1;
