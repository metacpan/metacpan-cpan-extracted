package Spreadsheet::Reader::Format::ParseExcelFormatStrings;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.6.4');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::Format::ParseExcelFormatStrings-$VERSION";

use 5.010;
use Moose::Role;
requires qw( get_defined_excel_format );
###LogSD	requires 'get_all_space',
		;
use Types::Standard qw(
		Int							Str						Maybe
		Num							HashRef					ArrayRef
		CodeRef						Object					ConsumerOf
		InstanceOf					HasMethods				Bool
		is_Object					is_Num					is_Int
    );
use Carp qw( confess longmess );
use	Type::Coercion;
use	Type::Tiny;
use DateTimeX::Format::Excel 0.014;
use DateTime::Format::Flexible;
use DateTime;
use Clone 'clone';
use lib	'../../../../lib',;
#~ ###LogSD	use Capture::Tiny 'capture_stderr';
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::Unhide;
use	Spreadsheet::Reader::Format::Types qw(
		PositiveNum					NegativeNum				ZeroOrUndef
		NotNegativeNum				Excel_number_0
	);#

#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9

my	$coercion_index		= 0;
my	@type_list			= ( PositiveNum, NegativeNum, ZeroOrUndef, Str );
my	$last_date_cldr		= 'yyyy-mm-dd';# This is critical to getting the next string to date conversion right
my	$last_duration		= 0;
my	$last_sub_seconds	= 0;
my	$last_format_rem	= 0;
my	$duration_order		={ h => 'm', m =>'s', s =>'0' };
my	$number_build_dispatch ={
		all =>[qw(
			_convert_negative
			_divide_by_thousands
			_convert_to_percent
			_split_decimal_integer
			_move_decimal_point
			_build_fraction
			_round_decimal
			_add_commas
			_pad_exponent
		)],
		scientific =>[qw(
			_convert_negative
			_split_decimal_integer
			_move_decimal_point
			_round_decimal
			_add_commas
			_pad_exponent
		)],
		percent =>[qw(
			_convert_negative
			_convert_to_percent
			_split_decimal_integer
			_round_decimal
			_add_commas
		)],
		fraction =>[qw(
			_convert_negative
			_split_decimal_integer
			_build_fraction
			_add_commas
		)],
		integer =>[qw(
			_convert_negative
			_divide_by_thousands
			_split_decimal_integer
			_round_decimal
			_add_commas
		)],
		decimal =>[qw(
			_convert_negative
			_divide_by_thousands
			_split_decimal_integer
			_round_decimal
			_add_commas
		)],
	};

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has workbook_inst =>(
		isa	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
		handles =>[ qw( set_error get_epoch_year )],
		writer	=> 'set_workbook_inst',
		predicate => '_has_workbook_inst',
	);

has	cache_formats =>(
		isa		=> Bool,
		reader	=> 'get_cache_behavior',
		writer	=> 'set_cache_behavior',
		default	=> 1,
	);

has	datetime_dates =>(
		isa		=> Bool,
		reader	=> 'get_date_behavior',
		writer	=> 'set_date_behavior',
		default	=> 0,
	);

