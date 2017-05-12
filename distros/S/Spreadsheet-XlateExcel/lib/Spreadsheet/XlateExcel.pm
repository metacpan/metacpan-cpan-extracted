#
# Module.
#

package Spreadsheet::XlateExcel;

#
# Dependencies.
#

use Carp::Assert::More;
use Spreadsheet::ParseExcel;

#
# Bitch.
#

use warnings;
use strict;

#
# Documentation.
#

=head1 NAME

Spreadsheet::XlateExcel - Trigger a callback subroutine on each row of an Excel spreadsheet

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This modules triggers a callback subroutine on each row of an Excel spreadsheet.

Wrote this simple module because I was fed up from writing the same boilerplate code ever when I had to mine spreadsheets for data.

Operates on every sheet unless a given sheet is targeted by name, RE inclusion or RE exclusion.

Operates on every column unless targeted by column head name or RE (inclusion).

For example:

    use Spreadsheet::XlateExcel;

    my $id = Spreadsheet::XlateExcel->new ({ file => 'sheet.xls' });

    # rip odd rows of "Sheet2" sheet

    my $lol;

    $id->xlate ({
        on_sheet_named  => 'Sheet2',
        for_each_row_do => sub {
            my ( $sheet_id, $row, $row_vs ) = @_;

            push @$lol, $row_vs unless $row % 2;
        },
    });

=head1 METHODS

=cut

#
# Methods.
#

=head2 new

  my $id = Spreadsheet::XlateExcel->new ({ file => 'sheet.xls' [, formatter => Spreadsheet::ParseExcel::Fmt->new })

Ye constructor.

Optional formatter attribute is a Spreadsheet::ParseExcel formatter instance.
Refer to L<http://metacpan.org/module/Spreadsheet::ParseExcel#parse-filename-formatter-> for more about such formatters.

=cut

sub new {
  my ( $class, $option ) = @_;

  assert_exists      $option=>'file';
  assert_nonblank    $option->{file};
  assert_defined  -f $option->{file}, 'incoming file exists';

  bless { book_id => Spreadsheet::ParseExcel->new->parse ( $option->{file}, $option->{formatter} ) }, $class;
}

=head2 xlate

  $self->xlate ({ for_each_row_do => sub { my ( $sheet_id, $row, $row_vs ) = @_ ; ... } })

Applies C<for_each_row_do> sub to each row of each sheet (unless filtered, see below) of the book.

Options:

=over

=item *

C<on_sheet_named>: targets a given book sheet by name

=item *

C<on_sheets_like>: targets a given book sheet by RE inclusion on name

=item *

C<on_sheets_unlike>: targets a given book sheet by RE exclusion on name

=item *

C<on_columns_heads_named>: targets columns via a listref of strings

=item *

C<on_columns_heads_like>: targets columns via a listref of regular expressions

=back

Callback function gets called for each row, fed with L<Spreadsheet::ParseExcel::Worksheet> ID, row index and arrayref of row values parameters.

Returns self.

=cut

sub xlate {
  my ( $self, $option ) = @_;

  assert_exists  $option => 'for_each_row_do';

  assert_listref $option->{on_columns_heads_named} if exists $option->{on_columns_heads_named};
  assert_listref $option->{on_columns_heads_like}  if exists $option->{on_columns_heads_like};

  my $match = $option->{on_columns_heads_named} ? sub { $_[0] eq $_[1] } : sub { $_[0] =~ $_[1] };
  my $targets;
  if ( $option->{on_columns_heads_named} || $option->{on_columns_heads_like} ) {
    $targets = [ $option->{on_columns_heads_named} ? @{$option->{on_columns_heads_named}} : @{$option->{on_columns_heads_like}} ];
  }

  XLATE_LOOP : for my $sheet ( $self->book_id->worksheets ) {
    my $sheet_name = $sheet->get_name;

    next if $option->{on_sheet_named}   && $sheet_name ne $option->{on_sheet_named};
    next if $option->{on_sheets_like}   && $sheet_name !~ $option->{on_sheets_like};
    next if $option->{on_sheets_unlike} && $sheet_name =~ $option->{on_sheets_unlike};

    my ( $row_min, $row_max ) = $sheet->row_range;
    my ( $col_min, $col_max ) = $sheet->col_range;

    my @rows = $row_min .. $row_max;
    my @cols = $col_min .. $col_max;

    if ( $targets ) {
      my @matching_cols;

      for my $target ( @$targets ) {
        push @matching_cols, map { $_->[0] } grep { $match->( $_->[1]->value, $target ) } grep { defined $_->[1] } map { [ $_, $sheet->get_cell ( $row_min, $_ ) ] } @cols;
      }

      @cols = @matching_cols;
    }

    for my $row ( @rows ) {
      $option->{for_each_row_do}->( $sheet, $row, [ map { $_ ? $_->value : '' } map { $sheet->get_cell ( $row, $_ ) } @cols ] );
    }
  }

  $self;
}

=head2 book_id

  my $book_id = $self->book_id ()

Accessor to L<Spreadsheet::ParseExcel::Workbook> instance ID.

=cut

sub book_id {
  my ( $self ) = @_;

  $self->{book_id};
}

#
# Documentation.
#

=head1 AUTHOR

Xavier Caron, C<< <xav at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-spreadsheet-xlateexcel at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-XlateExcel>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spreadsheet::XlateExcel

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spreadsheet-XlateExcel>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spreadsheet-XlateExcel>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spreadsheet-XlateExcel>

=item * Search CPAN

L<http://search.cpan.org/dist/Spreadsheet-XlateExcel/>

=back

Code is available through github (L<http://github.com/maspalio/Spreadsheet-XlateExcel>).

=head1 ACKNOWLEDGEMENTS

To Kawai Takanori, Gabor Szabo and John McNamara, authors of cool L<http://search.cpan.org/dist/Spreadsheet-ParseExcel/> module.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Xavier Caron.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

#
# True.
#

1;
