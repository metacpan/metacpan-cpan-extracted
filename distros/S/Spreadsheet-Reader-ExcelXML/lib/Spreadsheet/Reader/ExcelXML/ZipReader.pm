package Spreadsheet::Reader::ExcelXML::ZipReader;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::ZipReader-$VERSION";

use 5.010;
use Moose;
use MooseX::StrictConstructor;
use MooseX::HasDefaults::RO;
use Types::Standard qw(
		HasMethods			Bool			Str				Enum
    );#Int		Num
use	Archive::Zip qw( AZ_OK );
use Capture::Tiny qw( capture_stderr );
use Carp 'confess';
use IO::File;
use lib	'../../../../lib',;
###LogSD	with 'Log::Shiras::LogSpace';
###LogSD	use Log::Shiras::Telephone;

use Spreadsheet::Reader::ExcelXML::Types qw( IOFileType );

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has file =>(
		isa			=> IOFileType,
		reader		=> 'get_file',
		writer		=> 'set_file',
		predicate	=> 'has_file',
		clearer		=> 'clear_file',
		coerce		=> 1,
		trigger		=> \&_build_zip_reader,
		handles 	=> [ 'close' ],
	);

has	file_type =>(
		isa			=> 	Enum[ 'zip' ],
		reader		=> 'get_file_type',
		default		=> 'zip',
	);

has workbook_inst =>(
		isa	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
		handles =>[ qw( set_error )],
		writer	=> 'set_workbook_inst',
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub extract_file{
    my ( $self, $file ) = ( @_ );
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::extract_file', );
	###LogSD		$phone->talk( level => 'trace', message =>[
	###LogSD			'Arrived at extract_file for the workbook general settings:', $file ] );
	my $zip_member = $self->_member_named( $file );
	###LogSD	$phone->talk( level => 'debug', message =>[ 'zip member:', $zip_member	] );
	if( $zip_member ){
		my $workbook_fh = IO::File->new_tmpfile;
		$workbook_fh->binmode();
		$zip_member->extractToFileHandle( $workbook_fh );
		$workbook_fh->seek( 0, 0 );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		'succesfully built the zip sub file:', $workbook_fh ] );
		return $workbook_fh;
	}else{
		###LogSD	$phone->talk( level => 'debug', message =>[ "no zip file for: $file"	] );
		return undef;
	}
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _loaded =>(
		isa			=> Bool,
		writer		=> '_good_load',
		reader		=> 'loaded_correctly',
		default		=> 0,
	);

has _zip_reader =>(
	isa			=> 'Archive::Zip',
	reader		=> '_get_zip_parser',
	writer		=> '_set_zip_parser',
	predicate	=> '_has_zip_parser',
	clearer		=> '_clear_zip_parser',
	handles	=>{
		_member_named => 'memberNamed',
	},
);

has _read_unique_bits =>(
		isa		=> Bool,
		reader	=> '_get_unique_bits',
		writer	=> '_need_unique_bits',
		clearer	=> '_clear_read_unique_bits',
		default	=> 1,
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _build_zip_reader{
	my( $self, $file ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::ZipReader::_build_zip_reader', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"turning a file handle into a zip reader", $file, ] );

    # Read the XLSX zip file and catch any errors (other zip file sanity tests go here)
	my $workbook_file = Archive::Zip->new();
	my $read_state;
	$file->seek( 0, 0 );# Reset in case an XML read attempt was made
	my $error_message = capture_stderr{ $read_state = $workbook_file->readFromFileHandle($file) };
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD			"Error message is:", $error_message ] );
    if(	$read_state != AZ_OK ){
		###LogSD	$phone->talk( level	=> 'warn', message =>[
		###LogSD		"Failed to open the file as a zip file" ] );
		$self->set_error( "|$file| won't open as a zip file because: $error_message" );
		$self->clear_file;
		$self->_clear_zip_parser;
	}else{
		###LogSD	$phone->talk( level	=> 'debug', message =>[
		###LogSD		"Certified this as a zip file" ] );
		$self->_set_zip_parser( $workbook_file );
		$self->_good_load( 1 );
	}
}

