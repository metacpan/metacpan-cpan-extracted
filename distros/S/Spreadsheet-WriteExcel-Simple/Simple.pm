package Spreadsheet::WriteExcel::Simple;

$VERSION = '1.04';

use strict;

use Spreadsheet::WriteExcel 0.31;
use IO::Scalar              1.126;

=head1 NAME

Spreadsheet::WriteExcel::Simple - A simple single-sheet Excel document

=head1 SYNOPSIS

  my $ss = Spreadsheet::WriteExcel::Simple->new;
     $ss->write_bold_row(\@headings);
     $ss->write_row(\@data);

  print $ss->data;
	# or
	$ss->save("filename.xls");

=head1 DESCRIPTION

This provides an abstraction to the L<Spreadsheet::WriteExcel> module
for easier creation of simple single-sheet Excel documents.

In its most basic form it provides two methods for writing data:
write_row and write_bold_row which write the data supplied to
the next row of the spreadsheet. 

However, you can also use $ss->book and $ss->sheet to get at the
underlying workbook and worksheet from Spreadsheet::WriteExcel if you
wish to manipulate these directly.

=head1 METHODS

=head2 new

  my $ss = Spreadsheet::WriteExcel::Simple->new;

Create a new single-sheet Excel document. You should not supply this
a filename or filehandle. The data is stored internally, and can be
retrieved later through the 'data' method or saved using the 'save'
method.

=cut

sub new {
  my $class = shift;
  my $self = bless {}, $class;

  my $fh = shift;
  # Store the workbook in a tied scalar filehandle
  $self->{book} = Spreadsheet::WriteExcel->new(
    IO::Scalar->new_tie(\($self->{content}))
  );
  $self->{bold} = $self->book->addformat();
  $self->{bold}->set_bold;
  $self->{sheet} = $self->book->addworksheet;
  $self->{_row} = 0;
  $self;
}

=head2 write_row / write_bold_row

  $ss->write_bold_row(\@headings);
  $ss->write_row(\@data);

These write the list of data into the next row of the spreadsheet.

Caveat: An internal counter is kept as to which row is being written
to, so if you mix these functions with direct writes of your own,
these functions will continue where they left off, not where you have
written to.

=cut

sub write_row {
  my $self = shift;
  my $dataref = shift;
  my @data = map { defined $_ ? $_ : '' } @$dataref;
  my $fmt  = shift || '';
  my $col = 0;
  my $ws = $self->sheet;
     $ws->write($self->{_row}, $col++, $_, $fmt) foreach @data;
  $self->{_row}++;
}

sub write_bold_row { $_[0]->write_row($_[1], $_[0]->_bold) }

=head2 data

  print $ss->data;

This returns the data of the spreadsheet. If you're planning to print this
to a web-browser, be sure to print an 'application/excel' header first.

=cut

sub data {
  my $self = shift;
  $self->book->close;
  return $self->{content};
}

=head2 book / sheet

  my $workbook  = $ss->book;
  my $worksheet = $ss->sheet;

These return the underlying Spreadsheet::WriteExcel objects representing
the workbook and worksheet respectively. If you find yourself making
more that a trivial amount of use of these, you probably shouldn't be
using this module, but using Spreadsheet::WriteExcel directly.

=cut

sub book  { $_[0]->{book} }
sub sheet { $_[0]->{sheet} }

sub _bold { $_[0]->{bold} }

=head2 save

	$ss->save("filename.xls");

Save the spreadsheet with the given filename.

=cut

sub save {
	my $self = shift;
	my $name = shift or die 'save() needs a file name';
	open  my $file, ">$name" or die "Could not open $name for writing: $!";
	binmode $file;
	print $file $self->data;
	close $file;
}

=head1 BUGS

This can't yet handle dates in a sensible manner.

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Spreadsheet-WriteExcel-Simple@rt.cpan.org

=head1 SEE ALSO

L<Spreadsheet::WriteExcel>. John McNamara has done a great job with
this module.

=head1 COPYRIGHT

Copyright (C) 2001-2005 Tony Bowden. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

