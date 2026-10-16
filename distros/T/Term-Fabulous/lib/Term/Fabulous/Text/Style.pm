package Term::Fabulous::Text::Style;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Exporter 'import';
our @EXPORT_OK = qw(parse_style style compose_styles apply_style);

use Feature::Compat::Try;
use Term::Fabulous::Check qw(color non_negative_integer optional);
use Term::Fabulous::Color;
use Term::Fabulous::Termbox qw(TB_BOLD TB_ITALIC TB_UNDERLINE TB_REVERSE TB_DIM TB_BLINK TB_STRIKEOUT TB_OVERLINE TB_INVISIBLE);

my %BIT_BY_WORD = (
	bold          => TB_BOLD,
	italic        => TB_ITALIC,
	underline     => TB_UNDERLINE,
	reverse       => TB_REVERSE,
	dim           => TB_DIM,
	blink         => TB_BLINK,
	strike        => TB_STRIKEOUT,
	strikethrough => TB_STRIKEOUT,
	overline      => TB_OVERLINE,
	conceal       => TB_INVISIBLE,
);
my $KNOWN_WORDS = join ', ', sort( keys %BIT_BY_WORD ), 'not WORD', 'on COLOR', 'default';

# Alpha 0 is the terminal's own color everywhere in Term::Fabulous.
my $DEFAULT_COLOR = [ 0, 0, 0, 0 ];

my @STYLE_KEYS = qw(set clear color background);

sub _fail ( $what, $style ) {
	die "Term::Fabulous::Text::Style: $what in '$style' (known: $KNOWN_WORDS, and any color)";
}

# The [r, g, b, a] a word of a style string names (any string
# Term::Fabulous::Color reads, web color names included), or undef when
# it is not a color.
sub _color_of_word ($word) {    ## no critic (Subroutines::RequireFinalReturn) PPI does not parse try/catch
	return $DEFAULT_COLOR if $word eq 'default';

	my $parsed;
	try {
		$parsed = [ Term::Fabulous::Color->new( color => $word )->to_rgba ];
	}
	catch ($error) {
		$parsed = undef;    # not a color either
	}
	return $parsed;
}