has	european_first =>(
		isa		=> Bool,
		reader	=> 'get_european_first',
		writer	=> 'set_european_first',
		default	=> 0,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub get_defined_conversion{#  Add a test for this function in 08-parse...
	my( $self, $position, $target_name ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_defined_conversion', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Searching for the coercion for position: $position", ($target_name ? "With suggested name: $target_name" : '') ] );
	my	$coercion_string = $self->get_defined_excel_format( $position );
	if( !defined $coercion_string ){
		$self->set_error( "No coercion available for position: $position" );
		return undef;
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Position -$position- is associated with the string: $coercion_string", ] );
	my	$coercion = $self->parse_excel_format_string( $coercion_string, ($target_name//"Excel__$position") );
	if( !$coercion ){
		$self->set_error( "Unparsable conversion string at position -$position- found: $coercion_string" );
		return undef;
	}
	###LogSD	my $level =
	#~ ###LogSD		$position == 164 ? 'fatal' :
	###LogSD				'trace';
	###LogSD	$phone->talk( level => $level, message => [
	###LogSD		'Returning coercion:', $coercion,] );
	return $coercion;
}

sub parse_excel_format_string{
	my( $self, $format_strings, $coercion_name ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::parse_excel_format_string', );
	if( !defined $format_strings ){
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Nothing passed to convert",] );
		return Excel_number_0;
	}
	$format_strings =~ s/\\//g;
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"parsing the custom excel format string: $format_strings",
	###LogSD		($coercion_name ? "With passed name: $coercion_name" : '')] );
	my $conversion_type = 'number';
	# Check the cache
	my	$cache_key;
	if( $self->get_cache_behavior ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"checking stored cache of the key: $format_strings",
		###LogSD		'..searching in stored keys:', keys %{$self->_get_all_format_cache} ] );
		$cache_key	= $format_strings; # TODO fix the non-hashkey character issues;
		if( $self->_has_cached_format( $cache_key ) ){
			###LogSD		$phone->talk( level => 'debug', message => [
			###LogSD			"Format already built - returning stored value for: $cache_key", ] );
			return $self->_get_cached_format( $cache_key );
		}else{
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Building new format for key: $cache_key", ] );
		}
	}

	# Split into the four sections positive, negative, zero, and text
		$format_strings =~ s/General/\@/ig;# Change General to text input
	my	@format_string_list = split /;/, $format_strings;
	my	$last_is_text = ( $format_string_list[-1] =~ /^[A-Za-z\@\s\"]*$/ ) ? 1 : 0 ;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Is the last position text: $last_is_text",	scalar( @format_string_list ) ] );
	# Make sure the full range of number inputs are sent down the right path;
	my	@used_type_list = @{\@type_list};
	pop @used_type_list if !$last_is_text;
	if( scalar( @format_string_list ) == ( 2 + $last_is_text ) ){
		$used_type_list[0] = NotNegativeNum;#Maybe[NotNegativeNum];
		splice( @used_type_list, 2, 1 );
	}elsif( scalar( @format_string_list ) == ( 1 + $last_is_text ) ){
		$used_type_list[0] = Num;#Maybe[Num];
		splice( @used_type_list, 1, 2 );
	}elsif( scalar( @format_string_list ) == ( 0 + $last_is_text ) ){# Generally only true for text only formats
		@used_type_list = ();
		$used_type_list[0] = Str;
		$conversion_type = 'text';
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Now operating on each format string", @format_string_list,
	###LogSD		'..with used type list:', map{ $_->name } @used_type_list,	] );
	my	$format_position = 0;
	my	@coercion_list;
	my	$action_type;
	my	$is_date = 0;
	my	$date_text = 0;
	my	$last_deconstructed_list;
	for my $format_string ( @format_string_list ){
		$format_string =~ s/_.//g;# no character justification to other rows
		$format_string =~ s/\*//g;# Remove the repeat character listing (not supported here)
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Building format for: $format_string", ] );

		# Pull out all the straight through stuff
		my	@deconstructed_list;
		my	$x = 0;
			#~ $action_type = undef;
		while( defined $format_string and my @result = $format_string =~
					/^(													# Collect any formatting stuff first
						(AM\/PM|										# Date 12 hr flag
						A\/P|											# Another date 12 hr flag
						\[hh?\]|										# Elapsed hours
						\[mm\]|											# Elapsed minutes
						\[ss\]|											# Elapsed seconds
						[dmyhms]+)|										# DateTime chunks
						([0-9#\?]+[,\-\_]?[#0\?]*,*|					# Number string
						\.|												# Split integers from decimals
						[Ee][+\-]|										# Exponential notiation
						%)|												# Percentage
						(\@)											# Text input
					)?(													# Finish collecting format actions
					(\"[^\"]*\")|										# Anything in quotes just passes through
					(\[[^\]]*\])|										# Anything in brackets needs modification
					[\(\)\$\-\+\/\:\!\^\&\'\~\{\}\<\>\=\s]|				# All the pass through characters
					\,\s												# comma space for verbal separation
					)?(.*)/x											){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Now processing: $format_string", '..with result:', @result ] );
			my	$pre_action		= $1;
			my	$date			= $2;
			my	$number			= $3;
			my	$text			= $4;
			my	$fixed_value	= $5;
			my	$quote_string	= $6;
				$format_string	= $8;
			if( $fixed_value ){
				if( $fixed_value =~ /\[\$([^\-\]]*)\-?\d*\]/ ){# removed the localized element of fixed values
					$fixed_value = $1;
				}elsif( $fixed_value =~ /\[[^hms]*\]/ ){# Remove all color and conditionals as they will not be used
					$fixed_value = undef;
				}elsif( $fixed_value =~ /\"\-\"/ and $format_string ){# remove decimal justification for zero bars
					###LogSD	$phone->talk( level => 'trace', message => [
					###LogSD		"Initial format string: $format_string", ] );
					$format_string =~ s/^(\?+)//;
					###LogSD	$phone->talk( level => 'trace', message => [
					###LogSD		"updated format string: $format_string", ] );
				}
			}
			if( defined $pre_action ){
				my	$current_action =
						( $date ) ? 'DATE' :
						( defined $number ) ? 'NUMBER' :
						( $text ) ? 'TEXT' : 'BAD' ;
					$is_date = 1 if $date;
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Current action from -$pre_action- is: $current_action",
				###LogSD		"..now testing against: " . ($action_type//'')					] );
				if( $action_type and $current_action and ($current_action ne $action_type) and $action_type ne 'TEXT' ){
					###LogSD	$phone->talk( level => 'info', message => [
					###LogSD		"General action type: $action_type",
					###LogSD		"is failing current action: $current_action", ] );
					my $fail = 1;
					if( $action_type eq 'DATE' ){
						$conversion_type = 'date';
						###LogSD	$phone->talk( level => 'info', message => [
						###LogSD		"Checking the date mishmash", ] );
						if( $current_action eq 'NUMBER' ){
							###LogSD	$phone->talk( level => 'info', message => [
							###LogSD		"Special case of number following action", ] );
							if(	( $pre_action =~ /^\.$/ and $format_string =~ /^0+/				) or
								( $pre_action =~ /^0+$/ and $deconstructed_list[-1]->[0] =~ /^\.$/	)	){
								$current_action = 'DATE';
								$fail = 0;
							}
						}elsif( $pre_action eq '@' ){
							###LogSD	$phone->talk( level => 'info', message => [
							###LogSD		"Excel conversion of pre-epoch datestring pass through highjacked here", ] );
							$current_action = 'DATESTRING';
							$fail = 0;
						}
					}elsif( $action_type eq 'NUMBER' ){
						###LogSD	$phone->talk( level => 'info', message => [
						###LogSD		"Checking for possible number field exceptions", ] );
						if( $current_action eq 'TEXT' ){
							###LogSD	$phone->talk( level => 'info', message => [
							###LogSD		"Special case of text following a number", ] );
							$fail = 0;
						}
					}elsif( $action_type eq 'INTEGER' or $action_type eq 'DECIMAL'){
						###LogSD	$phone->talk( level => 'info', message => [
						###LogSD		"Checking for possible sub-Number generalities", ] );
						if( $current_action eq 'NUMBER' ){
							###LogSD	$phone->talk( level => 'info', message => [
							###LogSD		"Integers are numbers", ] );
							$fail = 0;
						}
					}
					if( $fail ){
						confess "Bad combination of actions in this format string: $format_strings - $action_type - $current_action";
					}
				}
				$action_type = $current_action if $current_action;
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		(($pre_action) ? "First action resolved to: $pre_action" : undef),
				###LogSD		(($fixed_value) ? "Extracted fixed value: $fixed_value" : undef),
				###LogSD		(($format_string) ? "Remaining string: $format_string" : undef),
				###LogSD		"With updated deconstruction list:", @deconstructed_list, ] );
			}else{
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Early elements unusable - remaining string: $fixed_value", $quote_string ] );
				$action_type = 'TEXT' if $quote_string and $fixed_value eq $quote_string;
			}
			push @deconstructed_list, [ $pre_action, $fixed_value ];
			if( $x++ == 30 ){
				confess "Attempts to use string |$format_string| as an excel custom format failed. Contact the author jandrew\@cpan (.org) if you feel there is an error";
			}
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		(($pre_action) ? "First action resolved to: $pre_action" : undef),
			###LogSD		(($fixed_value) ? "Extracted fixed value: $fixed_value" : undef),
			###LogSD		(($format_string) ? "Remaining string: $format_string" : undef),
			###LogSD		"With updated deconstruction list:", @deconstructed_list, ] );
			last if length( $format_string ) == 0;
		}
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Handling action type: $action_type", ] );
		push @deconstructed_list, [ $format_string, undef ] if $format_string;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"List with fixed values separated:", @deconstructed_list ] );
		my $method = '_build_' . ( $action_type =~ /^(NUMBER|SCIENTIFIC|INTEGER|PERCENT|FRACTION|DECIMAL)$/ ? 'number' : lc($action_type) );
		###LogSD	$phone->talk( level => 'info', message => [ "Method: $method",  ] );
		my $filter = ( $action_type and $action_type eq 'TEXT' ) ? Str : $used_type_list[$format_position++];
		if( $action_type and $action_type eq 'DATESTRING' ){
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Found date string and making adjustments with:", @deconstructed_list, $last_deconstructed_list ] );
			$date_text = 1;
			$filter = Str;
			@deconstructed_list = @$last_deconstructed_list if $last_deconstructed_list;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updated deconstructed list:", @deconstructed_list, ] );
		}
		$last_deconstructed_list = clone( [@deconstructed_list] );

		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Running method -$method- for list:", @deconstructed_list ] );
		my( $intermediate_action, @intermediate_coercions ) = $self->$method( $filter, \@deconstructed_list, $format_string );
		###LogSD	$phone->talk( level => 'trace', message => [ "Returning from: $method", $intermediate_action, @intermediate_coercions ] );
		push @coercion_list, @intermediate_coercions;
		$action_type = $intermediate_action =~ /^(NUMBER|SCIENTIFIC|INTEGER|PERCENT|FRACTION|DECIMAL|DATE|DATESTRING)$/ ? $intermediate_action : $action_type;
		###LogSD	$phone->talk( level => 'trace', message => [ "Action type: $action_type", $intermediate_action, @coercion_list ] );
	}
	if( $is_date and !$date_text ){
		( my $intermediate_action, my @intermediate_coercions ) = $self->_build_datestring( Str, $last_deconstructed_list );
		push @coercion_list, @intermediate_coercions;
		$action_type = $intermediate_action =~ /^(NUMBER|SCIENTIFIC|INTEGER|PERCENT|FRACTION|DECIMAL|DATE|DATESTRING)$/ ? $intermediate_action : $action_type;
		###LogSD	$phone->talk( level => 'info', message => [ "Adjusted action type: $action_type", ] );
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		'Length of coersion list: ' . scalar( @coercion_list ),
	###LogSD		"Action type: $action_type", "Conversion type: $conversion_type", ] );
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		($coercion_name ? "Initial coercion name: $coercion_name" : ''), ] );

	# Build the final format
	#~ $conversion_type = 'text' if $action_type eq 'TEXT';
	$coercion_name =~ s/__/_${conversion_type}_/ if $coercion_name;
	###LogSD	$phone->talk( level => 'info', message => [ "Action type: $action_type" ] );
	my	%args = (
			name			=> $action_type,
			display_name	=> ($coercion_name // ($action_type . '_' . $coercion_index++)),
			coercion		=>	Type::Coercion->new(
								type_coercion_map => [ @coercion_list ],
							),
			#~ coerce		=> 1,
		);
	my	$final_type = Type::Tiny->new( %args );
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Final type:", $final_type ] );

	# Save the cache
	if( $self->get_cache_behavior ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"setting cache for key:", $cache_key ] );
		$self->_set_cashed_format( $cache_key => $final_type );
	}

	return $final_type;
}


#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has	_format_cash =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		reader	=> '_get_all_format_cache',
		handles =>{
			_has_cached_format => 'exists',
			_get_cached_format => 'get',
			_set_cashed_format => 'set',
		},
		default	=> sub{ {} },
	);

has	_alt_epoch_year =>(
		isa		=> Int,
		reader	=> '_get_alt_epoch_year',
		default	=> 1900,
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _build_text{
	my( $self, $type_filter, $list_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_text', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building an anonymous sub to process text values", $list_ref ] );
	my $sprintf_string;
	my $found_string = 0;
	my $alt_string;
	for my $piece ( @$list_ref ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"processing text piece:", $piece ] );
		if( !$found_string and defined $piece->[0] ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The first element is defined:", $piece->[0] ] );
			$sprintf_string .= '%s';
			$found_string = 1;
		}
		if( $piece->[1] ){
			$piece->[1] =~ s/\"(.*)\"/$1/g;# Remove quotes around text strings (mostly spaces?)
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Adding fixed value |$piece->[1]|" ] );
			$sprintf_string .= $piece->[1];
			$alt_string .= $piece->[1];
		}
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Final sprintf string: $sprintf_string",
	###LogSD		"Final alt string: " . ($alt_string//'undef') ] );
	my $return_sub;
	###LogSD	my $sub_phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_log_space . '::Cell::_hidden::_return_value_only::_build_text', );
	if( $found_string ){
		$return_sub = sub{
			#~ print "Using Text sub!!!!!!\n";
			###LogSD	$sub_phone->talk( level => 'debug', message => [
			###LogSD		"Updated Input: $_[0]" ] );
			return sprintf( $sprintf_string, $_[0] );
		};
	}else{
		$return_sub = sub{
			#~ print "Using Text sub!!!!!!\n";
			###LogSD	$sub_phone->talk( level => 'debug', message => [
			###LogSD		"Received Input |$_[0]| -> returning $alt_string" ] );
			return $alt_string;
		};
	}
	return( 'TEXT', Str, $return_sub );
}

sub _build_date{
	my( $self, $type_filter, $list_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_date', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building an anonymous sub to process date values", $list_ref ] );

	my	$build_ref;#
	@$build_ref{qw( is_duration sub_seconds )} = ( 0, 0 );
	# Process once to build the cldr string and other flags
	@$build_ref{qw( cldr_string is_duration sub_seconds format_remainder )} = $self->_build_date_cldr( $list_ref );
	my	$clone_ref = clone( $build_ref );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Conversion sub will use ref: ", $clone_ref ] );
	my	@args_list = ( $self->get_epoch_year == 1904 ) ? ( system_type => 'apple_excel' ) : ();
	my	$converter = DateTimeX::Format::Excel->new( @args_list );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Building sub with:", @args_list, "And get_date_behavior set to: " . $self->get_date_behavior	] );
	my	$conversion_sub = sub{
			my	$num = $_[0];
			if( !defined $num ){
				return undef;
			}
			#~ print "Using Date sub!!!!!!\n";
			###LogSD	my $sub_phone = Log::Shiras::Telephone->new( name_space =>
			###LogSD			$self->get_log_space . '::Cell::_hidden::_return_value_only::_build_date', );
			###LogSD	$sub_phone->talk( level => 'debug', message => [
			###LogSD		"Processing date number: $num",
			###LogSD		'..with adjustement ref:', $clone_ref, ] );
			my	$dt = $converter->parse_datetime( $num );
			my $return_string;
			my $calc_sub_secs;
			if( $clone_ref->{is_duration} ){
				my	$di = $dt->subtract_datetime_absolute( $converter->_get_epoch_start );
				if( $self->get_date_behavior ){
					return $di;
				}
				my	$sign = DateTime->compare_ignore_floating( $dt, $converter->_get_epoch_start );
				$return_string = ( $sign == -1 ) ? '-' : '' ;
				my $key = $clone_ref->{is_duration}->[0];
				my $delta_seconds	= $di->seconds;
				my $delta_nanosecs	= $di->nanoseconds;
				$return_string .= $self->_build_duration( $clone_ref->{is_duration}, $delta_seconds, $delta_nanosecs );
				###LogSD	$sub_phone->talk( level => 'debug', message => [
				###LogSD		"Duration return string: $return_string" ] );
			}else{
				if( $self->get_date_behavior ){
					###LogSD	$sub_phone->talk( level => 'debug', message => [
					###LogSD		"Returning the DateTime object rather than the format string" ] );
					return $dt;
				}
				if( $clone_ref->{sub_seconds} ){
					$calc_sub_secs = $dt->format_cldr( $clone_ref->{sub_seconds} );
					###LogSD	$sub_phone->talk( level => 'debug', message => [
					###LogSD		"Processing sub-seconds: $calc_sub_secs" ] );
					if( "0.$calc_sub_secs" >= 0.5 ){
						###LogSD	$phone->talk( level => 'debug', message => [
						###LogSD		"Rounding seconds back down" ] );
						$dt->subtract( seconds => 1 );
					}
				}
				###LogSD	$sub_phone->talk( level => 'debug', message => [
				###LogSD		"Converting it with CLDR string: " . ($clone_ref->{cldr_string}//'undef') ] );
				if( $clone_ref->{cldr_string} ){
					$return_string .= $dt->format_cldr( $clone_ref->{cldr_string} );
				}else{
					$self->set_error( "No cldr string passed where one is expected while processing |$num|" );
					$return_string .= scalar( $dt );
				}
				if( $clone_ref->{sub_seconds} and $clone_ref->{sub_seconds} ne '1' ){
					$return_string .= $calc_sub_secs;
				}
				$return_string .= $dt->format_cldr( $clone_ref->{format_remainder} ) if $clone_ref->{format_remainder};
			}
			###LogSD	$sub_phone->talk( level => 'debug', message => [
			###LogSD		"returning: $return_string" ] );
			return $return_string;
		};
	return( 'DATE', $type_filter, $conversion_sub, );
}

sub _build_datestring{
	my( $self, $type_filter, $list_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_datestring', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building an anonymous sub to process date strings", $list_ref, ] );

	my	$build_ref;#
	@$build_ref{qw( is_duration sub_seconds )} = ( 0, 0 );
	# Process once to build the cldr string and other flags
	@$build_ref{qw( cldr_string is_duration sub_seconds format_remainder )} = $self->_build_date_cldr( $list_ref );
	my	$clone_ref = clone( $build_ref );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Conversion sub will use ref: ", $clone_ref ] );
	my	$conversion_sub = sub{
			my	$date = $_[0];
			if( !$date ){
				return undef;
			}
			#~ print "Using DateString sub!!!!!!\n";
			###LogSD	my $sub_phone = Log::Shiras::Telephone->new( name_space =>
			###LogSD			$self->get_log_space . '::Cell::_hidden::_return_value_only::_build_datestring', );
			my $calc_sub_secs;
			###LogSD	$sub_phone->talk( level => 'debug', message => [
			###LogSD		"Processing date: $date", "..with clone_ref:", $clone_ref] );
			if( $date =~ /(.*:\d+)\.(\d+)(.*)/ ){
				$calc_sub_secs = $2;
				###LogSD	$sub_phone->talk( level => 'debug', message => [
				###LogSD		"updated sub seconds: " . ($calc_sub_secs//'undef') ] );
				$date = $1;
				$date .= $3 if $3;
				$calc_sub_secs .= 0 x (9 - length( $calc_sub_secs ));
			}
			###LogSD	$sub_phone->talk( level => 'debug', message => [
			###LogSD		"Processing new date string: $date",
			###LogSD		"..with stripped nanoseconds: " . ($calc_sub_secs//'undef'),
			###LogSD		"..against date return behaviour: " . $self->get_date_behavior,
			###LogSD		"..and format ref:", $clone_ref ] );
			my ( $dt_us, $dt_eu );
			eval '$dt_us = DateTime::Format::Flexible->parse_datetime( $date )';
			eval '$dt_eu = DateTime::Format::Flexible->parse_datetime( $date, european => 1, )';
			if( !$dt_us and !$dt_eu ){# handle double digit years in formats unreadable by ~::Flexible
				###LogSD	$sub_phone->talk( level => 'debug', message => [
				###LogSD		"Initial DateTime conversion failed - attempting backup work for: $date"		] );
				my	$current_year = DateTime->now()->truncate( to => 'year' );
				my	$century_prefix = substr( $current_year, 0, 2 );
				my	$century_postfix = substr( $current_year, 2, 2 );
				my	$bump_year = ( $century_postfix + 20 > 99 ) ? ( $century_postfix - 80 ) : undef;# The double digit years are probably less than 21 years in the future of the processing time
				my	$drop_year = ( $century_postfix - 79 < 0 ) ? ( $century_postfix + 21 ) : undef;# The double digit years are probably less than 81 years in the past of the processing time
				$date =~ /(\d{1,2})\D(\d{1,2})\D(\d{1,2})(\s|T)(\d{1,2})\D(\d{1,2})(\D(\d{1,2}))?/;
				if ( defined $1 and defined $2 and defined $3 ){
					###LogSD	$sub_phone->talk( level => 'debug', message => [
					###LogSD		"Processing date parse for: $date", $1, $2, $3, $4, $5, $6, $7 ] );
					my $year = $3;
					   $year = (
							(defined $bump_year and $year <= $bump_year ) ? $century_prefix + 1 :
							(defined $drop_year and $year >= $drop_year ) ? $century_prefix - 1 : $century_prefix ) . sprintf '%02u', $year;
					my $us_str = sprintf "%u-%02u-%02uT%02u:%02u:%02u", $year, $1, $2, $5, $6, ($7//'00');
					my $eu_str = sprintf "%u-%02u-%02uT%02u:%02u:%02u", $year, $2, $1, $5, $6, ($7//'00');
					eval '$dt_us = DateTime::Format::Flexible->parse_datetime( $us_str )';
					eval '$dt_eu = DateTime::Format::Flexible->parse_datetime( $eu_str )';# european => 1,
				}
			}
			my $dt =
				( $self->get_european_first and $dt_eu )? $dt_eu :# DD-MM-YY tested instead of MM-DD-YY
				( $dt_us ) ? $dt_us :  $dt_eu ;
			###LogSD	$sub_phone->talk( level => 'debug', message => [
			###LogSD		"Result of the processing of -$date- " . $dt	] );
			if( $dt ){
				$dt->add( nanoseconds => $calc_sub_secs ) if $calc_sub_secs;
				###LogSD	$sub_phone->talk( level => 'debug', message => [
				###LogSD		"Date building sucessfull - result to this point: $dt"		] );
			}else{
				###LogSD	$sub_phone->talk( level => 'debug', message => [
				###LogSD		"Unable to convert the string to a date time object: $date"		] );
				return $date;
			}
			my $return_string;
			if( $clone_ref->{is_duration} ){
				my	@args_list = ( $self->get_epoch_year == 1904 ) ? ( system_type => 'apple_excel' ) : ();
				my	$converter = DateTimeX::Format::Excel->new( @args_list );
				my	$di = $dt->subtract_datetime_absolute( $converter->_get_epoch_start );
				if( $self->get_date_behavior ){
					return $di;
				}
				my	$sign = DateTime->compare_ignore_floating( $dt, $converter->_get_epoch_start );
				$return_string = ( $sign == -1 ) ? '-' : '' ;
				my $key = $clone_ref->{is_duration}->[0];
				my $delta_seconds	= $di->seconds;
				my $delta_nanosecs	= $di->nanoseconds;;
				###LogSD	$sub_phone->talk( level => 'debug', message => [
				###LogSD		"Delta seconds: $delta_seconds",
				###LogSD		(($delta_nanosecs) ? "Delta nanoseconds: $delta_nanosecs" : undef) ] );
				$return_string .= $self->_build_duration( $clone_ref->{is_duration}, $delta_seconds, $delta_nanosecs );
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Duration return string: $return_string" ] );
			}else{
				if( $self->get_date_behavior ){
					return $dt;
				}
				if( $clone_ref->{sub_seconds} ){
					$calc_sub_secs = $dt->format_cldr( $clone_ref->{sub_seconds} );
					###LogSD	$sub_phone->talk( level => 'debug', message => [
					###LogSD		"Processing sub-seconds: $calc_sub_secs" ] );
					if( "0.$calc_sub_secs" >= 0.5 ){
						###LogSD	$sub_phone->talk( level => 'debug', message => [
						###LogSD		"Rounding seconds back down" ] );
						$dt->subtract( seconds => 1 );
					}
				}
				if( $clone_ref->{cldr_string} ){
					###LogSD	$sub_phone->talk( level => 'debug', message => [
					###LogSD		"Using CLDR string: $clone_ref->{cldr_string}\n", ] );
					$return_string .= $dt->format_cldr( $clone_ref->{cldr_string} );
				}else{
					$self->set_error( "No cldr string passed where one is expected while processing |$date|" );
					$return_string .= scalar( $dt );
				}
				if( $clone_ref->{sub_seconds} and $clone_ref->{sub_seconds} ne '1' ){
					$return_string .= $calc_sub_secs;
				}
				$return_string .= $dt->format_cldr( $clone_ref->{format_remainder} ) if $clone_ref->{format_remainder};
				###LogSD	$sub_phone->talk( level => 'debug', message => [
				###LogSD		"returning: $return_string" ] );
			}
			return $return_string;
		};
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"returning:",  'DATESTRING', $type_filter, $conversion_sub ] );
	return( 'DATESTRING', $type_filter, $conversion_sub );
}

sub _build_date_cldr{
	my( $self, $list_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_date_cldr', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"transforming an excel format string to the cldr equivalent", $list_ref ] );

	my ( $cldr_string, $format_remainder );
	my	$is_duration = 0;
	my	$sub_seconds = 0;
	# Process once to build the cldr string
	my $prior_duration;
	for my $piece ( @$list_ref ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"processing date piece:", $piece ] );
		if( defined $piece->[0] ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Manageing the cldr part: " . $piece->[0] ] );
			if( $piece->[0] =~ /\[(.+)\]/ ){
				###LogSD	$phone->talk( level => 'debug', message =>[ "Possible duration" ] );
				(my $initial,) = split //, $1;
				my $length = length( $1 );
				$is_duration = [ $initial, 0, [ $piece->[1] ], [ $length ] ];
				if( $is_duration->[0] =~ /[hms]/ ){
					$piece->[0] = '';
					$piece->[1] = '';
					$prior_duration = 	$is_duration->[0];
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"found a duration piece:", $is_duration,
					###LogSD		"with prior duration: $prior_duration"		] );
				}else{
					confess "Bad duration element found: $is_duration->[0]";
				}
			}elsif( ref( $is_duration ) eq 'ARRAY' ){
				###LogSD	$phone->talk( level => 'debug', message =>[ "adding to duration", $piece ] );
				my	$next_duration = $duration_order->{$prior_duration};
				if( $piece->[0] eq '.' ){
					push @{$is_duration->[2]}, $piece->[0];
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"found a period" ] );
				}elsif( $piece->[0] =~ /$next_duration/ ){
					my $length = length( $piece->[0] );
					$is_duration->[1]++;
					push @{$is_duration->[2]}, $piece->[1] if $piece->[1];
					push @{$is_duration->[3]}, $length;
					($prior_duration,) = split //, $piece->[0];
					if( $piece->[0] =~ /^0+$/ ){
						$piece->[0] =~ s/0/S/g;
						$sub_seconds = $piece->[0];
						###LogSD	$phone->talk( level => 'debug', message => [
						###LogSD		"found a subseconds format piece: $sub_seconds" ] );
					}
					$piece->[0] = '';
					$piece->[1] = '';
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Current duration:", $is_duration,
					###LogSD		"with prior duration: $prior_duration"	 ] );
				}else{
					confess "Bad duration element found: $piece->[0]";
				}
			}elsif( $piece->[0] =~ /m/ ){
				###LogSD	$phone->talk( level => 'debug', message =>[ "Minutes or Months" ] );
				if( ($cldr_string and $cldr_string =~ /:'?$/) or ($piece->[1] and $piece->[1] eq ':') ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Found minutes - leave them alone" ] );
				}else{
					$piece->[0] =~ s/m/L/g;
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Converting to cldr stand alone months (m->L)" ] );
				}
			}elsif( $piece->[0] =~ /h/ ){
				$piece->[0] =~ s/h/H/g;
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Converting 12 hour clock to 24 hour clock" ] );
			}elsif( $piece->[0] =~ /AM?\/PM?/i ){
				$cldr_string =~ s/H/h/g;
				$piece->[0] = 'a';
				###LogSD	$phone->talk( level => 'debug', message =>[ "Set 12 hour clock and AM/PM" ] );
			}elsif( $piece->[0] =~ /d{3,5}/ ){
				$piece->[0] =~ s/d/E/g;
				###LogSD	$phone->talk( level => 'debug', message =>[ "Found a weekday request" ] );
			}elsif( !$sub_seconds and $piece->[0] =~ /[\.]/){#
				$piece->[0] = "'.'";
				#~ $piece->[0] = "':'";
				$sub_seconds = 1;
				###LogSD	$phone->talk( level => 'debug', message =>[ "Starting sub seconds" ] );
			}elsif( $sub_seconds eq '1' ){
				###LogSD	$phone->talk( level => 'debug', message =>[ "Formatting sub seconds" ] );
				if( $piece->[0] =~ /^0+$/ ){
					$piece->[0] =~ s/0/S/g;
					$sub_seconds = $piece->[0];
					$piece->[0] = '';
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"found a subseconds format piece: $sub_seconds" ] );
				}else{
					confess "Bad sub-seconds element after [$cldr_string] found: $piece->[0]";
				}
			}
			if( $sub_seconds and $sub_seconds ne '1' ){
				$format_remainder .= $piece->[0];
			}else{
				$cldr_string .= $piece->[0];
			}
		}
		if( $piece->[1] ){
			if( $sub_seconds and $sub_seconds ne '1' ){
				$format_remainder .= $piece->[1];
			}else{
				$cldr_string .= $piece->[1];
			}
		}
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		(($cldr_string) ? "Updated CLDR string: $cldr_string" : undef),
		###LogSD		(($format_remainder) ? "Updated format remainder: $format_remainder" : undef),
		###LogSD		(($is_duration) ? ('Duration ref:', $is_duration) : undef)			] );
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Updated CLDR string: $cldr_string",
	###LogSD		(($is_duration) ? ('...and duration:', $is_duration) : undef ),
	###LogSD		(($sub_seconds) ? ('...and sub seconds:' . $sub_seconds) : undef ),
	###LogSD		(($format_remainder) ? ('...and format_remainder:' . $format_remainder) : undef )	] );
	return( $cldr_string, $is_duration, $sub_seconds, $format_remainder );
}

sub _build_duration{
	my( $self, $duration_ref, $delta_seconds, $delta_nanosecs ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_date::_build_duration', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Building a duration string with duration ref:', $duration_ref,
	###LogSD			"With delta seconds: $delta_seconds",
	###LogSD			(($delta_nanosecs) ? "And delta nanoseconds: $delta_nanosecs" : undef) ] );
	my	$return_string;
	my	$key = $duration_ref->[0];
	my	$first = 1;
	for my $position ( 0 .. $duration_ref->[1] ){
		if( $key eq '0' ){
			my $length = length( $last_sub_seconds );
			$return_string .= '.' . sprintf( "%0.${length}f", $delta_nanosecs/1000000000);
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Return string with nanoseconds: $return_string", ] );
		}
		if( $key eq 's' ){
			$return_string .= ( $first ) ? $delta_seconds :
				sprintf "%0$duration_ref->[3]->[$position]d", $delta_seconds;
			$first = 0;
			$key = $duration_order->{$key};
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Delta seconds: $delta_seconds",
			###LogSD		"Next key to process: $key"			] );
		}
		if( $key eq 'm' ){
			my $minutes = int($delta_seconds/60);
			$delta_seconds = $delta_seconds - ($minutes*60);
			$return_string .= ( $first ) ? $minutes :
				sprintf "%0$duration_ref->[3]->[$position]d", $minutes;
			$first = 0;
			$key = $duration_order->{$key};
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Calculated minutes: $minutes",
			###LogSD		"Remaining seconds: $delta_seconds",
			###LogSD		"Next key to process: $key"			] );
		}
		if( $key eq 'h' ){
			my $hours = int($delta_seconds /(60*60));
			$delta_seconds = $delta_seconds - ($hours*60*60);
			$return_string .= ( $first ) ? $hours :
				sprintf "%0$duration_ref->[3]->[$position]d", $hours;
			$first = 0;
			$key = $duration_order->{$key};
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Calculated hours: $hours",
			###LogSD		"Remaining seconds: $delta_seconds",
			###LogSD		"Next key to process: $key"			] );
		}
		$return_string .= $duration_ref->[2]->[$position] if $duration_ref->[2]->[$position];
	}
	return $return_string;
}

sub _build_number{
	my( $self, $type_filter, $list_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Processing a number list to see how it should be converted",
	###LogSD			'With type constraint: ' . $type_filter->name,
	###LogSD			'..using list ref:' , $list_ref 			] );
	my ( $code_hash_ref, $number_type, );

	# Resolve zero replacements quickly
	if(	$type_filter->name eq 'ZeroOrUndef' and
		!$list_ref->[-1]->[0] and $list_ref->[-1]->[1] eq '"-"' ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Found a zero to bar replacement"			] );
		my $return_string;
		for my $piece ( @$list_ref ){
			$return_string .= $piece->[1];
		}
		$return_string =~ s/"\-"/\-/;
		return( 'NUMBER', $type_filter, sub{ $return_string } );
	}

	# Handle trailing negative
	if( $list_ref->[-1]->[0] =~ /(.*[\d\#])\-$/ ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Found a trailing negative sign", ] );
		$list_ref->[-1]->[0] = $1;
		push @$list_ref, [ undef, '-' ];
	}

	# Process once to determine what to do
	for my $piece ( @$list_ref ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"processing number piece:", $piece ] );
		if( defined $piece->[0] ){
			if( my @result = $piece->[0] =~ /^([0-9#\?]+)([,\-\_])?([#0\?]+)?(,+)?$/ ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Regex yielded result:", @result ] );
				my	$comma = ($2) ? $2 : undef,
				my	$comma_less = defined( $3) ? "$1$3" : $1;
				my	$comma_group = $3 ? length( $3 ) : 0;
				my	$divide_by_thousands = ( $4 ) ? (( $2 and $2 ne ',' ) ? $4 : "$2$4" ) : undef;#eval{ $2 . $4 }
				my	$divisor = $1 if $1 =~ /^([0-9]+)$/;
				my ( $leading_zeros, $trailinq_zeros );
				if( $comma_less =~ /^[\#\?]*(0+)$/ ){
					$leading_zeros = $1;
				}
				if( $comma_less =~ /^(0+)[\#\?]*$/ ){
					$trailinq_zeros = $1;
				}
				$code_hash_ref->{divide_by_thousands} = length( $divide_by_thousands ) if $divide_by_thousands;
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"The comma less string is extracted to: $comma_less",
				###LogSD		((defined $comma_group) ? "The separator group length is: $comma_group" : undef),
				###LogSD		(($comma) ? "The separator character is: $comma" : undef),
				###LogSD		(($leading_zeros and length( $leading_zeros )) ? ".. w/leading zeros: $leading_zeros" : undef),
				###LogSD		(($trailinq_zeros and length( $trailinq_zeros )) ? ".. w/trailing zeros: $trailinq_zeros" : undef),
				###LogSD		(($divisor) ? "..with identified divisor: $divisor" : undef),
				###LogSD		'Initial code hash:', $code_hash_ref] );
				if( !$number_type ){
					$number_type = 'INTEGER';
					$code_hash_ref->{integer}->{leading_zeros} = length( $leading_zeros ) if $leading_zeros and length( $leading_zeros );
					$code_hash_ref->{integer}->{minimum_length} = length( $comma_less );
					if( $comma ){
						@{$code_hash_ref->{integer}}{ 'group_length', 'comma' } = ( $comma_group, $comma );
					}
					if( defined $piece->[1] ){
						if( $piece->[1] =~ /(\s+)/ ){
							$code_hash_ref->{separator} = $1;
						}elsif( $piece->[1] eq '/' ){
							$number_type = 'FRACTION';
							$code_hash_ref->{numerator}->{leading_zeros} = length( $leading_zeros ) if $leading_zeros and length( $leading_zeros );
							delete $code_hash_ref->{integer};
						}
					}
				}elsif( ($number_type eq 'INTEGER') or $number_type eq 'DECIMAL' ){
					if( $piece->[1] and $piece->[1] eq '/'){
						$number_type = 'FRACTION';
					}else{
						$number_type = 'DECIMAL';
						$code_hash_ref->{decimal}->{trailing_zeros} = length( $trailinq_zeros ) if $trailinq_zeros and length( $trailinq_zeros );
						$code_hash_ref->{decimal}->{max_length} = length( $comma_less );
					}
				}elsif( ($number_type eq 'SCIENTIFIC') or $number_type eq 'FRACTION' ){
					$code_hash_ref->{exponent}->{leading_zeros} = length( $leading_zeros ) if $leading_zeros and length( $leading_zeros );
					$code_hash_ref->{fraction}->{target_length} = length( $comma_less );
					if( $divisor ){
						$code_hash_ref->{fraction}->{divisor} = $divisor;
					}
				}
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Current number type: $number_type", 'updated settings:', $code_hash_ref] );
			}elsif( $piece->[0] =~ /^((\.)|([Ee][+\-])|(%))$/ ){
				if( $2 ){
					$number_type = 'DECIMAL';
					$code_hash_ref->{separator} = $1;
				}elsif( $3 ){
					$number_type = 'SCIENTIFIC';
					$code_hash_ref->{separator} = $2;
				}else{
					$number_type = 'PERCENT';
				}
				###LogSD	$phone->talk( level => 'info', message => [
				###LogSD		"Number type now: $number_type" ] );
			}else{
				confess "badly formed number format passed: $piece->[0]";
			}
		}
	}

	# Set negative type
	if( $type_filter->name eq 'NegativeNum' ){
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Setting this as a negative number type" ] );
		$code_hash_ref->{negative_type} = 1;
	}

	my $method = '_build_' . lc( $number_type ) . '_sub';
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Resolved the number type to: $number_type",
	###LogSD		'Working with settings:', $list_ref, $code_hash_ref ] );
	my $conversion_sub = $self->$method( $type_filter, $list_ref, $code_hash_ref );

	return( $number_type, $type_filter, $conversion_sub );
}

sub _build_integer_sub{
	my( $self, $type_filter, $list_ref, $conversion_defs ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_integer_sub', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building an anonymous sub to return integer values",
	###LogSD			'With type constraint: ' . $type_filter->name,
	###LogSD			'..using list ref:' , $list_ref, '..and conversion defs:', $conversion_defs	] );

	my $sprintf_string;
	# Process once to determine what to do
	my $found_integer = 0;
	for my $piece ( @$list_ref ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"processing number piece:", $piece ] );
		if( !$found_integer and defined $piece->[0] ){
			$sprintf_string .= '%s';
			$found_integer = 1;
		}
		if( $piece->[1] ){
			$sprintf_string .= $piece->[1];
		}
	}
	$conversion_defs->{no_decimal} = 1;
	$conversion_defs->{sprintf_string} = $sprintf_string;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Final sprintf string: $sprintf_string" ] );
	my $dispatch_sequence = $number_build_dispatch->{decimal};

	my 	$conversion_sub = sub{
			#~ print "Using Integer sub!!!!!!\n";
			###LogSD	my $sub_phone = Log::Shiras::Telephone->new( name_space =>
			###LogSD			$self->get_log_space . '::Cell::_hidden::_return_value_only::_build_number::_build_integer_sub', );
			my $adjusted_input = $_[0];
			if( !defined $adjusted_input or $adjusted_input eq '' ){
				###LogSD	$sub_phone->talk( level => 'debug', message => [
				###LogSD		"Return undef for empty strings" ] );
				return undef;
			}
			my	$value_definitions = clone( $conversion_defs );
				$value_definitions->{initial_value} = $adjusted_input;
			###LogSD	$sub_phone->talk( level => 'trace', message => [
			###LogSD		'Building scientific output with:',  $conversion_defs,
			###LogSD		'..and dispatch sequence:', $dispatch_sequence ] );
			my $built_ref = $self->_build_elements( $dispatch_sequence, $value_definitions );
			###LogSD	$sub_phone->talk( level => 'trace', message => [
			###LogSD		"Received built ref:", $built_ref ] );
			my	$return .= sprintf(
					$built_ref->{sprintf_string},
					$built_ref->{integer}->{value}
				);
			$return = $built_ref->{sign} . $return if $built_ref->{sign} and $return;
			return $return;
		};
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Conversion sub for filter name: " . $type_filter->name, $conversion_sub ] );

	return $conversion_sub;
}

sub _build_decimal_sub{
	my( $self, $type_filter, $list_ref, $conversion_defs ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_decimal_sub', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building an anonymous sub to return decimal values",
	###LogSD			'With type constraint: ' . $type_filter->name,
	###LogSD			'..using list ref:' , $list_ref, '..and code hash ref:', $conversion_defs ] );

	my $sprintf_string;
	# Process once to determine what to do
	for my $piece ( @$list_ref ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"processing number piece:", $piece ] );
		if( defined $piece->[0] ){
			if( $piece->[0] eq '.' ){
				$sprintf_string .= '.';
			}else{
				$sprintf_string .= '%s';
			}
		}
		if( $piece->[1] ){
			$sprintf_string .= $piece->[1];
		}
	}
	$conversion_defs->{sprintf_string} = $sprintf_string;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Final sprintf string: $sprintf_string" ] );
	my $dispatch_sequence = $number_build_dispatch->{decimal};

	my 	$conversion_sub = sub{
			#~ print "Using Decimal sub!!!!!!\n";
			###LogSD	my $sub_phone = Log::Shiras::Telephone->new( name_space =>
			###LogSD			$self->get_log_space . '::Cell::_hidden::_return_value_only::_build_number::_build_decimal_sub', );
			my $adjusted_input = $_[0];
			if( !defined $adjusted_input or $adjusted_input eq '' ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Return undef for empty strings" ] );
				return undef;
			}
			my	$value_definitions = clone( $conversion_defs );
				$value_definitions->{initial_value} = $adjusted_input;
			###LogSD	$sub_phone->talk( level => 'trace', message => [
			###LogSD		'Building scientific output with:',  $conversion_defs,
			###LogSD		'..and dispatch sequence:', $dispatch_sequence ] );
			my $built_ref = $self->_build_elements( $dispatch_sequence, $value_definitions );
			###LogSD	$sub_phone->talk( level => 'trace', message => [
			###LogSD		"Received built ref:", $built_ref ] );
			my	$return .= sprintf(
					$built_ref->{sprintf_string},
					$built_ref->{integer}->{value},
					$built_ref->{decimal}->{value},
				);
			$return = $built_ref->{sign} . $return if $built_ref->{sign} and $return;
			return $return;
		};
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Conversion sub for filter name: " . $type_filter->name, $conversion_sub ] );

	return $conversion_sub;
}

sub _build_percent_sub{
	my( $self, $type_filter, $list_ref, $conversion_defs ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_percent_sub', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building an anonymous sub to return decimal values",
	###LogSD			'With type constraint: ' . $type_filter->name,
	###LogSD			'..using list ref:' , $list_ref, '..and code hash ref:', $conversion_defs	] );

	my $sprintf_string;
	my $decimal_count = 0;
	# Process once to determine what to do
	for my $piece ( @$list_ref ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"processing number piece:", $piece ] );
		if( defined $piece->[0] ){
			if( $piece->[0] eq '%' ){
				$sprintf_string .= '%%';
			}elsif( $piece->[0] eq '.' ){
				$sprintf_string .= '.';
			}else{
				$sprintf_string .= '%s';
				$decimal_count++;
			}
		}
		if( $piece->[1] ){
			$sprintf_string .= $piece->[1];
		}
	}
	$conversion_defs->{no_decimal} = 1 if $decimal_count < 2;
	$conversion_defs->{sprintf_string} = $sprintf_string;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Final sprintf string: $sprintf_string" ] );
	my $dispatch_sequence = $number_build_dispatch->{percent};

	my 	$conversion_sub = sub{
			#~ print "Using Percent sub!!!!!!\n";
			###LogSD	my $sub_phone = Log::Shiras::Telephone->new( name_space =>
			###LogSD			$self->get_log_space . '::Cell::_hidden::_return_value_only::_build_number::_build_percent_sub', );
			my $adjusted_input = $_[0];
			if( !defined $adjusted_input or $adjusted_input eq '' ){
				###LogSD	$sub_phone->talk( level => 'debug', message => [
				###LogSD		"Return undef for empty strings" ] );
				return undef;
			}
			my	$value_definitions = clone( $conversion_defs );
				$value_definitions->{initial_value} = $adjusted_input;
			###LogSD	$sub_phone->talk( level => 'trace', message => [
			###LogSD		'Building scientific output with:',  $conversion_defs,
			###LogSD		'..and dispatch sequence:', $dispatch_sequence ] );
			my $built_ref = $self->_build_elements( $dispatch_sequence, $value_definitions );
			###LogSD	$sub_phone->talk( level => 'trace', message => [
			###LogSD		"Received built ref:", $built_ref ] );
			my $return;
			if( $decimal_count < 2 ){
				$return .= sprintf(
					$built_ref->{sprintf_string},
					$built_ref->{integer}->{value},
				);
			}else{
				$return .= sprintf(
					$built_ref->{sprintf_string},
					$built_ref->{integer}->{value},
					$built_ref->{decimal}->{value},
				);
			}
			$return = $built_ref->{sign} . $return if $built_ref->{sign} and $return;
			return $return;
		};
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Conversion sub for filter name: " . $type_filter->name, $conversion_sub ] );

	return $conversion_sub;
}

sub _build_scientific_sub{
	my( $self, $type_filter, $list_ref, $conversion_defs ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_scientific_sub', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building an anonymous sub to return scientific values",
	###LogSD			'With type constraint: ' . $type_filter->name,
	###LogSD			'..using list ref:' , $list_ref, '..and code hash ref:', $conversion_defs	] );

	# Process once to determine what to do
	my ( $sprintf_string, $exponent_sprintf );
	$conversion_defs->{no_decimal} = ( exists $conversion_defs->{decimal} ) ? 0 : 1 ;
	for my $piece ( @$list_ref ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"processing number piece:", $piece ] );
		if( defined $piece->[0] ){
			if( $piece->[0] =~ /(E)(.)/ ){
				$sprintf_string .= $1;
				$exponent_sprintf = '%';
				$exponent_sprintf .= '+' if $2 eq '+';
				if( exists $conversion_defs->{exponent}->{leading_zeros} ){
					$exponent_sprintf .= '0.' . $conversion_defs->{exponent}->{leading_zeros};
				}
				$exponent_sprintf .= 'd';
			}elsif( $piece->[0] eq '.' ){
				$sprintf_string .= '.';
				$conversion_defs->{no_decimal} = 0;
			}elsif( $exponent_sprintf ){
				$sprintf_string .= $exponent_sprintf;
			}else{
				$sprintf_string .= '%s';
			}
		}
		if( $piece->[1] ){
			$sprintf_string .= $piece->[1];
		}
	}
	$conversion_defs->{sprintf_string} = $sprintf_string;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Final sprintf string: $sprintf_string" ] );
	my $dispatch_sequence = $number_build_dispatch->{scientific};

	my 	$conversion_sub = sub{
			my $adjusted_input = $_[0];
			if( !defined $adjusted_input or $adjusted_input eq '' ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Return undef for empty strings" ] );
				return undef;
			}elsif( $adjusted_input =~ /^\-?\d*(\.\d+)?$/ or
						( $adjusted_input =~ /^(\-)?((\d{1,3})?(\.\d+)?)[Ee](\-)?(\d+)$/ and $2 and $6 and $6 < 309 ) ){# Check for non-scientific numbers passed to scientific format
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Passed the first scientific format test with: $adjusted_input" ] );
				my	$value_definitions = clone( $conversion_defs );
					$value_definitions->{initial_value} = $adjusted_input;

				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		'Building scientific output with:',  $conversion_defs,
				###LogSD		'..and dispatch sequence:', $dispatch_sequence ] );
				my $built_ref = $self->_build_elements( $dispatch_sequence, $value_definitions );
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Received built ref:", $built_ref ] );
				my $return;
				if( $built_ref->{no_decimal} ){
					$return .= sprintf(
						$built_ref->{sprintf_string},
						$built_ref->{integer}->{value},
						$built_ref->{exponent}->{value}
					);
				}else{
					$return .= sprintf(
						$built_ref->{sprintf_string},
						$built_ref->{integer}->{value},
						$built_ref->{decimal}->{value} ,
						$built_ref->{exponent}->{value}
					);
				}
				$return = $built_ref->{sign} . $return if $built_ref->{sign} and $return;
				return $return;
			}else{
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Doesn't really seem like this is a scientific number recognized by excel: $adjusted_input" ] );
				return $adjusted_input;
			}
		};
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Conversion sub for filter name: " . $type_filter->name, $conversion_sub ] );

	return $conversion_sub;
}

sub _build_fraction_sub{
	my( $self, $type_filter, $list_ref, $conversion_defs ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_fraction_sub', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building an anonymous sub to return integer and fraction strings",
	###LogSD			'With type constraint: ' . $type_filter->name,
	###LogSD			'..using list ref:' , $list_ref, '..and code hash ref:', $conversion_defs	] );

	# I'm worried about pulling the sprintf parser out of here and I may need to put it back sometime

	my $dispatch_sequence = $number_build_dispatch->{fraction};
	my $conversion_sub = sub{
			#~ print "Using Fraction sub!!!!!!\n";
			###LogSD	my $sub_phone = Log::Shiras::Telephone->new( name_space =>
			###LogSD			$self->get_log_space . '::Cell::_hidden::_return_value_only::_build_number::_build_fraction_sub', );
			my $adjusted_input = $_[0];
			if( !defined $adjusted_input or $adjusted_input eq '' ){
				###LogSD	$sub_phone->talk( level => 'debug', message => [
				###LogSD		"Return undef for empty strings" ] );
				return undef;
			}
			my	$value_definitions = clone( $conversion_defs );
				$value_definitions->{initial_value} = $adjusted_input;
			###LogSD	$sub_phone->talk( level => 'trace', message => [
			###LogSD		'Building scientific output with:',  $conversion_defs,
			###LogSD		'..and dispatch sequence:', $dispatch_sequence ] );
			my $built_ref = $self->_build_elements( $dispatch_sequence, $value_definitions );
			###LogSD	$sub_phone->talk( level => 'trace', message => [
			###LogSD		"Received built ref:", $built_ref ] );
			my $return;
			if( $built_ref->{integer}->{value} ){
				$return = sprintf( '%s', $built_ref->{integer}->{value} );
				if( $built_ref->{fraction}->{value} ){
					$return .= ' ';
				}
			}
			if( $built_ref->{fraction}->{value} ){
				$return .= $built_ref->{fraction}->{value};
			}
			if( !$return and $built_ref->{initial_value} ){
				$return = 0;
			}
			$return = $built_ref->{sign} . $return if $built_ref->{sign} and $return;
			return $return;
		};
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Conversion sub for filter name: " . $type_filter->name, $conversion_sub ] );

	return $conversion_sub;
}

sub _build_elements{
	my( $self, $dispatch_ref, $value_definitions, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_elements', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached the dispatcher for number building with:', $value_definitions,
	###LogSD			'..using dispatch list', $dispatch_ref	] );
	for my $method ( @$dispatch_ref ){
		$value_definitions = $self->$method( $value_definitions );
		###LogSD		$phone->talk( level => 'debug', message => [
		###LogSD			'Updated value definitions:', $value_definitions, ] );
	}
	return $value_definitions;
}

sub _convert_negative{
	my( $self, $value_definitions, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_elements::_convert_negative', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached _convert_negative with:', $value_definitions,	] );

	if( $value_definitions->{negative_type} and $value_definitions->{initial_value} < 0 ){
		$value_definitions->{initial_value} = $value_definitions->{initial_value} * -1;
	}
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'updated value definitions:', $value_definitions,	] );
	return $value_definitions;
}

sub _divide_by_thousands{
	my( $self, $value_definitions, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_elements::_divide_by_thousands', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached _convert_to_percent with:', $value_definitions,	] );
	if(	$value_definitions->{initial_value} and
		$value_definitions->{divide_by_thousands} ){
		$value_definitions->{initial_value} =
			$value_definitions->{initial_value}/
				( 1000**$value_definitions->{divide_by_thousands} );
	}
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'updated value definitions:', $value_definitions,	] );
	return $value_definitions;
}

sub _convert_to_percent{
	my( $self, $value_definitions, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_elements::_convert_to_percent', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached _convert_to_percent with:', $value_definitions,	] );

	$value_definitions->{initial_value} = $value_definitions->{initial_value} * 100;
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'updated value definitions:', $value_definitions,	] );
	return $value_definitions;
}

