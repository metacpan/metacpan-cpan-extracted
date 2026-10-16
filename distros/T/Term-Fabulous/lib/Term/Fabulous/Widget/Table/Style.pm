package Term::Fabulous::Widget::Table::Style;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Exporter 'import';
our @EXPORT_OK = qw(style_hash merge_styles);

use Term::Fabulous::Check qw(boolean border_style color);
use Term::Fabulous::Enum::BorderStyle;

# What each kind of style may hold. Borders name the lines around a cell,
# a row or a column; 'column_lines' are the lines between the cells of a
# row, 'row_lines' those between the cells of a column.
my @LOOK    = qw(text_color background_color bold italic underline border_color);
my %KEYS_OF = (
	cell   => [ @LOOK, qw(border_top border_right border_bottom border_left) ],
	row    => [ @LOOK, qw(border_top border_right border_bottom border_left column_lines) ],
	column => [ @LOOK, qw(border_left border_right row_lines) ],
	header => [@LOOK],
);

my %KIND_OF_KEY = (
	text_color       => 'color',
	background_color => 'color',
	border_color     => 'color',
	bold             => 'boolean',
	italic           => 'boolean',
	underline        => 'boolean',
	map { $_ => 'border' } qw(border_top border_right border_bottom border_left column_lines row_lines),
);

# A validated copy of a style hash of the given kind: colors as
# [r, g, b, a], booleans as 1 or 0, borders as BorderStyle items. Keys
# with an undef value are left out (they inherit).
sub style_hash ( $owner, $name, $kind, $style ) {
	my $keys = $KEYS_OF{$kind} // die "Term::Fabulous::Widget::Table::Style: unknown style kind '$kind'";
	return {} unless defined $style;
	die( ( ref $owner || $owner ) . ": $name must be a hash reference, got " . ( ref $style ? ref($style) . ' reference' : "'$style'" ) )
		unless ref $style eq 'HASH';
	my %allowed = map  { $_ => 1 } @$keys;
	my @unknown = grep { !$allowed{$_} } sort keys %$style;
	die( ( ref $owner || $owner ) . ": $name does not know @unknown (known: " . join( ', ', sort @$keys ) . ")" ) if @unknown;

	my %copy;
	foreach my $key ( grep { defined $style->{$_} } sort keys %$style ) {
		my $kind_of_key = $KIND_OF_KEY{$key};
		$copy{$key}
			= $kind_of_key eq 'color'   ? color( $owner, "$name $key", $style->{$key} )
			: $kind_of_key eq 'boolean' ? boolean( $owner, "$name $key", $style->{$key} )
			:                             border_style( $owner, "$name $key", $style->{$key}, none => Term::Fabulous::Enum::BorderStyle->Hidden );
	}
	return \%copy;
}

# The first defined value of each key, from the most specific style to
# the least.
sub merge_styles (@styles) {
	my %merged;
	foreach my $style ( reverse grep { defined } @styles ) {
		$merged{$_} = $style->{$_} foreach keys %$style;
	}
	return \%merged;
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Table::Style - Check the style hashes of a table

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Table::Style qw(style_hash);

	my $style = style_hash( $table, 'row style', row => {
		background_color => '#203040',
		bold             => 1,
		border_bottom    => 'Heavy',
	} );

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Table> takes looks and lines as I<style
hashes> at four levels: the table, its columns, its rows and single
cells (see L<Term::Fabulous::Manual::TableStyles/STYLES AND BORDERS>). This
module checks them where they are given. You do not need it unless you
write a table subclass.

=head1 FUNCTIONS

=head2 style_hash

	my $copy = style_hash( $owner, $name, $kind, \%style );

A validated copy of C<\%style>, or an empty hash for C<undef>. C<$kind>
says which keys are allowed: C<cell>, C<row>, C<column> or C<header>
(the look of a header cell; see
L<Term::Fabulous::Manual::TableStyles/Style keys>). Colors become
C<[r, g, b, a]> (any format L<Term::Fabulous::Color> takes), booleans 1
or 0, and lines L<Term::Fabulous::Enum::BorderStyle> items (an item, a
style name such as C<'Heavy'>, or C<'none'> for no line, which is the
C<Hidden> style). Keys whose value is C<undef> are left out. Unknown keys
and invalid values die with a message that starts with C<$owner>'s class
and names C<$name>.

=head2 merge_styles

	my $style = merge_styles( $cell_style, $row_style, $column_style, $table_style );

A new hash with, for every key, the value of the first style hash that
has it (C<undef> arguments are skipped).

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Manual::TableStyles/Style keys>,
L<Term::Fabulous::Manual::TableStyles/Which style wins>.

=cut
