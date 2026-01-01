package PDF::Builder::FontManager;

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.028'; # manually update whenever code is changed

use Carp;
use Scalar::Util qw(weaken);

# unless otherwise noted, routines beginning with _ are internal helper 
# functions and should not be used by others
#
# TBD (future)
#  spec use of synfont() against a base to get
#   fake bold, italic, bold+italic
#   small caps (80% height), perhaps petite caps (1 ex height)
#   condensed and expanded (or via hscale())
#  support for UTF-8 subfonts for single byte encoding fonts

=head1 NAME

PDF::Builder::FontManager - Managing the font library for PDF::Builder

=head1 SYNOPSIS

These routines are called from the PDF::Builder class (see C<get_font(),
add_font()> methods).

    # core fonts come preloaded
    # Add new a new font face and variants
    my $rc = $pdf->add_font(
        'face' => $unique_face_name,  # font family, e.g., Times
	'type' => 'core',             # note that core fonts preloaded
	'style' => 'serif',           # also sans-serif, script (cursive),
	                              #  and symbol
	'width' => 'proportional',    # also constant
        'settings' => { 'encode' => $encoding },
        # note that these are actual core font names rather than file paths
	'file' => { 'roman'       => 'Times-Roman',      
	            'italic'      => 'Times-Italic',
		    'bold'        => 'Times-Bold',
		    'bold-italic' => 'Times-BoldItalic' },
		# for non-core these would be the actual file paths
		# prefixed with font search paths 
    );
    $rc = $pdf->add_font(
        'face' => 'DejaVuSans',       # Deja Vu  sans serif family
	'type' => 'ttf',              # otf uses 'ttf'
	'style' => 'sans-serif',
	'width' => 'proportional',
        'settings' => { 'encode' => 'utf8' },
        # the defined font paths will be prepended to find the actual path
	'file' => { 'roman'       => 'DejaVuSans.ttf',
	            'italic'      => 'DejaVuSans-Oblique.ttf',
	            'bold'        => 'DejaVuSans-Bold.ttf',
	            'bold-italic' => 'DejaVuSans-BoldOblique.ttf' }
    );

Some of the global data, which can be reset via the C<font_settings()> method:

    * default-face:  initialized to Times-Roman (core), used if you start
      formatting text without explicitly setting a face, or inheriting one
    * default-serif: initialized to Times-Roman (core), used if you want
      a "generic" serif typeface
    * default-sansserif: initialized to Helvetica (core), used if you want
      a "generic" sans-serif typeface
    * default-constant: initialized to Courier (core), used if you want
      a "generic" constant-width typeface
    * default-script: NOT initialized (no default), used if you want
      a "generic" script (cursive) typeface
    * default-symbol initialized to Symbol (core), used if you want
      a "generic" symbol typeface
    * font-paths: C:/Windows/Fonts for Windows systems for TTF, other types
      are in non-standard paths, and for non-Windows, anything goes

Usage of C<get_font()> is to specify the face and variants, and then each time,
specify I<italic> and I<bold> to be on or off. If the desired file is not yet
opened, it will be, and the C<$font> returned. If the font was already
created earlier, the saved C<$font> will be returned.

    my $font = $pdf->get_font(
         'face' => 'Times',
	 'italic' => 0,     # desire Roman (upright)
	 'bold' => 0,       # desire medium weight
    );
    # if $font is undef, we have a problem...
    $text->font($font, $font_size);
    $text->...  # use this font (medium weight Times-Roman core font)
    $font = $pdf->get_font('italic' => 1);
    $text->...  # switched to italic
    $font = $pdf->get_font('italic' => 0);
    $text->...  # back to Roman (upright) text

=head1 METHODS

=head2 new

    PDF::Builder::FontManager->new(%opts)

=over

This is called from Builder.pm's C<new()>. Currently there are no options
selectable. It will set up the font manager system and preload it with the
core fonts. Various defaults will be set for the face (core Times-Roman),
serif face (core Times-Roman), sans-serif face (core Helvetica), constant
width (fixed pitch) face (core Courier), and a symbol font (core Symbol).
There is no default for a script (cursive) font unless you set one using
the C<font_settings()> method.

=back

=cut

sub new {
    my ($class, $pdf) = @_;

    my $self = bless { 'pdf' => $pdf }, $class;
    weaken $self->{'pdf'};
   #$pdf = $pdf->{'pdf'} if $pdf->isa('PDF::Builder');
   #$class = ref($class) if ref($class);
   #my $self = $class->SUPER::new($pdf);
    $self->{' pdf'} = $pdf;
    weaken $self->{' pdf'};

    # current font is default font until face explicitly changed.
    # Times face should be element 0 of the font-list array.
    $self->{' current-font'}      = {'face' => 'Times', 'index' => 0,
                                     'italic' => 0, 'bold' => 0};
    # just the face to use. index assumes standard core initialization
    $self->{' default-font'}      = {'face' => 'Times', 'index' => 0};
    $self->{' default-serif'}     = {'face' => 'Times', 'index' => 0};
    $self->{' default-sansserif'} = {'face' => 'Helvetica', 'index' => 1};
    $self->{' default-constant'}  = {'face' => 'Courier', 'index' => 2};
    $self->{' default-symbol'}    = {'face' => 'Symbol', 'index' => 3};
    # no script font loaded by default
    $self->{' default-script'}    = {'face' => undef, 'index' => -1};
    $self->{' font-paths'}        = [];

    $self->{' font-list'}         = [];

    # For Windows, can at least initialize to TTF place. Any additional fonts
    # for Windows, and all non-Windows paths, will have to be added by the
    # user. Note that an absolute (starts with /) or semi-absolute (starts 
    # with ./ or ../) font path/file will NOT have any search paths
    # prepended!
    push @{$self->{' font-paths'}}, $pdf->font_path();
    # can add any additional paths, but better to do in Builder.pm

    $self->_initialize_core();

    return $self;
} # end of new()

=head2 font_settings

    @list = $pdf->font_settings()  # Get

    $pdf->font_settings(%info)  # Set

=over

Get or set some information about fonts, particularly the fonts to be used for
"generic" purposes.