sub DEMOLISH{
	my ( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::ZipReader::DEMOLISH', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"clearing the zip reader for log space:", $self->get_log_space, ] );

	# Clear the reader
	if( $self->_has_zip_parser ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Clearing the zip parser", ] );
		$self->_clear_zip_parser;
	}

	# Clear the file
	if( $self->has_file ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Closing and disconnecting the file handle for the zip parser", ] );
		$self->clear_file;
	}
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::ZipReader - Base Zip file reader

=head1 SYNOPSIS

	#!/usr/bin/env perl
	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use lib '../../../../lib';
	use Spreadsheet::Reader::ExcelXML::ZipReader;
	use Spreadsheet::Reader::ExcelXML::WorkbookFileInterface;
	my	$test_file = '../../../../t/test_files/TestBook.xlsx';
	my	$test_instance =  build_instance(
			package	=> 'WorkbookFileInterface',
			superclasses => ['Spreadsheet::Reader::ExcelXML::ZipReader'],
			add_roles_in_sequence =>[
				'Spreadsheet::Reader::ExcelXML::WorkbookFileInterface',
			],
			file => $test_file,
		);
	my $sub_file = $test_instance->extract_file( 'xl/workbook.xml' );
	print $sub_file->getline;

	##############################################################
	# SYNOPSIS Screen Output
	# 01: <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
	##############################################################

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own
excel parser.  To use the general package for excel parsing out of the box please review
the documentation for L<Workbooks|Spreadsheet::Reader::ExcelXML>,
L<Worksheets|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>

This module provides a way to open a zip file or file handle and then extract sub files.
This package uses L<Archive::Zip>.  Not all versions of Archive::Zip work for everyone.
I have tested this with Archive::Zip 1.30.  Please let me know if this does not work with
a sucessfully installed (read passed the full test suit) version of Archive::Zip newer
than that.

=head2 Attributes

Data passed to new when creating an instance.  For modification of these attributes see
the listed 'attribute methods'. For general information on attributes see
L<Moose::Manual::Attributes>.  For ways to manage the instance when opened see the
L<Methods|/Methods>.

=head3 file

=over

B<Definition:> This attribute holds the file handle for the file being read.  If the full
file name and path is passed to the attribute it is coerced to an IO::File file handle.
This file handle will be expected to pass the test

B<Default:> no default - this must be provided to read a file

B<Required:> yes

B<Range:> any Zip file name and path or IO::File file handle for a zip file

B<attribute methods> Methods provided to adjust this attribute

=over

B<set_file>

=over

B<Definition:> change the file value in the attribute (this will reboot
the file instance and lock the file)

=back

B<get_file>

=over

B<Definition:> Returns the file handle of the file even if a file name
was passed

=back

B<has_file>

=over

B<Definition:> this is used to see if the file loaded correctly.

=back

B<clear_file>

=over

B<Definition:> this clears (and unlocks) the file handle

=back

=back

B<Delegated Methods>

=over

L<close|IO::Handle/$io-E<gt>close>

=over

closes the file handle

=back

=back

=back

=head3 file_type

=over

B<Definition:> This stores the file type for this file.  The type defaults to 'zip'
for this reader.

B<Default:> zip

B<Range:> 'zip'

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_file_type>

=over

B<Definition:> returns the attribute value

=back

=back

=back

=head3 workbook_inst

=over

B<Definition:> This attribute holds a reference to the top level workbook (parser).
The purpose is to use some of the methods provided there.

B<Default:> no default

B<Required:> not strictly for this class but the attribute is provided to give
self referential access to general workbook settings and methods for composed
classes that inherit this a base class.

B<Range:> isa => 'Spreadsheet::Reader::ExcelXML::Workbook'

B<attribute methods> Methods provided to adjust this attribute

=over

B<set_workbook_inst>

=over

set the attribute with a workbook instance

=back

=back

B<Delegated Methods (required)> Methods delegated to this module by the
attribute.  All methods are delegated with the method name unchanged.
Follow the link to review documentation of the provider for each method.
As you can see several are delegated through the Workbook level and
don't originate there.

=over

L<Spreadsheet::Reader::ExcelXML::Error/set_error( $error_string )>

=back

=back

=head2 Methods

These are the methods provided by this class.

=head3 extract_file( $zip_sub_file )

=over

B<Definition:> This will pull a subfile from the zipped package using the Archive::Zip
method L<memberNamed|Archive::Zip/Zip Archive Accessors> and load it to a new
'IO::File->new_tmpfile' file handle.

B<Accepts:> $zip_sub_file compliant with the Archive::Zip method 'memberNamed'

B<Returns:> an IO::File handle loaded with the extracted target sub file for reading

=back

=head3 loaded_correctly

=over

B<Definition:> This will indicate if the zip reader was able to open the base file
with Archive::Zip as a zip file.

B<Accepts:> nothing

B<Returns:> (1|0) 1 = good file

=back

=head1 SUPPORT

=over

L<github Spreadsheet::Reader::ExcelXML/issues
|https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues>

=back

=head1 TODO

=over

B<1.> Nothing currently

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2016 by Jed Lund

=head1 DEPENDENCIES

=over

L<Spreadsheet::Reader::ExcelXML> - the package

=back

=head1 SEE ALSO

=over

L<Spreadsheet::Read> - generic Spreadsheet reader

L<Spreadsheet::ParseExcel> - Excel binary version 2003 and earlier (.xls files)

L<Spreadsheet::XLSX> - Excel version 2007 and later

L<Spreadsheet::ParseXLSX> - Excel version 2007 and later

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end   5#########6#########7#########8#########9