sub _split_decimal_integer{
	my( $self, $value_definitions, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_elements::_split_decimal_integer', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached _split_decimal_integer with:', $value_definitions,	] );

	# Extract negative sign
	if( $value_definitions->{initial_value} < 0 ){
		$value_definitions->{sign} = '-';
		$value_definitions->{initial_value} = $value_definitions->{initial_value} * -1;
	}

	# Build the integer
	$value_definitions->{integer}->{value} = int( $value_definitions->{initial_value} );

	# Build the decimal
	$value_definitions->{decimal}->{value} = $value_definitions->{initial_value} - $value_definitions->{integer}->{value};
	###LogSD	$phone->talk( level => 'debug', message =>[ 'Updated ref: ', $value_definitions  ] );
	return $value_definitions;
}

sub _move_decimal_point{
	my( $self, $value_definitions, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_elements::_move_decimal_point', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached _move_decimal_point with:', $value_definitions,	] );
	my ( $exponent, $stopped );
	if(defined	$value_definitions->{integer}->{value} and
		sprintf( '%.0f', $value_definitions->{integer}->{value} ) =~ /([1-9])/ ){
		$stopped = $+[0];
		###LogSD	$phone->talk( level => 'debug', message =>[ "Matched integer value at: $stopped",	] );
		$exponent = length( sprintf( '%.0f', $value_definitions->{integer}->{value} ) ) - $stopped;
	}elsif( $value_definitions->{decimal}->{value} ){
		if( $value_definitions->{decimal}->{value} =~ /E(-?\d+)$/i ){
			$exponent = $1 * 1;
		}elsif( $value_definitions->{decimal}->{value} =~ /([1-9])/ ){
			$exponent = $+[0] * -1;
			$exponent += 2;
			###LogSD	$phone->talk( level => 'debug', message =>[ "Matched decimal value at: $exponent",	] );
		}
	}else{
		$exponent = 0;
	}
	###LogSD	$phone->talk( level => 'debug', message =>[ "Initial exponent: $exponent",	] );
	my	$exponent_remainder = $exponent % $value_definitions->{integer}->{minimum_length};
	###LogSD	$phone->talk( level => 'debug', message =>[ "Exponent remainder: $exponent_remainder",	] );
		$exponent -= $exponent_remainder;
	###LogSD	$phone->talk( level => 'debug', message =>[ "New exponent: $exponent",	] );
		$value_definitions->{exponent}->{value} = $exponent;
	if( $exponent < 0 ){
		my $adjustment = '1' . (0 x abs($exponent));
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"The exponent |$exponent| is less than zero - the decimal must move to the right by: $adjustment"  ] );
		my $new_integer = $value_definitions->{integer}->{value} * $adjustment;
		my $new_decimal = $value_definitions->{decimal}->{value} * $adjustment;
		my $decimal_int = int( $new_decimal );
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Bumped integer: $new_integer", "Bumped decimal: $new_decimal", "Decimal integer: $decimal_int" ] );
		$value_definitions->{integer}->{value} = $new_integer + $decimal_int;
		$value_definitions->{decimal}->{value} = $new_decimal - $decimal_int;
	}elsif( $exponent > 0 ){
		my $adjustment = '1' . (0 x $exponent);
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"The exponent -$exponent- is greater than zero - the decimal must move to the left"  ] );
		my $new_integer = $value_definitions->{integer}->{value} / $adjustment;
		my $new_decimal = $value_definitions->{decimal}->{value} / $adjustment;
		my $integer_int = int( $new_integer );
		$value_definitions->{integer}->{value} = $integer_int;
		$value_definitions->{decimal}->{value} = $new_decimal + ($new_integer - $integer_int);
	}

	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		'Updated ref:', $value_definitions		] );
	return $value_definitions;
}

