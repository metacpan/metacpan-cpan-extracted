package Spreadsheet::XLSX::Reader::LibXML::XMLReader::NamedStyles;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::XMLReader::NamedStyles-$VERSION";

use 5.010;
use Moose::Role;
requires qw(
		location_status			start_the_file_over			advance_element_position
		parse_element			squash_node					parse_excel_format_string
	);
use Types::Standard qw( Bool HashRef );
use Carp qw( confess );
use Clone qw( clone );

#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9

my	$cell_attributes ={
		Font			=> 'cell_font',
		Borders			=> 'cell_border',
		Interior		=> 'cell_fill',
		'ss:ID'			=> 'cell_style',
		NumberFormat	=> 'cell_coercion',
		Alignment		=> 'cell_alignment',
	};

my	$xml_from_cell ={
		cell_font		=> 'fontId',
		cell_border		=> 'borderId',
		cell_fill		=> 'fillId',
		cell_style		=> 'xfId',
		cell_coercion	=> 'numFmtId',
		cell_alignment	=> 'alignment',
	};

my $date_keys ={# SpreadsheetML to Excel 2007+ custom date formats
		'Short Date'	=> 'yyyy-mm-dd',
		'Fixed'			=> '0.00',
	};

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9
	
has cache_positions =>(
		isa		=> Bool,
		reader	=> 'should_cache_positions',
		default	=> 1,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub get_format{
	my( $self, $name, $header, $exclude_header ) = @_;
	my	$xml_target_header = $header ? $header : '';#$xml_from_cell->{$header}
	my	$xml_exclude_header = $exclude_header ? $exclude_header : '';
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_format', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Get defined formats named: $name",
	###LogSD			( $header ? "Returning only the values for header: $header - $xml_target_header" : '' ),
	###LogSD			( $exclude_header ? "..excluding the values for header: $exclude_header - $xml_exclude_header" : '' ) , ] );
	
	
	my $target_ref;
	my $found_it = 0;
	if( $self->_has_styles ){# Check for stored value - when caching implemented
		if( !$self->_has_s_name( $name ) ){
			$self->set_error( "Style named |$name| is not recorded!" );
			return undef;
		}
		$target_ref = clone( $self->_get_s_name( $name ) );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The complete cached style is:", $target_ref, ] );
		$found_it = 1;
	}else{# pull the value the long (hard and slow) way
		my $x = 0;
		$self->start_the_file_over;
		while( !$found_it ){
			###LogSD		$phone->talk( level => 'debug', message => [
			###LogSD			"Looking for a 'Style' node on pass: $x", ] );
			$self->advance_element_position( 'Styles', 1 );
			my ( $node_depth, $node_name, $node_type ) = $self->location_status;
			###LogSD		$phone->talk( level => 'debug', message => [
			###LogSD			"Arrived at node name: $node_name", ] );
			last if $node_name ne 'Styles';
			my $xml_ref = $self->parse_element;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Parsing the node to find the name", $xml_ref ] );
			my $perlized_ref = $self->squash_node( $xml_ref );
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"After squashing:", $perlized_ref ] );
			( my $element_name, $target_ref ) = $self->_add_style_element( $perlized_ref );
			if( $element_name eq $name ){
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Found requested node named: $element_name" ] );
				$found_it = 1;
				last;
			}
		}
	}
	
	# Restrict the return value based on passed parameters
	if( $found_it ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The style named -$name- is:", $target_ref  ] );
		if( $header ){
			$target_ref = $target_ref->{$header} ? { $header => $target_ref->{$header} } : undef;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The style with target header -$header- only is:", $target_ref  ] );
		}elsif( $exclude_header ){
			delete $target_ref->{$exclude_header};
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The style with exclude header -$exclude_header- removed is:", $target_ref  ] );
		}
	}
	return $target_ref;
}

