package Term::Fabulous::Document::Look;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

our $VERSION = '0.05';

class Term::Fabulous::Document::Look :strict(params) {
	use Scalar::Util qw(blessed refaddr);
	use Term::Fabulous::Check qw(describe);
	use Term::Fabulous::Text::Style ();
	use Term::Fabulous::Theme;

	# Every kind of styled text a document view shows, as the style words
	# it sets and the palette tokens of its text color and background.
	# A subclass adds kinds by overriding recipes.
	method recipes :common () {
		return (
			bold          => { words      => 'bold' },
			italic        => { words      => 'italic' },
			strike        => { words      => 'strike' },
			code          => { color      => 'warning' },
			file          => { words      => 'italic', color => 'success' },
			match         => { background => 'selection' },
			match_current => { color      => 'text_inverse', background => 'warning' },
			heading1      => { words      => 'bold',         color      => 'accent' },
			heading2      => { words      => 'bold',         color      => 'text_bright' },
			heading3      => { words      => 'bold',         color      => 'text' },
			heading4      => { words      => 'bold italic',  color      => 'text' },
			heading5      => { words      => 'italic',       color      => 'text_bright' },
			heading6      => { words      => 'italic',       color      => 'text_muted' },
			term          => { words      => 'bold',         color      => 'text_bright' },
			marker        => { color      => 'accent' },
			quote         => { color      => 'text_muted' },
			code_block    => { color      => 'text',       background => 'surface_low' },
			clipped       => { color      => 'text_muted', background => 'surface_low' },
		);
	}

	field $theme :param :reader;
	field %style_of;

	ADJUST {
		die ref($self) . ": theme must be a Term::Fabulous::Theme, got " . describe($theme) unless blessed $theme && $theme->isa('Term::Fabulous::Theme');
		my %recipe = __CLASS__->recipes;
		%style_of = map { $_ => _style_of_recipe( $theme, $recipe{$_} ) } keys %recipe;
	}

