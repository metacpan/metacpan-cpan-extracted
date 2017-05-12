package Spreadsheet::Reader::ExcelXML;
our $AUTHORITY = 'cpan:JANDREW';
use version 0.77; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML-$VERSION";

use 5.010;
use	Moose;
use	MooseX::StrictConstructor;
use	MooseX::HasDefaults::RO;
use Types::Standard qw( is_HashRef is_Object );
use Clone 'clone';
###LogSD	use B::Deparse;
###LogSD	my $deparser = B::Deparse->new;

use	MooseX::ShortCut::BuildInstance 1.040 qw(
		build_instance		should_re_use_classes	set_args_cloning
	);
should_re_use_classes( 1 );
set_args_cloning ( 0 );
###LogSD use Log::Shiras::Telephone v0.48.0;
use lib	'../../../../lib',;
use Spreadsheet::Reader::ExcelXML::Error;
use Spreadsheet::Reader::ExcelXML::Workbook;
use Spreadsheet::Reader::Format v0.6.4;
use Spreadsheet::Reader::Format::FmtDefault;
use Spreadsheet::Reader::Format::ParseExcelFormatStrings;
use Spreadsheet::Reader::ExcelXML::Types qw( XLSXFile IOFileType );
###LogSD with 'Log::Shiras::LogSpace';

#########1 Dispatch Tables and data     4#########5#########6#########7#########8#########9

my	$attribute_defaults ={
		error_inst =>{
			package => 'ErrorInstance',
			superclasses => ['Spreadsheet::Reader::ExcelXML::Error'],
			should_warn => 0,
		},
		formatter_inst =>{
			package => 'FormatInstance',
			superclasses => [ 'Spreadsheet::Reader::Format::FmtDefault' ],
			add_roles_in_sequence =>[qw(
					Spreadsheet::Reader::Format::ParseExcelFormatStrings
					Spreadsheet::Reader::Format
			)],
		},
		count_from_zero		=> 1,
		file_boundary_flags	=> 1,
		empty_is_end		=> 0,
		values_only			=> 0,
		from_the_edge		=> 1,
		group_return_type	=> 'instance',
		empty_return_type	=> 'empty_string',
		cache_positions	=>{# Test this !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			shared_strings_interface => 5242880,# 5 MB
			styles_interface => 5242880,# 5 MB
			worksheet_interface => 2097152,# 2 MB
		},
		show_sub_file_size => 0,
		spread_merged_values => 0,
		skip_hidden => 0,
		spaces_are_empty => 0,
		merge_data => 1,
		column_formats => 1,

	};
my	$flag_settings ={
		alt_default =>{
			values_only       => 1,
			count_from_zero   => 0,
			empty_is_end      => 1,
		},
		just_the_data =>{
			count_from_zero   => 0,
			values_only       => 1,
			empty_is_end      => 1,
			group_return_type => 'value',
			from_the_edge     => 0,
			empty_return_type => 'undef_string',
			spaces_are_empty  => 1,
			merge_data		  => 0,
			column_formats	  => 0,
		},
		just_raw_data =>{
			count_from_zero   => 0,
			values_only       => 1,
			empty_is_end      => 1,
			group_return_type => 'unformatted',
			from_the_edge     => 0,
			empty_return_type => 'undef_string',
			spaces_are_empty  => 1,
			merge_data		  => 0,
			column_formats	  => 0,
		},
		like_ParseExcel =>{
			count_from_zero => 1,
			group_return_type => 'instance',
		},
		debug =>{
			error_inst =>{
				superclasses => ['Spreadsheet::Reader::ExcelXML::Error'],
				package => 'ErrorInstance',
				should_warn => 1,
			},
			show_sub_file_size => 1,
		},
		lots_of_ram =>{
			cache_positions	=>{
				shared_strings_interface => 209715200,# 200 MB
				styles_interface => 209715200,# 200 MB
				worksheet_interface => 209715200,# 200 MB
			},
		},
		less_ram =>{
			cache_positions	=>{
				shared_strings_interface => 10240,# 10 KB
				styles_interface => 10240,# 10 KB
				worksheet_interface => 1024,# 1 KB
			},
		},
	};
my $delay_till_build = [qw( formatter_inst )];

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

###LogSD sub get_class_space{ 'Top' }

sub import{# Flags handled here!
    my ( $self, @flag_list ) = @_;
	#~ print "Made it to import\n";
	#~ if( scalar( @flag_list ) ){
		for my $flag ( @flag_list ){
			#~ print "Arrived at import with flag: $flag\n";
			if( $flag =~ /^:(\w*)$/ ){# Handle text based flags
				my $default_choice = $1;
				#~ print "Attempting to change the default group type to: $default_choice\n";
				if( exists $flag_settings->{$default_choice} ){
					for my $attribute ( keys %{$flag_settings->{$default_choice}} ){
						#~ print "Changing flag -$attribute- to:" . Dumper( $flag_settings->{$default_choice}->{$attribute} );
						$attribute_defaults->{$attribute} = $flag_settings->{$default_choice}->{$attribute};
					}
				}else{
					confess "No settings available for the flag: $flag";
				}
			}elsif( $flag =~ /^v?\d+\.?\d*/ ){# Version check may wind up here
				#~ print "Running version check on version: $flag\n";
				my $result = $VERSION <=> version->parse( $flag );
				#~ print "Tested against version -$VERSION- gives result: $result\n";
				if( $result < 0 ){
					confess "Version -$flag- required - the installed version is: $VERSION";
				}
			}else{
				confess "Passed attribute default flag -$flag- does not comply with the correct format";
			}
		}
	#~ }
	#~ print "Finished import\n";
}

sub parse{

    my ( $self, $file, $formatter ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::parse', );
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			"Arrived at parse for:", $file,
	###LogSD			(($formatter) ? "with formatter: $formatter" : '') ] );

	# Test the file
	if( XLSXFile->check( $file ) ){
		###LogSD	$phone->talk( level => 'info', message =>[ "This is an xlsx file: $file" ] );
	}elsif( IOFileType->check( $file ) ){
		###LogSD	$phone->talk( level => 'info', message =>[ "This is a file handle:", $file ] );
	}else{
		$self->set_error( "Value \"$file\" did not pass type constraint \"IOFileType\"" );
		return undef;
	}

	# Load the formatter
	if( $formatter ){
		$self->set_formatter_inst( $formatter );
		###LogSD	$phone->talk( level => 'info', message =>[ "Formatter added" ] );
	}

	$self->set_file( $file );
	###LogSD	$phone->talk( level => 'info', message =>[ "Build workbook attempt complete", $self->file_opened ] );
	return $self->file_opened ? $self : undef;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _workbook =>(
		isa			=> 'Spreadsheet::Reader::ExcelXML::Workbook',
		predicate	=> '_has_workbook',
		writer		=> '_set_workbook',
		clearer		=> '_clear_the_workbook',
		handles		=> [qw(
			error									set_error							clear_error						set_warnings
			should_spew_longmess	spewing_longmess			if_warn								has_error
			get_error_inst				has_error_inst				set_formatter_inst		get_excel_region

			get_formatter_region	has_target_encoding		get_target_encoding		set_workbook_for_formatter
			set_target_encoding		set_european_first		set_date_behavior			get_defined_conversion
			set_defined_excel_formats										change_output_encoding
			set_formatter_cache_behavior								parse_excel_format_string

			set_file							counting_from_zero		boundary_flag_setting	spreading_merged_values
			is_empty_the_end			get_values_only				starts_at_the_edge		get_group_return_type
			get_empty_return_type	cache_positions				get_cache_size				has_cache_size
			should_skip_hidden		are_spaces_empty

			worksheet							worksheets						build_workbook				demolish_the_workbook

			file_name							file_opened						get_epoch_year				has_epoch_year
			get_sheet_names				get_sheet_name				sheet_count						get_sheet_info
			get_rel_info					get_id_info						get_worksheet_names		worksheet_name
			worksheet_count				get_chartsheet_names	chartsheet_name				chartsheet_count
			creator								modified_by						date_created					date_modified
			in_the_list						start_at_the_beginning
		)],
	);
			#~ get_shared_string		start_the_ss_file_over	has_shared_strings_interface
			#~ has_styles_interface	get_format

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
	my %args = is_HashRef( $args[0] ) ? %{$args[0]} : @args;
	###LogSD	$args{log_space} //= 'ExcelXML';
	###LogSD	my	$class_space = __PACKAGE__->get_class_space;
	###LogSD	my	$log_space = $args{log_space} . "::$class_space" . '::_hidden::BUILDARGS';
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => $log_space, );
	###LogSD		$phone->talk( level => 'trace', message =>[
	###LogSD			'Arrived at BUILDARGS with: ', @args, ] );# caller(3), caller(4), caller(5)

	# Handle depricated cache_positions
	#~ print longmess( Dumper( %args ) );
	if( exists $args{cache_positions} ){
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"The user did pass a value to cache_positions as:", $args{cache_positions}] );
		if( !is_HashRef( $args{cache_positions} ) ){
			warn "Passing a boolean value to the attribute 'cache_positions' is depricated since v0.40.2 - the input will be converted per the documentation";
			$args{cache_positions} = !$args{cache_positions} ?
				$flag_settings->{big_file}->{cache_positions} :
				$attribute_defaults->{cache_positions};
		}

		#scrub cache_positions
		for my $passed_key ( keys %{$args{cache_positions}} ){
			if( !exists $attribute_defaults->{cache_positions}->{$passed_key} ){
				warn "Passing a cache position for '$passed_key' but that is not allowed";
			}
		}
		for my $stored_key ( keys %{$attribute_defaults->{cache_positions}} ){
			if( !exists $args{cache_positions}->{$stored_key} ){
				warn "Passed cache positions are missing key => values for key: $stored_key";
			}
		}
	}

	# Add any defaults
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Processing possible default values", $attribute_defaults ] );
	for my $key ( keys %$attribute_defaults ){
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Processing possible default for -$key- with value:", $attribute_defaults->{$key} ] );
		if( exists $args{$key} ){
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Found user defined -$key- with value(s): ", $args{$key} ] );
		}else{
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Setting default -$key- with value(s): ", $attribute_defaults->{$key} ] );
			$args{$key} = clone( $attribute_defaults->{$key} );
		}
	}

	# Build object instances as needed
	for my $key ( keys %args ){
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Checking if an instance needs built for key: $key" ] );
		if( $key =~ /_inst$/ and !is_Object( $args{$key} ) and is_HashRef( $args{$key} ) ){
			# Import log_space as needed
			###LogSD	if( exists $args{log_space} and $args{log_space} ){
			###LogSD		$args{$key}->{log_space} = $args{log_space};
			###LogSD	}
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Key -$key- requires an instance built from:", $args{$key} ] );
			$args{$key} = build_instance( $args{$key} );
		}
	}

	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD			"Final BUILDARGS:", %args ] );
	my $workbook = Spreadsheet::Reader::ExcelXML::Workbook->new( %args );
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD			"Assigning the built workbook to the _workbook attribute with: ", $deparser->coderef2text( $orig ),
	###LogSD			"..with workboook: ", $workbook->dump ] );
    return $class->$orig(
				_workbook => $workbook,
	###LogSD	log_space => $args{log_space}
	);
};