sub parse_style ($string) {
	die 'Term::Fabulous::Text::Style: a style is a string' if !defined $string || ref $string;

	my $style = _neutral();
	my @words = $string =~ /\w+\([^)]*\)|\S+/g;    # rgb(1, 2, 3) is one word
	while (@words) {
		my $word = shift @words;
		my %word_style
			= $word eq 'not'      ? ( clear => $BIT_BY_WORD{ shift(@words) // '' } // _fail( "'not' needs a style word after it", $string ) )
			: $word eq 'on'       ? ( background => _color_of_word( shift(@words) // '' ) // _fail( "'on' needs a color after it", $string ) )
			: $BIT_BY_WORD{$word} ? ( set => $BIT_BY_WORD{$word} )
			:                       ( color => _color_of_word($word) // _fail( "unknown style word '$word'", $string ) );
		$style = _compose( $style, { %{ _neutral() }, %word_style } );
	}
	return $style;
}

sub _neutral () {
	return { set => 0, clear => 0, color => undef, background => undef };
}

# The style $later stacked on $earlier: later bits win over earlier ones
# (set after clear sets, clear after set clears), a later color replaces
# an earlier one.
sub _compose ( $earlier, $later ) {
	return {
		set        => ( $earlier->{set} & ~$later->{clear} ) | $later->{set},
		clear      => ( $earlier->{clear} & ~$later->{set} ) | $later->{clear},
		color      => $later->{color}      // $earlier->{color},
		background => $later->{background} // $earlier->{background},
	};
}

sub style ($value) {
	return parse_style($value) unless ref $value;
	die "Term::Fabulous::Text::Style: a style is a string or a hash reference, not $value" unless ref $value eq 'HASH';

	my @unknown = sort grep { !( $_ eq 'set' || $_ eq 'clear' || $_ eq 'color' || $_ eq 'background' ) } keys %$value;
	die "Term::Fabulous::Text::Style: unknown style key(s) @unknown (known: " . join( ', ', @STYLE_KEYS ) . ')' if @unknown;

	my $owner = __PACKAGE__;
	return {
		set        => non_negative_integer( $owner, set   => $value->{set}   // 0 ),
		clear      => non_negative_integer( $owner, clear => $value->{clear} // 0 ),
		color      => optional( \&color, $owner, color      => $value->{color} ),
		background => optional( \&color, $owner, background => $value->{background} ),
	};
}

sub compose_styles (@styles) {
	my $composed = _neutral();
	$composed = _compose( $composed, $_ ) foreach @styles;
	return $composed;
}

# The look's bits are a style that sets them and clears nothing, so
# applying is composing.
sub apply_style ( $look, $style ) {
	my $applied = _compose( { set => $look->{attrs}, clear => 0, color => $look->{color}, background => $look->{background} }, $style );
	return { attrs => $applied->{set}, color => $applied->{color}, background => $applied->{background} };
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Text::Style - Parse style strings such as "bold red on
#202020"

=head1 SYNOPSIS

	use Term::Fabulous::Text::Style qw(parse_style style compose_styles apply_style);

	my $style = parse_style('bold underline SteelBlue on #202020');
	# { set => TB_BOLD | TB_UNDERLINE, clear => 0, color => [ 70, 130, 180, 255 ], background => [ 32, 32, 32, 255 ] }

	my $plain = parse_style('not bold default');
	# { set => 0, clear => TB_BOLD, color => [ 0, 0, 0, 0 ], background => undef }

	my $same = style($style);    # a style hash is checked and copied, a string parsed

	my $inner = compose_styles( $style, parse_style('not bold') );    # stacked: the later wins
	# { set => TB_UNDERLINE, clear => TB_BOLD, color => [ 70, 130, 180, 255 ], background => [ 32, 32, 32, 255 ] }

	my $look = apply_style( { attrs => TB_ITALIC, color => [ 220, 223, 228, 255 ], background => undef }, $style );
	# { attrs => TB_ITALIC | TB_BOLD | TB_UNDERLINE, color => [ 70, 130, 180, 255 ], background => [ 32, 32, 32, 255 ] }

=head1 DESCRIPTION

A I<style> is what a span of a L<Term::Fabulous::Widget::RichText>
adds to the look of the characters it covers: style bits to set or
clear, a text color and a background. It is written as a string of
words, in the manner of Python's C<rich> library, or given as a hash.
This module turns both into one normalized hash, stacks such hashes
(L</compose_styles>) and applies one to a look (L</apply_style>). These
two functions are the only place where style bits are combined:
L<Term::Fabulous::Widget::RichText> composes the styles of nested spans
with the first, and L<Term::Fabulous::Render::Text> paints each run of
a line with the second.

=head2 Style strings

A style string is words separated by whitespace, in any order:

=over

=item C<bold>, C<italic>, C<underline>, C<reverse>, C<dim>, C<blink>, C<strike>, C<overline>, C<conceal>

Set the style bit of that name (the termbox2 attributes C<TB_BOLD>,
C<TB_ITALIC>, C<TB_UNDERLINE>, C<TB_REVERSE>, C<TB_DIM>, C<TB_BLINK>,
C<TB_STRIKEOUT>, C<TB_OVERLINE> and C<TB_INVISIBLE> of
L<Term::Fabulous::Termbox>). C<strikethrough> is the same as C<strike>.
Terminals show these with what their font has; a terminal may ignore
some of them.

=item C<not WORD>

Clear that style bit, so an inner span can switch off what an outer
one set: C<not bold>.

=item A color

The text color: any string L<Term::Fabulous::Color> reads (see
L<Term::Fabulous::Color/A string>), such as a CSS color name in any case
(C<SteelBlue>, C<steelblue>), C<#ff8800>, C<rgb(255, 136, 0)> or
C<hsl(32, 100%, 50%)>. C<default> is the terminal's default color
(alpha 0); the style words above win over a color of the same spelling
(there is none among the CSS names).

=item C<on COLOR>

The background, a color as above: C<on #202020>, C<on default>.

=back

The last word wins where words contradict (C<bold not bold> clears
bold). Unknown words die with the known ones.

=head2 Style hashes

The normalized form has exactly these keys:

	{
		set        => $bits,            # style bits to set
		clear      => $bits,            # style bits to clear
		color      => $rgba | undef,    # [ r, g, b, a ], undef leaves the color alone
		background => $rgba | undef,
	}

Colors are C<[r, g, b, a]> with alpha 0 for the terminal's default
color; C<undef> means the style does not touch that color.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 parse_style

	my $style = parse_style('bold red on #202020');

Parses a style string (see L</Style strings>) into a style hash. An
unknown word, a C<not> or C<on> without its argument, C<undef> or a
reference die with a message starting with
C<Term::Fabulous::Text::Style:>.

=head2 style

	my $style = style($string_or_hash);

Returns a normalized style hash for a style string or a hash with any
of the keys of L</Style hashes>; missing keys are 0 or C<undef>, and
the colors may be in any format L<Term::Fabulous::Color> accepts. The
result is a new hash. Unknown keys, invalid bits (not a non-negative
integer) and invalid colors die.

=head2 compose_styles

	my $style = compose_styles( $outer, $inner, $innermost );

Stacks style hashes in order and returns the style hash they make
together, as if each were applied after the ones before it: a later
C<set> bit wins over an earlier C<clear> of the same bit and the other
way round (both stay recorded, so the result still clears what it must
clear), and a later color replaces an earlier one. No styles give the
style that touches nothing. Applying the result to a look gives the
same look as applying the styles one after the other. The given hashes
are not changed.

=head2 apply_style

	my $look = apply_style( { attrs => $bits, color => $rgba, background => $rgba_or_undef }, $style );

Applies a style hash to a I<look>, a hash of the termbox2 style bits
C<attrs>, the text C<color> and the C<background>, and returns the new
look: the bits with C<clear> removed and C<set> added, and each color
replaced when the style has one. The given look is not changed. The
colors are passed through as they are, so they may be in any one form
as long as the look and the style agree: L<Term::Fabulous::Render::Text>
applies RichText runs whose colors are termbox attributes.

=head1 SEE ALSO

L<Term::Fabulous::Text::Markup>, L<Term::Fabulous::Widget::RichText>,
L<Term::Fabulous::Color>, L<Term::Fabulous::Enum::WebColor>,
L<Term::Fabulous::Termbox>.

=cut
