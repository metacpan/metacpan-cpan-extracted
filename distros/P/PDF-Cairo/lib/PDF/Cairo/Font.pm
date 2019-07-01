package PDF::Cairo::Font;

use 5.016;
use strict;
use warnings;
use Carp;
use Cairo;
use Font::FreeType;

our $VERSION = "1.05";
$VERSION = eval $VERSION;

=head1 NAME

PDF::Cairo::Font - wrapper that adds some useful methods to Cairo fonts

=head1 SYNOPSIS

L<Cairo> supports three types of fonts: built-in, L<Font::FreeType>,
and L<Pango>, which all have subtly different behaviors. This module
hides that complexity while also adding compatibility methods for
easily converting scripts from L<PDF::API2::Lite>.

=head1 DESCRIPTION

=cut

our (
	@ISA,
	@EXPORT,
	@EXPORT_OK,
	%EXPORT_TAGS,
	@FONT_PATH,
	%_api2font,
);
BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw();
	@EXPORT_OK = qw();
	%EXPORT_TAGS = (all => \@EXPORT_OK);

	# last-ditch mapping of PDF::API2 core fonts to Cairo toy fonts
	%_api2font = (
		'courier' => [ "mono", "normal", "normal" ],
		'courier-bold' => [ "mono", "normal", "bold" ],
		'courier-boldoblique' => [ "mono", "oblique", "bold" ],
		'courier-oblique' => [ "mono", "oblique", "normal" ],
		'helvetica' => [ "sans", "normal", "normal" ],
		'helvetica-bold' => [ "sans", "normal", "bold" ],
		'helvetica-boldoblique' => [ "sans", "oblique", "bold" ],
		'helvetica-oblique' => [ "sans", "oblique", "normal" ],
		'times-bold' => [ "serif", "normal", "bold" ],
		'times-bolditalic' => [ "serif", "italic", "bold" ],
		'times-italic' => [ "serif", "italic", "normal" ],
		'times-roman' => [ "serif", "normal", "normal" ],
		'georgia' => [ "serif", "normal", "normal" ],
		'georgia-bold' => [ "serif", "normal", "bold" ],
		'georgia-bolditalic' => [ "serif", "italic", "bold" ],
		'georgia-italic' => [ "serif", "italic", "normal" ],
		'verdana' => [ "sans", "normal", "normal" ],
		'verdana-bold' => [ "sans", "normal", "bold" ],
		'verdana-bolditalic' => [ "sans", "italic", "bold" ],
		'verdana-italic' => [ "sans", "italic", "normal" ],
	);
	no warnings qw(once);

	# try to use FontConfig's fc-list to locate all the active
	# font directories on the current system. Note that on a
	# Mac, this will not find all active fonts; see macos2fc.pl
	# for a workaround.
	# If fc-match is in the path, use it and fc-list to get access
	# to all installed fonts
	my $fctmp = `fc-match -V 2>&1` || '';

	if ($fctmp =~ /^fontconfig/) {
		open(my $In, "-|", "fc-list : file");
		my %tmp;
		while (<$In>) {
			s|/[^/]+$||;
			$tmp{$_}++;
		}
		close($In);
		@FONT_PATH = sort keys %tmp;
	}
	push(@FONT_PATH, ".");
}

=head2 Methods

=over 4

=item B<new> $pdf_cairo_ref, $font, [$index|$metrics]

The first argument must be a PDF::Cairo object, in order for Cairo to
locate the surface/context, and to stash a reference to a
Font::FreeType instance.

=cut

sub new {
	my $class = shift;
	my $pcref = shift;
	my @font = split(/,/,shift);
	my $self = {};
	my $type = '';
	if (index($font[0], '.') == -1) {
		@font = find_api2font(@font);
	}
	if ($font[0] =~ /\.([ot]t[cf]|pfb|dfont)$/i) {
		$type = $1;
		$type =~ tr/A-Z/a-z/;
		if (index($font[0], "/") == -1) {
			foreach my $path (@FONT_PATH) {
				if (-f "$path/$font[0]") {
					$font[0] = "$path/$font[0]";
					last;
				}
			}
		}
		if (! -f $font[0]) {
			carp("PDF::Cairo::Font::new: '$font[0]' not found, going generic");
			@font = find_api2font('Times');
		}
	}
	my $collection_index = 0;
	my $metrics_file;
	if (grep($type eq $_, qw(otc ttc dfont)) and defined $font[1]) {
		$collection_index = $font[1];
	}elsif ($type eq "pfb") {
		my @metrics_file;
		if (defined $font[1]) {
			$metrics_file[0] = $font[1];
		}else{
			$metrics_file[0] = $font[0];
			$metrics_file[1] = $font[0];
			$metrics_file[0] =~ s/pfb$/afm/;
			$metrics_file[1] =~ s/pfb$/AFM/;
		}
		if (-f $metrics_file[0]) {
			$metrics_file = $metrics_file[0];
		}elsif ($metrics_file[1] and -f $metrics_file[1]) {
			$metrics_file = $metrics_file[1];
		}else{
			foreach my $path (@FONT_PATH) {
				foreach my $file (@metrics_file) {
					if (-f "$path/$file") {
						$metrics_file = "$path/$file";
						last;
					}
				}
				last if $metrics_file;
			}
		}						
	}
	$self->{type} = "freetype";
	$pcref->{_freetype} = Font::FreeType->new
		unless ref $pcref->{_freetype};
	my $ft_face = $pcref->{_freetype}->face(
		$font[0],
			load_flags => FT_LOAD_NO_HINTING,
			index => $collection_index,
	);
	croak("PDF::Cairo::Font::new($font[0]): bitmap fonts not supported")
		unless $ft_face->is_scalable;
	if ($metrics_file) {
		$ft_face->attach_file($metrics_file);
	}
	$ft_face->set_char_size(1, 1, 72, 72);
	$self->{_source} = {
		type => $type,
		file => $font[0],
		index => $collection_index,
		metrics_file => $metrics_file,
		freetype => $pcref->{_freetype},
		face => $ft_face,
	};
	$self->{face} = Cairo::FtFontFace->create($ft_face);

	# no font file found? put *something* on the page...
	if (! defined $self->{type}) {
		$self->{type} = "cairo";
		$self->{face} = $pcref->{context}->select_font_face("sans");
	}
	_create_font_metrics($self);
	bless($self, $class);
}

# slow but precise method of determining the actual metrics
# of a font, by rendering strings in a recording surface and
# using the resulting ink_extents().
# TODO:
#   bbox - loop over the font; don't go nuts if it's CJK
#   maxwidth - use results from calculating bbox
#   has_cjk (requires testing for presence of glyphs)
#   baseline_cjk - try to render \u{66DC} (UTF-8 0xE69B9C)
#   cjkheight - use the h from calculating baseline_cjk
#
sub _create_font_metrics {
	my ($self) = @_;
	my $metrics = {};
	my @tmp;

	if ($self->{type} eq 'freetype') {
		my $ft_face = $self->{_source}->{face};
		my $upm = $ft_face->units_per_em;
		$metrics->{ascender} = $ft_face->ascender / $upm;
		$metrics->{descender} = $ft_face->descender / $upm;
		$metrics->{height} = $ft_face->height / $upm;
		$metrics->{underline_position} = $ft_face->underline_position / $upm;
		$metrics->{underline_thickness} = $ft_face->underline_thickness / $upm;
		my $tmp = $ft_face->bounding_box;
		$metrics->{bbox} = [
			$tmp->x_min / $upm,
			$tmp->y_min / $upm,
			$tmp->x_max / $upm,
			$tmp->y_max / $upm,
		];
	}elsif ($self->{type} eq 'cairo') {
		# TODO: scaled_font_extents()
	}

	# calculated ascender
	@tmp = _text_bbox($self, "XETIhktfb");
	$metrics->{exact_ascender} = - $tmp[1];

	# calculated xheight
	@tmp = _text_bbox($self, "x");
	$metrics->{exact_xheight} = - $tmp[1];
	# calculated baseline != 0 usually only found in specialty fonts
	$metrics->{is_unusual} = $tmp[1] + $tmp[3] != 0;

	# calculated capheight
	@tmp = _text_bbox($self, "XETI");
	$metrics->{exact_capheight} = - $tmp[1];
	$metrics->{is_unusual} = $tmp[1] + $tmp[3] != 0;

	# calculated descender
	@tmp = _text_bbox($self, "ygj");
	$metrics->{exact_descender} = $tmp[1] + $tmp[3];

	# fall back to my calculated values
	for my $i (qw(ascender descender capheight xheight)) {
		$metrics->{$i} = $metrics->{"exact_$i"}
			unless defined $metrics->{$i};
	}
	if (! defined $metrics->{height}) {
		# wild-assed guess
		$metrics->{height} = $metrics->{ascender} / 0.8;
	}
	# TODO: fake up a bbox
	# TODO: fake up underline_{position,thickness}

	$self->{metrics} = $metrics;
}

# use a recording surface to calculate the exact bounding box
# of a string rendered in the current font.
# returns ULx, ULy, width, height
#
sub _text_bbox {
	my ($self, $text) = @_;
	# render at this size to get plenty of precision
	my $size = 1000;
	my $s = Cairo::RecordingSurface->create("color-alpha", undef);
	my $c = Cairo::Context->create($s);
	if ($self->{type} eq 'freetype') {
		$c->set_font_face($self->{face});
	}elsif ($self->{type} eq 'cairo') {
		$c->select_font_face(@{$self->{_source}->{name}});
	}
	$c->set_source_rgb(0, 0, 0);
	$c->move_to(0, 0);
	$c->set_font_size($size);
	$c->show_text($text);
	my @bbox = map($_ / $size, $s->ink_extents());
	$s->flush;
	$s->finish;
	return @bbox;
}

=item B<ascender> $use_exact

Returns the ascender value for the font, assuming size of 1 point.
If you supply a non-zero argument, this will be calculated by
rendering sample characters in the font and determining exactly
how far they extend above the baseline.

=cut

sub ascender {
	my $self = shift;
	my $metrics = $self->{metrics};
	return $_[0] ? $metrics->{exact_ascender} : $metrics->{ascender};
}

=item B<bbox>

Returns the bounding box of the font (LLx, LLy, URx, URy),
assuming size of 1 point.

=cut

sub bbox {
	my $self = shift;
	my $metrics = $self->{metrics};
	return @{$metrics->{bbox}};
}

=item B<capheight> $use_exact

Returns the capheight value for the font, assuming size of 1 point. If
you supply a non-zero argument, this will be calculated by rendering
sample upper-case characters in the font and determining exactly how
far they extend above the baseline.

=cut

sub capheight {
	my $self = shift;
	my $metrics = $self->{metrics};
	return $_[0] ? $metrics->{exact_capheight} : $metrics->{capheight};
}

=item B<descender> $use_exact

Returns the descender value for the font, assuming size of 1 point.
This is usually negative, reflecting its offset from the baseline.
If you supply a non-zero argument, this will be calculated by
rendering sample characters in the font and determining exactly
how far they extend below the baseline.

=cut

sub descender {
	my $self = shift;
	my $metrics = $self->{metrics};
	return $_[0] ? $metrics->{exact_descender} : $metrics->{descender};
}

=item B<xheight> $use_exact

Returns the xheight value for the font, assuming size of 1 point.
If you supply a non-zero argument, this will be calculated by
rendering a lower-case "X" in the font and determining exactly
how far it extends above the baseline.

=cut

sub xheight {
	my $self = shift;
	my $metrics = $self->{metrics};
	return $_[0] ? $metrics->{exact_xheight} : $metrics->{xheight};
}

=back

=head2 PDF::API2 Compatibility

=over 4

=item B<fontbbox>

Alias for bbox().

=cut

sub fontbbox {
	return bbox(@_);
}

=item B<width> $text

Calculate width of text in this font at size of 1 point.

=cut

sub width {
	return 0 unless defined $_[1];
	my @bbox = _text_bbox(@_);
	return $bbox[2];
}

=back

=head2 Utility Functions

=over 4

=item B<append_font_path> @paths

Add @paths to the end of the font search path.

=cut

sub append_font_path {
	push(@FONT_PATH, @_);
}

=item B<get_font_path>

Returns an array of directories that will be searched for fonts,
and for AFM metrics files if you load a PFB font (case-insensitive).

=cut

sub get_font_path {
	return @FONT_PATH;
}

=item B<set_font_path> @paths

Set the font search path to @paths.

=cut

sub set_font_path {
	@FONT_PATH = @_;
}

=item B<find_api2font> $name

Uses Fontconfig to locate a decent match for the PDF::API2 builtin
(non-embedded) fonts. The 'core' fonts are Times, Courier, Helvetica,
Georgia, and Verdana, which Fontconfig is pretty good at finding
matches for. The 'cjk' fonts are more problematic, and I recommend
downloading the language-specific OTF files of Source Han from these
links and loading them by filename instead:

    https://github.com/adobe-fonts/source-han-sans/tree/release
    https://github.com/adobe-fonts/source-han-serif/tree/release

Otherwise, the following Fontconfig searches will be used, with
results that depend on how sane your F<fonts.conf> is:

    traditional|ming = "serif:lang=zh-tw"
    simplified|song = "serif:lang=zh-cn"
    korean|myungjo = "serif:lang=ko"
    japanese|kozmin = "serif:lang=ja"
    kozgo = "sans:lang=ja"

=cut

sub find_api2font {
	my $fontname = join('-', @_);
	$fontname =~ tr/,A-Z/-a-z/;
	my ($family, $weight, $style) = qw(serif normal normal);
	my $lang = '';
	$weight = 'bold' if $fontname =~ /bold/;
	$style = 'italic' if $fontname =~ /oblique|italic/;
	if ($fontname =~ /^(times|courier|helvetica|georgia|verdana)/) {
		$family = $1;
	}elsif ($fontname =~ /^(traditional|ming)/) {
		$lang = 'lang=zh-cn';
	}elsif ($fontname =~ /^(simplified|song)/) {
		$lang = 'lang=zh-tw';
	}elsif ($fontname =~ /^(japanese|kozmin)/) {
		$lang = 'lang=ja';
	}elsif ($fontname =~ /^kozgo/) {
		$family = 'sans';
		$lang = 'lang=ja';
	}
	my $search = join(':', $family, $weight, $style, $lang, 'scalable=true');
	my $match = `fc-match -f '%{file}\t%{index}' $search`;
	my ($file, $index) = split(/\t/, $match);
	if (defined $file) {
		return ($file, $index);
	}else{
		# this allows fallthrough to cairo toy API if matching fonts
		# are not installed on your system
		return @_;
	}
}	

=back

=head1 AUTHOR

J Greely, C<< <jgreely at cpan.org> >>

=head1 SEE ALSO

L<PDF::API2>, L<PDF::Builder>, L<Cairo>, L<Font::FreeType>, L<Pango>,
L<Fontconfig|http://fontconfig.org>

=cut

1;
