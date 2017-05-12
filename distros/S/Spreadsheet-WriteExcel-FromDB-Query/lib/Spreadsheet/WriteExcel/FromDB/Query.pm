package Spreadsheet::WriteExcel::FromDB::Query;

$VERSION = '0.01';

use strict;
use warnings;

use Spreadsheet::WriteExcel::FromDB;

sub _croak { require Carp; Carp::croak(@_) }

# 2 functions are redefined.  Stop the warnings for redefine.
no warnings 'redefine';

=head1 NAME

Spreadsheet::WriteExcel::FromDB::Query - Convert a database query to an Excel spreadsheet

=head1 SYNOPSIS

  use Spreadsheet::WriteExcel::FromDB::Query;

  my $dbh = DBI->connect(...);

  $query = q{select user from users};
  my $ss = Spreadsheet::WriteExcel::FromDB->read($dbh, $query);

  print $ss->as_xls;
  # or
	$ss->write_xls('spreadsheet.xls');

=head1 DESCRIPTION

This module exports a database query as an Excel Spreadsheet.  It functions
very similar to Spreadsheet::WriteExcel::FromDB, except that it forms the
Excel spreadsheet from a query instead of an entire table.

=head1 METHODS

=head2 _data_query

Returns the query directly to Spreadsheet::WriteExcel::FromDB

=cut

# Redefine _data_query
undef &_data_query;
*Spreadsheet::WriteExcel::FromDB::_data_query = \&Spreadsheet::WriteExcel::FromDB::_data_query;

# Redefined _data_query function
sub Spreadsheet::WriteExcel::FromDB::_data_query {
  my $self   = shift;
  my $query = $self->table;
  return $query;
};

=head2 _columns_in_table

Returns the columns from the query directly to Spreadsheet::WriteExcel::FromDB

=cut

# Redefine _columns_in_table
undef &_data_query;
*Spreadsheet::WriteExcel::FromDB::_columns_in_table = \&Spreadsheet::WriteExcel::FromDB::_columns_in_table;

# Redefined _columns_in_table function
sub Spreadsheet::WriteExcel::FromDB::_columns_in_table {
  my $self = shift;
	my $query = $self->table;
	(my $sth = $self->dbh->prepare($query))->execute;
	my @cols = @{$sth->{NAME}};
	$sth->finish;
	return @cols;
}

1;


=head1 BUGS

The same bugs that apply to Spreadsheet::WriteExcel::FromDB also apply to 
Spreadsheet::WriteExcel::FromDB::Query.  Dates are handled as strings, rather than dates.

=head1 AUTHOR

Christopher Kois, <cpkois@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) May, 2006 Christopher Kois.

This module is Copyright (c) 2006 by Christopher Kois. http://www.christopherkois.com
All rights reserved.  You may distribute this module under the terms of GNU General Public 
License (GPL). 

The Spreadsheet::WriteExcel::FromDB::Query is a subclass derived from the Spreadsheet::WriteExcel::FromDB
module, Copyright (C) 2001-2005 by Tony Bowden.  
  
Module Copyrights:
  - The Spreadsheet::WriteExcel::FromDB module is Copyright © 2001-2005, Tony Bowden.  
    Available at: http://search.cpan.org/~tmtm/Spreadsheet-WriteExcel-FromDB-1.00/lib/Spreadsheet/WriteExcel/FromDB.pm
  - The Spreadsheet::WriteExcel::Simple module is Copyright © 2001-2005, Tony Bowden.  
    Available at: http://search.cpan.org/~tmtm/Spreadsheet-WriteExcel-Simple-1.04/Simple.pm

=head1 SUPPORT/WARRANTY

Spreadsheet::WriteExcel::FromDB::Query is free Open Source software. 
IT COMES WITHOUT WARRANTY OR SUPPORT OF ANY KIND.

		
=head1 SEE ALSO

L<Spreadsheet::WriteExcel::FromDB>. L<Spreadsheet::WriteExcel::Simple>. L<Spreadsheet::WriteExcel>. L<DBI>

=cut

1;