sub _round_decimal{
	my( $self, $value_definitions, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_elements::_round_decimal', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached _round_decimal with:', $value_definitions,	] );
	if( $value_definitions->{no_decimal} ){
		if( $value_definitions->{decimal}->{value} > 0.4998 ){# Err on the side of fixing precision up
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		'Rouding the integer -' . $value_definitions->{integer}->{value} .
			###LogSD		"- for the no-decimal condition with decimal: $value_definitions->{decimal}->{value}",  ] );
			$value_definitions->{integer}->{value}++;
		}
		delete $value_definitions->{decimal};
	}elsif( $value_definitions->{decimal}->{max_length} ){
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Enforcing decimal max length: " . $value_definitions->{decimal}->{max_length}  ] );
		if( $value_definitions->{decimal}->{value} ){
			my $adder			= '0.' . (0 x $value_definitions->{decimal}->{max_length}) . '00002';
			my $sprintf_string	= '%.' . $value_definitions->{decimal}->{max_length} . 'f';
			my $round_decimal	= sprintf( $sprintf_string,  ($value_definitions->{decimal}->{value}+$adder) );
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"Sprintf string: $sprintf_string", "Rounded decimal: $round_decimal", "Adder: $adder",] );
			if( $round_decimal >= 1 ){
				$value_definitions->{integer}->{value}++;
				$round_decimal -= 1;
				###LogSD	$phone->talk( level => 'info', message => [
				###LogSD		"New integer: " . $value_definitions->{integer}->{value}, "New decimal: $round_decimal" ] );
			}
			my $decimal_multiply = '1' . (0 x $value_definitions->{decimal}->{max_length});
			my $string_sprintf = '%0' . $value_definitions->{decimal}->{max_length} . 's';
			$value_definitions->{decimal}->{value} = sprintf( $string_sprintf, ($round_decimal * $decimal_multiply) );
		}

		if( !$value_definitions->{decimal}->{value} ){
			$value_definitions->{decimal}->{value} = 0 x $value_definitions->{decimal}->{max_length};
		}
	}

	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		'Updated ref:', $value_definitions		] );
	return $value_definitions;
}

sub _add_commas{
	my( $self, $value_definitions, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_elements::_add_commas', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached _add_commas with:', $value_definitions,	] );
	if( exists $value_definitions->{integer}->{comma} ){
		$value_definitions->{integer}->{value} = $self->_add_integer_separator(
			sprintf( '%.0f', $value_definitions->{integer}->{value} ),
			$value_definitions->{integer}->{comma},
			$value_definitions->{integer}->{group_length},
		);
	}

	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		'Updated ref:', $value_definitions		] );
	return $value_definitions;
}

sub _pad_exponent{
	my( $self, $value_definitions, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_elements::_pad_exponent', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached _pad_exponent with:', $value_definitions,	] );
	if(	$value_definitions->{exponent}->{leading_zeros} ){
		my $pad_string = '%0' . $value_definitions->{exponent}->{leading_zeros} . 's';
		$value_definitions->{exponent}->{value} =
			sprintf( $pad_string, sprintf( '%.0f', $value_definitions->{exponent}->{value} ) );
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		'Updated ref:', $value_definitions		] );
	return $value_definitions;
}

sub _build_fraction{
	my( $self, $value_definitions, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_elements::_build_fraction', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached _build_fraction with:', $value_definitions,	] );
	if( $value_definitions->{decimal}->{value} ){
		$value_definitions->{fraction}->{value} =
			( $value_definitions->{fraction}->{divisor} ) ?
				$self->_build_divisor_fraction(
					$value_definitions->{fraction}->{divisor}, $value_definitions->{decimal}->{value}
				) :
				$self->_continued_fraction(
					$value_definitions->{decimal}->{value}, 20, $value_definitions->{fraction}->{target_length},
				);
	}
	delete $value_definitions->{decimal};
	$value_definitions->{fraction}->{value} //= 0;
	if( $value_definitions->{fraction}->{value} eq '1' ){
		$value_definitions->{integer}->{value}++;
		$value_definitions->{fraction}->{value} = 0;
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		'Updated ref:', $value_definitions		] );
	return $value_definitions;
}