	sub _style_of_recipe ( $theme, $recipe ) {
		my $style = Term::Fabulous::Text::Style::style( $recipe->{words} // {} );
		$style->{color}      = $theme->token( $recipe->{color} ) if defined $recipe->{color};
		$style->{background} = $theme->token( $recipe->{background} ) if defined $recipe->{background};
		return $style;
	}

	method kinds :common () {
		my %recipe = $class->recipes;
		my @kinds  = sort keys %recipe;
		return @kinds;
	}

	# The style of a kind with the palette tokens of its recipe as they
	# are: a widget that paints it asks its own theme for the colors, so
	# a theme switch needs no new style.
	method token_style :common ($kind) {
		my %recipe = $class->recipes;
		my $recipe = $recipe{ $kind                                       // '' } // die "$class: unknown kind " . describe($kind) . "; the kinds are " . join( ', ', $class->kinds );
		my $style  = Term::Fabulous::Text::Style::style( $recipe->{words} // {} );
		$style->{color}      = $recipe->{color} if defined $recipe->{color};
		$style->{background} = $recipe->{background} if defined $recipe->{background};
		return $style;
	}

	method style ($kind) {
		my $style = $style_of{ $kind // '' } // die ref($self) . ": unknown kind " . describe($kind) . "; the kinds are " . join( ', ', __CLASS__->kinds );
		return { %$style, map { ref $style->{$_} ? ( $_ => [ @{ $style->{$_} } ] ) : () } keys %$style };
	}

	# The look of the theme a widget draws with, as
	# Term::Fabulous::Role::Themed decides (drawing_theme); the default
	# theme for a widget that is not themed. The last look of each class is
	# kept until the theme or the theme generation changes. The entry holds
	# the theme itself, so that its address cannot be reused by another
	# theme while the look is kept.
	my %last_of_class;    # class => [ look, theme, generation ]

	method of :common ($widget) {
		my $theme      = $widget->can('drawing_theme') ? $widget->drawing_theme : Term::Fabulous::Theme->default;
		my $generation = Term::Fabulous::Theme::generation();
		my $last       = $last_of_class{$class};
		return $last->[0] if defined $last && refaddr( $last->[1] ) == refaddr($theme) && $last->[2] == $generation;
		my $look = $class->new( theme => $theme );
		$last_of_class{$class} = [ $look, $theme, $generation ];
		return $look;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Document::Look - Styles for each kind of document text, taken from a theme

=head1 SYNOPSIS

	use Term::Fabulous::Document::Look;

	# The look of the theme a widget draws with:
	my $look = Term::Fabulous::Document::Look->of($widget);
	$text->stylize( $look->style('code'), 4, 12 );

	# The look of a particular theme:
	my $light = Term::Fabulous::Document::Look->new( theme => Term::Fabulous::Theme->builtin('light') );

	# A look with a kind of its own and a different style for code:
	class My::Look :isa(Term::Fabulous::Document::Look) {
		method recipes :common () {
			return (
				$class->SUPER::recipes,
				title => { words => 'bold', color => 'accent' },
				code  => { color => 'success', background => 'surface_low' },
			);
		}
	}

=head1 DESCRIPTION

A parser records what a range of text I<is>, such as bold text, code or
a heading, as a I<mark> of a certain I<kind> (see
L<Term::Fabulous::Document/FACTORIES>). A look decides how each kind is
I<shown>. For every kind it holds a style in the sense of
L<Term::Fabulous::Text::Style>: the style bits to set and clear, a text
color and a background. A L<Term::Fabulous::Widget::Text> span
takes such a style unchanged.

Links are not a kind of the look. A Text draws its links itself, in
the link looks of the theme (see
L<Term::Fabulous::Widget::Text/Looks>).

A look takes every color from the palette of a L<Term::Fabulous::Theme>
(see L<Term::Fabulous::Theme/Tokens>), never from fixed values. A
document view therefore follows the theme the program runs with,
whether it is built in or read from a theme file, and switching the
theme restyles the text.

=head2 Recipes

The styles are defined by I<recipes>, one per kind. A recipe is a hash
reference with up to three keys, all optional:

=over

=item C<words>

A style string of L<Term::Fabulous::Text::Style/Style strings>, usually
one or more style words such as C<'bold'> or C<'bold italic'>. Without
it, the kind sets and clears no style bits.

=item C<color>

The name of a palette token for the text color, such as C<'accent'>.
Without it, the style leaves the text color alone.

=item C<background>

The name of a palette token for the background, such as
C<'surface_low'>. Without it, the style leaves the background alone.

=back

The style string could name colors of its own, but these would not
change with the theme; use the token keys instead. A color from a token
key replaces any text color or background the style string names.

When a look is created, it turns every recipe into a style: it parses
C<words> and looks up both tokens in its theme with
L<Term::Fabulous::Theme/token>.

=head1 KINDS

The base class defines these kinds. In the middle column, C<bold>,
C<italic> and C<strike> are style words and every other name is a
palette token. A token on its own or after a comma is the text color;
C<X on Y> means text color X on background Y, and C<on Y> alone sets
only the background.

=for highlighter language=text

	Kind           Shown as                     Used for
	-------------  ---------------------------  ---------------------------------------
	bold           bold                         bold text
	italic         italic                       italic text
	strike         strike                       struck-through text
	code           warning                      code in a paragraph
	file           italic, success              a file name
	match          on selection                 a search match
	match_current  text_inverse on warning      the current search match
	heading1       bold, accent                 a first-level heading
	heading2       bold, text_bright            a second-level heading
	heading3       bold, text                   a third-level heading
	heading4       bold italic, text            a fourth-level heading
	heading5       italic, text_bright          a fifth-level heading
	heading6       italic, text_muted           a sixth-level heading
	term           bold, text_bright            the term of a definition list
	marker         accent                       bullets and numbers of items
	quote          text_muted                   the bar beside a block quote
	code_block     text on surface_low          verbatim blocks
	clipped        text_muted on surface_low    the marks of clipped code lines

=head2 Changing and adding kinds

To restyle documents or to support mark kinds of a new format, write a
subclass that overrides L</recipes>. It returns the recipes of its
parent followed by its own; a recipe with the name of an existing kind
replaces that kind's recipe. Keep all kinds of the base class: the
document view and L<Term::Fabulous::Widget::CodeBlock> ask for several
of them by name, and L</style> dies for a kind the look does not have.

A document names the look class its factories style marks with:

=for highlighter language=perl

	my $document = Term::Fabulous::Document->new( look => 'My::Look' );

The factories of the document die at once for a mark whose kind the
look class does not list in L</kinds> (links need no kind), and the
document's code blocks paint with the same class.
L<Term::Fabulous::Cookbook::DocumentTechniques/Change the styles of a document and add mark kinds (Look)>
is a worked example that changes the styles of a document and adds
mark kinds this way.

=head1 CONSTRUCTORS

=head2 new

	my $look = Term::Fabulous::Document::Look->new( theme => $theme );

Creates the look of a L<Term::Fabulous::Theme>, with a style for every
kind of L</recipes>. The C<theme> parameter is required. The
constructor dies when C<theme> is not a Term::Fabulous::Theme, when it
gets an unknown parameter, and when a recipe names a palette token the
theme does not know or contains a style string that does not parse.

=head2 of

	my $look = Term::Fabulous::Document::Look->of($widget);

Returns the look of the theme a widget draws with: its
L<drawing_theme|Term::Fabulous::Role::Themed/drawing_theme>, which is
the theme the L<Term::Fabulous> UI gives the widget's part of the tree,
or the default theme (L<Term::Fabulous::Theme/default>) while it is
part of no UI or of one without themes; the default theme for a widget
that does not compose L<Term::Fabulous::Role::Themed>. So the styles of
the look and the widget's own looks come from the same theme. Call C<of>
on the look class you want; the look is an instance of that class.

Each look class caches the look it made last and returns it again as
long as the theme is the same object and no theme has been switched
anywhere in the process since (see
L<Term::Fabulous::Theme/"generation, bump_generation">). Calling C<of>
in every frame is therefore cheap. There is one cached look per look
class, so views that use the same look class but draw with different
themes make a new look whenever the theme differs from the previous
call.

=head1 CLASS METHODS

=head2 recipes

	my %recipe = Term::Fabulous::Document::Look->recipes;

Returns the recipes of all kinds as a list of pairs, in the form
C<< kind => { words => 'bold italic', color => TOKEN, background => TOKEN } >>
(see L</Recipes>). A subclass overrides this method to change or add
kinds, as described in L</Changing and adding kinds>.

=head2 kinds

	my @kinds = Term::Fabulous::Document::Look->kinds;    # bold, clipped, code, ...

Returns the names of all kinds of the class, sorted. The factories of
L<Term::Fabulous::Document> check the kind of every mark against this
list (through L</token_style>) and die for a kind that is missing.

=head2 token_style

	my $style = Term::Fabulous::Document::Look->token_style('code');    # { set => 0, clear => 0, color => 'warning', background => undef }

Class method. The style of a kind as a style hash whose colors are
still the palette tokens of its recipe, not colors: what the factories
of L<Term::Fabulous::Document> give their texts, which look the tokens
up in their own theme when they paint (see
L<Term::Fabulous::Text::Style/Palette tokens>). A new hash on every
call. An unknown or undefined kind dies with the known kinds.

=head1 METHODS

=head2 theme

	my $theme = $look->theme;

Returns the L<Term::Fabulous::Theme> the styles were made from.

=head2 style

	my $style = $look->style('code');    # { set => 0, clear => 0, color => [...], background => undef }

Returns the style of a kind as a style hash (see
L<Term::Fabulous::Text::Style/Style hashes>). The hash and its color
arrays are new copies on every call, so the caller may change them
without affecting the look. An unknown or undefined kind dies with a
message that lists the known kinds.

=head1 SEE ALSO

L<Term::Fabulous::Cookbook::DocumentTechniques>, L<Term::Fabulous::Text::Style>,
L<Term::Fabulous::Theme>, L<Term::Fabulous::Manual::Looks/THEMES>,
L<Term::Fabulous::Document>, L<Term::Fabulous::Widget::DocumentView>.

=cut