"Get" returns a list (array) of the default font face name, the default generic
serif face, the default generic sans-serif face, the default generic constant
width face, the default generic symbol face, and the default generic script
(cursive) face. It is possible for an element to be undefined (e.g., the
generic script face is C<undef>).

"Set" changes one or more default settings:

    'font' => face to use for the default font face (initialized to Times)
    'serif' => face to use for the generic serif face (initialized to Times)
    'sans-serif' => face to use for the generic sans serif face 
                    (initialized to Helvetica)
    'constant' => face to use for the generic constant width face 
                  (initialized to Courier)
    'script' => face to use for the generic script face (uninitialized)
    'symbol' => face to use for the generic symbol face 
                (initialized to Symbol)

=back

=cut

sub font_settings {
    my ($self, %info) = @_;

    if (!keys %info) {
	# Get default faces, nothing passed in
	return (
            $self->{' default-font'}->{'face'},
            $self->{' default-serif'}->{'face'},
            $self->{' default-sansserif'}->{'face'},
            $self->{' default-constant'}->{'face'},
            $self->{' default-script'}->{'face'},
            $self->{' default-symbol'}->{'face'},
	       );
    }

    # Set default info from %info passed in
    # also check if face exists, and at same time pick up the index value
    my $index;
    if (defined $info{'font'}) {
	$index = $self->_face2index($info{'font'});
	if ($index >= 0) {
	    $self->{' default-font'}->{'face'} = $info{'font'};
	    $self->{' default-font'}->{'index'} = $index;
	} else {
	    carp "font_settings can't find face $info{'font'}. ignored.";
	}
    }
    if (defined $info{'serif'}) {
	$index = $self->_face2index($info{'serif'});
	if ($index >= 0) {
	    $self->{' default-serif'}->{'face'} = $info{'serif'};
	    $self->{' default-serif'}->{'index'} = $index;
	} else {
	    carp "font_settings can't find face $info{'serif'}. ignored.";
	}
    }
    if (defined $info{'sans-serif'}) {
	$index = $self->_face2index($info{'sans-serif'});
	if ($index >= 0) {
	    $self->{' default-sansserif'}->{'face'} = $info{'sans-serif'};
	    $self->{' default-sansserif'}->{'index'} = $index;
	} else {
	    carp "font_settings can't find face $info{'sans-serif'}. ignored.";
	}
    }
    if (defined $info{'constant'}) {
	$index = $self->_face2index($info{'constant'});
	if ($index >= 0) {
	    $self->{' default-constant'}->{'face'} = $info{'constant'};
	    $self->{' default-constant'}->{'index'} = $index;
	} else {
	    carp "font_settings can't find face $info{'constant'}. ignored.";
	}
    }
    if (defined $info{'script'}) {
	$index = $self->_face2index($info{'script'});
	if ($index >= 0) {
	    $self->{' default-script'}->{'face'} = $info{'script'};
	    $self->{' default-script'}->{'index'} = $index;
	} else {
	    carp "font_settings can't find face $info{'script'}. ignored.";
	}
    }
    if (defined $info{'symbol'}) {
	$index = $self->_face2index($info{'symbol'});
	if ($index >= 0) {
	    $self->{' default-symbol'}->{'face'} = $info{'symbol'};
	    $self->{' default-symbol'}->{'index'} = $index;
	} else {
	    carp "font_settings can't find face $info{'symbol'}. ignored.";
	}
    }

    return;
}

=head2 add_font_path

    $rc = $pdf->add_font_path("a directory path", %opts)

=over

This method adds one search path to the list of paths to search. In the
C<get_font()> method, each defined search path will be prepended to the C<file> 
entry (except for core fonts) in turn, until the font file is found. However, 
if the C<file> entry starts with / or ./ or ../, it will be used alone.
A C<file> entry starting with .../ is a special case, which is turned into ../
before the search path is prepended. This permits you to give a search path
that you expect to move up one or more directories.

The font path search list always includes the current directory (.), and is
initialized in C<Builder.pm> as C<@font_path>. For the
Windows operating system, C</Windows/Fonts> usually contains a number of TTF
fonts that come standard with Windows, so it is added by default. Anything
else, including all Linux (and other non-Windows operating systems), will have
to be added depending on your particular system. Some common places are:

Windows (B<NOTE:> use / and not \\ in Windows paths!). Linux systems may or
may not handle spaces in directory names gracefully!

    /Windows/Fonts
    /WinNT/Fonts
    /Program Files/MikTex 2.9/fonts/type1/urw/bookman (URW Bookman for MikTex)
    /Program Files (x86)/MikTex 2.9/fonts/type1/urw/bookman (older versions)
    /Program Files/Adobe/Acrobat DC/Resource/CIDFont (Adobe Reader fonts)
    GhostScript may have its own directories

Note that directory names with spaces (e.g., C</Program Files>) may not play
nice with some Linux systems, so they are not included by default.

Linux, etc.

    /usr/share/fonts (common base)
    /usr/local/share/fonts (common base)
    /usr/share/fonts/dejavu-sans-fonts  (Deja Vu Sans TTF specifically)
    /usr/share/fonts/truetype/ttf-dejavu
    /usr/share/fonts/truetype/dejavu
    /usr/lib/defoma/gs.d/devs/fonts   (GhostScript?)
    /usr/share/fonts/type1/gsfonts    (GhostScript PS)
    /usr/share/X11/fonts/urw-fonts    (URW PS)

Third-party application installations, such as Adobe's Acrobat Reader, may be
a source of installed fonts, too.

A return code of 0 means the path was successfully added, while 1 means there
was a problem encountered (and a message was issued).

No options are currently defined.

=back

=cut

sub add_font_path {
    my ($self, $newpath, %opts) = @_;

    my $rc = 0;  # OK so far!

    # TBD: consider validating that this $newpath exists?
    #      will not be using until actually attempt to open the file!
    push @{ $self->{' font-paths'} }, $newpath;

    return $rc;
} # end of add_font_path()

=head2 add_font

    $rc = add_font(%info)

=over

Add a new font entry (by face and variants) to the Font Manager's list of
known fonts.