sub _build_divisor_fraction{
	my( $self, $divisor, $decimal ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_build_number::_build_elements::_build_divisor_fraction', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached _build_divisor_fraction with:', $divisor, $decimal	] );
	my $low_numerator = int( $divisor * $decimal );
	my $high_numerator = $low_numerator + 1;
	my $low_delta = $decimal - ($low_numerator / $divisor);
	my $high_delta = ($high_numerator / $divisor) - $decimal;
	my $return;
	my $add_denominator = 0;
	if( $low_delta < $high_delta ){
		$return = $low_numerator;
		$add_denominator = 1 if $return;
	}else{
		$return = $high_numerator;
		if( $high_numerator == $divisor ){
			$return = 1;
		}else{
			$add_denominator = 1;
		}
	}
	$return .= "/$divisor" if $add_denominator;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Final fraction: $return"		] );
	return $return;
}

sub _add_integer_separator{
	my ( $self, $int, $comma, $frequency ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_util_function::_add_integer_separator', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Attempting to add the separator -$comma- to " .
	###LogSD			"the integer portion of: $int" ] );
		$comma //= ',';
	my	@number_segments;
	if( is_Int( $int ) ){
		while( $int =~ /(-?\d+)(\d{$frequency})$/ ){
			$int= $1;
			unshift @number_segments, $2;
		}
		unshift @number_segments, $int;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		'Final parsed list:', @number_segments ] );
		return join( $comma, @number_segments );
	}else{
		###LogSD	$phone->talk( level => 'warn', message => [
		###LogSD		"-$int- is not an integer!" ] );
		return undef;
	}
}

