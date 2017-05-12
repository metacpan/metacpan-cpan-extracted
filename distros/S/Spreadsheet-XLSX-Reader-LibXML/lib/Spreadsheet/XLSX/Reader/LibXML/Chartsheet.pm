package Spreadsheet::XLSX::Reader::LibXML::Chartsheet;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::Chartsheet-$VERSION";

use	5.010;
use	Moose;
use	MooseX::StrictConstructor;
use	MooseX::HasDefaults::RO;
use Carp qw( confess );
use Types::Standard qw(
		Int				Str				ArrayRef
		HashRef			HasMethods		Bool
		Enum
    );
use lib	'../../../../../../lib';
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::UnhideDebug;
###LogSD	sub get_class_space{ 'Chartsheet' }
extends	'Spreadsheet::XLSX::Reader::LibXML::XMLReader';

#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has sheet_type =>(
		isa		=> Enum[ 'chartsheet' ],
		default	=> 'chartsheet',
		reader	=> 'get_sheet_type',
	);

has sheet_rel_id =>(
		isa		=> Str,
		reader	=> 'rel_id',
	);

has sheet_id =>(
		isa		=> Int,
		reader	=> 'sheet_id',
	);

has sheet_position =>(# XML position
		isa		=> Int,
		reader	=> 'position',
	);

has sheet_name =>(
		isa		=> Str,
		reader	=> 'get_name',
	);

has drawing_rel_id =>(
		isa		=> Str,
		writer	=> '_set_drawing_rel_id',
		reader	=> 'get_drawing_rel_id',
	);
	
has workbook_instance =>(
		isa		=> HasMethods[qw(
						counting_from_zero			boundary_flag_setting
						change_boundary_flag		_has_shared_strings_file
						get_shared_string_position	_has_styles_file
						get_format_position			set_empty_is_end
						is_empty_the_end			_starts_at_the_edge
						get_group_return_type		set_group_return_type
						get_epoch_year				change_output_encoding
						get_date_behavior			set_date_behavior
						get_empty_return_type		set_error
						get_values_only				set_values_only
					)],
		handles	=> [qw(
						counting_from_zero			boundary_flag_setting
						change_boundary_flag		_has_shared_strings_file
						get_shared_string_position	_has_styles_file
						get_format_position			set_empty_is_end
						is_empty_the_end			_starts_at_the_edge
						get_group_return_type		set_group_return_type
						get_epoch_year				change_output_encoding
						get_date_behavior			set_date_behavior
						get_empty_return_type		set_error
						get_values_only				set_values_only
					)],
		required => 1,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9



#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _load_unique_bits{
	my( $self, ) = @_;#, $new_file, $old_file
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_load_unique_bits', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Setting the Chartsheet unique bits", "Byte position: " . $self->byte_consumed ] );
	
	#collect the drawing rel_id
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Loading the relID" ] );
	if( $self->next_element('drawing') ){
		my	$rel_id = $self->get_attribute( 'r:id' );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The relID is: $rel_id", ] );
		$self->_set_drawing_rel_id( $rel_id );
	}else{
		confess "Couldn't find the drawing relID for this chart";
	}
	#~ $self->start_the_file_over;# not needed yet
	return 1;
}

#~ sub DEMOLISH{
	#~ my ( $self ) = @_;
	#~ ###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	#~ ###LogSD				$self->get_all_space . '::hidden::DEMOLISH', );
	#~ ###LogSD		$phone->talk( level => 'debug', message => [
	#~ ###LogSD			"Closing the chartsheet object" ] );
	#~ print "Chartsheet closed\n";
#~ }

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::XMLReader::Chartsheet - A LibXML::XMLReader chartsheet base class

=head1 SYNOPSIS

See the SYNOPSIS in L<Spreadsheet::XLSX::Reader::LibXML>
    
=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your 
own excel parser or extending this package.  To use the general package for excel 
parsing out of the box please review the documentation for L<Workbooks
|Spreadsheet::XLSX::Reader::LibXML>, L<Worksheets
|Spreadsheet::XLSX::Reader::LibXML::Worksheet>, and 
L<Cells|Spreadsheet::XLSX::Reader::LibXML::Cell>.

This class is written to extend L<Spreadsheet::XLSX::Reader::LibXML::XMLReader>.  
It addes to that functionality specifically to read any 'chartsheet'.xml sub files.  
Chartsheet files are not charts they are just tabs in a workbook similar to 'worksheets' 
that only hold one chart. This POD only describes the functionality incrementally provided 
by this module.  For an overview of sharedStrings.xml reading see 
L<Spreadsheet::XLSX::Reader::LibXML::Chartsheet>

=head2 Extending the chartsheet class

I don't have any good ideas yet.  Outside input welcome.

=head2 Attributes

Data passed to new when creating an instance.   For modification of these attributes 
see the listed 'attribute methods'. For more information on attributes see 
L<Moose::Manual::Attributes>.  I<It may be that these attributes migrate based on the 
reader type.>

=head3 file

=over

B<Definition:> This needs to be the full file path to the sharedStrings file or an 
opened file handle .  When set it will coerce to a file handle and then will open 
and read the primary settings in the sharedStrings.xml file and then maintain an open 
file handle for accessing specific sharedStrings position information.

B<Required:> Yes

B<Default:> none

B<Range> an actual Excel 2007+ sharedStrings.xml file or open file handle (with the 
pointer set to the beginning of the file)

B<attribute methods> Methods provided to adjust this attribute
		
=over

B<get_file>

=over

B<Definition:> Returns the value (file handle) stored in the attribute

=back

B<set_file>

=over

B<Definition:> Sets the value (file handle) stored in the attribute. Then triggers 
a read of the file level unique bits.

=back

B<has_file>

=over

B<Definition:> predicate for the attribute

=back

=back

=back

=head3 error_inst

=over

B<Definition:> Currently all ShareStrings readers require an 
L<Error|Spreadsheet::XLSX::Reader::LibXML::Error> instance.  In general the 
package will share an error instance reference between the workbook and all 
classes built during the initial workbook build.

B<Required:> Yes

B<Default:> none

B<Range:> The minimum list of methods to implement for your own instance is;

	error set_error clear_error set_warnings if_warn

B<attribute methods> Methods provided to adjust this attribute
		
=over

B<get_error_inst>

=over

B<Definition:> returns this instance

=back

B<error>

=over

B<Definition:> Used to get the most recently logged error

=back

B<set_error>

=over

B<Definition:> used to set a new error string

=back

B<clear_error>

=over

B<Definition:> used to clear the current error string in this attribute

=back

B<set_warnings>

=over

B<Definition:> used to turn on or off real time warnings when errors are set

=back

B<if_warn>

=over

B<Definition:> a method mostly used to extend this package and see if warnings 
should be emitted.

=back

=back

=back

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

=back

=head1 TODO

=over

B<1.> Nothing L<yet|/SUPPORT>

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

This software is copyrighted (c) 2014 by Jed Lund

=head1 DEPENDENCIES

=over

L<Spreadsheet::XLSX::Reader::LibXML>

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

#########1 Documentation End  3#########4#########5#########6#########7#########8#########9