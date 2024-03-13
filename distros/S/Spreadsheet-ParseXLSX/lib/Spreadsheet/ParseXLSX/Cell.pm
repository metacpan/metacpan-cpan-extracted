package Spreadsheet::ParseXLSX::Cell;

use strict;
use warnings;

our $VERSION = '0.34'; # VERSION

# ABSTRACT: wrapper class around L<Spreadsheet::ParseExcel::Cell>

use Spreadsheet::ParseXLSX ();
use base 'Spreadsheet::ParseExcel::Cell';



sub is_merged {
  my ($self, $sheet, $row, $col) = @_;

  return $self->{Merged} if defined $self->{Merged};

  $sheet //= $Spreadsheet::ParseXLSX::Worksheet::_registry{$self->{Sheet}};
  $row //= $self->{Row};
  $col //= $self->{Col};

  return unless defined $sheet && defined $row && defined $col;

  return $self->{Merged} = Spreadsheet::ParseXLSX::_is_merged(undef, $sheet, $row, $col);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::ParseXLSX::Cell - wrapper class around L<Spreadsheet::ParseExcel::Cell>

=head1 VERSION

version 0.34

=head1 SYNOPSIS

  use Spreadsheet::ParseXLSX::Cell;

  my $cell = Spreadsheet::ParseXLSX::Cell->new(
    Sheet => $sheet,
    Row => $row,
    Col => $row,
    ...
  );

  my $isMerged = $cell->is_merged();
  # see Spreadsheet::ParseExcel::Cell for further documentation

=head1 METHODS

=head2 is_merged($sheet, $row, $col)

Returns true if the cell is merged being part of the given sheet, located at
the given row and column. Returns undef if the current cell is not connected to
any sheet:

C<$sheet> defaults to the cell's C<{Sheet}> property,
C<$row> to C<{Row}> and
C<$col> to the C<{Col}>.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