sub DEMOLISH{
	my ( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_hidden::DEMOLISH', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"Forcing Non-recursive garbage collection on recursive stuff" ] );
	if( $self->_has_workbook ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Need to demolish the workbook" ] );
		$self->demolish_the_workbook;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Clearing the attribute" ] );
		$self->_clear_the_workbook;
	}
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML - Read xlsx/xlsm/xml extention Excel files

=begin html

<a href="https://www.perl.org">
	<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="perl version">
</a>

<a href="https://travis-ci.org/jandrew/p5-spreadsheet-reader-excelxml">
	<img alt="Build Status" src="https://travis-ci.org/jandrew/p5-spreadsheet-reader-excelxml.png?branch=master" alt='Travis Build'/>
</a>

<a href='https://coveralls.io/github/jandrew/p5-spreadsheet-reader-excelxml?branch=master'>
	<img src='https://coveralls.io/repos/github/jandrew/p5-spreadsheet-reader-excelxml/badge.svg?branch=master' alt='Coverage Status' />
</a>

<a href='https://github.com/jandrew/p5-spreadsheet-reader-excelxml'>
	<img src="https://img.shields.io/github/tag/jandrew/p5-spreadsheet-reader-excelxml.svg?label=github version" alt="github version"/>
</a>

<a href="https://metacpan.org/pod/Spreadsheet::Reader::ExcelXML">
	<img src="https://badge.fury.io/pl/Spreadsheet-Reader-ExcelXML.svg?label=cpan version" alt="CPAN version" height="20">
</a>

<a href='http://cpants.cpanauthors.org/dist/Spreadsheet-Reader-ExcelXML'>
	<img src='http://cpants.cpanauthors.org/dist/Spreadsheet-Reader-ExcelXML.png' alt='kwalitee' height="20"/>
</a>

=end html

=encoding UTF-8

=head1 SYNOPSIS

The following uses the 'TestBook.xlsx' file found in the t/test_files/ folder of the package

	#!/usr/bin/env perl
	use strict;
	use warnings;
	use Spreadsheet::Reader::ExcelXML;

	my $parser   = Spreadsheet::Reader::ExcelXML->new();
	my $workbook = $parser->parse( 'TestBook.xlsx' );

	if ( !defined $workbook ) {
		die $parser->error(), "\n";
	}

	for my $worksheet ( $workbook->worksheets() ) {

		my ( $row_min, $row_max ) = $worksheet->row_range();
		my ( $col_min, $col_max ) = $worksheet->col_range();

		for my $row ( $row_min .. $row_max ) {
			for my $col ( $col_min .. $col_max ) {

				my $cell = $worksheet->get_cell( $row, $col );
				next unless $cell;

				print "Row, Col    = ($row, $col)\n";
				print "Value       = ", $cell->value(),       "\n";
				print "Unformatted = ", $cell->unformatted(), "\n";
				print "\n";
			}
		}
		last;# In order not to read all sheets
	}

	###########################
	# SYNOPSIS Screen Output
	# 01: Row, Col    = (0, 0)
	# 02: Value       = Category
	# 03: Unformatted = Category
	# 04:
	# 05: Row, Col    = (0, 1)
	# 06: Value       = Total
	# 07: Unformatted = Total
	# 08:
	# 09: Row, Col    = (0, 2)
	# 10: Value       = Date
	# 11: Unformatted = Date
	# 12:
	# 13: Row, Col    = (1, 0)
	# 14: Value       = Red
	# 16: Unformatted = Red
	# 17:
	# 18: Row, Col    = (1, 1)
	# 19: Value       = 5
	# 20: Unformatted = 5
	# 21:
	# 22: Row, Col    = (1, 2)
	# 23: Value       = 2017-2-14 #(shows as 2/14/2017 in the sheet)
	# 24: Unformatted = 41318
	# 25:
	# More intermediate rows ...
	# 82:
	# 83: Row, Col    = (6, 2)
	# 84: Value       = 2016-2-6 #(shows as 2/6/2016 in the sheet)
	# 85: Unformatted = 40944
	###########################

=head1 DESCRIPTION

This is an Excel spreadsheet reading package that should parse all excel files with the
extentions .xlsx, .xlsm, .xml I<L<Excel 2003 xml
|https://en.wikipedia.org/wiki/Microsoft_Office_XML_formats> (L<SpreadsheetML
|https://en.wikipedia.org/wiki/SpreadsheetML>)> that can be opened in the Excel 2007+
applications.  The quick-start example provided in the SYNOPSIS attempts to follow the
example from L<Spreadsheet::ParseExcel> (.xls binary file reader) as close as possible.
There are additional methods and other approaches that can be used by this package for
spreadsheet reading but the basic access to data from newer xml based Excel files can be
as simple as above.

This is L<not the only perl package|/SEE ALSO> able to parse .xlsx files on METACPAN.  For
now it does appear to be the only package that will parse .xlsm and Excel 2003 .xml
workbooks.

There is some documentation throughout this package for users who intend to extend the
package but the primary documentation is intended for the person who uses the package as
is.  Parsing through an Excel workbook is done with three levels of classes;

=head2 Workbook level (This doc)

=over

=item * General L<attribute|/Attributes> settings that affect parsing of the file in general

=item * The place to L<set workbook level output formatting|Spreadsheet::Reader::Format>

=item * Object L<methods|/Methods> to retreive document level metadata and worksheets

=back

=head2 L<Worksheet level|Spreadsheet::Reader::ExcelXML::Worksheet>

=over

=item * Object methods to return specific cell instances/L<data|/group_return_type>

=item * Access to some worksheet level format information (more access pending)

=item * The place to L<customize|Spreadsheet::Reader::ExcelXML::Worksheet/custom_formats>
data output formats targeting specific cell ranges

=back

=head2 L<Cell level|Spreadsheet::Reader::ExcelXML::Cell>

=over

=item * Access to the cell contents

=item * Access to the cell formats (more access pending)

=back

There are some differences from the L<Spreadsheet::ParseExcel> package.  For instance
in the L<SYNOPSIS|/SYNOPSIS> the '$parser' and the '$workbook' are actually the same
class for this package.  You could therefore combine both steps by calling ->new with
the 'file' attribute called out.  The test for load success would then rely on the
method L<file_opened|/file_opened>.   Afterward it is still possible to call ->error
on the instance.  Another difference is the data formatter and specifically date
handling.  This package leverages L<Spreadsheet::Reader::Format> to allows for a
simple pluggable custom output format that is very flexible as well as handling dates
in the Excel file older than 1-January-1900.  I leveraged coercions from L<Type::Tiny
|Type::Tiny::Manual> to do this but anything that follows that general format will work
here.

The why and nitty gritty of design choices I made are in the L<Architecture Choices
|/Architecture Choices> section.  Some pitfalls are outlined in the L<Warnings|/Warnings>
section.  Read the full documentation for all opportunities!

=head2 Primary Methods

These are the primary ways to use this class.  They can be used to open a workbook,
investigate information at the workbook level, and provide ways to access sheets in
the workbook.

All methods are object methods and should be implemented on the object instance.

B<Example:>

	my @worksheet_array = $workbook_instance->worksheets;

=head3 parse( $file_name|$file_handle, $formatter )

=over

B<Definition:> This is a convenience method to match L<Spreadsheet::ParseExcel/parse($filename, $formatter)>.
It is one way to set the L<file|/file> attribute [and the L<formatter_inst|/formatter_inst> attribute].

B<Accepts:>

	$file = see the L<file|/file> attribute for valid options (required) (required)
	[$formatter] = see the L<formatter_inst|/formatter_inst> attribute for valid options (optional)

B<Returns:> an instance of the package (not cloned) when passing with the xlsx file successfully
opened or undef for failure.

=back

=head3 worksheets

=over

B<Definition:> This method will return an array (I<not an array reference>) containing a list of references
to all worksheets in the workbook as objects.  This is not a reccomended method because it builds all
worksheet instance and returns an array of objects.  It is provided for compatibility to
Spreadsheet::ParseExcel.  For alternatives see the L<get_worksheet_names|/get_worksheet_names> method and
the L<worksheet|/worksheet( $name )> methods.  B<It also only returns the tabular worksheets in the
workbook.  All chart sheets are ignored!>

B<Accepts:> nothing

B<Returns:> an array ref of  L<Worksheet|Spreadsheet::Reader::ExcelXML::Worksheet>
objects for all worksheets in the workbook.

=back

=head3 worksheet( $name )

=over

B<Definition:> This method will return an  object to read values in the identified
worksheet.  If no value is passed to $name then the 'next' worksheet in physical order
is returned. I<'next' will NOT wrap>  It also only iterates through the 'worksheets'
in the workbook (not the 'chartsheets').

B<Accepts:> the $name string representing the name of the worksheet object you
want to open.  This name is the word visible on the tab when opening the spreadsheet
in Excel. (not the underlying zip member file name - which can be different.  It will
not accept chart tab names.)

B<Returns:> a L<Worksheet|Spreadsheet::Reader::ExcelXML::Worksheet> object with the
ability to read the worksheet of that name.  It returns undef and sets the error attribute
if a 'chartsheet' is requested.  Or in 'next' mode it returns undef if past the last sheet.

B<Example:> using the implied 'next' worksheet;

	while( my $worksheet = $workbook->worksheet ){
		print "Reading: " . $worksheet->name . "\n";
		# get the data needed from this worksheet
	}

=back

=head3 file_name

=over

B<Definition:> If you pass a file $location/$name string to the attribute L<file|/file> then before
the package converts it to a file handle it will store the string.  You can retreive that string
with this method.  This is true if you pass a string to the L<parse
|/parse( $file_name|$file_handle, $formatter )> method as well.

B<Accepts:> nothing

B<Returns:> the $location/$name file string if available.

=back

=head3 file_opened

=over

B<Definition:> This method is the test for success that should be used when opening a workbook
using the -E<gt>new method.  This allows for the object to store the error without dying
entirely.

B<Accepts:> nothing

B<Returns:> 1 if the workbook file was successfully opened

B<Example:>

	use Spreadsheet::Reader::ExcelXML qw( :just_the_data );

	my $workbook  = Spreadsheet::Reader::ExcelXML->new( file => 'TestBook.xlsx' );

	if ( !$workbook->file_opened ) {
		die $workbook->error(), "\n";
	}

	for my $worksheet ( $workbook->worksheets ) {

		print "Reading worksheet named: " . $worksheet->get_name . "\n";

		while( 1 ){
			my $cell = $worksheet->get_next_value;
			print "Cell is: $cell\n";
			last if $cell eq 'EOF';
		}
	}

=back

=head3 get_sheet_names

=over

B<Definition:> This method returns an array ref of all the sheet names (tabs) in the
workbook in order.  (It includes chartsheets.)

B<Accepts:> nothing

B<Returns:> an array ref of strings

=back

=head3 worksheet_name( $position )

=over

B<Definition:> This returns the name of the worksheet in that $position. (counting from zero)
interspersed chartsheets in the file are not considered to hold a position by this accounting.

B<Accepts:> $position (an integer)

B<Returns:> the worksheet name

B<Example:> To return only worksheet positions 2 through 4 without building them all at once

	for $x (2..4){
		my $worksheet = $workbook->worksheet( $workbook->worksheet_name( $x ) );
		# Read the worksheet here
	}

=back

=head3 get_worksheet_names

=over

B<Definition:> This method returns an array ref of all the worksheet names (tabs) in the
workbook in order.  (No chartsheets.)

B<Accepts:> nothing

B<Returns:> an array ref of strings

B<Example:> Another way to parse a workbook without building all the sheets at
once is;

	for $sheet_name ( @{$workbook->worksheet_names} ){
		my $worksheet = $workbook->worksheet( $sheet_name );
		# Read the worksheet here
	}

=back

=head3 worksheet_count

=over

B<Definition:> This returns the total number of recorded worksheets

B<Accepts:> nothing

B<Returns:> $total - a count of all worksheets (only)

=back

=head2 Attributes

Data passed to new when creating an instance.  For modification of these attributes
see the listed 'attribute methods'. For general information on attributes see
L<Moose::Manual::Attributes>.  For additional lesser used workbook options see
L<Secondary Methods|/Secondary Methods>.  There are several grouped default values
for these attributes documented in the L<Flags|/Flags> section.

B<Example>

	$workbook_instance = Spreadsheet::Reader::ExcelXML->new( %attributes )

I<note: if the file information is not included in the initial %attributes then it must be
set by one of the attribute setter methods below or the L<parse
|parse( $file_nameE<verbar>$file_handle, $formatter )> method before the rest of the package
can be used.>

=head3 file

=over

B<Definition:> This attribute holds the file handle for the top level workbook.  If a
file name is passed it is coerced into an L<IO::File> handle and stored that way.  The
originaly file name can be retrieved with the method L<file_name|/file_name>.

B<Default> no default

B<Required:> yes

B<Range> any unencrypted xlsx|xlsm|xml file that can be opened in Microsoft Excel 2007+.

B<attribute methods> Methods provided to adjust this attribute

=over

B<set_file( $file|$file_handle )>

=over

B<Definition:> change the file value in the attribute (this will reboot the workbook instance)

=back

=back

=back

=head3 error_inst

=over

B<Definition:> This attribute holds an 'error' object instance.  It should have several
methods for managing errors.  Currently no error codes or error language translation
options are available but this should make implementation of that easier.

B<Default:> a L<Spreadsheet::Reader::ExcelXML::Error> instance with the attributes set
as;

	( should_warn => 0 )

B<Range:> See the 'Exported methods' section below for methods required by the workbook.
The error instance must also be able to extract the error string from a passed error
object as well.  For now the current implementation will attempt ->as_string first
and then ->message if an object is passed.

B<attribute methods> Methods provided to manage this attribute

=over

B<get_error_inst>

=over

B<Definition:> returns this instance

=back

B<has_error_inst>

=over

B<Definition:> indicates in the error instance has been set

=back

B<Exported methods:>

The following methods are exported (delegated) to the workbook level
from the stored instance of this class.  Links are provided to the default implemenation;

=over

L<Spreadsheet::Reader::ExcelXML::Error/error>

L<Spreadsheet::Reader::ExcelXML::Error/set_error>

L<Spreadsheet::Reader::ExcelXML::Error/clear_error>

L<Spreadsheet::Reader::ExcelXML::Error/set_warnings>

L<Spreadsheet::Reader::ExcelXML::Error/if_warn>

L<Spreadsheet::Reader::ExcelXML::Error/should_spew_longmess>

L<Spreadsheet::Reader::ExcelXML::Error/spewing_longmess>

L<Spreadsheet::Reader::ExcelXML::Error/has_error>

=back

=back

=back

=head3 formatter_inst

=over

B<Definition:> This attribute holds a 'formatter' object instance.  This instance does all
the heavy lifting to transform raw text into desired output.  It does include
a role that interprets the excel L<format string
|https://support.office.com/en-us/article/Create-or-delete-a-custom-number-format-2d450d95-2630-43b8-bf06-ccee7cbe6864?ui=en-US&rs=en-US&ad=US>
into a L<Type::Tiny> coercion.  The default case is actually built from a number of
different elements using L<MooseX::ShortCut::BuildInstance> on the fly so you can
just call out the replacement base class or role rather than fully building
the formatter prior to calling new on the workbook.  However the naming of the interface
|http://www.cs.utah.edu/~germain/PPS/Topics/interfaces.html> is locked and should not be
tampered with since it manages the methods to be imported into the workbook;

B<Default> An instance built with L<MooseX::ShortCut::BuildInstance> from the following
arguments (note the instance itself is not built here)
	{
		superclasses => ['Spreadsheet::Reader::ExcelXML::FmtDefault'], # base class
		add_roles_in_sequence =>[qw(
			Spreadsheet::Reader::ExcelXML::ParseExcelFormatStrings # role containing the heavy lifting methods
			Spreadsheet::Reader::ExcelXML::FormatInterface # the interface
		)],
		package => 'FormatInstance', # a formality more than anything
	}

B<Range:> A replacement formatter instance or a set of arguments that will lead to building an acceptable
formatter instance.  See the 'Exported methods'section below for all methods required methods for the
workbook.  The FormatInterface is required by name so a replacement of that role requires the same name.

B<attribute methods> Methods provided to manage this attribute

=over

B<get_formatter_inst>

=over

B<Definition:> returns the stored formatter instance

=back

B<set_formatter_inst>

=over

B<Definition:> sets the formatter instance

=back

B<Exported methods:>

Additionally the following methods are exported (delegated) to the workbook level
from the stored instance of this class.  Links are provided to the default implemenation;

=over

B<Example:> name_the_workbook_uses_to_access_the_method => B<Link to the default source of the method>

get_formatter_region => L<Spreadsheet::Reader::Format::FmtDefault/get_excel_region>

has_target_encoding => L<Spreadsheet::Reader::Format::FmtDefault/has_target_encoding>

get_target_encoding => L<Spreadsheet::Reader::Format::FmtDefault/get_target_encoding>

set_target_encoding => L<Spreadsheet::Reader::Format::FmtDefault/set_target_encoding( $encoding )>

change_output_encoding => L<Spreadsheet::Reader::Format::FmtDefault/change_output_encoding( $string )>

set_defined_excel_formats => L<Spreadsheet::Reader::Format::FmtDefault/set_defined_excel_formats( %args )>

get_defined_conversion => L<Spreadsheet::Reader::Format::ParseExcelFormatStrings/get_defined_conversion( $position )>

parse_excel_format_string => L<Spreadsheet::Reader::Format::ParseExcelFormatStrings/parse_excel_format_string( $string, $name )>

set_date_behavior => L<Spreadsheet::Reader::Format::ParseExcelFormatStrings/set_date_behavior( $bool )>

set_european_first => L<Spreadsheet::Reader::Format::ParseExcelFormatStrings/set_european_first( $bool )>

set_formatter_cache_behavior => L<Spreadsheet::Reader::Format::ParseExcelFormatStrings/set_cache_behavior( $bool )>

set_workbook_for_formatter => L<Spreadsheet::Reader::Format::ParseExcelFormatStrings/set_workbook_inst( $instance )>

=back

=back

=back

=head3 count_from_zero

=over

B<Definition:> Excel spreadsheets count from 1.  L<Spreadsheet::ParseExcel>
counts from zero.  This allows you to choose either way.

B<Default> 1

B<Range> 1 = counting from zero like Spreadsheet::ParseExcel,
0 = Counting from 1 like Excel

B<attribute methods> Methods provided to adjust this attribute

=over

B<counting_from_zero>

=over

B<Definition:> a way to check the current attribute setting

=back

=back

=back

=head3 file_boundary_flags

=over

B<Definition:> When you request data to the right of the last column or below
the last row of the data this package can return 'EOR' or 'EOF' to indicate that
state.  This is especially helpful in 'while' loops.  The other option is to
return 'undef'.  This is problematic if some cells in your table are empty which
also returns undef.   The determination for what constitues the last column and
row is selected with the attributes L<empty_is_end|/empty_is_end>, L<values_only
|/values_only>, and L<spaces_are_empty|/spaces_are_empty>.

B<Default> 1

B<Range> 1 = return 'EOR' or 'EOF' flags as appropriate, 0 = return undef when
requesting a position that is out of bounds

B<attribute methods> Methods provided to adjust this attribute

=over

B<boundary_flag_setting>

=over

B<Definition:> a way to check the current attribute setting

=back

=back

=back

=head3 empty_is_end

=over

B<Definition:> The excel convention is to read the table left to right and top
to bottom.  Some tables have an uneven number of columns with real data from row
to row.  This allows the several methods that excersize a 'next' function to wrap
after the last element with data rather than going to the max column.  This also
can combine with the attribute L<file_boundary_flags|/file_boundary_flags> to
trigger 'EOR' flags after the last data element and before the sheet max column
when not implementing 'next' functionality.  It will also return 'EOF' if the
remaining rows are empty even if the max row is farther on.

B<Default> 0

B<Range> 0 = treat all columns short of the max column for the sheet as being in
the table, 1 = treat all cells after the last cell with data as past the end of
the row.  This will be most visible when
L<boundary flags are turned on|/boundary_flag_setting> or next functionality is
used in the context of the attribute L<values_only|/values_only>.

B<attribute methods> Methods provided to adjust this attribute

=over

B<is_empty_the_end>

=over

B<Definition:> a way to check the current attribute setting

=back

=back

=back

=head3 values_only

=over

B<Definition:> Excel will store information about a cell even if it only contains
formatting data.  In many cases you only want to see cells that actually have
values.  This attribute will change the package behaviour regarding cells that have
formatting stored against that cell but no actual value.  If values in the cells
exist as zero length strings or spaces only you can also set those to empty with
the attribute L<spaces_are_empty|/spaces_are_empty>.

B<Default> 0

B<Range> 1 = return 'undef' for cells with formatting only,
0 = return the result of L<empty_return_type|/empty_return_type> (or cell objects)
for cells that only contain formatting.

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_values_only>

=over

B<Definition:> a way to check the current attribute setting

=back

=back

=back

=head3 from_the_edge

=over

B<Definition:> Some data tables start in the top left corner.  Others do not.  I
don't reccomend that practice but when aquiring data in the wild it is often good
to adapt.  This attribute sets whether the file percieves the L<min_col
|/Spreadsheet::Reader::Worksheet/min_col> and L<min_row
|/Spreadsheet::Reader::Worksheet/min_col> as the top left edge of the sheeto or
from the top row with data and starting from the leftmost column with data.

B<Default> 1

B<Range> 1 = treat the top left corner of the sheet as the beginning of rows and
columns even if there is no data in the top row or leftmost column, 0 = Set the
minimum row and minimum columns to be the first row and first column with data

B<attribute methods> Methods provided to adjust this attribute

=over

B<starts_at_the_edge>

=over

B<Definition:> returns the attribute state

=back

=back

=back

=head3 cache_positions

=over

B<Definition:> Using the standard architecture this parser would go back and
read the sharedStrings and styles files sequentially from the beginning each
time it had to access a sub elelement.  This trade-off is generally not desired
for these two files since the data is generally stored in a less than sequential
fasion.  The solution is to cache these files as they are read the first time so
that a second pass through is not necessary to retreive an earlier element.  The
only time this doesn't make sence is if either of the files would overwhelm RAM if
cached.  The package has file size break points below which the files will cache.
The thinking is that above these points the RAM is at risk of being overwhelmed
and that not crashing and slow is better than a possible out-of-memory state.
This attribute allows you to change those break points based on the target machine
you are running on.  The breaks are set on the byte size of the sub file not on the
cached expansion of the sub file.  In general the styles file is cached into a hash
and the shared strings file is cached into an array ref.  The attribute
L<group_return_type|/group_return_type> also affects the size of the cache for the
sharedStrings file since it will not cache the string formats unless the attribute
is set to 'instance'.  There is also a setting for caching worksheet data.  Some
worksheet row position settings will always be cached in order to speed up multiple
reads over the same sheet or to query meta data about the rows.  However, this
cache level is set lower since the row caching creates much deeper data structures.

B<Default>

	{
		shared_strings_interface => 5242880,# 5 MB
		styles_interface => 5242880,# 5 MB
		worksheet_interface => 2097152,# 2 MB
	}

B<attribute methods> Methods provided to adjust this attribute

=over

B<cache_positions>

=over

B<Definition:> returns the full attribute settings as a hashref

=back

B<get_cache_size( (shared_strings_interface|styles_interface|worksheet_interface) )>

=over

B<Definition:> return the max file size allowed to cache for the indicated interface

=back

B<set_cache_size( $target_interface => $max_file_size )>

=over

B<Definition:> set the $max_file_size in bytes to be cached for the indicated $target_interface

=back

B<has_cache_size( $target_interface )>

=over

B<Definition:> returns true if the $target_interface has a cache size set

=back

=back

=back

=head3 show_sub_file_size

=over

B<Definition:> Especially for zip (xlsx and xlsm) files you may not know how big the
file is and want to the package to tell you what size it thinks the file is.  This
attribute turns on a warning statment that prints to STDERR with information on the
size of potientially cached files.

B<Default> 0

B<Range> 0 = don't warn the file size, 1 = send the potentially cached file sizes to
STDERR for review

=back

=head3 group_return_type

=over

B<Definition:> Traditionally ParseExcel returns a cell object with lots of methods
to reveal information about the cell.  In reality the extra information is not used very
much (witness the popularity of L<Spreadsheet::XLSX>).  Because many users don't need or
want the extra cell formatting information it is possible to get either the raw xml value,
the raw visible cell value (seen in the Excel format bar), or the formatted cell value
returned either the way the Excel file specified or the L<way you specify
|Spreadsheet::Reader::ExcelXML::Worksheet/custom_formats> instead of a Cell instance with
all the data.  All empty cells return undef no matter what.

B<Default> instance

B<Range> instance = returns a populated L<Spreadsheet::Reader::ExcelXML::Cell> instance,
xml_value = returns the string stored in the xml file - for xml based sheets this can sometimes
be different thant the visible value in the cell or formula bar.  unformatted = returns just the
raw visible value of the cell shown in the Excel formula bar, value = returns just the formatted
value stored in the excel cell

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_group_return_type>

=over

B<Definition:> a way to check the current attribute setting

=back

=back

=back

=head3 empty_return_type

=over

B<Definition:> Traditionally L<Spreadsheet::ParseExcel> returns an empty string for cells
with unique formatting but no stored value.  It may be that the more accurate way of returning
undef works better for you.  This will turn that behaviour on.

B<Default> empty_string

B<Range>
	empty_string = populates the unformatted value with '' even if it is set to undef
	undef_string = if excel stores undef for an unformatted value it will return undef

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_empty_return_type>

=over

B<Definition:> a way to check the current attribute setting

=back

=back

=back

=head3 spread_merged_values

=over

B<Definition:> In Excel you visibly see the value of the primary cell in a merged range displayed
in all the cells.  This attribute lets the code see the primary value show in each of the merged
cells.  There is some mandatory caching to pull this off so it will consume more memory.

B<Default> 0 (To match the Excel formula bar, VBscript, and Spreadsheet::ParseExcel)

B<Range> 0 = don't spread the primary value, 1 = spread the primary value

B<attribute methods> Methods provided to adjust this attribute

=over

B<spreading_merged_values>

=over

B<Definition:> a way to check the current attribute setting

=back

=back

=back

=head3 skip_hidden

=over

B<Definition:> Like the previous attribute this attempts to match a visual effect in Excel.
Even though hidden cells still contain values you can't see them visibly.  This allows
you to skip hidden rows and columns (not hidden sheets).  The one gotcha is Excel will
place the primary value in the new primary merged cell (formula bar) if a merge range is
only partially obscured to include the original primary cell.  This package can't do that.
Either spread the primary to all cells or none.

B<Default> 0 (To match VBscript and Spreadsheet::ParseExcel)

B<Range> 0 = don't skip hidden rows and columns, 1 = skip hidden rows and columns

B<attribute methods> Methods provided to adjust this attribute

=over

B<should_skip_hidden>

=over

B<Definition:> a way to check the current attribute setting

=back

=back

=back

=head3 spaces_are_empty

=over

B<Definition:> Some auto file generators tend to add empty strings or strings with spaces to
fill empty cells.  There may be some visual value in this but they can slow down parsing scripts.
this attribute allows the sheet to treat spaces as empty or undef instead of cells with values.

B<Default> 0 (To match Excel and Spreadsheet::ParseExcel)

B<Range> 0 = cells with zero length strings and spaces are considered to have 'values", 1 = There must
be something other than spaces or a zero length string for the cell to have value.

B<attribute methods> Methods provided to adjust this attribute

=over

B<are_spaces_empty>

=over

B<Definition:> a way to check the current attribute setting

=back

=back

=back

=head3 merge_data

=over

B<Definition:> For zip based worksheets the merge data is stored at the end of the file.  In order for
the parser to arrive at that point it has to read through the whole sheet first.  For big worksheet
files this is very slow.  If you are willing to not know or implement cell merge information then turn
this off and the sheet should load much faster.

B<Default> 1 (collect merge data)

B<Range> 1 = The merge data is parsed from the worksheet file when it is opened, 0 = No merge data is
parsed.  The effect is equal to the cell merges dissapearing.

B<attribute methods> Methods provided to adjust this attribute

=over

B<collecting_merge_data>

=over

B<Definition:> a way to check the current attribute setting

=back

=back

=back

=head2 FLAGS

The parameter list (Attributes) that are possible to pass to ->new is somewhat long.
Therefore you may want a shortcut that aggregates some set of attribute settings that
are not the defaults but wind up being boilerplate.  I have provided possible
alternate sets like this and am open to providing others that are suggested.  The
flags will have a : in front of the identifier and will be passed to the class in the
'use' statement for consumption by the import method.  The flags can be stacked and
where there is conflict between the flag settings the rightmost passed flag setting is
used. If everything in the flag but one or two settings are desirable still use the flag and
then overwrite those settings when calling new.

Example;

	use Spreadsheet::Reader::ExcelXML v0.2 qw( :alt_default :debug );

=head3 :alt_default

This is intended for a deep look at data and skip formatting cells.

=over

B<Default attribute differences>

=over

L<values_only|/values_only> => 1

L<count_from_zero|/count_from_zero> => 0

L<empty_is_end|/empty_is_end> => 1

=back

=back

=head3 :just_the_data

This is intended for a shallow look at data with value formatting implemented

=over

B<Default attribute differences>

=over

L<count_from_zero|/count_from_zero> => 0

L<values_only|/values_only> => 1

L<empty_is_end|/empty_is_end> => 1

L<group_return_type|/group_return_type> => 'value'

L<from_the_edge|/from_the_edge> => 0

L<empty_return_type|/empty_return_type> => 'undef_string'

L<spaces_are_empty|/spaces_are_empty> => 1

L<merge_data|/merge_data> => 0

L<column_formats|/column_formats> => 0

=back

=back

=head3 :just_raw_data

This is intended for a shallow look at raw text and skips all formatting including number formats.

=over

B<Default attribute differences>

=over

L<count_from_zero|/count_from_zero> => 0

L<values_only|/values_only> => 1

L<empty_is_end|/empty_is_end> => 1

L<group_return_type|/group_return_type> => 'xml_value'

L<from_the_edge|/from_the_edge> => 0,

L<empty_return_type|/empty_return_type> => 'undef_string'

L<spaces_are_empty|/spaces_are_empty> => 1

L<merge_data|/merge_data> => 0

L<column_formats|/column_formats> => 0

=back

=back

=head3 :like_ParseExcel

This is a way to force some of the other groups back to instance and count from zero

=over

B<Default attribute differences>

=over

L<count_from_zero|/count_from_zero> => 1

L<group_return_type|/group_return_type> => 'instance'

=back

=back

=head3 :debug

This is a way to turn on as much reporting as possible

=over

B<Default attribute differences>

=over

L<error_inst|/error_inst> ->

	error_inst =>{
		superclasses => ['Spreadsheet::Reader::ExcelXML::Error'],
		package => 'ErrorInstance',
		should_warn => 1,
	}

L<show_sub_file_size|/show_sub_file_size> => 1

=back

=back

=head3 :lots_of_ram

This opens the caching size allowances way up

=over

B<Default attribute differences>

=over

L<cache_positions|/cache_positions> ->

	cache_positions =>{
		shared_strings_interface => 209715200,# 200 MB
		styles_interface => 209715200,# 200 MB
		worksheet_interface => 209715200,# 200 MB
	},

=back

=back

=head3 :less_ram

This tightens caching size allowances way down

=over

B<Default attribute differences>

=over

L<cache_positions|/cache_positions> ->

	cache_positions =>{
		shared_strings_interface => 10240,# 10 KB
		styles_interface => 10240,# 10 KB
		worksheet_interface => 1024,# 1 KB
	},

=back

=back

=head2 Secondary Methods

These are additional ways to use this class.  They can be used to open an .xlsx workbook.
They are also ways to investigate information at the workbook level.  For information on
how to retrieve data from the worksheets see the
L<Worksheet|Spreadsheet::Reader::ExcelXML::Worksheet> and
L<Cell|Spreadsheet::Reader::ExcelXML::Cell> documentation.  For additional workbook
options see the L<Secondary Methods|/Secondary Methods>
and the L<Attributes|/Attributes> sections.  The attributes section specifically contains
all the methods used to adjust the attributes of this class.

All methods are object methods and should be implemented on the object instance.

B<Example:>

	my @worksheet_array = $workbook_instance->worksheets;

=head3 get_epoch_year

=over

B<Definition:> This returns the epoch year defined by the Excel workbook.  The epoch year
affects the way dates are processed in the formatter L<Spreadsheet::Reader::Format>

B<Accepts:> nothing

B<Returns:> 1900 = Windows Excel or 1904 = Apple Excel

=back

=head3 has_epoch_year

=over

B<Definition:> This indicates if an epoch_year has been determined for the workbook (yet)

B<Accepts:> nothing

B<Returns:> 1 = yes there is one, 0 = nothing (yet)

=back

=head3 get_sheet_name( $Int )

=over

B<Definition:> This method returns the sheet name for a given physical position
in the workbook from left to right. It counts from zero even if the workbook is in
'count_from_one' mode.  B(It will return chart names but chart tab names cannot currently
be converted to worksheets). You may actually want L<worksheet_name|worksheet_name( $Int )>
instead of this function.

B<Accepts:> integers

B<Returns:> the sheet name (both worksheet and chartsheet )

=back

=head3 sheet_count

=over

B<Definition:> This returns the total number of recorded sheets

B<Accepts:> nothing

B<Returns:> $total - a count of all sheets (including chartsheets and worksheets)

=back

=head3 get_sheet_info( $name )

=over

B<Definition:> This returns any stored metadata about the sheet in a hashref

B<Accepts:> $name

B<Returns:> a hashref of sheet metadata ( a pretty thin list still )

=back

=head3 get_rel_info( $relId )

=over

B<Definition:> This returns the sheet name for the $relId

B<Accepts:> $relId ex; 'rId5'

B<Returns:> The sheet $name associated with that relId

=back

=head3 get_id_info( $Id )

=over

B<Definition:> This returns the sheet name for the $Id

B<Accepts:> $Id (an integer) ex; '2'

B<Returns:> The sheet $name associated with that Id

=back

=head3 get_chartsheet_names

=over

B<Definition:> This method returns an array ref of all the chartsheet names (tabs) in the
workbook in order.  (No worksheets.)

B<Accepts:> nothing

B<Returns:> an array ref of strings

=back

=head3 chartsheet_name( $position )

=over

B<Definition:> This returns the name of the chartsheet in that $position. (counting from zero)
interspersed worksheets in the file are not considered to hold a position by this accounting.

B<Accepts:> $position (an integer)

B<Returns:> the chartsheet name

=back

=head3 chartsheet_count

=over

B<Definition:> This returns the total number of recorded chartsheets

B<Accepts:> nothing

B<Returns:> $total - a count of all chartsheets (only)

=back

=head3 creator

=over

B<Definition:> Returns the recorded creator of the file from the parsed metadata

B<Accepts:> nothing

B<Returns:> a string

=back

=head3 modified_by

=over

B<Definition:> Returns the recorded last entity to modify the file from the parsed metadata

B<Accepts:> nothing

B<Returns:> a string

=back

=head3 date_created

=over

B<Definition:> Returns the date that Excel recorded for the file creation

B<Accepts:> nothing

B<Returns:> a string (YYYY-MM-DD)

=back

=head3 date_modified

=over

B<Definition:> Returns the date that Excel recorded for the last file modification

B<Accepts:> nothing

B<Returns:> a string (YYYY-MM-DD)

=back

=head3 in_the_list

=over

B<Definition:> This is a predicate method that indicates if the 'next'
L<worksheet|/worksheet( $name )> function has been implemented at least once.

B<Accepts:>nothing

B<Returns:> true = 1, false = 0

=back

=head3 start_at_the_beginning

=over

B<Definition:> This restarts the 'next' worksheet at the first worksheet.  This
method is only useful in the context of the L<worksheet|/worksheet( $name )>
function.

B<Accepts:> nothing

B<Returns:> nothing

=back

=head2 Architecture Choices

This is yet another package for parsing Excel xml or 2007+ (and 2003+ xml) workbooks.
There are two other options for 2007+ XLSX parsing (but not 2003 xml parsing) on CPAN.
(L<Spreadsheet::ParseXLSX> and L<Spreadsheet::XLSX>)  In general if either of them
already work for you without issue then there is probably no compelling reason to
switch to this package.  However, the goals of this package which may provide
differentiation are five fold.  First, as close as possible produce the same output as
is visible in an excel spreadsheet with exposure to underlying settings from Excel.
Second, adhere as close as is reasonable to the L<Spreadsheet::ParseExcel> API (where
it doesn't conflict with the first objective) so that less work would be needed to
integrate ParseExcel and this package.  An addendum to the second goal is this package
will not expose elements of the object hash for use by the consuming program.  This
package will either return an unblessed hash with the equivalent elements to the
Spreadsheet::ParseExcel output (instead of a class instance) or it will provide methods
to provide these sets of data.  The third goal is to read the excel files in a 'just in
time' manner without storing all the data in memory.  The intent is to minimize the
footprint of large file reads.  Initially I did this using L<XML::LibXML> but it
eventually L<proved to not play well|http://www.perlmonks.org/?node_id=1151609> with
Moose ( or perl? ) garbage collection so this package uses a pure perl xml parser.
In general this means that design decisions will generally sacrifice speed to keep RAM
consumption low.  Since the data in the sheet is parsed just in time the information that
is not contained in the primary meta-data headers will not be available for review L<until
the sheet parses to that point|Spreadsheet::Reader::ExcelXML::Worksheet/max_row>.  In
cases where the parser has made choices that prioritize speed over RAM savings there will
generally be an L<attribute available to turn that decision off|/set_cache_behavior>.
Fourth, Excel files get abused in the wild.  In general the Microsoft (TM) Excel
application handles these mangled files gracefully. The goal is to be able to read any
xml based spreadsheet Excel can read from the supported extention list.  Finally, this
parser supports the Excel 2003 xml format.  All in all this package solves many of the
issues I found parsing Excel in the wild.  I hope it solves some of yours as well.

=head2 Warnings

B<1.>This package uses L<Archive::Zip>.  Not all versions of Archive::Zip work for everyone.
I have tested this with Archive::Zip 1.30.  Please let me know if this does not work with a
sucessfully installed (read passed the full test suit) version of Archive::Zip newer than that.

B<2.> Not all workbook sheets (tabs) are created equal!  Some Excel sheet tabs are only a
chart.  These tabs are 'chartsheets'.  The methods with 'worksheet' in the name only act on
the sub set of tabs that are worksheets.  Future methods with 'chartsheet' in the name will
focus on the subset of sheets that are chartsheets.  Methods with just 'sheet' in the name
have the potential to act on both.  The documentation for the chartsheet level class is
found in L<Spreadsheet::Reader::ExcelXML::Chartsheet> (still under construction).
All chartsheet classes do not provide access to cells.

B<3.> This package supports reading xlsm files (Macro enabled Excel 2007+ workbooks).
xlsm files allow for binaries to be embedded that may contain malicious code.  However,
other than unzipping the excel file no work is done by this package with the sub-file
'vbaProject.bin' containing the binaries.  This package does not provide an API to that
sub-file and I have no intention of doing so.  Therefore my research indicates there should
be no risk of virus activation while parsing even an infected xlsm file with this package
but I encourage you to use your own judgement in this area. B<L<caveat utilitor!
|https://en.wiktionary.org/wiki/Appendix:List_of_Latin_phrases>>

B<4.> This package will read some files with 'broken' xml.  In general this should be
transparent but in the case of the maximum row value and the maximum column value for a
worksheet it can cause some surprising problems.  This includes the possibility that the
maximum values are initially stored as 'undef' if the sheet does not provide them in the
metadata as expected.  I<These values are generally never available in Excel 2003 xml
files.>  The answer to the methods L<Spreadsheet::Reader::ExcelXML::Worksheet/row_range>
and L<Spreadsheet::Reader::ExcelXML::Worksheet/col_range> will then change as more
of the sheet is parsed.  You can use the attribute L<file_boundary_flags
|/file_boundary_flags> or the methods L<Spreadsheet::Reader::ExcelXML::Worksheet/get_next_value>
or L<Spreadsheet::Reader::ExcelXML::Worksheet/fetchrow_arrayref> as alternates to
pre-testing for boundaries when iterating.  The primary cause of these broken XML
elements in Excel 2007+ files are non-XML applications writing to or editing the
underlying xml.  If you have an example of other broken xml files readable by the
Excel application that are not parsable by this package please L<submit them
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues> to my github repo
so I can work to improve this package.  If you don't want your test case included
with the distribution I will use it to improve the package without publishing it.

B<5.> I reserve the right to tweak the sub file L<caching breakpoints|/cache_positions>
over the next few releases.  The goal is to have a default that appears to be the
best compromise by 2017-1-1.

B<6.> This package provides  support for L<SpreadsheetML
|https://odieweblog.wordpress.com/2012/02/12/how-to-read-and-write-office-2003-excel-xml-files/>
(Excel 2003) .xml extention documents.  These files should include the header;

	<?mso-application progid="Excel.Sheet"?>

to indicate their intended format.  Please L<submit|/SUPPORT> any cases that
appear to behave differently than expected for .xml extention files that are
readable by the Excel application.  I am also interested in cases where an out of
memory error occurs with an .xml extension file.  This warning will stay till
2017-1-1.

B<7.> This package uses two classes at the top to L<handle cleanup for some self
referential|http://perldoc.perl.org/5.8.9/perlobj.html#Two-Phased-Garbage-Collection>
object organization that I use.  As a result the action taken on this package is
(mostly) implemented in L<Spreadsheet::Reader::ExcelXML::Workbook> code.  I documented
most of that code API here.  If you want to look at the raw code go there.

=head1 BUILD / INSTALL from Source

B<0.> Using L<cpanm|https://metacpan.org/pod/App::cpanminus> is much easier
than a source build!

	cpanm Spreadsheet::Reader::ExcelXML

And then if you feel kindly L<App::cpanminus::reporter>

	cpanm-reporter

B<1.> Download a compressed file with this package code from your favorite source

=over

L<github|https://github.com/jandrew/p5-spreadsheet-reader-excelxml>

L<Meta::CPAN|https://metacpan.org/pod/Spreadsheet::Reader::ExcelXML>

L<CPAN|http://search.cpan.org/~jandrew/Spreadsheet-Reader-ExcelXML/>

=back

B<2.> Extract the code from the compressed file.

=over

If you are using tar on a .tar.gz file this should work:

	tar -zxvf Spreadsheet-Reader-ExcelXML-v0.xx.tar.gz

=back

B<3.> Change (cd) into the extracted directory

B<4.> Run the following

=over

(for Windows find what version of make was used to compile your perl)

	perl  -V:make

(then for Windows substitute the correct make function (s/make/dmake/g)? below)

=back

	perl Makefile.PL

	make

	make test

	make install # As sudo/root

	make clean

=head1 SUPPORT

=over

L<github Spreadsheet::Reader::Format/issues
|https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues>

=back

=head1 TODO

=over

B<1.> Write a chartsheet parser and functions

B<2.> Add a pivot table reader (Not just read the values from the sheet)

B<3.> Add calc chain methods

B<4.> Add more exposure to workbook/worksheet formatting values

=back

=head1 AUTHOR

=over

Jed Lund

jandrew@cpan.org

=back

=head1 CONTRIBUTORS

This is the (likely incomplete) list of people who have helped
make this distribution what it is, either via code contributions,
patches, bug reports, help with troubleshooting, etc. A huge
'thank you' to all of them.  Most were contributors to
L<Spreadsheet::XLSX::Reader::LibXML> but the contributions have
(hopefully) not been lost.

=over

L<Frank Maas|https://github.com/Frank071>

L<Stuart Watt|https://github.com/morungos>

L<Toby Inkster|https://github.com/tobyink>

L<Breno G. de Oliveira|https://github.com/garu>

L<Bill Baker|https://github.com/wdbaker54>

L<H.Merijin Brand|https://github.com/Tux>

L<Todd Eigenschink|mailto:todd@xymmetrix.com>

L<Slaven Rezić|https://metacpan.org/author/SREZIC>

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2016, 2017 by Jed Lund

=head1 DEPENDENCIES

=over

L<perl 5.010|perl/5.10.0>

L<Archive::Zip>

L<Carp>

L<Clone>

L<DateTime::Format::Flexible>

L<DateTimeX::Format::Excel>

L<IO::File>

L<Moose> - 2.1213

L<MooseX::HasDefaults::RO>

L<MooseX::ShortCut::BuildInstance> - 1.032

L<MooseX::StrictConstructor>

L<Type::Tiny> - 1.000

L<version> - 0.077

=back

=head1 SEE ALSO

=over

L<Spreadsheet::Read> - generic Spreadsheet reader

L<Spreadsheet::ParseExcel> - Excel binary files from 2003 and earlier

L<Spreadsheet::ParseXLSX> - Excel version 2007 and later

L<Spreadsheet::XLSX> - Excel version 2007 and later (Very rough)

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=begin html

<a href="http://www.perlmonks.org/?node_id=706986">
	<img src="http://www.perlmonksflair.com/jandrew.jpg" alt="perl monks">
</a>

=end html

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
