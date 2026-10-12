package Term::Fabulous::Text::Markup;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw(parse_markup);

use Term::Fabulous::Text::Style qw(parse_style);

# A tag starts (after optional blanks) with a letter, a '#' (a hex color)
# or a '/' (a closing tag) and holds no brackets. Anything else between
# brackets is text.
my $TOKEN = qr/\G(?:(?<escaped>\\\[)|\[(?<tag>\s*[a-zA-Z#\/][^\[\]]*)\]|(?<text>[^\[\\]+|.))/s;

sub _fail ( $what, $markup ) {
	die "Term::Fabulous::Text::Markup: $what in '$markup'";
}

sub _closes ( $tag, $open, $markup ) {
	my $name = $tag =~ s/\A\s*\/\s*//r;
	$name =~ s/\s+\z//;
	return pop @$open if $name eq '' && @$open;
	_fail( 'closing tag [/] without an open tag', $markup ) if $name eq '';

	my ($index) = grep { $open->[$_][0] eq $name } reverse 0 .. $#$open;
	_fail( "closing tag [/$name] does not match an open tag", $markup ) unless defined $index;
	return splice @$open, $index, 1;
}

# A link tag: 'link=' and the target, which may not be empty.
sub _link_target ( $tag_text, $markup ) {
	my ($target) = $tag_text =~ /\Alink\s*=\s*(.*)\z/s;
	return undef unless defined $target;
	_fail( "link tag [$tag_text] without a target", $markup ) unless length $target;
	return $target;
}

sub parse_markup ($markup) {
	die 'Term::Fabulous::Text::Markup: markup is a string' if !defined $markup || ref $markup;

	my $plain = '';
	my @open;    # [ $name, $style, $start, $link_target ] of every open tag, outermost first
	my @closed;    # [ $start, $end, $style ] in closing order
	my @links;    # [ $start, $end, $target ] in closing order
	my $close = sub ($tag) {
		my ( undef, $style, $start, $target ) = @$tag;
		return unless $start < length $plain;
		push @{ defined $target ? \@links : \@closed }, [ $start, length $plain, $target // $style ];
		return;
	};

	while ( $markup =~ /$TOKEN/gc ) {
		my ( $text, $escaped, $tag ) = @+{qw(text escaped tag)};    # copied: the next match resets %+
		if ( defined $text ) {
			$plain .= $text;
		}
		elsif ( defined $escaped ) {
			$plain .= '[';
		}
		elsif ( $tag =~ /\A\s*\// ) {
			$close->( _closes( $tag, \@open, $markup ) );
		}
		else {
			my $tag_text = $tag =~ s/\A\s+|\s+\z//gr;
			my $target   = _link_target( $tag_text, $markup );
			if ( !defined $target ) {
				push @open, [ $tag_text, parse_style($tag_text), length $plain, undef ];
				next;
			}
			_fail( "link tag [$tag_text] inside another link", $markup ) if grep { defined $_->[3] } @open;
			push @open, [ 'link', undef, length $plain, $target ];
		}
	}
	$close->($_) foreach reverse @open;

	# Outer spans first, so that an inner span wins where they overlap.
	my @spans = sort { $a->[0] <=> $b->[0] } reverse @closed;
	return ( $plain, \@spans, [ sort { $a->[0] <=> $b->[0] } @links ] );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Text::Markup - Parse "[bold red]text[/]" markup into text,
styled spans and links

=head1 SYNOPSIS

	use Term::Fabulous::Text::Markup qw(parse_markup);

	my ( $text, $spans ) = parse_markup('Press [bold]Enter[/] to [green on #202020]save[/green on #202020].');
	# $text  is 'Press Enter to save.'
	# $spans is [ [ 6, 11, { set => TB_BOLD, ... } ], [ 15, 19, { color => [ 0, 128, 0, 255 ], ... } ] ]

	my ( $see, undef, $links ) = parse_markup('See [link=https://perl.org]perl.org[/link].');
	# $see   is 'See perl.org.'
	# $links is [ [ 4, 12, 'https://perl.org' ] ]

=head1 DESCRIPTION

Markup is text with style tags in square brackets, in the syntax of
Python's C<rich> library. L<Term::Fabulous::Widget::RichText> takes it
as its C<markup> parameter; this module does the parsing.

=over

=item C<[STYLE]>

Opens a span with a style string of L<Term::Fabulous::Text::Style>:
C<[bold]>, C<[italic SteelBlue on #202020]>, C<[not bold]>. An invalid
style dies.

=item C<[link=TARGET]>

Opens a link to C<TARGET>: everything after the C<=> up to the closing
bracket, without the blanks at its ends (C<[link=https://perl.org]>,
C<[link=perlfunc/open]>, C<[link=page two]> for the target
C<page two>). The target is always a string, and cannot contain C<[>
or C<]>; give other targets from Perl with
L<add_link|Term::Fabulous::Widget::RichText/add_link>. What the target
means is the program's business (see
L<Term::Fabulous::Widget::RichText/LINKS>). A link tag without a
target, and a link inside another link, die. Close it with C<[/link]>
or C<[/]>. A link is no span: style the words with a style tag inside
or around it, as in C<[bold][link=faq]FAQ[/link][/]>.

=item C<[/]>

Closes the innermost open span or link.

=item C<[/STYLE]>

Closes the innermost open span that was opened with exactly that style
string: C<[/bold]> closes a C<[bold]>. Dies when no such span is open.

=item C<\[>

A literal C<[>. Every other backslash is a backslash.

=back

Brackets that do not look like a tag are text: a tag starts with a
letter, C<#> or C</> and contains no brackets, so C<[1]>, C<[ ]> and
C<[]> stay as they are. Spans still open at the end run to the end of
the text. Tags nest: an inner span is applied after the outer one, so
its words win where they overlap.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 parse_markup

	my ( $text, $spans, $links ) = parse_markup($markup);

Returns the text without its tags and the spans as an array reference
of C<[ $start, $end, $style ]>: the character offsets of the span in
C<$text> (C<$end> is the offset after its last character) and its
normalized style hash (see L<Term::Fabulous::Text::Style/Style hashes>).
Spans are ordered by their start, outer spans before inner ones that
start at the same offset; empty spans are dropped. The links are an
array reference of C<[ $start, $end, $target ]>, ordered by their start;
empty links are dropped as well. C<undef> and
references die with a message starting with
C<Term::Fabulous::Text::Markup:>.

=head1 SEE ALSO

L<Term::Fabulous::Text::Style>, L<Term::Fabulous::Widget::RichText>.

=cut
