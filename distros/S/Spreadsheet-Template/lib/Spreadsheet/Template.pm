package Spreadsheet::Template;
our $AUTHORITY = 'cpan:DOY';
$Spreadsheet::Template::VERSION = '0.05';
use Moose;
# ABSTRACT: generate spreadsheets from a template

use Class::Load 'load_class';
use JSON;



has processor_class => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Spreadsheet::Template::Processor::Xslate',
);


has processor_options => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);


has writer_class => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Spreadsheet::Template::Writer::XLSX',
);


has writer_options => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has _processor => (
    is      => 'ro',
    does    => 'Spreadsheet::Template::Processor',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $class = $self->processor_class;
        load_class($class);
        return $class->new($self->processor_options);
    },
);


has json => (
    is => 'ro',
    default => sub {
        return JSON->new;
    }
);

sub _writer {
    my $self = shift;
    my $class = $self->writer_class;
    load_class($class);
    return $class->new($self->writer_options);
}


sub render {
    my $self = shift;
    my ($template, $vars) = @_;
    my $contents = $self->_processor->process($template, $vars);
    # not decode_json, since we expect that we are already being handed a
    # character string (decode_json also decodes utf8)
    my $data = $self->json->decode($contents);
    return $self->_writer->write($data);
}

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Template - generate spreadsheets from a template

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use Spreadsheet::Template;

  my $template = Spreadsheet::Template->new;
  my $in = do { local $/; <> };
  my $out = $template->render($in);
  open my $fh, '>', 'out.xlsx';
  binmode $fh;
  $fh->print($out);
  $fh->close;

=head1 DESCRIPTION

This module is used to render spreadsheets from JSON files which describe the
desired content and formatting. These JSON files can be preprocessed with a
template engine such as L<Text::Xslate> in order to customize the spreadsheet
contents before generation, in a similar way to how HTML pages can be rendered
with templates.

The typical workflow for using this module is to create a sample spreadsheet in
Excel with the desired layout and formatting, and use
L<Spreadsheet::Template::Generator> (or the included C<spreadsheet_to_template>
script) to generate a base template. That base template can then be edited
to add in template declarations, and then this module can be used to generate
new spreadsheets based on the template.

=head1 ATTRIBUTES

=head2 processor_class

Name of the L<Spreadsheet::Template::Processor> class to use to preprocess the
template. Defaults to L<Spreadsheet::Template::Processor::Xslate>.

=head2 processor_options

Arguments to pass to the C<processor_class> constructor.

=head2 writer_class

Name of the L<Spreadsheet::Template::Writer> class to use to preprocess the
template. Defaults to L<Spreadsheet::Template::Writer::XLSX>.

=head2 writer_options

Arguments to pass to the C<writer_class> constructor.

=head2 json

Instance of a JSON class that will handle decoding. Defaults to an instance of L<JSON>.
Passing in a JSON obj with ->relaxed(1) set will allow for trailing commas in your templates.

=head1 METHODS

=head2 render($template, $vars)

Calls C<process> on the L<Spreadsheet::Template::Processor> instance with
C<$template> and C<$vars> as arguments, decodes the result as JSON, and returns
the result of passing that data to the C<write> method of the
L<Spreadsheet::Template::Writer> instance.

=head1 DATA FORMAT

The intermediate data format that should be produced after the template has
been preprocessed is a JSON file, with a structure that looks like this:

  {
     "selection" : 0,
     "worksheets" : [
        {
           "column_widths" : [ 10, 10, 10 ],
           "name"          : "Sheet1",
           "row_heights"   : [ 18, 18, 18 ],
           "selection"     : [ 0, 0 ],
           "autofilter"    : [
               [ [0, 0], [0, 2] ]
           ],
           "cells"         : [
              [
                 {
                    "contents" : "This is cell A1",
                    "format"   : {
                       "color" : "#000000",
                       "size" : 14,
                       "text_wrap" : true,
                       "valign" : "vcenter"
                    },
                    "type"     : "string"
                 },
                 {
                    "contents" : "3.25",
                    "format"   : {
                       "color" : "#000000",
                       "num_format" : "\"$\"#,##0.00_);[Red]\\(\"$\"#,##0.00\\)",
                       "size" : 14
                    },
                    "type"     : "number"
                 }
              ],
              [
                 {
                    "contents" : "2013-03-20T00:00:00",
                    "format"   : {
                       "color" : "#000000",
                       "align" : "center",
                       "num_format" : "d-mmm",
                       "size" : 14,
                       "border_color" : [
                          "#000000",
                          "#000000",
                          "#000000",
                          "#000000"
                       ],
                       "border" : [
                          "thin",
                          "thin",
                          "thin",
                          "thin"
                       ]
                    },
                    "type"     : "date_time"
                 },
                 {
                    "contents" : "3.25",
                    "formula"  : "SUM(B1:B1)",
                    "format"   : {
                       "bg_color" : "#d8d8d8",
                       "bold" : true,
                       "color" : "#000000",
                       "num_format" : "\"$\"#,##0.00_);[Red]\\(\"$\"#,##0.00\\)",
                       "pattern" : "solid",
                       "size" : 14
                    },
                    "type"     : "string"
                 }
              ]
           ],
           "merge" : [
              {
                  "range"    : [ [1, 0], [1, 2] ],
                  "contents" : "Merged Contents",
                  "format"   : {
                      "color" : "#000000"
                  },
                  "type"     : "string"
              }
           ]
        }
     ]
  }