C<%info> items to be defined:

=over

=item face => 'face name'

This should be a unique string to identify just one entry in the Font
Manager fonts table. I.e., you should not have two "Times" (one a core font
and the other a TTF font). Give them different names (face names are case 
I<sensitive>, so 'Times' is different from 'times'). The C<face> name is
used to retrieve the desired font.

The default core font face names
(I<Times, Helvetica, Courier, Symbol, ZapfDingbats, 
Georgia, Verdana, Trebuchet, Wingdings, Webdings>),
as well as class names
I<current, default, serif, sans-serif, constant, script, symbol, -external->
are B<reserved> and should not be used for user-added faces.
They I<may> be redefined at your discretion.
The MS Windows core extension I<BankGothic> is currently B<not> added to the
core fonts automatically. I<-external-> may or may not be defined, and should
not be used by user code.

B<Note> that use of Windows extension "core" fonts (Georgia, Verdana, Trebuchet,
Wingdings, and Webdings) expect those fonts to be installed on platforms if
they are used, and a (hopefully) close substitution will be attempted if not.
These fonts are normally available on Windows platforms, but may not be 
available on non-Windows platforms. Use (create PDFs specifying them) at your 
own risk.

=item type => 'type string'

This tells which Builder font routine to use to load the font. The allowed
entries are:

=over

=item B<core>

This is a core font, and is loaded via the C<CoreFont()> routine. Note that
the core fonts are automatically preloaded (including additional ones on
Windows systems), so you should not need to explicitly load any core fonts
(at least, the 14 basic ones). All PDF installation are supposed to include
these 14 basic core fonts, but the precise actual file type may vary among
installations, and substitutions may be made (so long as the metrics match).
Currently, core fonts are limited to single byte encodings.

On Windows systems, there are an additional 14 core fonts which are normally
loaded. These are Georgia, Verdana, Trebuchet, Wingdings, and Webdings faces.
Use caution if making use of these additional core fonts, as non-Windows
systems may not include them without explicit manual installation of these
fonts. These fonts may be safe to use if you know that all your PDF readers
will be running on Windows systems. Finally, PDF::Builder includes metrics
for Bank Gothic, but this is not automatically loaded into the core set, as
it is not clear whether all Windows systems actually include this font.

=item B<ttf>

This is a TrueType (.ttf) or OpenType (.otf) font, loaded with C<ttfont()>. 
Currently this is the only
type which can be used with multibyte (e.g., I<utf8>) encodings, as well as 
with single byte encodings such as I<Latin-1>. It is also the only font type
that can be used with HarfBuzz::Shaper. Many systems include a number of TTF
fonts, but unlike core fonts, none are automatically loaded by the PDF::Builder
Font Manager, and must be explicitly loaded via C<add_font()>.

=item B<type1>

This is a PostScript (Type1) font, loaded with C<psfont()>, which used to be 
quite commonly used, but is
fairly rarely used today, having mostly been supplanted by the more capable
TTF format. Some systems may include some Type1 fonts, but Windows, 
for example, does not normally come with any. No Type1 fonts are automatically
loaded by the PDF::Builder Font Manager, and must be explicitly loaded via
C<add_font()>.

It is assumed that the font metrics file (.afm or .pfm) has the same base file
name as the glyph file (.pfa or .pfb), is found in the same directory, I<and>
either can work with either.
If you have need for a different directory, a different base name, or a 
specific metrics file to go with a specific glyph file, let us know, so we can 
add such functionality. Otherwise, you will need to directly use the C<psfont()>
method in order to specify such different paths.

=item B<cjk>

This is an East Asian (Chinese-Japanese-Korean) type font, loaded with the
C<cjkfont()> method. Note that CJK fonts
have never been well supported by PDF::Builder, and depend on some fairly old
(obsolete) features and external files (.cmap and .data). We suggest that,
rather than going directly to CJK files, you first try directly using the
(usually) TTF files, in the TTF format. Few systems come with CJK fonts
installed. No CJK fonts are automatically loaded by the PDF::Builder Font 
Manager, and must be explicitly loaded via C<add_font()>.

=item B<bdf>

This is an Adobe Bitmap Distribution Format font, loaded with the C<bdfont()>
method, a very old bitmapped format 
dating back to the early days of the X11 system. Unlike the filled smooth 
outlines used in most modern fonts, BDF's are a coarse grid of on/off pixels.
Please be kind to your readers and use this format sparingly, such as only for
chapter titles or headings! Few systems come with BDF fonts installed any more. 
No BDF fonts are automatically loaded by the PDF::Builder Font Manager, and 
must be explicitly loaded via C<add_font()>.

=back

=item settings => { 'encode' => string, ... }

