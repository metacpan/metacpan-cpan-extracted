package Spreadsheet::XLSX::Reader::LibXML::ZipReader;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::ZipReader-$VERSION";

use 5.010;
use Moose;
use MooseX::StrictConstructor;
use MooseX::HasDefaults::RO;
use Types::Standard qw(
		HasMethods			Bool			Str	
    );#Int		Num	
use	Archive::Zip qw( AZ_OK );
use Capture::Tiny qw( capture_stderr );
use Carp 'confess';
use lib	'../../../../../lib',;
###LogSD	with 'Log::Shiras::LogSpace';
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::UnhideDebug;
use Spreadsheet::XLSX::Reader::LibXML::Types qw(
		IOFileType
	);

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
		isa			=> 	Str,
		reader		=> 'get_file_type',
		default		=> 'zip',
	);

has workbook_inst =>(
		isa	=> 'Spreadsheet::XLSX::Reader::LibXML', 
		handles =>[ qw(
			error set_error clear_error
		)],
		writer	=> 'set_workbook_inst',
		weak_ref => 1,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

	

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

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
	###LogSD			$self->get_all_space . '::XMLReader::_build_zip_reader', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"turning a file handle into a zip reader", ] );
	
    # Read the XLSX zip file and catch any errors (other zip file sanity tests go here)
	my $workbook_file = Archive::Zip->new();
	my $read_state;
	my $error_message = capture_stderr{ $read_state = $workbook_file->readFromFileHandle($self->get_file) };
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
	}
}

#~ sub DEMOLISH{
	#~ my ( $self ) = @_;
	#~ ###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	#~ ###LogSD			$self->get_all_space . '::XMLReader::DEMOLISH', );
	#~ ###LogSD		$phone->talk( level => 'debug', message => [
	#~ ###LogSD			"clearing the zip reader for log space:", $self->get_log_space, ] );
	#~ print "ZipReader closed\n";
	
	#~ # Clear the reader
	#~ if( $self->_has_zip_parser ){
		#~ print "Disconnecting the sheet zip parser from the parser\n";
		#~ ###LogSD	$phone->talk( level => 'debug', message =>[ "Clearing the zip parser", ] );
		#~ $self->_clear_zip_parser;
	#~ }
	
	#~ # Clear the file
	#~ if( $self->has_file ){
		#~ ###LogSD	$phone->talk( level => 'debug', message =>[ "Closing and disconnecting the file handle for the zip parser", ] );
		#~ $self->clear_file;
	#~ }
#~ }

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::XMLReader - A LibXML::Reader xlsx base class

=head1 SYNOPSIS

	package MyPackage;
	use MooseX::StrictConstructor;
	use MooseX::HasDefaults::RO;
	extends	'Spreadsheet::XLSX::Reader::LibXML::XMLReader';
    
=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own excel 
parser.  To use the general package for excel parsing out of the box please review the 
documentation for L<Workbooks|Spreadsheet::XLSX::Reader::LibXML>,
L<Worksheets|Spreadsheet::XLSX::Reader::LibXML::Worksheet>, and 
L<Cells|Spreadsheet::XLSX::Reader::LibXML::Cell>

This module provides a generic way to open an xml file or xml file handle and then extract 
information using the L<XML::LibXML::Reader> parser.  The additional methods and attributes 
are intended to provide some coalated parsing commands that are specifically useful in turning 
xml to perl data structures.

=head2 Attributes

Data passed to new when creating an instance.  For modification of these attributes see the 
listed 'attribute methods'. For general information on attributes see 
L<Moose::Manual::Attributes>.  For ways to manage the instance when opened see the 
L<Methods|/Methods>.
	
=head3 file

=over

B<Definition:> This attribute holds the file handle for the file being read.  If the full 
file name and path is passed to the attribute it is coerced to an IO::File file handle.

B<Default:> no default - this must be provided to read a file

B<Required:> yes

B<Range:> any unencrypted xml file name and path or IO::File file handle

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

L<Delegated Methods>

=over

B<close>

=over

closes the file handle

=back

=back

=back

=head3 error_inst

=over

B<Definition:> This attribute holds the L<error handler
|Spreadsheet::XLSX::Reader::LibXML::Error>.

B<Default:> no default - this must be provided to read a file

B<Required:> yes

B<Range:> any object instance that can provide the required delegated methods.

B<attribute methods> Methods provided to adjust this attribute

=over

B<_clear_error_inst>

=over

clear the attribute value

=back

=back

B<_get_error_inst>

=over

get the attribute value

=back

=back

B<Delegated Methods (required)> Methods delegated to this module by the attribute
		
=over

B<error>

=over

B<Definition:> returns the currently stored error string

=back

B<set_error>

=over

B<Definition:> Sets the error string

=back

B<clear_error>

=over

B<Definition:> clears the error string

=back

B<set_warnings>

=over