=head2 workbook

The entire JSON document describes a workbook to be produced. The document
should be a JSON object with these keys:

=over 4

=item selection

The (zero-based) index of the worksheet to be initially selected when the
spreadsheet is opened.

=item worksheets

An array of worksheet objects.

=back

=head2 worksheet

Each element of the C<worksheets> array in the workbook object should be a JSON
object with these keys:

=over 4

=item name

The name of the worksheet.

=item column_widths

An array of numbers corresponding to the widths of the columns in the
spreadsheet.

=item row_heights

An array of numbers corresponding to the heights of the rows in the
spreadsheet.

=item selection

An array of two numbers corresponding to the (zero-based) row and column of the
cell that should be selected when the worksheet is first displayed.

=item autofilter

Enables autofilter behavior for each range of cells listed. Cell ranges are
specified by an array of two arrays of two numbers, corresponding to the row
and column of the top left and bottom right cell of the autofiltered range.

=item cells

An array of arrays of cell objects. Each innermost array represents a row,
containing all of the cell data for that row.

=item merge

An array of merge objects. Merge objects are identical to cell objects, except
that they contain an additional C<range> key, which has a value of an array of
two arrays of two numbers, corresponding to the row and column of the top left
and bottom right cell of the range to be merged.

=back

=head2 cell

Each element of the two-dimensional C<cells> array in a worksheet object should
be a JSON object with these keys:

=over 4

=item contents

The unformatted contents of the cell. For cells with a C<type> of C<string>,
this should be a string, for cells with a C<type> of C<number>, this should be
a number, and for cells with a C<type> of C<date_time>, this should be a string
containing the ISO8601 representation of the date and time.

=item format

The format object describing how the cell's contents should be formatted.

=item type

The type of the data in the cell. Can be either C<string>, C<number>, or
C<date_time>.

=item formula

The formula used to calculate the cell contents. This field is optional. If you
want the generated spreadsheet to be able to be read by programs other than
full spreadsheet applications (such as by L<Spreadsheet::Template::Generator>,
then you should ensure that you include an accurate value for C<contents> as
well, since most simple spreadsheet parsers don't include a full formula
calculation engine.

=back

=head2 format

Each cell object contains a C<format> key whose value should be a JSON object
with these (all optional) keys:

=over 4

=item size

The font size for the cell contents.

=item color

The font color for the cell contents.

=item bold

True if the cell contents are bold.

=item italic

True if the cell contents are italic.

=item pattern

The background pattern for the cell. Can have any of these values (with
C<none> being the default if nothing is specified):

  none
  solid
  medium_gray
  dark_gray
  light_gray
  dark_horizontal
  dark_vertical
  dark_down
  dark_up
  dark_grid
  dark_trellis
  light_horizontal
  light_vertical
  light_down
  light_up
  light_grid
  light_trellis
  gray_125
  gray_0625

=item bg_color

The background color for the cell. Only has meaning if a C<pattern> other than
C<none> is chosen.

=item fg_color

The foreground color for the cell. Only has meaning if a C<pattern> other than
C<none> or C<solid> is chosen.

=item border

The border style for the cell. This should be an array with four elements,
corresponding to the left, right, top, and bottom borders. Each element can
have any of these values (with C<none> being the default if nothing is
specified):

  none
  thin
  medium
  dashed
  dotted
  thick
  double
  hair
  medium_dashed
  dash_dot
  medium_dash_dot
  dash_dot_dot
  medium_dash_dot_dot
  slant_dash_dot

=item border_color

The border color for the cell. This should be an array with four elements,
corresponding to the left, right, top, and bottom borders.

=item align

The horizontal alignment for the cell contents. Can have any of these values,
with C<none> being the default:

  none
  left
  center
  right
  fill
  justify
  center_across

=item valign

The vertical alignment for the cell contents. Can have any of these values,
with C<bottom> being the default:

  top
  vcenter
  bottom
  vjustify

=item text_wrap

True if the contents of the cell should be text-wrapped.

=item num_format

The numeric format for the cell. Only meaningful if the cell's type is
C<number> or C<date_time>. This is the string representation of the format as
understood by Excel itself.

=back

=head1 BUGS

=over 4

=item *

Default values aren't handled properly - spreadsheets can set defaults for
things like font sizes, but this isn't actually handled, so cells that are
supposed to use the default may get an incorrect value.

=back

Please report any bugs to GitHub Issues at
L<https://github.com/doy/spreadsheet-template/issues>.

=head1 SEE ALSO

L<Excel::Template>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Spreadsheet::Template

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Spreadsheet-Template>

=item * Github

L<https://github.com/doy/spreadsheet-template>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spreadsheet-Template>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spreadsheet-Template>

=back

=head1 SPONSORS

Parts of this code were paid for by

=over 4

=item Socialflow L<http://socialflow.com>

=back

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
