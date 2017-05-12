package Spreadsheet::ExcelHashTable;
use 5.006;
use strict;
use warnings;
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;
use Tie::IxHash;

=head1 NAME

	Spreadsheet::ExcelHashTable - Converts Excel Table to Perl Hash and vicerversa 

=head1 VERSION

	Version 0.02

=cut

our $VERSION = '0.02';


sub new {
	my $class =  shift;
	my $self = {
	excel_hash => {},
	excel_file => '',
	excel_sheet => '',
	};
	bless ( $self, $class);
	tie %{$self->{excel_hash}}, "Tie::IxHash";
	$self->{excel_file} = shift if(@_);
	my $parser = Spreadsheet::ParseExcel->new();
	$self->{excel_obj} = $parser->parse($self->{excel_file});
	return $self;
}

sub set_read_xls {
	my $self = shift;
	$self->{excel_file} = shift ;
	my $parser = Spreadsheet::ParseExcel->new();
	$self->{excel_obj} = $parser->parse($self->{excel_file});
}

sub parse_table {
	my $self = shift;
	my $sheet = shift;
	my $var = shift;
	$self->{excel_sheet} = $sheet;
	$self->{sheet_obj} = $self->{excel_obj}->worksheet($sheet);
	$self->{table_name} = $var;
	if ($self->excel_checker()) {  $self->error(); die;   }
	my $cell_info = $self->_search_var($var);
	if ( ! exists $self->{excel_hash}->{$var} ) { $self->{excel_hash}->{$var} = {}; }
	my ($row_v, $col_v) = split " ", $cell_info;
	my $row_v_max = $self->_get_table_row_max($row_v, $col_v);
	my $col_v_max = $self->_get_table_col_max($row_v, $col_v);
	$self->_get_table_hash($row_v, $col_v, $row_v_max, $col_v_max);
}