This is a collection of any other settings, flags, etc. accepted by this
particular font type. See the POD for C<corefont>, C<ttfont>, etc. (per
I<type> for the allowable entries. An important one will be the encoding,
which you will need to specify, if you use any characters beyond basic ASCII.

Currently, all fonts may use any single byte encoding you
desire (the default is I<CP-1252>). Only TTF type fonts (which includes OTF and 
CJK fonts) may currently specify a multibyte encoding such as I<utf8>. Needless
to say, the text data that you pass to text routines must conform to the given
encoding. You are I<not> forced to use the same encoding for all defined fonts,
but if you wish to mix-and-match encodings, it is up to you to define your
text that uses the encoding specified for the particular font used!

Note in particular when you use I<entities> that (if numeric) they are given 
in the Unicode number. When out of the single byte range (x00-xFF), results are 
unpredictable if you give an entity that does not fall within the encoding's
range! Also check results for Unicode points within the range x80-xFF if you
are using I<utf8> encoding.

=item style => 'styling'

This specifies the styling of the font: B<serif>, B<sans-serif>, B<constant> 
(constant width, or fixed pitch), B<script> (cursive), or B<symbol> 
(non-alphabetic). It has no effect on how a font is loaded or used, but may 
be useful to you for defining a generic style font.

=item width => 'relative widths'

Currently, B<proportional> (variable width) and B<constant> (constant width) 
may be specified. It has no effect on how a font is loaded or used, but may be 
useful to you for defining a generic style font.

=item file => {anonymous hash of source files}

This tells the Font Manager where to find the actual font file. 

Various font paths are tried from the C<font_path> list to find an actual file. 
TrueType and OpenType fonts
(C<'type'=E<gt>'ttf'>) may instead be given as a C<Font::TTF::Font> I<object>,
such as one extracted from a TTC (TrueType Collection) file, one per "file"
('roman', 'italic', etc.). In a dump of the FontManager tables 
(C<dump_font_tables()>), these will show up as a file "name" of 
C<Font::TTF::Font=HASH(....)>. B<Other ways of specifying TTC fonts are 
expected to be added in the future.>

For core fonts, it is the standard I<name>, rather than a I<file> (and 
remember, they are preloaded).
For all other types, it lists from one to four of the following variants:

=over

=item B<roman> => 'path to Roman'

This specifies the "Roman" or "regular" posture variant of the font. Almost all 
available fonts include a Roman (normal, upright posture) variant at normal 
(medium) weight.

=item B<italic> => 'path to Italic'

This specifies the "Italic", "slanted", or "oblique" posture variant of the 
font. Most available fonts include an italic variant at normal (medium) weight.

=item B<bold> => 'path to Bold'

This specifies the "Bold" or "heavy" variant of the font. Most available fonts 
include a bold (heavy weight) variant with normal (Roman) posture.

=item B<bold-italic> => 'path to BoldItalic'

This specifies the "Bold" I<and> "Italic" variant of the font. Many
available fonts include a bold (heavy weight) variant with italic posture.

=item B<symbol> => 'path to Symbol'

For symbol type fonts (non-alphabetic), rather than risk confusion by reusing
the "roman" term, the "symbol" term is used to specify what is usually the
only variant of a symbol font. It is possible that there are bold, italic, and
even bold-italic variants of a symbol file, but if so, they are not
currently supported.

=back

You I<can> give the entire path of the font's source file, in an absolute
path, if you wish. However, it's usually less typing to use C<add_font_path()>
to specify a list of font directories to search, and only give the name (and
perhaps a subdirectory) for the path here in C<add_font()>.

=back

=back

=cut

sub add_font {
    my ($self, %info) = @_;

    my $rc = 0;  # so far, so good!

    # basically, all %info gets pushed onto self->font_list as the next
    # element. then an entry hash element is added for each variant,
    # initialized to undef.

    my $ele = \%info;  # don't want to modify original list
    $ele->{'entry'} = undef; # store the discovered/enabled fonts here

    # check that all fields are defined, and file includes at least one
    # subfield
    if (!defined $info{'face'}) {
	carp "add_font missing 'face' entry";
	$rc = 1;
    }
    # is this face name already in use?
    foreach (@{ $self->{' font-list'} }) {
	if ($_->{'face'} eq $info{'face'}) {
	    carp "add_font finds face name '$info{'face'} already in use!";
	    $rc = 1;
	    last;
	}
    }
    # is this face name reserved?
#   foreach (qw/current default serif sans-serif constant script symbol -external-/) {
#       if ($_ eq $info{'face'}) {
#           carp "add_font finds face name '$info{'face'} is reserved!";
#           $rc = 1;
#           last;
#       }
#   }

    if (!defined $info{'type'}) {
	carp "add_font missing 'type' entry";
	$rc = 1;
    }
    # TBD what to do about synthetic fonts?
    if ($info{'type'} ne 'core' && 
	$info{'type'} ne 'ttf' &&
        $info{'type'} ne 'type1' && 
	$info{'type'} ne 'cjk' &&
        $info{'type'} ne 'bdf' &&
        !($info{'type'} eq '?' && $info{'face'} eq '-external-')) {
	carp "add_font unknown 'type' entry $info{'type'}";
	$rc = 1;
    }

   # encode and other settings should be optional
   #if (!defined $info{'settings'}) {
   #    carp "add_font missing 'settings' entry";
   #    $rc = 1;
   #}
    # TBD: utf8 etc only for ttf, check single byte encoding name is valid?

    if (!defined $info{'style'}) {
	carp "add_font missing 'style' entry";
	$rc = 1;
    }
    if ($info{'style'} ne 'serif' && 
	$info{'style'} ne 'sans-serif' &&
        $info{'style'} ne 'constant' && 
	$info{'style'} ne 'script' &&
        $info{'style'} ne 'symbol' &&
        !($info{'style'} eq '?' && $info{'face'} eq '-external-')) {
	carp "add_font unknown 'style' entry $info{'style'}";
	$rc = 1;
    }

    if (!defined $info{'width'}) {
	carp "add_font missing 'width' entry";
	$rc = 1;
    }
    if ($info{'width'} ne 'proportional' && 
	$info{'width'} ne 'constant' &&
        !($info{'width'} eq '?' && $info{'face'} eq '-external-')) {
	carp "add_font unknown 'width' entry $info{'width'}";
	$rc = 1;
    }

    if (!defined $info{'file'}) {
	carp "add_font missing 'file' entry";
	$rc = 1;
    }
    # one or more of roman, italic, bold, bold-italic (non-symbol fonts)
    # symbol faces ('style') use symbol, italic, bold, bold-italic
    # create 'entry' of same structure, to hold undef and then $font
    # will ignore any subfields not matching above list
    my $found = 0; # did we find any of the required four?
    my @style_list = qw/italic bold bold-italic/;
    if (defined $info{'style'} && $info{'style'} ne 'symbol') {
	unshift @style_list, 'roman';
    }
    # symbol valid only for style=symbol, where it is usually the only one
    if (defined $info{'style'} && $info{'style'} eq 'symbol') {
	unshift @style_list, 'symbol';
    }
    foreach my $file (@style_list) {
        if (defined $info{'file'}->{$file}) {
	    $ele->{'entry'}->{$file} = undef;
            $found = 1;
        }
    }

    if (!$found) {
        carp "add_font 'file' entry does not have at least one of roman, italic, bold, bold-italic, or symbol";
        $rc = 1;
    }
    return $rc if $rc;

    # $ele should contain an entry to be inserted into the font list as an
    # array element
    push @{ $self->{' font-list'} }, $ele;
    return 0;

} # end of add_font()

# load up the standard core fonts
sub _initialize_core {
    my $self = shift;

    my $single = 'cp-1252';  # let's try this one for single byte encodings
    # the universal core fonts. note that some systems may have similar
    # fonts substituted (but the metrics should be the same)
    # index = 0
    $self->add_font('face' => 'Times', 'type' => 'core', 
	        'settings' => { 'encode' => $single },
	        'style' => 'serif', 'width' => 'proportional',
                'file' => {'roman' => 'Times-Roman', 
                           'italic' => 'Times-Italic',
                           'bold' => 'Times-Bold', 
                           'bold-italic' => 'Times-BoldItalic'} );
    # index = 1
    $self->add_font('face' => 'Helvetica', 'type' => 'core', 
	        'settings' => { 'encode' => $single },
	        'style' => 'sans-serif', 'width' => 'proportional',
                'file' => {'roman' => 'Helvetica', 
                           'italic' => 'Helvetica-Oblique',
                           'bold' => 'Helvetica-Bold', 
                           'bold-italic' => 'Helvetica-BoldOblique'} );
    # index = 2
    $self->add_font('face' => 'Courier', 'type' => 'core', 
	        'settings' => { 'encode' => $single },
	        'style' => 'serif', 'width' => 'constant',
                'file' => {'roman' => 'Courier', 
                           'italic' => 'Courier-Oblique',
                           'bold' => 'Courier-Bold', 
                           'bold-italic' => 'Courier-BoldOblique'} );
    # index = 3
    $self->add_font('face' => 'Symbol', 'type' => 'core', 
	        'settings' => { 'encode' => $single },
	        'style' => 'symbol', 'width' => 'proportional',
                'file' => {'symbol' => 'Symbol'} );
    # index = 4
    $self->add_font('face' => 'ZapfDingbats', 'type' => 'core', 
	        'settings' => { 'encode' => $single },
	        'style' => 'symbol', 'width' => 'proportional',
                'file' => {'symbol' => 'ZapfDingbats'} );

# apparently available on Windows systems
   #if ($^O eq 'MSWin32') { # always allow, even on non-Windows platforms

    # index = 5
    $self->add_font('face' => 'Georgia', 'type' => 'core', 
                'settings' => { 'encode' => $single }, 
		'style' => 'serif', 'width' => 'proportional',
                'file' => {'roman' => 'Georgia',
                           'italic' => 'GeorgiaItalic',
                           'bold' => 'GeorgiaBold',
                           'bold-italic' => 'GeorgiaBoldItalic'} );
    # index = 6
    $self->add_font('face' => 'Verdana', 'type' => 'core', 
                'settings' => { 'encode' => $single }, 
		'style' => 'sans-serif', 'width' => 'proportional',
                'file' => {'roman' => 'Verdana',
                           'italic' => 'VerdanaItalic',
                           'bold' => 'VerdanaBold',
                           'bold-italic' => 'VerdanaBoldItalic'} );
    # index = 7
    $self->add_font('face' => 'Trebuchet', 'type' => 'core', 
                'settings' => { 'encode' => $single }, 
		'style' => 'sans-serif', 'width' => 'proportional',
                'file' => {'roman' => 'Trebuchet',
                           'italic' => 'TrebuchetItalic',
                           'bold' => 'TrebuchetBold',
                           'bold-italic' => 'TrebuchetBoldItalic'} );
    # index = 8
    $self->add_font('face' => 'Wingdings', 'type' => 'core', 
                'settings' => { 'encode' => $single }, 
		'style' => 'symbol', 'width' => 'proportional',
                'file' => {'symbol' => 'Wingdings'} );
    # index = 9
    $self->add_font('face' => 'Webdings', 'type' => 'core', 
                'settings' => { 'encode' => $single }, 
		'style' => 'symbol', 'width' => 'proportional',
                'file' => {'symbol' => 'Webdings'} );

    # there is also a Bank Gothic on my Windows system, but I'm not sure if I
    # loaded that one from some place, or it came with Windows. In either case,
    # I think it should be OK to provide the metrics (but not the font itself).
    #
    # Bank Gothic is confusing... it only has regular and italic, and it 
    # doesn't look anything like the examples shown on various font websites.
    # I think some other sans-serif font is being substituted for it.
#   $self->add_font('face' => 'BankGothic', 'type' => 'core', 
#               'settings' => { 'encode' => $single }, 
#	        'style' => 'sans-serif', 'width' => 'proportional',
#               'file' => {'roman' => 'BankGothic',
#                          'italic' => 'BankGothicItalic',
#                         #'bold' => 'BankGothicBold',
#                         #'bold-italic' => 'BankGothicBoldItalic'} 
#                         } );

   #} # Windows additional core fonts

    return;
} # end of _initialize_core()

## for some reason, this is uncallable from Content::Text
## try to fix it... it belongs here and not in Text.pm
#=head2 get_fv_extents
#
#    ($ascender, $descender, $d_leading) = $pdf->get_fv_extents($font_size, $leading)
#
#=over
#
#Get the I<current> font's vertical extents (points above and below the
#baseline), scaled by font_size, and leading is added to the descender amount.
#C<$descender> is the deepest glyph descender; C<$d_leading> is that plus the
#leading.
#
#Note that the extents are the maximum values defined for this particular 
#I<font>, and not what the particular text's ascenders and descenders are 
#actually using.
#
#=back
#
#=cut
#
#sub get_fv_extents {
#    my ($self, $font_size, $leading) = @_;
#
#    $leading = 1.0 if $leading <= 0; # actually, a bad value
#    $leading++ if $leading < 1.0;    # might have been given as fractional
#
#    my $current = $self->{' current-font'}->{'face'};  # font name
#    my $font = $self->get_font('face' => $current);    # font object realized
#    # now it's loaded, if it wasn't already
#    my $ascender  = $font->ascender()/1000*$font_size; # positive
#    my $descender = $font->ascender()/1000*$font_size; # negative
#
#    # ascender is positive, descender is negative (above/below baseline)
#    return ($ascender, $descender, $descender-($leading-1.0)*$font_size);
#} # end of get_fv_extents()

=head2 get_font

    @current = $pdf->get_font()  # Get

    $font = $pdf->get_font(%info)  # Set

=over

If no parameters are given (C<@current = $pdf-E<gt>get_font()>), a list
(array) is returned giving the I<current> font setting: I<face> name, I<italic> 
flag 0/1, I<bold> flag 0/1, I<type> ('core', 'ttf', etc.), a hash reference of
I<settings>, such as the I<encoding> ('utf8',
etc.), I<style> value, I<width> value, and an array reference (list) of 
variants (roman, bold, etc.). If no font has yet been explicitly set, the 
current font will be the default font.

If at least one parameter is given (C<%info> hash), the font manager will
attempt to discover the appropriate font (from within the font list), load it
if not already done, and return the C<$font> value. If I<undef> is returned,
there was an error.

%info fields:

=over

=item face => face name string

This is the font family (face) name loaded up with the core fonts (e.g., Times),
or by C<$pdf-E<gt>add_font()> calls. In addition, the I<current> font face or
the I<default> face can be 
requested, the I<serif> generic serif face, the I<sans-serif> generic sans-serif
face, the I<constant> generic constant width face, or the I<script> generic
script (cursive) face (B<if defined>) may be requested.

If you give the C<face> entry, the other settings (C<italic>, C<bold>, etc.)
are I<not> reset, unless it is impossible to use the existing setting.
If you do I<not> give the C<face> entry, the I<current> entry will be updated
(bold, italic switched on/off, etc.). You may always explicitly give 
I<current> to make it clear in your code that you I<don't> want to change 
the face.

=item italic => flag

This requests use of the italic (slanted, oblique) variant of the font, in
either the current face (C<face> not given in this call) or the new face. The
value is 0 or 1 for "off" (Roman/upright posture) and "on" (italic posture).

=item bold => flag

This requests use of the bold (heavy weight) variant of the font, in
either the current face (C<face> not given in this call) or the new face. The
value is 0 or 1 for "off" (medium weight) and "on" (heavy weight).

=back

=back

=cut

sub get_font {
    my ($self, %info) = @_;

    my $font = undef;  # means NOT GOOD
    my $index;
    my @list;

    if (!keys %info) {
	# Get request for whatever the "current" (last selected) entry is
	push @list, $self->{' current-font'}->{'face'};                # [0] s
	push @list, $self->{' current-font'}->{'italic'};              # [1] b
	push @list, $self->{' current-font'}->{'bold'};                # [2] b
	$index = $self->{' current-font'}->{'index'};

	push @list, $self->{' font-list'}->[$index]->{'type'};         # [3] s
	# note that settings will be a hashref, not a string
	if (defined $self->{' font-list'}->[$index]->{'settings'}) {
	    push @list, $self->{' font-list'}->[$index]->{'settings'}; # [4] hr
	} else {
	    push @list, {};
	}
	push @list, $self->{' font-list'}->[$index]->{'style'};        # [5] s
	push @list, $self->{' font-list'}->[$index]->{'width'};        # [6] s

	# what variants are defined? just the key names
	my @variants = keys %{ $self->{' font-list'}->[$index]->{'entry'} };
	push @list, \@variants;                                        # [7] ar

	return @list;
    }

    # if we're here, the user is requesting a font, given some combination of
    # face, type, italic, and bold flags. keys %info > 0.
    my $face_name      = $self->{' current-font'}->{'face'};
    my $current_italic = $self->{' current-font'}->{'italic'};
    my $current_bold   = $self->{' current-font'}->{'bold'};
    my $current_index  = $self->{' current-font'}->{'index'};
    $index = -1;
    if (defined $info{'face'}) {
	# face = current, default, serif, sans-serif, constant, script, symbol,
	#   or actual path/name
	if      ($info{'face'} eq 'current') {
	    # not really a change, but to make sure some font is loaded!
            $face_name = $self->{' current-font'}->{'face'};
            $index     = $self->{' current-font'}->{'index'};
        } elsif ($info{'face'} eq 'default') {
	    # change selected font to the default face
            $face_name = $self->{' default-font'}->{'face'};
            $index     = $self->{' default-font'}->{'index'};
	} elsif ($info{'face'} eq 'serif') {
	    # change selected font to the generic (default) serif face
            $face_name = $self->{' default-serif'}->{'face'};
            $index     = $self->{' default-serif'}->{'index'};
	} elsif ($info{'face'} eq 'sans-serif') {
	    # change selected font to the generic (default) sans serif face
            $face_name = $self->{' default-sansserif'}->{'face'};
            $index     = $self->{' default-sansserif'}->{'index'};
	} elsif ($info{'face'} eq 'constant') {
	    # change selected font to the generic (default) constant width face
            $face_name = $self->{' default-constant'}->{'face'};
            $index     = $self->{' default-constant'}->{'index'};
	} elsif ($info{'face'} eq 'script') {
	    # change selected font to the generic (default) script face
	    # this is the only 'default' not initialized by Font Manager
	    if (defined $self->{' default-script'}->{'face'}) {
                $face_name = $self->{' default-script'}->{'face'};
                $index = $self->{' default-script'}->{'index'};
	    } else {
		carp "get_font has no default set for 'script'. ignored.";
		$index = $current_index; # face_name leave at current
	    }
	} elsif ($info{'face'} eq 'symbol') {
	    # change selected font to the generic (default) symbol face
            $face_name = $self->{' default-symbol'}->{'face'};
            $index     = $self->{' default-symbol'}->{'index'};
	} else {
	    # info{face} must be a named face. search list of defined faces
	    $index = $self->_face2index($info{'face'});
	    if ($index >= 0) {
		$face_name = $info{'face'};
	    } else {
		carp "get_font can't find requested face '$info{'face'}'. ignored.";
		$index = $current_index; # leave face_name unchanged
	    }
	}
	# if 'face' given, $face_name and $index are set
	
    } else {
	$index = $current_index;
	# face not defined, so use current face, possibly modified by
	# italic or bold. $face_name is left at current, as is index
    }

    # reset current font entry
    $self->{' current-font'}->{'face'} = $face_name;
    # $index is new face's index
    $self->{' current-font'}->{'index'} = $index;
    # italic flag given? info{italic}
    if (defined $info{'italic'}) {
	$current_italic = $info{'italic'};
        $self->{' current-font'}->{'italic'} = $current_italic;
    }
    # bold flag given? info{bold}
    if (defined $info{'bold'}) {
	$current_bold = $info{'bold'};
        $self->{' current-font'}->{'bold'} = $current_bold;
    }

    my $type = $self->{' font-list'}->[$index]->{'type'};
    my $style = $self->{' font-list'}->[$index]->{'style'};
    my $which;
    if ($style eq 'symbol') {
	$which = 'symbol'; # currently no bold or italic for symbols
    } else {
	if ($current_italic) {
	    if ($current_bold) {
		$which = 'bold-italic';
	    } else {
		$which = 'italic';
	    }
	} else {
	    if ($current_bold) {
		$which = 'bold';
	    } else {
		$which = 'roman';
	    }
	}
    }

    # assuming proper face and/or italic and/or bold, current-font updated
    if (!defined $self->{' font-list'}->[$index]->{'file'}->{$which}) {
	# requested a variant (bold, etc.) not available!
	# just pick first one available (there is at least one)
 	my @keys = keys %{ $self->{' font-list'}->[$index]->{'file'} };
 	my $key = shift @keys;
	carp "Requested unavailable variant for face $face_name. Use $key in its place.";
        $which = $key;
    }

    $font = $self->{' font-list'}->[$index]->{'entry'}->{$which};
    # already loaded this one?
    if (defined $font) { return $font; }

    # need to first load the new font
    my $file = $self->{' font-list'}->[$index]->{'file'}->{$which};
    if (!defined $file) { return $file; } # no file entry for these variants

    my $settings = $self->{' font-list'}->[$index]->{'settings'};

    # loop through font-paths list until find a file, or failure
    if      ($type eq 'core') {
	# no paths to search for core fonts
	$font = $self->{' pdf'}->corefont($file, %$settings);

    } elsif ($type eq 'ttf') {
	if (ref($file) eq 'Font::TTF::Font') {
	    # it's a Font::TTF::Font object, not a real file
	    # may be used as input to ttfont() to get a real font out of it
	    $font = $self->{' pdf'}->ttfont($file, %$settings);
	} else {
	    # it's a regular real file
	    foreach my $filepath ($self->_filepath($file)) {
	        if (!(-f $filepath && -r $filepath)) { next; }
	        $font = $self->{' pdf'}->ttfont($filepath, %$settings);
	        if (defined $font) { last; }
            }
        }

    } elsif ($type eq 'type1') {
	# filepath is glyph file itself (.pfa or .pfb). 
	# metrics file is specified as afmfile or pfmfile, subject to the
	# same search paths
	my @glyphs = $self->_filepath($file);
	my (@metrics, $met_type, $metricf, $filepath);
	if (defined $self->{' font-list'}->[$index]->{'settings'}->{'afmfile'}) {
	    @metrics = $self->_filepath($self->{' font-list'}->[$index]->{'settings'}->{'afmfile'});
	    $met_type = 'afmfile';
	} elsif (defined $self->{' font-list'}->[$index]->{'settings'}->{'pfmfile'}) {
	    @metrics = $self->_filepath($self->{' font-list'}->[$index]->{'settings'}->{'pfmfile'});
	    $met_type = 'pfmfile';
	} else {
	    carp "get_font: metrics file (afmfile or pfmfile) not defined for Type1 font!";
	    $met_type = '';
	}
	for (my $i = 0; $i < @glyphs; $i++) {
	    $filepath = $glyphs[$i];
	    if (!(-f $filepath && -r $filepath)) { next; }
	    $metricf = $metrics[$i];
	    if (!(-f $metricf && -r $metricf)) { next; }
	    if ($met_type ne '') {
		# note that settings will still have an afmfile or pfmfile,
		# but met_type should override it (with the full path version)
	        $font = $self->{' pdf'}->psfont($filepath, %$settings, $met_type => $metricf);
	        if (defined $font) { last; }
	    }
	}

    } elsif ($type eq 'cjk') {
	foreach my $filepath ($self->_filepath($file)) {
	    if (!(-f $filepath && -r $filepath)) { next; }
	    $font = $self->{' pdf'}->cjkfont($filepath, %$settings);
	    if (defined $font) { last; }
	}

    } elsif ($type eq 'bdf') {
	foreach my $filepath ($self->_filepath($file)) {
	    if (!(-f $filepath && -r $filepath)) { next; }
	    $font = $self->{' pdf'}->bdfont($filepath, %$settings);
	    if (defined $font) { last; }
	}

    } else {
	# TBD: synfont variants?
    }

    if (defined $font) { 
	# cache it so we don't have to create another copy
	$self->{' font-list'}->[$index]->{'entry'}->{$which} = $font;
    } else {
	carp "get_font: unable to find or load $type font $file.";
    }

    return $font;  # undef if unable to find or successfully load
} # end of get_font()

# input: face name
# output: index of array element with matching face, -1 if no match
sub _face2index {
    my ($self, $face) = @_;

    for (my $index = 0; $index < scalar(@{$self->{' font-list'}}); $index++) {
        if ($self->{' font-list'}->[$index]->{'face'} eq $face) { return $index; }
    }

    return -1; # failed to match
}

# input: file name (may include full or partial path)
# output: list of file name appended to each font-paths entry
sub _filepath {
    my ($self, $file) = @_;

    # if absolute path or dotted relative path, use as-is
    if (substr($file, 0, 1) eq '/') { return $file; }
    if (substr($file, 0, 2) eq './') { return $file; }
    if (substr($file, 0, 3) eq '../') { return $file; }
    if ($file =~ m#^[a-z]:/#i) { return $file; } # Windows drive letter
    # .../ actually go up one from font-path (trim to ../, prepend path/)
    if (substr($file, 0, 4) eq '.../') { $file = substr($file, 1); }

    my @out_list = @{ $self->{' font-paths'} };
    for (my $i = 0; $i < @out_list; $i++) {
	# we know that file does NOT start with a /, so append / to
	# font-path element if missing, before appending file
	if (substr($out_list[$i], -1, 1) eq '/') {
	    $out_list[$i] .= $file;
	} else {
	    $out_list[$i] .= "/$file";
	}
    }

    return @out_list;
}

=head2 get_external_font

    $rc = $pdf->get_external_font($text)

=over

If the user has already defined a font outside of C<FontManager>, in the 
C<$text> text context, this call permits it to be retrieved as the 
I<current font>, named B<-external->. If no font has been defined already,
nothing is changed and the return code is 1.

If C<$text-E<gt>{' font'}> has been defined, that font is stored in the
internal cache (as an "already read" font) in a new "-external-" font, and
it is made the current font. The return code is 0.

If there is no existing preloaded font, 
nothing is done and the return code is 1.

This is a way for those using "markdown" formatting to define the font used,
as an alternative to using C<'style'=E<gt>'body { font-family: ... '}> to
define the body font.

=back

=cut

sub get_external_font {
    my ($self, $text) = @_;

    if (!defined $text->{' font'}) {
	# there is no existing font defined
	return 1;
    }
    my $font = $text->{' font'};
    # does -external- already exist? search list of defined faces
    my $index = $self->_face2index('-external-');
    # $index == -1 if not found

    if ($index == -1) {
	# not yet added
        $self->add_font(
            'face' => '-external-',   # special reserved name
	    'type' => '?',            # we know nothing about the actual font!
	    'style' => '?',
	    'width' => '?',
            # will never be looking at for a filepath
	    'file' => { 'roman'       => '?',
	                'italic'      => '?',
	                'bold'        => '?',
	                'bold-italic' => '?' }
        );
        $index = $self->_face2index('-external-');
    }

    # -external- exists at $index, update $font entries
    # unlike regular fonts, all variants point to the same font entry
    foreach my $key (qw/roman italic bold bold-italic/) {
        $self->{' font-list'}->[$index]->{'entry'}->{$key} = $font;
    }
    # set current font to -external-. italic and bold irrelevant
    $self->{' current-font'} = {'face' => '-external-', 'index' => $index,
                                'italic' => 0, 'bold' => 0};

    return 0;
} # end of get_external_font()

=head2 dump_font_tables

    $pdf->dump_font_tables()

=over

Print (to STDOUT) all the Font Manager font information on hand.

=back

=cut

# a debug routine to dump everything about defined fonts
sub dump_font_tables {
    my $self = shift;

    # dump font table
    print "-------------------- fonts\n";
    for (my $i = 0; $i < @{ $self->{' font-list'} }; $i++) {
	print "  font table entry ".($i+1).":\n";

	print "    face = '".($self->{' font-list'}->[$i]->{'face'})."'\n";
       #print "    italic flag = ".($self->{' font-list'}->[$i]->{'italic'})."\n";
       #print "    bold flag = ".($self->{' font-list'}->[$i]->{'bold'})."\n";
	print "    type = '".($self->{' font-list'}->[$i]->{'type'})."'\n";
	print "    settings = {\n";
	my @keys = keys %{ $self->{' font-list'}->[$i]->{'settings'} };
	foreach my $key (@keys) {
	    print "      $key => '".($self->{' font-list'}->[$i]->{'settings'}->{$key})."'\n";
	}
	print "    }\n";
	print "    style = '".($self->{' font-list'}->[$i]->{'style'})."'\n";
	print "    width = '".($self->{' font-list'}->[$i]->{'width'})."'\n";

	# what variants are defined? 
	print "    files = {\n";
	@keys = keys %{ $self->{' font-list'}->[$i]->{'file'} };
	foreach my $key (@keys) {
	    print "      $key => '".($self->{' font-list'}->[$i]->{'file'}->{$key})."',";
	    if (defined $self->{' font-list'}->[$i]->{'entry'}->{$key}) {
		print " [font HAS been loaded]\n";
	    } else {
		print " [font has NOT been loaded]\n";
	    }
	}
	print "    }\n";
    }

    # dump font path list
    print "-------------------- font search paths\n";
    for (my $i = 0; $i < @{ $self->{' font-paths'} }; $i++) {
	print "  path ".($i+1).": ".($self->{' font-paths'}->[$i])."\n";
    }

    # dump current font
    print "-------------------- current font\n";
    print "  face = ".($self->{' current-font'}->{'face'})."\n";
    print "  index = ".($self->{' current-font'}->{'index'})."\n";
    print "  italic flag = ".($self->{' current-font'}->{'italic'})."\n";
    print "  bold flag = ".($self->{' current-font'}->{'bold'})."\n";

    # dump current defaults
    print "-------------------- current defaults\n";
    print "  default font: face = '".($self->{' default-font'}->{'face'})."',";
    print " index = ".($self->{' default-font'}->{'index'})."\n";
    print "  default serif font: face = '".($self->{' default-serif'}->{'face'})."',";
    print " index = ".($self->{' default-serif'}->{'index'})."\n";
    print "  default sans serif font: face = '".($self->{' default-sansserif'}->{'face'})."',";
    print " index = ".($self->{' default-sansserif'}->{'index'})."\n";
    print "  default constant width font: face = '".($self->{' default-constant'}->{'face'})."',";
    print " index = ".($self->{' default-constant'}->{'index'})."\n";
    print "  default symbol font: face = '".($self->{' default-symbol'}->{'face'})."',";
    print " index = ".($self->{' default-symbol'}->{'index'})."\n";
    # no script font loaded by default
    if (defined $self->{' default-script'}->{'face'}) {
        print "  default script font: face = '".($self->{' default-script'}->{'face'})."',";
        print " index = ".($self->{' default-script'}->{'index'})."\n";
    } else {
	print "  no default script font defined\n";
    }

    # lots of output once 'entry' points start getting filled!
   #use Data::Dumper;
   #print Dumper($self->{' font-list'});

    return;
} # end of dump_font_tables()

1;
