package PDF::TableX;

use Moose;
use MooseX::Types;
use MooseX::Types::Moose qw/Int/;

use Carp;
use PDF::API2;

use PDF::TableX::Row;
use PDF::TableX::Column;
use PDF::TableX::Cell;

with 'PDF::TableX::Stylable';

our $VERSION    = '0.014';

# public attrs
has width         => (is => 'rw', isa => 'Num', default => 0);
has start_x       => (is => 'rw', isa => 'Num', default => 0);
has start_y       => (is => 'rw', isa => 'Num', default => 0);
has rows          => (is => 'ro', isa => 'Int', default => 0);
has cols          => (is => 'ro', isa => 'Int', default => 0);
has repeat_header => (is => 'rw', isa => 'Bool', default => 0);

# private attrs
has _cols => (is => 'ro', init_arg => undef, isa => 'ArrayRef[ Object ]', default => sub {[]});

# some sugar
use overload '@{}' => sub { return $_[0]->{_children}; }, fallback => 1;

# make some methods
for my $attr (qw/width repeat_header/) {
	around $attr => sub {
		my $orig = shift;
		my $self = shift;
		return $self->$orig() unless @_;
		$self->$orig(@_);
		return $self;
	}
}

# overridden methods
override BUILDARGS => sub {
	my $class = shift;
	if (@_ == 2 and Int->check($_[0]) and Int->check($_[1])) {
		return { 
			cols    => $_[0],
			rows    => $_[1],
			width   => 190 / 25.4 *72,
			start_x => 10 / 25.4 *72,
			start_y => 287 / 25.4 *72,
		};
	}
	return super;
};

sub BUILD {
	my ($self) = @_;
	$self->_create_initial_struct;
};

# private methods
sub _create_initial_struct {
	my ($self) = @_;
	if ( my $rows =  $self->rows ) {
		$self->{rows} = 0;
		for (0..$rows-1) {
			$self->add_row( PDF::TableX::Row->new(
				cols     => $self->cols,
				width    => $self->width,
				_row_idx => $_,
				_parent  => $self,
				$self->properties,
				)
			);
		}	
	}
}

sub properties {
	my ($self, @attrs) = @_;
	@attrs = scalar(@attrs) ? @attrs : $self->attributes;
	return (map { $_ => $self->$_ } @attrs);
}

sub add_row {
	my ($self, $row) = @_;
	$self->{rows}++;
	push @{$self->{_children}}, $row;
}

sub col {
	my ($self, $i) = @_;
	return $self->{_cols}->[$i] if (defined $self->{_cols}->[$i]);
	my $col = PDF::TableX::Column->new();
	for ( @{$self} ) {
		$col->add_cell( $_->[$i] );
	}
	$self->{_cols}->[$i] = $col;
	return $col;
}

sub draw {
	my ($self, $pdf, $page, $y, $col_widths) = @_;
	my $spanned = 0;
	$self->{start_y} = $y || $self->{start_y};
	$self->_set_col_widths($col_widths);
	# get gfx, txt page objects in proper order to prevent from background hiding the text
	my @states = ($page->gfx, $page->text, $page->gfx, $page->text, $page->gfx, $page->text);
ROW:
	for (@{$self->{_children}}) {
		my ($row_height, $overflow) = $self->_draw_row( $_,  @states );
		if ( $overflow ) {
			$spanned++;
			$page = $pdf->page;
			$self->{start_y} = [ $page->get_mediabox ]->[3] - $self->margin->[0];
			@states = ($page->gfx, $page->text, $page->gfx, $page->text, $page->gfx, $page->text);
			if ( $self->repeat_header ) {
				my ($row_height, $overflow) = $self->_draw_row( $self->[0], @states );
				$self->{start_y} -= $row_height;
			}
			redo ROW;
		} else {
			$self->{start_y} -= $row_height;
		}
	}
	return ($page, $spanned, $self->{start_y});
}