sub _get_table_hash {
	my $self = shift;
	my ($row, $col, $row_max, $col_max) = @_;
	foreach my $r ($row+1 ... $row_max ) {
	my $row_key = $self->{sheet_obj}->get_cell($r,$col)->value ;
	if ($row_key =~ /\s+$/ ) { $row_key =~ s/\s+$//g ; }
	chop($row_key) if ($row_key =~ /\s+$/ );
	$self->{excel_hash}->{$self->{table_name}}->{$row_key} = {};
	}
	foreach my $c ($col+1 ... $col_max) {
		my $r = $row+1;
		my $row_key = $self->{sheet_obj}->get_cell($r,$col)->value;
		my $att = $self->{sheet_obj}->get_cell($row,$c)->value;
		if ( $att =~ /\s+$/ ) { $att =~ s/\s+$//g; }
		if ( $row_key =~ /\s+$/ ) { $row_key =~ s/\s+$//g; }
		$self->{excel_hash}->{$self->{table_name}}->{$row_key}->{$att} = "";
		$r = $r + 1;
	}
	foreach my $r ( $row+1 ... $row_max ) {
		foreach my $c ( $col+1 ... $col_max ) {
			my $val = "";
			my $cell = $self->{sheet_obj}->get_cell($r,$c);
			if ( defined $cell ) {
				$val = $cell->value();
				chop($val) if ($val =~ /\s+$/ );
			}
			my $row_key = $self->{sheet_obj}->get_cell($r,$col)->value;
			my $col_key = $self->{sheet_obj}->get_cell($row, $c)->value;
			if ($row_key =~ /\s+$/ ) { $row_key =~ s/\s+$//g; }
			if ($col_key =~ /\s+$/ ) { $col_key =~ s/\s+$//g; }
			$self->{excel_hash}->{$self->{table_name}}->{$row_key}->{$col_key} = $val;
		}
	}
}
sub _get_table_col_max {
	my $self = shift;
	my $row_v = shift;
	my $col_v = shift;
	my $col_v_max = $col_v;
	my ( $row_min, $row_max) = $self->{sheet_obj}->row_range;
	my ( $col_min, $col_max) = $self->{sheet_obj}->col_range;
	foreach my $col ( $col_v ... $col_max ) {
		$col_v_max = $col;
		my $cell = $self->{sheet_obj}->get_cell($row_v, $col);
		if ( ! defined $cell ) { $col_v_max = $col-1; last; }
		if ( $cell->value eq "" ) { $col_v_max = $col-1; last; }
	}
	if ( $col_v_max == $col_v ) {
	my $msg = "ERROR: It is not a Valid Table to create Hash. Double Check <$self->{table_name}>";
	$self->{error_hash}->{$msg} = "";
	return "";
	} else {
		return $col_v_max;
	}
}

sub error {
	my $self = shift;
	foreach my $msg ( keys  %{$self->{error_hash}} ) {
		print "\n\t$msg\n";
	}
}


sub _get_table_row_max {
	my $self = shift;
	my $row_v = shift;
	my $col_v = shift;
	my $row_v_max = $row_v;
	my ( $row_min, $row_max) = $self->{sheet_obj}->row_range;
	my ( $col_min, $col_max) = $self->{sheet_obj}->col_range;
	foreach my $row ( $row_v ... $row_max ) {
		$row_v_max = $row;
		my $cell = $self->{sheet_obj}->get_cell($row, $col_v);
		if ( ! defined $cell ) { $row_v_max = $row-1; last; }
		if ( $cell->value eq "" ) { $row_v_max = $row-1; last; }
	}
	if ( $row_v_max == $row_v ) {
	my $msg = "ERROR: It is not a Valid Table to create Hash. Double Check <$self->{table_name}>";
	$self->{error_hash}->{$msg} = "";
	return "";
	} else {
	return $row_v_max;
	}
}

sub _search_var {
	my $self = shift;
	my $var = shift;
	
	my ( $row_min, $row_max ) = $self->{sheet_obj}->row_range;
	my ( $col_min, $col_max) = $self->{sheet_obj}->col_range;
	foreach my $col ($col_min ... $col_max ) {
		foreach my $row ( $row_min ... $row_max ) {
			my $cell = $self->{sheet_obj}->get_cell($row, $col);
			if ( defined $cell ) {
				my $val =  $cell->value;
				if ($val =~ /\s+$/ ) { $val =~ s/\s+//g; }
				if ( $val eq "$var") { return "$row $col"; }
			}
		}
	}
	my $msg = "ERROR: No Cell found with <$var> value in <$self->{excel_file} : $self->{excel_sheet}, Make Sure it is Valid Excel Table\n";
	$self->{error_hash}->{$msg} = "";
	return "";
}

sub excel_checker {
	my $self = shift;
	my $sheet =  shift if @_;
	my $var =  shift if @_;
	if ( ! defined  $var ) { $var = $self->{table_name} ; }
	if ( ! defined  $sheet ) { $sheet = $self->{excel_sheet} ; }
	$self->{sheet_obj} = $self->{excel_obj}->worksheet($sheet);
	if (! defined $self->{sheet_obj} ) { $self->{error_hash}->{"Work Sheet $sheet Not found in $self->{excel_file}"} = "" ; return 1;}
	my $cell_info = $self->_search_var($var);
	if ( $cell_info eq "" ) { return 1 ; }
	my ($row_v, $col_v ) = split " " , $cell_info;
	my $row_v_max = $self->_get_table_row_max($row_v, $col_v);
	my $col_v_max = $self->_get_table_col_max($row_v, $col_v);
	if ( $col_v_max eq ""  || $row_v_max eq "" ) { return 1; }
	undef $var;
	undef $sheet;
	return 0;
}

sub _print_table {
	my $self = shift;
	foreach my $key ( keys %{$self->{excel_hash}} ) {
		print "Table: >$key< \n";
		foreach my $k ( keys %{$self->{excel_hash}->{$key}} ) {
			print ">$k<:\n";
			foreach my $j ( keys %{$self->{excel_hash}->{$key}->{$k}} ) {
				print ">$j<: >$self->{excel_hash}->{$key}->{$k}->{$j}<\n";
			}
		}
	}
}

sub set_write_xls {
	my $self = shift;
	my $xls = shift;
	$self->{work_book_obj} = Spreadsheet::WriteExcel->new($xls);
}

sub write_excel {
	my $self = shift;
	my $worksheet = shift;
	my $table = shift;
	my $work_sheet = $self->{work_book_obj}->add_worksheet($worksheet);
	my $row = 2;
	my $col = 2;
	my $format = $self->{work_book_obj}->add_format();
	$format->set_bold();
	$format->set_color("blue");
	$format->set_align("center");
	$work_sheet->write($row, $col, $table, $format );
	foreach my $row_key ( keys %{$self->{excel_hash}->{$table}} ) {
		$row = $row + 1;
		$work_sheet->write($row, $col, $row_key, $format );
	}
	$row = 2;
	foreach my $row_key ( keys %{$self->{excel_hash}->{$table}} ) {
		$col = 2;
		#print "$row_key\n";
		foreach my $col_key ( keys %{$self->{excel_hash}->{$table}->{$row_key}} ) {
			#print "$row $col $col_key\n";
			$col = $col + 1;
			if( $row == 2) { $work_sheet->write($row, $col, $col_key, $format ); }
			$work_sheet->write($row+1, $col, $self->{excel_hash}->{$table}->{$row_key}->{$col_key} );
		}
	$row = $row +1;
	}
}

sub get_table  {
	my $self = shift;
	my $table = shift;
	return $self->{excel_hash}->{$table};
}

sub get_xl_tables  {
	my $self = shift;
	return $self->{excel_hash};
}

1;

__END__

=head1 SYNOPSIS

	Spreadsheet::ExcelHashTable reads tables from Excel and converts them to Perl Data Structure and writes Perl Hash to a Excel Sheet

=head2 Motivation

	This Utility is more useful for converting randomly organized  Excel Tables to Perl hash. In my case it more useful in converting 
	this Excel Information to a EDA(Electronic Design Automation) tool scripts, using Template Tool Kit.

=head1 ExcelHashTable

=head2 Excel Table

In this context Excel Table is the following. In the below example "Employee is a table".

		<Employee.xls>  (ExcelHashTable cannot understand Merged Cells)

		----------------------------------------------------------------
		| Employee | ID       |  Designation     	|   Department
		----------------------------------------------------------------
		|  Mike    |  1001    |  Software Analyst 	|   BU1
		----------------------------------------------------------------
		|  Srinik  |  1002    |  Analyst  		|   BU2
		----------------------------------------------------------------

As shown above in the above Excel sheet, "Employee" is a table. So the complete table could be parsed in the following way

	my $excel_table  = Spreadsheet::ExcelHashTable->new("Employee.xls");
	$excel_table->parse_table("sheet1", "Employee") ;
	my $excel_hash = $excel_table->get_table("Employee");

	Structure of Hash Returned by get_table(<table_name>)
		$excel_hash  = { "Employee" => {
		Mike  => {
			ID    => "1001",
			Designation  => "Software Analyst"
			Department      => "BU1"
			},
		},
		Srinik   => { ....
		}
	} 

=head2 Merging Excel Tables

This Module is also helpful in merging various Excel Tables in different work books and also across various Excel sheets.
Below is a example which finds two Employee table from different excel sheets and create  a Perl data structure/Hash.

	my $excel_table  = Spreadsheet::ExcelHashTable->new("Employee.xls");
	$excel_table->parse_table("sheet1", "Employee") ;
	$excel_table->parse_table("sheet2", "Employee") ;
	$excel_table->parse_table("sheet3", "Employee") ;
	my $excel_hash = $excel_table->get_table("Employee");

Below two lines dumps the Employee hash to a Excel Sheet

	$excel_table->set_write_xls("Employee_new.xls");
	$excel_table->write_excel( "sheet1", "Employee" );


=head2  Different Excel Tables

This module can parse different Excel Tables from various Excel WorkBook/Sheets. Below is the example shown	

	<Company.xls>
		<BU Table> - <sheet1>

		----------------------------------------
		| BU  | Employee_Name   | Employee_Id
		----------------------------------------
		| BU1 | Mike  		| 1001
		----------------------------------------
		| BU2 | Srinik  	| 1002
		----------------------------------------

	<Employee Table> - sheet2

		---------------------------------------------------------------
		| Employee | ID       |  Designation     	|   Department
		---------------------------------------------------------------
		|  Mike    |  1001    |  Software Analyst 	|   BU1
		---------------------------------------------------------------
		|  Srinik  |  1002    |  Analyst  		|   BU2
		---------------------------------------------------------------


	my $excel_table  = Spreadsheet::ExcelHashTable->new("Company.xls");
	$excel_table->parse_table("sheet1", "BU") ;
	$excel_table->parse_table("sheet2", "Employee") ;
	my $excel_hash = $excel_table->get_xl_tables(); # Returns complete set of tables
	
	Hash Structure

	$excel_hash  = { "Employee" => {
				Mike  => {
					ID    => "1001",
					Designation  => "Software Analyst"
					Department      => "BU1"
					},
				},
				Srinik   => { ....
				},
			{ "BU" => {
				BU1 => {
					Employee_Name => "Mike"
					Employee_Id => "1001"
					}
				}
		}

=head2 excel_checker(<sheet>, <table>)

Returns 1 If the Excel Table has errors. Excel Table need to have certain format, so that any excel can be parsed.

=head2 error()

Displays Errors meesage caugh using excel_checker() function.
$excel_table->error();

=head2 get_table(<table>)

Return only the particular <table> hash.

=head2 get_xl_tables()

Return the complete hash, self->{excel_hash}

=head2 set_read_xls(<xl_file>)

Set the Excel File through this function.

Example:
	You can set excel while declaring the object like the one shown below

	my $excel_table  = Spreadsheet::ExcelHashTable->new("Company.xls");

	or you if you want parse a different table from another xl sheet, change the XL using

	excel_table->set_read_xls("Project.xls");


=head2 set_write_xls(<xl_file>)

set the excel file for writing. You cannot use the same file which you are reading.

Example:
	excel_table->set_write_xls("Project.xls");
	excel_table->write_excel("sheet1", "Project");
	excel_table->write_excel("sheet2", "Employee");


=head2 write_excel(<sheet>, <table>)

	Writes Hash table back to Excel


=head2 excel_hash

Access excel_hash from $excel_table object, you can modify/manupulate the excel_hash parsed from the excel sheet

	my $excel_table  = Spreadsheet::ExcelHashTable->new("Company.xls");
	$excel_table->parse_table("sheet1", "BU") ;
	$excel_table->parse_table("sheet2", "Employee") ;
	$excel_table->{excel_hash} = .............

You then use write_excel to write it to Excel or get_table to return the hash.

=head1 Limitations/Rules

Follow rules in writing Excel sheet, so ExcelHashTable can parse the table

	- Currently there cannot be any Cells Left emptly for a table, if any empty cell found the parsing stops. In the below example
	"Paul" is not parsed.

		----------------------------------------------------------------------
		| Employee | ID       |  Designation     	|   Department
		----------------------------------------------------------------------
		|  Mike    |  1001    |  Software Analyst 	|   BU1
		----------------------------------------------------------------------
		|  Srinik  |  1002    |  Analyst		|   BU2
		----------------------------------------------------------------------
		|    	   |          |          		|
		----------------------------------------------------------------------
		| Paul    |  1003    |   Engineer               |   BU2
		----------------------------------------------------------------------

	- Dont Merge any cells. Currenty L</excel_checker> cannot check this now. Will put this as a Part of next release

	- xlsx format is not yet supported or havent been tested




=head1 AUTHOR

Srinik, C<< <srinik.perl@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-spreadsheet-excelhashtable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-ExcelHashTable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spreadsheet::ExcelHashTable


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spreadsheet-ExcelHashTable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spreadsheet-ExcelHashTable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spreadsheet-ExcelHashTable>

=item * Search CPAN

L<http://search.cpan.org/dist/Spreadsheet-ExcelHashTable/>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2011 Srinik.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut




