package PostScript::LabelSheet;

use warnings;
use strict;

use parent qw/ Class::Accessor /; 
use Carp;
use File::Basename qw/ dirname /;
use Template;

our $VERSION = 0.02;

__PACKAGE__->mk_accessors(qw/
    columns rows
    label_width label_height
    width height
    v_margin h_margin
    v_spacing h_spacing
    v_padding h_padding
    skip fill_last_page grid
    labels
    postscript_skeleton
    portrait
    /
);

sub set {
    my $self = shift;
    $self->SUPER::set(@_);
    return $self;
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # Default values
    $self->width(595)        unless defined $self->width();          # 210 mm (a4)
    $self->height(842)       unless defined $self->height();         # 297 mm (a4)
    $self->v_margin(14.17)   unless defined $self->v_margin();       # 5 mm
    $self->h_margin(14.17)   unless defined $self->h_margin();       # 5 mm
    $self->v_spacing(0)      unless defined $self->v_spacing();
    $self->h_spacing(0)      unless defined $self->h_spacing();
    $self->v_padding(0)      unless defined $self->v_padding();
    $self->h_padding(0)      unless defined $self->h_padding();
    $self->skip(0)           unless defined $self->skip();
    $self->fill_last_page(1) unless defined $self->fill_last_page();
    $self->grid(1)           unless defined $self->grid();
    $self->portrait(1)       unless defined $self->portrait();
    return $self;
}

sub label_height {
    my $self = shift;
    if ( @_ ) {
        $self->_rows_accessor(undef);
    }
    elsif ( !defined $self->_label_height_accessor() ) {
        $self->_label_height_accessor(
             ($self->height() - $self->v_margin() * 2 + $self->v_spacing()) / $self->rows() - $self->v_spacing()
        );
    }
    $self->_label_height_accessor(@_);
}

sub label_width {
    my $self = shift;
    if ( @_ ) {
        $self->_columns_accessor(undef);
    }
    elsif ( !defined $self->_label_width_accessor() ) {
        $self->_label_width_accessor(
             ($self->width() - $self->h_margin() * 2 + $self->h_spacing()) / $self->columns() - $self->h_spacing()
        );
    }
    $self->_label_width_accessor(@_);
}

sub rows {
    my $self = shift;
    if ( @_ ) {
        $self->_label_height_accessor(undef);
    }
    elsif ( !defined $self->_rows_accessor() ) {
        $self->_rows_accessor(
            int(($self->height() - $self->v_margin() * 2 + $self->v_spacing()) / ($self->label_height() + $self->v_spacing()))
        );
    }
    $self->_rows_accessor(@_);
}

sub columns {
    my $self = shift;
    if ( @_ ) {
        $self->_label_width_accessor(undef);
    }
    elsif ( !defined $self->_columns_accessor() ) {
        $self->_columns_accessor(
            int(($self->width() - $self->h_margin() * 2 + $self->h_spacing()) / ($self->label_width() + $self->h_spacing()))
        );
    }
    $self->_columns_accessor(@_);
}

sub _parse_eps_file {
    my ($self, $filename) = @_;

    open my $eps_fh, '<', $filename
        or croak "Cannot read $filename: $!";
    my %record = ( path => $filename );
    my $buffer = '';
    while ( <$eps_fh> ) {
        @record{map "eps_bb_$_", qw/ ll_x ll_y ur_x ur_y/} = /(\d+)/g if /%%BoundingBox/;
        $buffer .= $_;
    }
    close $eps_fh;
    $record{code} = $buffer;
    if (   !$record{eps_bb_ll_x}
        && !$record{eps_bb_ll_y}
        && !$record{eps_bb_ur_x}
        && !$record{eps_bb_ur_y} ) {
        croak "No bounding box info found in $filename"
    }
    return \%record;
}

sub add {
    my $self = shift;
    my ($eps, $count) = @_;
    $count ||= 1;
    my $label_aref = $self->labels || [];
    my $eps_record = $self->_parse_eps_file($eps);
    $eps_record->{count} = $count;
    push @$label_aref, $eps_record;

    $self->labels($label_aref);
}