sub _continued_fraction{# http://www.perlmonks.org/?node_id=41961
	my ( $self, $decimal, $max_iterations, $max_digits ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_util_function::_continued_fraction', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Attempting to build an integer fraction with decimal: $decimal",
	###LogSD			"Using max iterations: $max_iterations",
	###LogSD			"..and max digits: $max_digits",			] );
	my	@continuous_integer_list;
	my	$start_decimal = $decimal;
	confess "Passed bad decimal: $decimal" if !is_Num( $decimal );
	while( $max_iterations > 0 and ($decimal >= 0.00001) ){
		$decimal = 1/$decimal;
		( my $integer, $decimal ) = $self->_integer_and_decimal( $decimal );
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"The integer of the inverse decimal is: $integer",
		###LogSD		"The remaining decimal is: $decimal" ] );
		if($integer > 999 or ($decimal < 0.00001 and $decimal > 1e-10) ){
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"Either I found a large integer: $integer",
			###LogSD		"...or the decimal is small: $decimal" ] );
			if( $integer <= 999 ){
				push @continuous_integer_list, $integer;
			}
			last;
		}
		push @continuous_integer_list, $integer;
		$max_iterations--;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Remaining iterations: $max_iterations" ] );
	}
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"The current continuous fraction integer list is:", @continuous_integer_list ] );
	my ( $numerator, $denominator ) = $self->_integers_to_fraction( @continuous_integer_list );
	if( !$numerator or ( $denominator and length( $denominator ) > $max_digits ) ){
		my $denom = 9 x $max_digits;
		my ( $int, $dec ) = $self->_integer_and_decimal( $start_decimal * $denom );
		$int++;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Passing through the possibilities with start numerator: $int",
		###LogSD		"..and start denominator: $denom", "Against start decimal: $decimal"] );
		my $lowest = ( $start_decimal >= 0.5 ) ?
				{ delta => (1-$start_decimal), numerator => 1, denominator => 1 } :
				{ delta => ($start_decimal-0), numerator => 0, denominator => 1 } ;
		while( $int ){
			my @check_list;
			my $low_int = $int - 1;
			my $low_denom = int( $low_int/$start_decimal ) + 1;
			push @check_list,
					{ delta => abs( $int/$denom - $start_decimal ), numerator => $int, denominator => $denom },
					{ delta => abs( $low_int/$denom - $start_decimal ), numerator => $low_int, denominator => $denom },
					{ delta => abs( $low_int/$low_denom - $start_decimal ), numerator => $low_int, denominator => $low_denom },
					{ delta => abs( $int/$low_denom - $start_decimal ), numerator => $int, denominator => $low_denom };
			my @fixed_list = sort { $a->{delta} <=> $b->{delta} } @check_list;
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		'Built possible list of lower fractions:', @fixed_list ] );
			if( $fixed_list[0]->{delta} < $lowest->{delta} ){
				$lowest = $fixed_list[0];
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		'Updated lowest with:', $lowest ] );
			}
			$int = $low_int;
			$denom = $low_denom - 1;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Attempting new possibilities with start numerator: $int",
			###LogSD		"..and start denominator: $denom", "Against start decimal: $decimal"] );
		}
		($numerator, $denominator) = $self->_best_fraction( @$lowest{qw( numerator denominator )} );
	}
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		(($numerator) ? "Final numerator: $numerator" : undef),
	###LogSD		(($denominator) ? "Final denominator: $denominator" : undef), ] );
	if( !$numerator ){
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Fraction is below the finite value - returning undef" ] );
		return undef;
	}elsif( !$denominator or $denominator == 1 ){
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Rounding up to: $numerator" ] );
		return( $numerator );
	}else{
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"The final fraction is: $numerator/$denominator" ] );
		return $numerator . '/' . $denominator;
	}
}

# Takes a list of terms in a continued fraction, and converts them
# into a fraction.
sub _integers_to_fraction {# ints_to_frac
	my ( $self, $numerator, $denominator) = (shift, 0, 1); # Seed with 0 (not all elements read here!)
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_util_function::_integers_to_fraction', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Attempting to build an integer fraction with the continuous fraction list: " .
	###LogSD			join( ' - ', @_ ), "With a seed numerator of -0- and seed denominator of -1-" ] );
	for my $integer( reverse @_ ){# Get remaining elements
		###LogSD	$phone->talk( level => 'info', message => [ "Now processing: $integer" ] );
		($numerator, $denominator) =
			($denominator, $integer * $denominator + $numerator);
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"New numerator: $numerator", "New denominator: $denominator", ] );
	}
	($numerator, $denominator) = $self->_best_fraction($numerator, $denominator);
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Updated numerator: $numerator",
	###LogSD		(($denominator) ? "..and denominator: $denominator" : undef) ] );
	return ( $numerator, $denominator );
}


# Takes a numerator and denominator, in scalar context returns
# the best fraction describing them, in list the numerator and
# denominator
sub _best_fraction{#frac_standard
	my ($self, $n, $m) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_util_function::_best_fraction', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD				"Finding the best fraction", "Start numerator: $n", "Start denominator: $m" ] );
	$n = $self->_integer_and_decimal($n);
	$m = $self->_integer_and_decimal($m);
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Updated numerator and denominator ( $n / $m )" ] );
	my $k = $self->_gcd($n, $m);
	###LogSD	$phone->talk( level => 'info', message => [ "Greatest common divisor: $k" ] );
	$n = $n/$k;
	$m = $m/$k;
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Reduced numerator and denominator ( $n / $m )" ] );
	if ($m < 0) {
		###LogSD	$phone->talk( level => 'info', message => [ "the divisor is less than zero" ] );
		$n *= -1;
		$m *= -1;
	}
	$m = undef if $m == 1;
	###LogSD	no warnings 'uninitialized';
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Final numerator and denominator ( $n / $m )" ] );
	###LogSD	use warnings 'uninitialized';
	if (wantarray) {
		return ($n, $m);
	}else {
		return ( $m ) ? "$n/$m" : $n;
	}
}