sub get_default_format{#### Re-use the get_format method for this since we are using names
	my( $self, $header, $exclude_header ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_default_format', );
	my	$name = 'Default';
	###LogSD		$phone->talk( level => 'info', message =>[ "Get the 'Default' format" ] );
	return $self->get_format( $name, $header, $exclude_header );
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _loaded =>(
		isa		=> Bool,
		writer	=> '_good_load',
		reader	=> 'loaded_correctly',
		default	=> 0,
	);
	
has _styles =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		handles	=>{
			_get_s_name => 'get',
			_set_s_name => 'set',
			_has_s_name => 'exists',
		},
		reader => '_get_all_cache',
		predicate => '_has_styles'
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_load_unique_bits', );
	my $good_load = 0;
	$self->start_the_file_over;
	my ( $node_depth, $node_name, $node_type ) = $self->location_status;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Currently at libxml2 level: $node_depth",
	###LogSD		"Current node name: $node_name",
	###LogSD		"..for type: $node_type", ] );
	my	$result = 1;
	if( $node_name eq 'Styles' ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"already at the Styles node" ] );
	}else{
		$result = $self->advance_element_position( 'Styles' );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"attempt to get to the Styles element result: $result" ] );
	}
	
	# Check for empty node
	$self->_read_next_node;
	if( ($self->location_status)[1] eq 'EOF' ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The Styles node is empty" ] );
		$result = 0;
	}else{
		$self->start_the_file_over;# Only works for extracted styles nodes
	}
	
	# Record file state
	if( $result ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The Styles node has value" ] );
		$self->_good_load( 1 );
	}else{
		$self->set_error( "No 'Styles' element with content found - can't parse this as a styles file" );
		return undef;
	}
	
	# Initial pull from the xml
	if( $self->should_cache_positions ){
		my $top_level_ref = $self->parse_element;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Parsing the whole thing for caching" ] );
		$self->_close_file_and_reader;# Don't need the file open any more!
		# Custom number formats are not position based here
		my $perlized_ref = $self->squash_node( $top_level_ref );
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"After squashing:", $perlized_ref ] );
		
		my $style_ref;
		# Handle the single style case
		if( exists $perlized_ref->{Style} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Converting a single style node" ] );
			$self->_add_style_element( $perlized_ref->{Style} );
		}else{
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Converting a list of style nodes" ] );
			for my $style ( @{$perlized_ref->{list}} ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Loading:", $style ] );
				$self->_add_style_element( $style );
			}
		}
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Final style ref:",  $self->_get_all_cache ] );
		
	}
	return 1;
}

sub _add_style_element{
	my( $self, $sub_element ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_load_unique_bits::_add_style_element', );
	###LogSD		$phone->talk( level => 'trace', message =>[
	###LogSD			"Adding sub element:", $sub_element, "To style ref:", $self->_get_all_cache ] );
	( my $element_name, $sub_element ) = $self->_transform_element( $sub_element );
	$self->_set_s_name( $element_name => $sub_element );
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Updated style ref:", $self->_get_all_cache ] );
}

sub _transform_element{
	my( $self, $sub_element ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_load_unique_bits::_transform_element', );
	###LogSD		$phone->talk( level => 'trace', message =>[
	###LogSD			"Transforming sub element:", $sub_element, ] );
	my ( $element_name, $new_sub );
	for my $key ( keys %$sub_element ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Processing sub element key: $key" ] );
		if( exists $cell_attributes->{$key} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Key matches cell attribute: $cell_attributes->{$key}" ] );
			if( $key =~ /\:ID/ ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Found the style name: $sub_element->{$key}" ] );
				$element_name = $sub_element->{$key};
				$new_sub->{$cell_attributes->{$key}} = $element_name;
			}elsif( $key =~ /NumberFormat/ ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Found a number format: ", $sub_element->{$key} ] );
				my $replaced_string = 
					!defined $sub_element->{$key} ? undef :
					exists( $date_keys->{$sub_element->{$key}->{'ss:Format'}} ) ? 
						$date_keys->{$sub_element->{$key}->{'ss:Format'}} :
						$sub_element->{$key}->{'ss:Format'} ;
				if( $replaced_string ){
					$replaced_string =~ /^(\[[A-Z]{3}\])?(.*)/;######### Take this back out when localization is implemented
					$replaced_string = $2;
				}
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Processing the date format string: " . ($replaced_string//'undef') ] );
				$new_sub->{$cell_attributes->{$key}} = 
					defined( $replaced_string ) ? 
						$self->parse_excel_format_string( $replaced_string ) : undef;
			}else{
				$new_sub->{$cell_attributes->{$key}} = $sub_element->{$key};
			}
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updated new sub:", $new_sub ] );
		}
	}
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Returning element name: $element_name" ] );
	###LogSD	$phone->talk( level => 'trace', message =>[ "..with ref:", $new_sub ] );
	return( $element_name, $new_sub );
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::XMLReader::NamedStyles - Excel 2003 Styles modifier

=head1 SYNOPSYS

Not written yet

=head1 DESCRIPTION

Not written yet

=head1 SEE ALSO

=over

L<Spreadsheet::ParseExcel> - Binary Excel 2003 and earlier

L<Spreadsheet::XLSX> - 2007+

L<Spreadsheet::ParseXLSX> - 2007+

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end   5#########6#########7#########8#########9