sub _make_h_and_v_setter {
    my $setting_name = shift;
    my $v_accessor = "v_$setting_name";
    my $h_accessor = "h_$setting_name";
    no strict 'refs';
    *$setting_name = sub {
        my $self = shift;
        if ( @_ ) {
            $self->$v_accessor(@_);
            $self->$h_accessor(@_);
            return $self;
        }
        else {
            return $self->$h_accessor();
        }
    }
}
_make_h_and_v_setter('margin');
_make_h_and_v_setter('spacing');
_make_h_and_v_setter('padding');

sub _install_dir {
    (my $module = __PACKAGE__ ) =~ s|::|/|g;
    return dirname( $INC{"$module.pm"} );
}

sub count_labels_per_page {
    my $self = shift;
    return $self->columns() * $self->rows();
}

sub count_labels {
    my $self = shift;
    my $count = 0;
    foreach ( @{$self->labels} ) {
        $count += $_->{count};
    }
    return $count;
}

sub _stretch_last_label {
    my $self = shift;
    my $rest = ( $self->count_labels() + $self->skip() ) % $self->count_labels_per_page();
    $self->labels()->[-1]{count} += $self->count_labels_per_page() - $rest;
}

sub _finalize {
    my $self = shift;
    if ( $self->fill_last_page() ) {
        $self->_stretch_last_label();
    }
}

sub as_postscript {
    my $self = shift;
    my $template = $self->postscript_skeleton() || $self->_install_dir() . '/LabelSheet/LabelSheet.ps';
    my $buffer = '';

    $self->_finalize();
    
    my $tt = new Template { ABSOLUTE => 1 };
    $tt->process($template, { sheet => $self }, \$buffer);
    return $buffer;
}

=head1 NAME

PostScript::LabelSheet - print multiple labels on a sheet, starting from PostScript label template.

=head1 SYNOPSIS

    use PostScript::LabelSheet;

    my $sheet = new PostScript::LabelSheet;
    
    $sheet->columns(3); # 3 labels abreast
    $sheet->rows(10);   # on 10 rows
    # Or specify the dimensions of the labels, in PostScript points
    # $sheet->label_width(...); $sheet->label_height(...);

    $sheet->skip(5); # leave 5 labels blank

    $sheet->add('/path/to/label_1.eps', 5);
    $sheet->add('/path/to/label_2.eps', 3);
    $sheet->add('/path/to/label_3.eps');
    $sheet->fill_last_page(1); # label_3 will fill the last sheet.

    print $sheet->as_postscript();

=head1 DESCRIPTION

=head2 Why this module?

I sometimes have to print a sheet of labels, each label bearing the same
design, for example to label jars of marmelade. I tried to do this with
OpenOffice.org writer, in a table. But I had to manually copy and paste the
design of the first label into every cell, and of course, if I changed the
design, the changes had to be reported manually to the other cells. And of
course, changing the dimensions, or adding a column or a row, need some manual
intervention.

This module is here to easily print a sheet (or sheets) of labels representing
a repeating pattern. Give it a design in Encapsulated PostScript (EPS), how
many labels you want, how big they should be or how many should fit in the
width and heigth of the page, and PostScript::LabelSheet generates the
PostScript code for you, which you can then directly print.

There are options to print several kinds of labels on the same sheet, each with
its own design, to draw a grid around the labels for cutting them, and to
control how they are laid out on the page.

Additionally, labels can be numbered. This can be useful to print numbered
tickets for a local event for instance.

=head2 Drawing the design