# Takes a number, returns the best integer approximation and
#	(in list context) the error.
sub _integer_and_decimal {# In the future see if this will merge with _split_decimal_integer
	my ( $self, $decimal ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_util_function::_integer_and_decimal', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Splitting integer from decimal for: $decimal" ] );
	my $integer = int( $decimal );
	###LogSD		$phone->talk( level => 'info', message => [ "Integer: $integer" ] );
	if(wantarray){
		return($integer, $decimal - $integer);
	}else{
		return $integer;
	}
}

# Euclidean algorithm for calculating a GCD.
# Takes two integers, returns the greatest common divisor.
sub _gcd {
	my ($self, $n, $m) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::hidden::_util_function::_gcd', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Finding the greatest common divisor for ( $n and $m )" ] );
	while ($m) {
		my $k = $n % $m;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Remainder after division: $k" ] );
		($n, $m) = ($m, $k);
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Updated factors ( $n and $m )" ] );
	}
	return $n;
}

around set_error => sub{
	my ($orig, $self, $error) = @_;

	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::set_error', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Recording the error:", $error ] );
	if( $self->_has_workbook_inst ){
		$self->$orig( $error );
	}else{
		print longmess( $error );
	}
};

around get_epoch_year => sub{
	my ($orig, $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_epoch_year', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Looking for the epoch year" ] );
	if( $self->_has_workbook_inst ){
		return $self->$orig;
	}
	return $self->_get_alt_epoch_year;
};

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::Format::ParseExcelFormatStrings - Convert Excel format strings to code

=head1 SYNOPSYS

	#!/usr/bin/env perl
	package MyPackage;
	use Moose;

	use lib '../../../../lib';
	extends	'Spreadsheet::Reader::Format::FmtDefault';
	with	'Spreadsheet::Reader::Format::ParseExcelFormatStrings';

	package main;

	my	$parser 		= MyPackage->new( epoch_year => 1904 );
	my	$conversion	= $parser->parse_excel_format_string( '[$-409]dddd, mmmm dd, yyyy;@' );
	print 'For conversion named: ' . $conversion->name . "\n";
	for my	$unformatted_value ( '7/4/1776 11:00.234 AM', 0.112311 ){
		print "Unformatted value: $unformatted_value\n";
		print "..coerces to: " . $conversion->assert_coerce( $unformatted_value ) . "\n";
	}

	###########################
	# SYNOPSIS Screen Output
	# 01: For conversion named: DATESTRING
	# 02: Unformatted value: 7/4/1776 11:00.234 AM
	# 03: ..coerces to: Thursday, July 04, 1776
	# 04: Unformatted value: 0.112311
	# 05: ..coerces to: Monday, January 01, 1900
	###########################

=head1 DESCRIPTION

This is the parser that converts Excel custom format strings into code that can be used
to transform values into output matching the form defined by the format string.  The goal
of this code is to support as much as possible the definition of L<excel custom format strings
|https://support.office.com/en-us/article/Create-or-delete-a-custom-number-format-78f2a361-936b-4c03-8772-09fab54be7f4>.
If you find cases where this parser and the Excel definition or excecution differ please
log a case in L<github|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>.

This parser converts the format strings to L<Type::Tiny> objects that have the appropriate
built in coercions.  Any replacement of this engine for use with
L<Spreadsheet::Reader::Format> I<and L<Spreadsheet::Reader::ExcelXML>> must output objects
that have the methods 'display_name' and 'assert_coerce'.  'display_name' is used by the
overall package to determine the cell type and should return a unique name containing an
indication of the output data type with either 'DATE' or 'NUMBER' in the name.  Otherwise
the cell type is assumed to be text.  L<Spreadsheet::Reader::ExcelXML> uses 'assert_coerce'
as the method to transform the raw value to the formatted value.

Excel format strings can have up to four parts separated by semi-colons.  The four parts
are positive, zero, negative, and text.  In the Excel application the text section is just
a pass through.  I<This is how excel handles L<dates earlier than 1900sh
|DateTimeX::Format::Excel/DESCRIPTION>>.  This parser deviates from that for dates.  Since
this parser provides code that parses Excel date numbers into a L<DateTime> object (and
then L<potentially back|/datetime_dates> to a differently formatted string) it also
attempts to parse strings to DateTime objects if the cell has a date format applied.  All
other types of Excel number conversions still treat strings as a pass through.

To replace this module just build a L<Moose::Role|Moose::Manual::Roles> that delivers
the method L<parse_excel_format_string|/parse_excel_format_string( $string, $name )>  and
L<get_defined_conversion|/get_defined_conversion( $position )>. See the L<documentation
|Spreadsheet::Reader::Format::FormatInterface> for the format interface to integrate into
the package.

=head2 Caveat Utilitor

The decimal (real number) to fraction conversion implementation here is processing
intensive.  I erred on the side of accuracy over speed.  While I tried my best to
provide equivalent accuracy to the Excel output I was unable to duplicate the results
in all cases.  In those cases this package provides a more precise result than Excel.
If you are experiencing delays when reading fraction formatted values then this package
is a place to investigate.  In order to get the most accurate answer this parser
initially uses the L<continued fraction|http://en.wikipedia.org/wiki/Continued_fraction>
algorythm to calculate a possible fraction for the pased $decimal value with the
setting of 20 max iterations and a maximum denominator width defined by the format
string.  If that does not resolve satisfactorily it then calculates -all- over/under
numerators with decreasing denominators from the maximum denominator (based on the
format string) all the way to the denominator of 2 and takes the most accurate result.
There is no early-out available in this computation so if you reach this point for multi
digit denominators things slow down.  (Not that continued fractions are
computationally so cheap.)  However, dual staging the calculation this way yields either
the same result as Excel or a more accurate result while providing a possible early out
in the continued fraction portion.  I was unable to even come close to Excel output
otherwise.  If you have a faster conversion or just want to opt out for specific cells
without replacing this whole parser then use the worksheet method
L<Spreadsheet::Reader::ExcelXML::Worksheet/set_custom_formats( $key =E<gt> $format_object_or_string )>.
I<hint: $format_object_or_string = '@' will set a pass through.>

=head2 requires

These are method(s) used by this role but not provided by the role.  Any class consuming this
role will not build without first providing this(ese) methods prior to loading this role.

=head3 get_defined_excel_format

=over

B<Definition:> Used to return the standard error string for a defined format position.

See L<Spreadsheet::Reader::Format::FmtDefault/defined_excel_translations>

=back

=head2 Methods

These are the methods provided by this role to whatever class or instance inherits this
role.  For additional ParseExcelFormatStrings options see the L<Attributes|/Attributes>
section.

=head3 parse_excel_format_string( $string, $name )

=over

B<Definition:> This is the method to convert Excel L<format strings
|https://support.office.com/en-us/article/Create-or-delete-a-custom-number-format-83657ca7-9dbe-4ee5-9c89-d8bf836e028e?ui=en-US&rs=en-US&ad=US>
into L<Type::Tiny> objects with built in coercions.  The type coercion objects are then used to
convert L<unformatted|Spreadsheet::Reader::Format::Cell/unformatted> values into formatted
values using the L<assert_coerce|Type::Coercion/Coercion> method. Coercions built by this module
allow for the format string to have up to four parts separated by semi-colons.  These four parts
correlate to four different data input ranges.  The four parts are positive, zero, negative, and
text.  If three substrings are sent then the data input is split to (positive and zero), negative,
and text.  If two input types are sent the data input is split between numbers and text.  One input
type is a take all comers type with the exception of dates.  When dates are built by this module it
always adds a possible from-text conversion to process Excel pre-1900ish dates.  This is because
Excel does not record dates prior to 1900ish as numbers.  All date unformatted values are then
processed into and then L<potentially|/datetime_dates> back out of L<DateTime> objects.  This
requires L<Type::Tiny::Manual::Coercions/Chained Coercions>.  The two packages used for conversion
to DateTime objects are L<DateTime::Format::Flexible> and L<DateTimeX::Format::Excel>.

B<Accepts:> an Excel number L<format string
|https://support.office.com/en-us/article/Create-or-delete-a-custom-number-format-83657ca7-9dbe-4ee5-9c89-d8bf836e028e?ui=en-US&rs=en-US&ad=US>
and a conversion name stored in the Type::Tiny object.  This package will auto-generate a name if
none is given

B<Returns:> a L<Type::Tiny> object with type coercions and pre-filters set for each input type
from the formatting string

=back

=head3 get_defined_conversion( $position )

=over

B<Definition:> This is a helper method that combines the call to
L<Spreadsheet::Reader::Format::FmtDefault/get_defined_excel_format( $position )> and
parse_excel_format_string above in order to get the final result with one call.

B<Accepts:> an Excel default format position

B<Returns:> a L<Type::Tiny> object with type coercions and pre-filters set for each input type
from the formatting string

=back

=head2 Attributes

Data passed to new when creating a class or instance containing this role.   For
modification of these attributes see the listed 'attribute methods'.  For more
information on attributes see L<Moose::Manual::Attributes>.

=head3 workbook_inst

=over

B<Definition:> This role works better if it has access to two workbook methods
there are defaults built in if the workbook is not connected but the package no
longer responds dynamically when that connection is broken.  This instance is a
way for this role to see those settings.

B<Required:> No but it's really nice

B<Range:> an instance of the L<Spreadsheet::Reader::ExcelXML> class

B<attribute methods> Methods provided to adjust this attribute

=over

B<set_workbook_inst( $instance )>

=over

B<Definition:> sets the workbook instance

=back

=back

B<delegated methods> Methods provided from the object stored in the attribute

	method_name => method_delegated_from_link

=over

B<set_error( $error_string )> => L<Spreadsheet::Reader::ExcelXML/set_error>

B<get_epoch_year> => L<Spreadsheet::Reader::ExcelXML/get_epoch_year>

=back

=back

=head3 cache_formats

=over

B<Definition:> In order to save re-building the coercion each time they are
requested, the built coercions can be cached with the format string as the key.
This attribute sets whether caching is turned on or not.  In rare cases with
lots of unique formats this would allow a reduction in RAM consumtion at the
price of speed.

B<Range:> Boolean

B<Default:> 1 = caching is on

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_cache_behavior>

=over

B<Definition:> returns the state of the attribute

=back

B<set_cache_behavior( $bool )>

=over

B<Definition:> sets the value of the attribute to $Bool

B<Range:> Boolean 1 = cache formats, 0 = Don't cache formats

=back

=back

=back

=head3 datetime_dates

=over

B<Definition:> It may be that you desire the full L<DateTime> object as output
rather than the finalized datestring when converting unformatted date data to
formatted date data. This attribute sets whether data coersions are built to do
the full conversion or just to a DateTime object in return.

B<Default:> 0 = unformatted values are coerced completely to date strings (1 =
stop at DateTime objects)

B<attribute methods> Methods provided to adjust this attribute.

=over

B<get_date_behavior>

=over

B<Definition:> returns the value of the attribute

=back

=back

=over

B<set_date_behavior( $bool )>

=over

B<Definition:> sets the attribute value (only L<new|/cache_formats> coercions
are affected)

B<Accepts:> Boolean values

B<Delegated to the workbook class:> yes

=back

=back

=back

=head3 european_first

=over

B<Definition:> This is a way to check for DD-MM-YY formatting of
inbound (read from the file) date stringsprior to checking for MM-DD-YY.
Since the package always checks both ways when the number is ambiguous
the goal is to catch data where the substring for DD < 13 and assign it
correctly.

B<Default:> 0 = MM-DD-YY[YY] is tested first

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_european_first>

=over

B<Definition:> returns the value of the attribute

=back

B<set_european_first( $bool )>

=over

B<Definition:> sets the value of the attribute

B<Range:> Boolean 0 = MM-DD-YY is tested first, 1 = DD-MM-YY is tested first

=back

=back

=back

=head1 SUPPORT

=over

L<github Spreadsheet::Reader::Format/issues
|https://github.com/jandrew/p5-spreadsheet-reader-format/issues>

=back

=head1 TODO

=over

B<1.> Attempt to merge _split_decimal_integer and _integer_and_decimal

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

L<Spreadsheet::Reader::Format>

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