B<Definition:> Sets the state that determins if the instance pro-activly 
warns with the error string when the error string is set.

=back

B<if_warn>

=over

B<Definition:> Returns the current state of the state value from 'set_warnings'

=back

=back

=head3 xml_version

=over

B<Definition:> This stores the xml version stored in the xml header.  It is read 
when the file handle is first set in this sheet.

B<Default:> no default - this is auto read from the header

B<Required:> no

B<Range:> xml versions

B<attribute methods> Methods provided to adjust this attribute

=over

B<_clear_xml_version>

=over

clear the attribute value

=back

=back

B<_set_xml_version>

=over

set the attribute value

=back

=back

=head3 xml_encoding

=over

B<Definition:> This stores the data encoding of the xml file from the xml header.  
It is read when the file handle is first set in this sheet.

B<Default:> no default - this is auto read from the header

B<Required:> no

B<Range:> valid xml file encoding

B<attribute methods> Methods provided to adjust this attribute

=over

B<encoding>

=over

get the attribute value

=back

=back

=over

B<has_encoding>

=over

predicate for the attribute value

=back

=back

=over

B<_clear_xml_encoding>

=over

clear the attribute value

=back

=back

B<_set_xml_encoding>

=over

set the attribute value

=back

=back

=head3 xml_header

=over

B<Definition:> This stores the xml header from the xml file.  It is read when 
the file handle is first set in this sheet.

B<Default:> no default - this is auto read from the header

B<Required:> no

B<Range:> valid xml file header

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_header>

=over

get the attribute value

=back

=back

=over

B<_set_xml_header>

=over

set the attribute value

=back

=back

=back

=head3 position_index

=over

B<Definition:> This attribute is available to facilitate other consuming roles and 
classes.  Of the attribute methods only the 'clear_location' method is used in this 
class during the 'start_the_file_over' method.  It can be used for tracking same level 
positions with the same node name.

B<Default:> no default - this is mostly managed by the child class or add on role

B<Required:> no

B<Range:> Integer

B<attribute methods> Methods provided to adjust this attribute

=over

B<where_am_i>

=over

get the attribute value

=back

=back

=over

B<i_am_here>

=over

set the attribute value

=back

=back

=over

B<clear_location>

=over

clear the attribute value

=back

=back

=over

B<has_position>

=over

set the attribute value

=back

=back

=back

=head2 Methods

These are the methods provided by this class.  They most likely should be agumented 
with file specific methods when extending this module.

=head3 start_the_file_over

=over

B<Definition:> This will disconnect the L<XML::LibXML::Reader> from the file handle,  
rewind the file handle, and then reconnect the L<XML::LibXML::Reader> to the file handle.

B<Accepts:> nothing

B<Returns:> nothing

=back

=head3 get_text_node

=over

B<Definition:> This will collect the text node at the current node position.  It will return 
two items ( $success_or_failure, $text_node_value )

B<Accepts:> nothing

B<Returns:> ( $success_or_failure(1|undef), ($text_node_value|undef) )

=back

=head3 get_attribute_hash_ref

=over

B<Definition:> Some nodes have attribute settings.  This method returns a hashref with any 
attribute settings attached as key => value pairs or an empty hash for no attributes

B<Accepts:> nothing

B<Returns:> { attribute_1 => attribute_1_value ... etc. }

=back

=head3 advance_element_position( [$node_name], [$number_of_times_to_index] )

=over

B<Definition:> This method will attempt to advance to $node_name (optional) or the next node 
if no $node_name is passed.  If there is an expectation of multiple nodes of the same name at 
the same level you can also pass $number_of_times_to_index (optional).  This will move through 
the xml file at the $node_name level the number of times indicated starting with wherever the 
xml file is already located.  Meaning $number_of_times_to_index is a relative index not an 
absolute index.

B<Accepts:> nothing

B<Returns:> success or failure for the method call

=back

=head3 location_status

=over

B<Definition:> This method gives three usefull location values with one call

B<Accepts:> nothing

B<Returns:> ( $node_depth (from the top of the file), $node_name, $node_type (xml numerical value for type) );

=back

=head2 Delegated Methods

These are the methods delegated to this class from L<XML::LibXML::Reader>.  For more 
general parsing of subsections of the xml file also see L<Spreadsheet::XLSX::Reader::LibXML>.

=head3 copy_current_node

=over

B<Delegated from:> L<XML::LibXML::Reader/copyCurrentNode (deep)>

Returns an XML::LibXML::Node object

=back

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

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

This software is copyrighted (c) 2014, 2015 by Jed Lund

=head1 DEPENDENCIES

=over

L<XML::LibXML::Reader>

=back

=head1 SEE ALSO

=over

L<Spreadsheet::ParseExcel> - Excel 2003 and earlier

L<Spreadsheet::XLSX> - 2007+

L<Spreadsheet::ParseXLSX> - 2007+

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end   5#########6#########7#########8#########9