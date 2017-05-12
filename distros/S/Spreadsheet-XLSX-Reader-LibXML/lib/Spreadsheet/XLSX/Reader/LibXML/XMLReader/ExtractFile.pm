package Spreadsheet::XLSX::Reader::LibXML::XMLReader::ExtractFile;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::XMLReader::ExtractFile-$VERSION";

use	Moose::Role;
use Clone 'clone';
use Carp 'confess';
use Data::Dumper;
use Types::Standard qw( is_HashRef HashRef Str is_Int is_ArrayRef );
requires qw(
	get_header 			start_the_file_over				advance_element_position
	parse_element		set_exclude_match				location_status
),
###LogSD	'get_all_space'
;
use File::Temp qw/ :seekable /;
#~ $File::Temp::DEBUG = 1;
use lib	'../../../../../lib',;
#~ ###LogSD	use Log::Shiras::Telephone;

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9

my	$default_top_level_attributes ={
		xmlns => "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
		'xmlns:r' => "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
	};

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub extract_file{###### All available potential nodes will be added if none are found only the first listed node will show as an empty node
    my ( $self, @node_list ) = ( @_ );
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::extract_file', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			'Arrived at extract_file for the nodes:', @node_list ] );
	#~ ###LogSD		$self->_print_current_file( $self->get_file );
	
	# Get the header
	my 	$file_string = $self->get_header;
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Header string: $file_string" ] );
	
	# Build a temp file and load it with the file string
	my	$fh = File::Temp->new();
	print $fh "$file_string";########## No newlines since there are differences between windows 
	###LogSD	$self->_print_current_file( $fh );
	
	# Add nodes
	my $found_a_node = 0;
	my $first_node;
	for my $node_name ( @node_list ){
		my @parse_commands = is_ArrayRef( $node_name ) ? @$node_name : ( $node_name );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Advancing to node -$parse_commands[0]- incrememtally: " . ($parse_commands[1]//1),  $self->location_status ] );
		###LogSD		$self->_print_current_file( $self->get_file );
		$self->start_the_file_over;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"File reset to the beginning" ] );
		$first_node = $parse_commands[0] if !defined $first_node;
		my $result = $self->advance_element_position( @parse_commands );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Advance result: " . ($result//'fail')] );
		if( $result ){
			my $node_string = $self->get_node_all;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Node string:", $node_string ] );
			if( is_ArrayRef( $node_string ) ){
				map{ print $fh $_ } @$node_string;
			}else{
				print $fh $node_string;
			}
			###LogSD	$self->_print_current_file( $fh );
			$found_a_node = 1;
		}
	}
	
	# Add the first node as an empty node if none found
	if( !$found_a_node ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		'None of the requested nodes were found', ] );
		print $fh "<$first_node/>";# Returns a dummy file - file content should be tested by file type
		###LogSD	$self->_print_current_file( $fh );
	}
	
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		'Final file handle:', $fh ] );
	###LogSD	$self->_print_current_file( $fh );
	return $fh;
}

	

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _file_headers =>(
		isa		=> HashRef,
		reader	=> '_get_file_headers',
		writer	=> '_set_file_headers',
		clearer	=> '_clear_file_headers',
	); 

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

###LogSD	sub _print_current_file{
	###LogSD    my ( $self, $ref ) = ( @_ );
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_hidden::_print_current_file', );
	###LogSD	my $line =  ( caller(0) )[2];
	###LogSD	if( !$ref ){
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"The file handle sent from line -$line- is empty" ], );
	###LogSD    }else{
	###LogSD		$ref->seek( 0, 0 );
	###LogSD		my( $next_line, $print_string );
	###LogSD		while( $next_line = <$ref>  ){
	#~ ###LogSD			chomp( $next_line );
	###LogSD			next if $next_line =~ /^\s*$/;
	###LogSD			$print_string .= $next_line;
	###LogSD    	}
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"For code line -$line- the file is:", $print_string ]);
	###LogSD    }
###LogSD	}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::XMLReader::ExtractFile - XMLReader (non Zip) file extractor

=head1 DESCRIPTION

Not written yet!

=head1 SEE ALSO

=over

L<Spreadsheet::ParseExcel> - Excel 2003 and earlier

L<Spreadsheet::ParseXLSX> - 2007+

L<Spreadsheet::Read> - Generic

L<Spreadsheet::XLSX> - 2007+

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9