sub _draw_row {
	my ($self, $row, @states) = @_;
	my ($row_height, $overflow) = $row->draw_content($self->start_x, $self->start_y, $states[4], $states[5] );
	$row->height( $row_height );
	$row->draw_background($self->start_x, $self->start_y, $states[0], $states[1]);
	$row->draw_borders($self->start_x, $self->start_y, $states[2], $states[3]);
	return ($row_height, $overflow);
}

sub _set_col_widths {
	my ($self, $col_widths) = @_;
	
	if ( defined $col_widths && scalar(@{$col_widths}) ) {
		for (0..$self->cols-1) {
			$self->col($_)->width( $col_widths->[$_] );
		}
		return;
	}
	
	my @min_col_widths = ();
	my @reg_col_widths = ();
	my @width_ratio    = ();
	
	for my $col (map {$self->col($_)} (0..$self->cols-1)) {
		push @min_col_widths, $col->get_min_width();
		push @reg_col_widths, $col->get_reg_width();
		push @width_ratio, ( $reg_col_widths[-1] / $min_col_widths[-1] );
	}

	my ($min_width, $free_space, $ratios) = (0,0,0);
	$min_width += $_ for @min_col_widths;
	$free_space = $self->width - $min_width;
	$ratios    += $_ for @width_ratio;

	return if ($free_space == 0);
	if ( $free_space ) {
		for (0..$self->cols-1) {
			$self->col($_)->width(($free_space/$ratios)*$width_ratio[$_] + $min_col_widths[$_]);
		}
	} else {
		carp "Error: unable to resolve column widht, content requires more space than the table has.\n";
	}
}

sub is_last_in_row {
	my ($self, $idx) = @_;
	return ($idx == $self->cols-1); #index starts from 0
}

sub is_last_in_col {
	my ($self, $idx) = @_;
	return ($idx == $self->rows-1); #index starts from 0
}

sub cycle_background_color {
	my ($self, @colors) = @_;
	my $length = (scalar @colors);
	for (0..$self->rows-1) {
		$self->[$_]->background_color( $colors[ $_ % $length ] );
	}
	return $self;
}

1;

=head1 NAME

PDF::TableX - Moose driven table generation module that is uses famous PDF::API2

=head1 VERSION

Version 0.012


=head1 SYNOPSIS

The module provides capabilities to create tabular structures in PDF files.
It is similar to PDF::Table module, however extends its functionality adding OO
interface and allowing placement of any element inside table cell such as image,
another pdf, or nested table.

Sample usage:

	use PDF::API2;
	use PDF::TableX;

	my $pdf = PDF::API2->new();
	my $page = $pdf->page;
	my $table = PDF::TableX->new(40,40);        # create 40 x 40 table
	$table
		->padding(3)                        # set padding for cells
		->border_width(2)                   # set border width
		->border_color('blue');             # set border color
	$table->[0][0]->content("Sample text");     # place "Sample text" in cell 0,0 (first cell in first row)
	$table->[0][1]->content("Some other text"); # place "Some other text" in cell 0,1
	$table->draw($pdf, $page);                  # place table on the first page of pdf

	$pdf->saveas('some/file.pdf');

=head1 ATTRIBUTES

All attributes when set return $self allowing chaining of the calls.

=head2 Style Definitions

Following attributes take as argument either array reference with four values describing the style
in each cell side in followin order [TOP, RIGHT, BOTTOM, LEFT]. Alternatively a scalar value can be
provided in which case it is coerced to ARRAY REF

=over 4

=item * padding => [1,1,1,1]

	# set padding for all cells
	$table->padding(2);
	# the same as
	$table->paddin([2,2,2,2]);
	# set padding of the first row
	$table->[0]->padding(4);
	# set padding of the first column
	$table->col(0)->padding(4);
	# set padding of single cell
	$table->[0][0]->padding(2);

=item * border_width => [1,1,1,1]

	$table->border_width(2);
	$table->border_width([2,3,4,5]);

=item * border_color => ['black','black','black','black']

	$table->border_color('red');
	$table->border_color(['#cccccc','white','green','blue']);

