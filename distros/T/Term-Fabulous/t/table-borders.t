use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Table::Borders qw(resolve_borders);

my %S     = map { $_ => Term::Fabulous::Enum::BorderStyle->$_ } qw(Solid Round Heavy Double Hidden Blank Outer Inner);
my %FRAME = ( border_top => $S{Round}, border_right => $S{Round}, border_bottom => $S{Round}, border_left => $S{Round}, column_lines => $S{Solid} );

# The sides a cell draws, as "top:Solid left:Round", and its corners.
sub sides ($cell) {
	return join ' ', map { "$_:" . $cell->{sides}{$_}->name } grep { $cell->{sides}{$_} } qw(top right bottom left);
}

sub corners ($cell) {
	return join ' ', map { "$_=$cell->{corners}{$_}" } grep { defined $cell->{corners}{$_} } qw(top_left top_right bottom_left bottom_right);
}

sub lines (%args) {
	return resolve_borders(%args)->{lines};
}

subtest 'a header and two rows' => sub {
	my $cells = lines( columns => 2, header => 1, table => { %FRAME, header_line => $S{Heavy} }, lines => [ {}, {}, {} ] );
	is sides( $cells->[0][0] ),   'top:Round bottom:Heavy left:Round',                                               'the header draws the line below it';
	is corners( $cells->[0][0] ), "top_left=\x{256D} bottom_left=\x{251D}",                                          'with the junctions of its corners';
	is corners( $cells->[0][1] ), "top_left=\x{252C} top_right=\x{256E} bottom_left=\x{253F} bottom_right=\x{2525}", 'second column';
	is sides( $cells->[1][0] ),   'left:Round',                                                                      'the first row has no top of its own and no line below';
	is sides( $cells->[2][1] ),   'right:Round bottom:Round left:Solid',                                             'the last row draws the bottom of the frame';
	is corners( $cells->[2][1] ), "bottom_left=\x{2534} bottom_right=\x{256F}",                                      'with its junctions';
	is $cells->[0][0]{outer},     [qw(left top)],                                                                    'outer frame sides';
	is $cells->[1][1]{outer},     ['right'],                                                                         'right side of the last column';
};

subtest 'row lines and a spanning line' => sub {
	my $cells = lines( columns => 2, table => { %FRAME, row_lines => $S{Solid} }, lines => [ {}, { spanning => 1 }, {} ] );
	is sides( $cells->[0][1] ),   'top:Round right:Round bottom:Solid left:Solid',                                   'the line above a spanning line draws its bottom';
	is corners( $cells->[0][1] ), "top_left=\x{252C} top_right=\x{256E} bottom_left=\x{2534} bottom_right=\x{2524}", 'its column line ends there';
	is sides( $cells->[1][0] ),   'right:Round left:Round',                                                          'the spanning line has only its outer sides';
	is sides( $cells->[2][0] ),   'top:Solid bottom:Round left:Round',                                               'the line below a spanning line draws the top';
	is corners( $cells->[2][1] ), "top_left=\x{252C} top_right=\x{2524} bottom_left=\x{2534} bottom_right=\x{256F}", 'where the column line starts again';
};

subtest 'which style wins' => sub {
	my %table = ( %FRAME, row_lines => $S{Solid} );
	my $cells = lines(
		columns       => 2,
		table         => \%table,
		column_styles => [ {}, { border_left => $S{Double}, row_lines => $S{Heavy} } ],
		lines         => [
			{},
			{ cells => [ { border_top => $S{Hidden} }, { border_left => $S{Heavy} } ] },
			{ style => { border_top => $S{Double} } },
			{ style => { border_top => $S{Hidden} } },
		],
	);
	is $cells->[0][1]{sides}{left}->name, 'Double',                  'a column style wins over the table';
	is $cells->[1][1]{sides}{left}->name, 'Heavy',                   'a cell style wins over the column';
	is $cells->[1][0]{sides}{top}->name,  'Blank',                   'a Hidden segment: no line, but the cell keeps the line\'s space';
	is $cells->[1][1]{sides}{top}->name,  'Heavy',                   'the column row_lines next to it';
	is $cells->[2][1]{sides}{top}->name,  'Double',                  'a row style wins over the column';
	is sides( $cells->[3][0] ),           'bottom:Round left:Round', 'a boundary hidden everywhere is no line at all (the last line has the frame below)';
	is sides( $cells->[2][0] ),           'top:Double left:Round',   'and the line above it stays';
};

subtest 'a frame in a block style' => sub {
	my %outer = map { $_ => $S{Outer} } qw(border_top border_right border_bottom border_left);
	my $cells = lines( columns => 2, header => 1, table => { %outer, column_lines => $S{Solid}, header_line => $S{Solid} }, lines => [ {}, {} ] );
	is corners( $cells->[0][0] ), "bottom_left=\x{258C}",                                         'the corners of the table keep the style\'s own glyphs; the header line ends at the left side';
	is corners( $cells->[0][1] ), "top_left=\x{2580} bottom_left=\x{253C} bottom_right=\x{2590}", 'the frame runs on where a column line meets it';
	is corners( $cells->[1][1] ), "bottom_left=\x{2584}",                                         'also at the bottom';
	is $cells->[0][0]{outer},     [],                                                             'Outer sides are drawn on the cells\' background';

	my %inner  = map { $_ => $S{Inner} } qw(border_top border_right border_bottom border_left);
	my $inside = lines( columns => 1, table => \%inner, lines => [ {} ] );
	is $inside->[0][0]{outer}, [qw(left right top bottom)], 'Inner sides are drawn on the background outside';
};

subtest 'ledges and the scrollbar column' => sub {
	my %table    = ( %FRAME, header_line => $S{Heavy}, row_lines => $S{Solid} );
	my $resolved = resolve_borders( columns => 2, header => 1, gutter => 1, table => \%table, lines => [ {}, {}, {}, { ledge => 1 } ] );
	my $cells    = $resolved->{lines};
	is sides( $cells->[2][1] ),   'top:Solid left:Solid',              'the last row draws neither the bottom of the frame nor its right side';
	is sides( $cells->[3][1] ),   'bottom:Round left:Solid',           'the ledge draws the bottom, with no line between it and the last row';
	is corners( $cells->[3][1] ), "bottom_left=\x{2534}",              'and the junction of the column line';
	is sides( $cells->[0][1] ),   'top:Round bottom:Heavy left:Solid', 'the header draws no right side either';
	my $strips = $resolved->{gutter};
	is sides( $strips->{header} ),   'top:Round right:Round bottom:Heavy',       'the header strip draws the top, the header line and the right side';
	is corners( $strips->{header} ), "top_right=\x{256E} bottom_right=\x{2525}", 'with the corner and the junction';
	is sides( $strips->{body} ),     'right:Round',                              'the body strip draws only the right side';
	is sides( $strips->{footer} ),   'right:Round bottom:Round',                 'the footer strip draws the bottom and the right side';
	is corners( $strips->{footer} ), "bottom_right=\x{256F}",                    'with the corner';
	is $strips->{body}{outer},       ['right'],                                  'a line style is drawn outside';

	my $top = lines( columns => 1, header => 1, table => \%table, lines => [ { ledge => 1 }, {}, { ledge => 1 } ] );
	is sides( $top->[0][0] ), 'top:Round right:Round left:Round', 'a top ledge draws the top of the frame without a header line below it';
	is sides( $top->[1][0] ), 'right:Round left:Round',           'the one row draws no top or bottom';
	like dies { resolve_borders( columns => 1, table => \%table, lines => [ {}, { ledge => 1 }, {} ] ) }, qr/a ledge must be the first or the last line/, 'a ledge in the middle dies';
};

subtest 'lines that do not exist take no space' => sub {
	my $cells = lines( columns => 3, table => {}, lines => [ {}, {} ] );
	is [ map { sides($_) } @{ $cells->[0] } ], [ '', '', '' ], 'no lines at all';
	my $one = lines( columns => 3, table => {}, lines => [ { cells => [ {}, { border_left => $S{Solid} }, {} ] }, {} ] );
	is sides( $one->[0][1] ), 'left:Solid', 'a single segment makes its grid line';
	is sides( $one->[1][1] ), 'left:Blank', 'which the other lines keep blank';
	is sides( $one->[1][0] ), '',           'other grid lines do not exist';
};

done_testing;
