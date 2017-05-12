package Spreadsheet::ParseExcel::Stream::XLSX;

use strict;
use warnings;

our $VERSION = '0.11';

sub new {
  my ($class, $file, $opts) = @_;
  $opts ||= {};
  my @converter = $opts->{Converter} ? $opts->{Converter} : ();
  require Spreadsheet::XLSX;
  # Silence warnings in XLSX library
  my $xls = do {
    local $SIG{__WARN__} = sub {};
    Spreadsheet::XLSX->new($file, @converter);
  };
  my @sheets = @{$xls->{Worksheet}};
  bless {
    XLS    => $xls,
    SHEETS => \@sheets,
    ROWS   => [],
  }, $class;
}

sub workbook { $_[0]{XLS} }
sub worksheet { $_[0]{CURR_SHEET}{SHEET} }

sub sheet {
  my $self = shift;
  my $sheet = shift @{$self->{SHEETS}} or return;
  my $min_row = $sheet->{MinRow};
  my $max_row = $sheet->{MaxRow} || $min_row;
  my $min_col = $sheet->{MinCol};
  my $max_col = $sheet->{MaxCol} || $min_col;
  $self->{CURR_SHEET} = {
    SHEET   => $sheet,
    MAX_ROW => $max_row,
    MAX_COL => $max_col,
    CURR_ROW => $min_row,
  };
  return $self;
}

sub name { $_[0]->{CURR_SHEET}{SHEET}{Name} }

sub row {
  my ( $self, $prev_row, $cell_func ) = @_;

  # Default to formatted value
  $cell_func ||= sub { $_[0]->value() };

  my $curr_sheet_data = $self->{CURR_SHEET};
  my $offset = $prev_row ? 1 : 0;
  my $row = $curr_sheet_data->{CURR_ROW} - $offset;
  return if $row > $curr_sheet_data->{MAX_ROW};
  my $sheet = $curr_sheet_data->{SHEET};
  
  my $row_data = $sheet->{Cells}[$row];
  my @data = map {
    defined($row_data->[$_]) ? $cell_func->($row_data->[$_]) : ''
  } 0..$curr_sheet_data->{MAX_COL};
  $curr_sheet_data->{CURR_ROW}++ unless $prev_row;
  if ( $self->{BIND} ) {
    $$_ = shift @data for @{$self->{BIND}};
    return 1;
  }
  return \@data;
}

sub unformatted {
  my ( $self, $prev_row ) = @_;
  $self->row($prev_row, sub { $_[0]->unformatted() } );
}

sub next_row {
  my ( $self, $prev_row ) = @_;
  $self->row($prev_row, sub { $_[0] } );
}

sub bind_columns {
  my $self = shift;
  $self->{BIND} = [ @_ ];
}

sub unbind_columns {
  delete $_[0]->{BIND};
}

1;

__END__

=head1 NAME

Spreadsheet::ParseExcel::Stream::XLSX - Simple interface to XLSX Excel data

=head1 SYNOPSIS

  my $xls = Spreadsheet::ParseExcel::Stream::XLSX->new($xlsx_file, \%options);
  while ( my $sheet = $xls->sheet() ) {
    while ( my $row = $sheet->row ) {
      my @data = @$row;
    }
  }

=head1 DESCRIPTION

See L<Spreadsheet::ParseExcel::Stream>.

=head1 AUTHOR

Douglas Wilson, E<lt>dougw@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
