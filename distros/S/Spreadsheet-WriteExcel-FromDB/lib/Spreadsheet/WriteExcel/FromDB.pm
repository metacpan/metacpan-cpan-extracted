package Spreadsheet::WriteExcel::FromDB;

$VERSION = '1.00';

use strict;

use Spreadsheet::WriteExcel::Simple 1.03;

sub _croak { require Carp; Carp::croak(@_) }

=head1 NAME

Spreadsheet::WriteExcel::FromDB - Convert a database table to an Excel spreadsheet

=head1 SYNOPSIS

  use Spreadsheet::WriteExcel::FromDB;

  my $dbh = DBI->connect(...);

  my $ss = Spreadsheet::WriteExcel::FromDB->read($dbh, $table_name);
  $ss->ignore_columns(qw/foo bar/); 
  # or
  $ss->include_columns(qw/foo bar/); 

  $ss->restrict_rows('age > 10');

  print $ss->as_xls;
  # or
	$ss->write_xls('spreadsheet.xls');

=head1 DESCRIPTION

This module exports a database table as an Excel Spreadsheet.

The data is not returned in any particular order, as it is a simple
task to perform this in Excel. However, you may choose to ignore certain
columns, using the 'ignore_columns' method.

=head1 METHODS

=head2 read

Creates a spreadsheet object from a database handle and a table name.

=cut

sub read {
  my $class = shift;
  my $dbh   = shift or _croak "Need a dbh";
  my $table = shift or _croak "Need a table";
  bless {
    _table           => $table,
    _dbh             => $dbh,
    _where           => "",
    _ignore_columns  => [],
    _include_columns => [],
  }, $class;
}

=head2 dbh / table

Accessor / mutator methods for the database handle and table name.

=cut

sub dbh {
  my $self = shift;
  $self->{_dbh} = shift if $_[0];
  $self->{_dbh};
}

sub table {
  my $self = shift;
  $self->{_table} = shift if $_[0];
  $self->{_table};
}

=head2 restrict_rows

  $ss->restrict_rows('age > 10');

An optional 'WHERE' clause for restricting the rows returned from the
database.

=cut

sub restrict_rows {
  my $self = shift;
  $self->{_where} = shift if $_[0];
  $self->{_where};
}

=head2 ignore_columns

  $ss->ignore_columns(qw/foo bar/);

Output all columns, except these ones, to the spreadsheet.

=cut

sub ignore_columns {
  my $self = shift;
  $self->{_ignore_columns} = [ @_ ];
}

=head2 include_columns

  $ss->include_columns(qw/foo bar/);

Only include these columns into the spreadsheet.

=cut

sub include_columns {
  my $self = shift;
  $self->{_include_columns} = [ @_ ];
}

=head2 as_xls

  print $ss->as_xls;

Return the table as an Excel spreadsheet.

=cut

sub as_xls { 
	shift->_xls->data;
}

sub _xls {
  my $self  = shift;
	$self->{_xls} ||= do { 
		my $ss = Spreadsheet::WriteExcel::Simple->new;
		$ss->write_bold_row([$self->_columns_wanted]);
		$ss->write_row($_) for @{$self->dbh->selectall_arrayref($self->_data_query)};
		$ss;
	};
}

=head2 write_xls

	$ss->write_xls('spreadsheet.xls');

Write the table to a spreadsheet with the given filename.

=cut

sub write_xls { 
	my ($self, $filename) = @_;
	$self->_xls->save($filename);
}

sub _data_query {
  my $self   = shift;
  my $query = sprintf 'SELECT %s FROM %s',
    (join ', ', $self->_columns_wanted), $self->table;
  $query .= " WHERE " . $self->restrict_rows if $self->restrict_rows;
  return $query;
}

sub _columns_wanted {
  my $self = shift;
	my @include = @{$self->{_include_columns}};
	@include = $self->_columns_in_table unless @include;
  my %ignore_columns = map { $_ => 1 } @{$self->{_ignore_columns}};
  return grep !$ignore_columns{$_}, $self->_columns_in_table;
}

sub _columns_in_table {
  my $self = shift;
	my $query = sprintf "SELECT * FROM %s WHERE 1 = 0", $self->table;
	(my $sth = $self->dbh->prepare($query))->execute;
	my @cols = @{$sth->{NAME}};
	$sth->finish;
	return @cols;
}

=head1 BUGS

Dates are handled as strings, rather than dates.

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Spreadsheet-WriteExcel-Simple@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2001-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Spreadsheet::WriteExcel::Simple>. L<Spreadsheet::WriteExcel>. L<DBI>

=cut

1;