Use inkscape (http://www.inkscape.org) to draw the design that you want to
print on each label. Keep the original in the SVG format, and export it as
Encapsulated PostScript for use with PostScript::LabelSheet.

The size of the design is unimportant, as this is vector graphics, the
generated PostScript program will resize without losing quality so that it fits
within a label. What is important, however, is that the design occupies all the
space on the page. The easiest is to draw without giving any thought to the
page, then adjust the page size to the drawing.  In inkscape, you can use the
Document Properties dialog box to let the page fit the design exactly (menu
File, Document Properties, in the Page tab, click the "Fit page to selection"
button).

To save the design in EPS format, in inkscape, go to menu File, Save a copy,
and choose the "C<Encapsulated PostScript (*.eps)>" format. Inkscape will show
a dialog with options for the conversion to EPS. Do check the box "Make
bounding box around full page", so that the generated EPS code contains
information about the size of the design. PostScript::LabelSheet needs it to
work out the scale at which the design should be included on the page.

=head2 Constructor

=over 4

=item B<new>

Returns a new instance of PostScript::LabelSheet with all its attributes set to
the built-in default values.

=back

=head2 Accessors / Mutators

The following methods are accessors when given no argument, and mutators when
given one. As accessor they return the corresponding attribute's value:

    print $sheet->width();

As mutators, they set the attribute's value, and return the
PostScript::LabelSheet instance itself, making it possible to stack several
calls to mutators:

    my $sheet = PostScript::LabelSheet->new()
        ->width(595)
        ->height(842)
        ->grid(0)
        ;

=head2 Labels management

=over 4

=item B<columns>

=item B<rows>

Give the number of columns and rows in which the labels should be laid out on
each page. The labels width and height will be calculated accordingly.

=item B<label_width>

=item B<label_height>

Give the width and height of each label. The program will automatically
calculate how many labels will fit on each row and column.

Either columns() or label_width(), and either row() or label_height(), must be
specified before invoking as_postscript().

=item B<fill_last_page> (defaults to true)

Set this option to a true value to have the last label repeat until the end of
the last page.

=back

=head2 Layout

=over 4

=item B<width>

=item B<height>

Dimensions of the page. Default to DIN A4 (S<< 210 E<times> 297 mm >>).

=item B<h_margin>

=item B<v_margin>

Vertical (top and bottom) and horizontal (left and right) margins.
Default to S<5 mm>.
Use margin() to set both v_margin() and h_margin() at the same time.
It is not possible to set the top margin independantly from the bottom
margin, nor the left margin independantly from the right one.

=item B<h_padding>

=item B<v_padding>

Space left blank inside each label and around the design within.
Default to 0.
Use padding() to set both h_padding() and v_padding() at the same time.

=item B<h_spacing>

=item B<v_spacing>

Space between columns (h_spacing()) or rows (v_spacing()) of labels.
Default to 0 (no space between rows and columns).
Use spacing() to set both h_spacing() and v_spacing() at the same time.

=item B<skip>

Number of labels to leave blank at the top of the first page. The default is to
start at the top left of the page.

=item B<portrait>

If set to a true value, the designs are rotated 90 degrees clockwise inside
each label. Default to false.

=item B<grid>

If set to a true value, a grid is drawn around the labels. This is the default.

=back

=head2 Miscellaneous

=over 4

=item B<postscript_skeleton>

=item B<labels>

=back

=head2 Methods

=over 4

=item B<add> I<PATH>, I<COUNT>

Adds a design to the sheet of labels. I<PATH> is the path to a file in the
Encapsulated PostScript format. See the L<Drawing the design> section above for
hints on how to make such a file. I<COUNT> is optional and defaults to 1.
However, it fill_last_page() is set to a true value, the last design will be
repeated until the end of the last page.

Returns the instance of the PostScript::LabelSheet object, so calls can be
stacked:

    $sheet->add('file1.eps', 5)
          ->add('file2.eps', 6)
          ->add('file3.eps', 4)
          ;

=item B<count_labels_per_page>

Returns the number labels that would fit on a page.

=item B<count_labels>

Returns the number of labels printed on all the pages. If fill_last_page() is
set to a true value, this might not reflect the number of labels actually
printed, as the last one will be printed multiple times. The number will be
accurate after the PostScript has been generated in a call to as_postscript(),
as the count property of the last design will be adjusted at that moment.

=item B<set> I<NAME>, I<VALUE>

A rewrite of Class::Accessor's set() mutator, that returns the instance of the
object, instead of the value.

=item B<margin> I<SIZE>

=item B<padding> I<SIZE>

=item B<spacing> I<SIZE>

Sets both h_margin() and v_margin() to I<SIZE> at the same time, and
respectively for h_padding() and v_padding(), and for h_spacing() and
v_spacing().

=item B<as_postscript>

Returns the PostScript code that prints the labels. It can be sent directly to
a printer spool, or converted to PDF, or whatever you can do with PostScript.

=back

=head1 AUTHOR

Cédric Bouvier, C<< <cbouvi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-postscript-labelsheet at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PostScript-LabelSheet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PostScript::LabelSheet


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PostScript-LabelSheet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PostScript-LabelSheet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PostScript-LabelSheet>

=item * Search CPAN

L<http://search.cpan.org/dist/PostScript-LabelSheet/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cédric Bouvier.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of PostScript::LabelSheet