=item * border_style => ['solid','solid','solid','solid']

Currently the only supported style is 'solid'.

=item * margin => [10/25.4*72,10/25.4*72,10/25.4*72,10/25.4*72]

Margin is used currently to determine the space between top and bottom of the page.

	$table->margin(20);
	$table->margin([20,10,10,2]);

=back

Following attributes require single value.

=over 4

=item * background_color => ''

	$table->background_color('blue');
		
=item * text_align => 'left'

Allowed values are: 'left', 'right', 'center', 'justify'

	# set text align in whole table
	$table->text_align('left');
	# set text align in single row
	$table->[0]->text_align('left');
	# set text align in single column
	$table->col(0)->text_align('left');

=item * font => 'Times'

Allowed values are the names of PDF::API2 corefonts: Courier, Courier-Bold, Courier-BoldOblique,
Courier-Oblique, Helvetica, Helvetica-Bold, Helvetica-BoldOblique, Helvetica-Oblique, Symbol,
Times-Bold, Times-BoldItalic, Times-Italic, Times-Roman, ZapfDingbats

	$table->font('ZapfDingbats');

=item * font_color => 'black'

	$table->font_color('green');

=item * font_size => 12
	
	$table->font_size(10);
	
=back

=head2 Placing & Behaviour

Following attributes control placing of the table and its behaviour


=over 4

=item * width - width of the table

=item * start_x - x position of the table

=item * start_y - y position of the table

=item * rows - number of table rows

=item * cols - number of table columns

=item * repeat_header - shall the header be repeated on every new page (default is 0, set 1 to repeat)

=back

=head1 METHODS

=head2 cycle_background_color

Set the background colors of rows. The method takes the list of colors and applies them to
subsequent rows. There is no limit to style e.g. only in odd/even fashio.

	# set odd and even background colors to black and white
	$table->cycle_background_color('black','white');

	# set the background color of rows to cycle with three colors: black, white, red
	$table->cycle_background_color('black','white','red');

=head2 BUILD

 TODO

=head2 add_row

 TODO

=head2 col

 TODO

=head2 draw

 TODO

=head2 is_last_in_col

 TODO

=head2 is_last_in_row

 TODO

=head2 properties

 TODO

=head1 EXTENDING THE MODULE

PDF::TableX uses Moose::Role(s) to define the styles and placing of the table. They can be 
relatively extended providing capabilites beyond those already available. Below code snipped
creates the role that uses elliptical background shape instead of rectangle.

	package EllipsedBackground;
	use Moose::Role;

	sub draw_background {
		my ($self, $x, $y, $gfx, $txt) = @_;
		$gfx->linewidth(0);
		$gfx->fillcolor('yellow');
		$gfx->ellipse($x+$self->width/2, $y-$self->height/2, $self->width/2, $self->height/2);
		$gfx->fill();
	}

	use Moose::Util qw( apply_all_roles );
	use PDF::TableX;
	use PDF::API2;

	my $table = PDF::TableX->new(2,2);
	my $pdf = PDF::API2->new();
	$pdf->mediabox('a4');

	# set some styles
	$table->padding(10)->border_width(1)->text_align('center');

	# apply moose roles to specific cells
	apply_all_roles( $table->[0][0], 'ElipsedBackground' );
	apply_all_roles( $table->[0][1], 'ElipsedBackground' );

	# set some content to those roles
	$table->[0][0]->content("Some text");
	$table->[0][1]->content("Some other text");

	# and finally draw it
	$table->draw($pdf, 1);
	# and save it
	$pdf->saveas('some/output.pdf');

=head1 AUTHOR

Grzegorz Papkala, C<< <grzegorzpapkala at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests at: L<https://github.com/grzegorzpapkala/PDF-TableX/issues>

=head1 SUPPORT

PDF::TableX is hosted on GitHub L<https://github.com/grzegorzpapkala/PDF-TableX>


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2013 Grzegorz Papkala, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut