package Spreadsheet::Reader::ExcelXML::Workbook;
our $AUTHORITY = 'cpan:JANDREW';
use version 0.77; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::Workbook-$VERSION";

use 5.010;
use	Moose;
use	MooseX::StrictConstructor;
use	MooseX::HasDefaults::RO;
use	Carp qw( confess longmess );
use Clone 'clone';
use Types::Standard qw(
 		InstanceOf			Str       			StrMatch			Enum
		HashRef				ArrayRef			CodeRef				Int
		HasMethods			Bool				is_Object			is_HashRef
		ConsumerOf			is_ArrayRef
    );
use lib	'../../../../lib',;
###LogSD use Log::Shiras::Telephone;
###LogSD use Spreadsheet::Reader::ExcelXML::ZipReader;
###LogSD use Spreadsheet::Reader::ExcelXML::Cell;
###LogSD use Spreadsheet::Reader::ExcelXML::CellToColumnRow;
###LogSD use Spreadsheet::Reader::ExcelXML::Chartsheet;
###LogSD use Spreadsheet::Reader::ExcelXML::Error;
###LogSD use Spreadsheet::Reader::ExcelXML::Row;
###LogSD use Spreadsheet::Reader::ExcelXML::SharedStrings;
###LogSD use Spreadsheet::Reader::ExcelXML::Styles;
###LogSD use Spreadsheet::Reader::ExcelXML::WorkbookFileInterface;
###LogSD use Spreadsheet::Reader::ExcelXML::WorkbookMetaInterface;
###LogSD use Spreadsheet::Reader::ExcelXML::WorkbookPropsInterface;
###LogSD use Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface;
###LogSD use Spreadsheet::Reader::ExcelXML::Worksheet;
###LogSD use Spreadsheet::Reader::ExcelXML::WorksheetToRow;
###LogSD use Spreadsheet::Reader::ExcelXML::XMLReader;
###LogSD use Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet;
###LogSD use Spreadsheet::Reader::ExcelXML::XMLReader::NamedSharedStrings;
###LogSD use Spreadsheet::Reader::ExcelXML::XMLReader::NamedStyles;
###LogSD use Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet;
###LogSD use Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings;
###LogSD use Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles;
###LogSD use Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookMeta;
###LogSD use Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookProps;
###LogSD use Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookRels;
###LogSD use Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookXML;
###LogSD use Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta;
###LogSD use Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookProps;
###LogSD use Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookRels;
use	MooseX::ShortCut::BuildInstance 1.040 qw(
		build_instance		should_re_use_classes	set_args_cloning
	);
should_re_use_classes( 1 );
set_args_cloning ( 0 );
use Spreadsheet::Reader::ExcelXML::Types qw( XLSXFile IOFileType is_XMLFile );
###LogSD with 'Log::Shiras::LogSpace';

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9

my	$parser_modules ={
		workbook =>{
			zip =>{
				package => 'ZipWorkbookFile',
				superclasses => ['Spreadsheet::Reader::ExcelXML::ZipReader'],
				add_roles_in_sequence => [
					'Spreadsheet::Reader::ExcelXML::WorkbookFileInterface'
				],
			},
			xml =>{
				package => 'XMLWorkbookFile',
				superclasses =>[ 'Spreadsheet::Reader::ExcelXML::XMLReader' ],
				add_roles_in_sequence =>[
					'Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookXML',
					'Spreadsheet::Reader::ExcelXML::WorkbookFileInterface',
				],
			},
		},
		workbook_meta_interface =>{
			superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
			package	=> 'WorkbookMetaInterface',
			differentiation =>{
				zip =>{
					file => 'xl/workbook.xml',
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta',
						'Spreadsheet::Reader::ExcelXML::WorkbookMetaInterface',
					],
				},
				xml =>{
					file => [qw( ALL_FILE )],
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookMeta',
						'Spreadsheet::Reader::ExcelXML::WorkbookMetaInterface',
					],
				},
			},
			meta_load => [ qw( epoch_year sheet_list sheet_lookup rel_lookup id_lookup ) ],
		},
		workbook_rels_interface =>{
			package	=> 'WorkbookRelsInterface',
			superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
			differentiation =>{
				zip =>{
					file => 'xl/_rels/workbook.xml.rels',
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookRels',
						'Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface',
					],
				},
				xml =>{
					file => [qw( NO_FILE )],
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookRels',
						'Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface',
					],
				},
			},
			meta_load => [ qw( sheet_lookup worksheet_list chartsheet_list ) ],
		},
		workbook_props_interface =>{
			package	=> 'WorkbookPropsInterface',
			superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
			differentiation =>{
				zip =>{
					file => 'docProps/core.xml',
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookProps',
						'Spreadsheet::Reader::ExcelXML::WorkbookPropsInterface',
					],
				},
				xml =>{
					file => [qw( DocumentProperties )],
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookProps',
						'Spreadsheet::Reader::ExcelXML::WorkbookPropsInterface',
					],
				},
			},
			meta_load => [ qw( creator modified_by date_created date_modified ) ],
		},
		shared_strings_interface =>{
			package => 'SharedStringsInterface',
			superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
			differentiation =>{
				zip =>{
					file => 'xl/sharedStrings.xml',
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings',
						'Spreadsheet::Reader::ExcelXML::SharedStrings',
					],
				},
				xml =>{
					file => [qw( SharedStrings )],
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::XMLReader::NamedSharedStrings',
						'Spreadsheet::Reader::ExcelXML::SharedStrings',
					],
				},
			},
			meta_load => [ qw( self ) ],
		},
		styles_interface =>{
			package => 'StylesInstance',
			superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
			differentiation =>{
				zip =>{
					file => 'xl/styles.xml',
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles',
						'Spreadsheet::Reader::ExcelXML::Styles',
					],
				},
				xml =>{
					file => [qw( Styles )],
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::XMLReader::NamedStyles',
						'Spreadsheet::Reader::ExcelXML::Styles',
					],
				},
			},
			meta_load => [ qw( self ) ],
		},
		worksheet_interface =>{
			package => 'Worksheet',
			superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
			differentiation =>{
				zip =>{
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::CellToColumnRow',
						'Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet',
						'Spreadsheet::Reader::ExcelXML::WorksheetToRow',
						'Spreadsheet::Reader::ExcelXML::Worksheet'
					],
				},
				xml =>{
					add_roles_in_sequence =>[
						'Spreadsheet::Reader::ExcelXML::CellToColumnRow',
						'Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet',
						'Spreadsheet::Reader::ExcelXML::WorksheetToRow',
						'Spreadsheet::Reader::ExcelXML::Worksheet'
					],
				},
			},
		},
		chartsheet_interface =>{
			package => 'Chartsheet',
			superclasses => ['Spreadsheet::Reader::ExcelXML::Chartsheet'],
		},
	};

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has error_inst =>(
		isa	=> 	HasMethods[qw(
							error					set_error				clear_error
							set_warnings			should_spew_longmess	if_warn
							spewing_longmess		has_error
					),
		###LogSD	'set_log_space',
				],
		clearer		=> '_clear_error_inst',
		reader		=> 'get_error_inst',
		predicate	=> 'has_error_inst',
		handles 	=>[ qw(
							error					set_error				clear_error
							set_warnings			should_spew_longmess	if_warn
							spewing_longmess		has_error
						), ],
	);

has formatter_inst =>(
		isa	=> 	ConsumerOf[ 'Spreadsheet::Reader::Format' ],# Interface
		writer	=> 'set_formatter_inst',
		reader	=> 'get_formatter_inst',
		clearer	=> '_clear_formatter_inst',
		predicate => '_has_formatter_inst',
		handles => { qw(
							get_formatter_region			get_excel_region
							has_target_encoding				has_target_encoding
							get_target_encoding				get_target_encoding
							set_target_encoding				set_target_encoding
							change_output_encoding			change_output_encoding
							set_defined_excel_formats		set_defined_excel_formats
							get_defined_conversion			get_defined_conversion
							parse_excel_format_string		parse_excel_format_string
							set_date_behavior				set_date_behavior
							set_european_first				set_european_first
							set_formatter_cache_behavior	set_cache_behavior
							set_workbook_for_formatter		set_workbook_inst
						),
					},
	);
							#~ get_excel_region				get_excel_region

has file =>(
		isa			=> XLSXFile|IOFileType,
		writer		=> 'set_file',
		reader		=> '_file',
		clearer		=> '_clear_file',
		predicate	=> '_has_file',
		trigger		=> \&build_workbook,
		coerce		=> 1,
	);

has count_from_zero =>(
		isa		=> Bool,
		reader	=> 'counting_from_zero',
	);

has file_boundary_flags =>(
		isa			=> Bool,
		reader		=> 'boundary_flag_setting',
	);

has empty_is_end =>(
		isa		=> Bool,
		reader	=> 'is_empty_the_end',
	);

has values_only =>(
		isa		=> Bool,
		reader	=> 'get_values_only',
	);

has from_the_edge =>(
		isa		=> Bool,
		reader	=> 'starts_at_the_edge',
	);

has group_return_type =>(
		isa		=> Enum[qw( unformatted value instance xml_value )],
		reader	=> 'get_group_return_type',
	);

has empty_return_type =>(
		isa		=> Enum[qw( empty_string undef_string )],
		reader	=> 'get_empty_return_type',
	);

has cache_positions =>(
		isa	=> HashRef,# broken -> Dict[ shared_strings_interface => Int, styles_interface => Int, worksheet_interface => Int ],
		traits => ['Hash'],
		reader	=> 'cache_positions',
		writer	=> '_set_cache_positions',
		handles =>{
			_set_cache_size => 'set',
			get_cache_size => 'get',
			has_cache_size => 'exists'
		},
	);

has show_sub_file_size =>(
		isa => Bool,
		reader	=> '_should_show_sub_file_size',
	);

has spread_merged_values =>(
		isa => Bool,
		reader => 'spreading_merged_values',
	);

has skip_hidden =>(
		isa => Bool,
		reader => 'should_skip_hidden',
	);

has spaces_are_empty =>(
		isa => Bool,
		reader => 'are_spaces_empty',
	);

has merge_data =>(
		isa => Bool,
		reader => 'collecting_merge_data',
	);

has column_formats =>(
		isa => Bool,
		reader => 'collecting_column_formats',
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

###LogSD sub get_class_space{ 'Workbook' }

sub worksheets{

    my ( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::worksheets', );
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			'Attempting to build all worksheets: ', $self->get_worksheet_names ] );
	my	@worksheet_array;
	while( my $worksheet_object = $self->worksheet ){
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		'Built worksheet: ' .  $worksheet_object->get_name ] );
		push @worksheet_array, $worksheet_object;#$self->worksheet( $worksheet_name );
	}
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		'sending worksheet array: ',@worksheet_array ] );
	return @worksheet_array;
}

sub worksheet{

    my ( $self, $worksheet_name ) = @_;
	my ( $next_position );
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::worksheet', );
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			"Arrived at (build a) worksheet with: ", $worksheet_name ] );

	# Handle an implied 'next sheet'
	if( !$worksheet_name ){
		my $worksheet_position = $self->_get_current_worksheet_position;
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"No worksheet name passed",
		###LogSD		((defined $worksheet_position) ? "Starting after position: $worksheet_position" : '')] );
		$next_position = ( !$self->in_the_list ) ? 0 : ($self->_get_current_worksheet_position + 1);
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"No worksheet name passed", "Attempting position: $next_position" ] );
		if( $next_position >= $self->worksheet_count ){
			###LogSD	$phone->talk( level => 'info', message =>[
			###LogSD		"Reached the end of the worksheet list" ] );
			return undef;
		}
		$worksheet_name = $self->worksheet_name( $next_position );
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Updated worksheet name: $worksheet_name", ] );
	}

	# Deal with chartsheet requests
	my $worksheet_info = $self->get_sheet_info( $worksheet_name );
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Info for the worksheet -$worksheet_name- is:", $worksheet_info, ] );
	$next_position = $worksheet_info->{sheet_position} if !defined $next_position;
	# Check for sheet existence
	if( !$worksheet_info or !$worksheet_info->{sheet_type} ){
		$self->set_error( "The worksheet -$worksheet_name- could not be located!" );
		return undef;
	}elsif( $worksheet_info->{sheet_type} and $worksheet_info->{sheet_type} eq 'chartsheet' ){
		$self->set_error( "You have requested -$worksheet_name- which is a 'chartsheet' using a worksheet focused method" );
		return undef;
	}
	# NOTE: THE CHARTSHEET / WORKSHEET COMMON SUB-METHOD COULD PROBABLY START HERE
	###LogSD	$phone->talk( level => 'info', message =>[
	###LogSD		"Building: $worksheet_name", "..with data:", $worksheet_info ] );

	# Check for a file and an available parser type then build the worksheet
	my $worksheet;
	confess "No file loaded yet" if !$self->file_opened;
	my $file_ref = clone( $parser_modules->{worksheet_interface} );
	###LogSD	$phone->talk( level	=> 'trace', message =>[
	###LogSD		"Merging general worksheet with this worksheet info" ] );
	my $args = { %$file_ref, %$worksheet_info };
	###LogSD	$phone->talk( level	=> 'trace', message =>[
	###LogSD		"worksheet_interface build attempt with settings:", $args] );

	# Strip bad args
	my $new_args;
	for my $arg (qw(	sheet_position package superclasses sheet_id file
						sheet_name is_hidden sheet_type differentiation		)){
		###LogSD	$phone->talk( level	=> 'debug', message =>[
		###LogSD		"Passing through the values for: $arg", ] );
		$new_args->{$arg} = $args->{$arg} if exists $args->{$arg};
	}

	$worksheet = $self->_build_file_interface( 'worksheet_interface', $new_args );
	###LogSD	$phone->talk( level	=> 'trace', message =>[
	###LogSD		"worksheet_interface build attempt returned:", $worksheet] );
	# handle the worksheet if succesfull
	if( $worksheet ){
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Successfully loaded: $worksheet_name",
		###LogSD		"Setting the current worksheet position to: $next_position" ] );
		$self->_set_current_worksheet_position( $next_position );
		return $worksheet;
	}else{
		$self->set_error( "Failed to build the object for worksheet: $worksheet_name" );
		return undef;
	}
}

sub build_workbook{

    my ( $self, $file ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_hidden::build_workbook', );
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			'Arrived at build_workbook for: ', $file ] );
	$self->clear_error;
	$self->start_at_the_beginning;
	$self->_clear_workbook_file_interface;
	$self->_set_epoch_year( 1900 );
	$self->_clear_sheet_list;
	$self->_clear_sheet_lookup;
	$self->_clear_rel_lookup;
	$self->_clear_id_lookup;
	$self->_clear_worksheet_list;
	$self->_clear_chartsheet_list;
	$self->_clear_creator;
	$self->_clear_modified_by;
	$self->_clear_date_created;
	$self->_clear_date_modified,
	$self->_clear_shared_strings_interface;
	$self->_clear_styles_interface;
	$self->_clear_file_name;
	$self->_set_successful( 0 );

	# Add workbook to formatter (There is a lot more sheet meta data based configuration available here)
	$self->set_workbook_for_formatter( $self );

	#save any file name
	if( XLSXFile->check( $file ) ){
		###LogSD	$phone->talk( level => 'info', message =>[ "Storing the file name: $file" ] );
		$self->_set_file_name( $file );
	}else{
		###LogSD	$phone->talk( level => 'info', message =>[ "Not an xlsx file: $file" ] );
	}

	# Attempt to turn whatever is passed into an IOFileType
	###LogSD	$phone->talk( level => 'info', message =>[ "attempting to coerce passed ref/value: " . (length( ref( $file ) ) > 0 ? ref( $file ) : $file) ] );
	my $file_handle = IOFileType->coerce( $file );
	###LogSD	$phone->talk( level => 'info', message =>[ "Successfully coerced passed value to an IOFileType" ] );
	if( ref $file_handle ){
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Successfully created the file handle:", $file_handle ] );
	}else{
		my $error_message = length( $@ ) > 0 ? $@ : IOFileType->get_message( $file );
		###LogSD	$phone->talk( level => 'info', message =>[ "saving error |$error_message|", ] );
		$self->set_error( $error_message );
		return undef;
	}

    # Attempt to build both a zip and an xml style workbook file extractor to see if either works
	my $result;
	for my $key ( keys %{$parser_modules->{workbook}} ){
		my	$args_ref = clone( $parser_modules->{workbook}->{$key} );
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Initial handle:", $file ] );
		open( my $clone_handle, "<&", $file_handle );# Do this so when a fail -> close sequence happens you still have an open filehandle
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Clone handle:", $clone_handle ] );
		$args_ref->{file} = $clone_handle;
		$args_ref->{workbook_inst} = $self;
		###LogSD	$args_ref->{log_space} = $self->get_log_space;
		###LogSD	$phone->talk( level	=> 'debug', message =>[
		###LogSD		"Attempting to build a base -$key- workbook file reader" ] );
		###LogSD	$phone->talk( level	=> 'trace', message =>[
		###LogSD		'...with ref:', $args_ref] );
		$result = build_instance( $args_ref );
		###LogSD	$phone->talk( level	=> 'trace', message =>[
		###LogSD		"Returned from building: $key" ] );
		if( $result ){
			###LogSD	$phone->talk( level	=> 'trace', message =>[
			###LogSD		'Workbook build attempt returned:', $result] );
			if( $result->loaded_correctly ){
				###LogSD	$phone->talk( level	=> 'debug', message =>[
				###LogSD		'workbook file succesfully integrated' ] );
				$self->clear_error;
				last;
			}else{
				$result = undef;
				###LogSD	$phone->talk( level	=> 'debug', message =>[
				###LogSD		"workbook file build attempt for -$key- failed" ] );
			}
		}
		if( !$result ){
			###LogSD	$phone->talk( level	=> 'debug', message =>[
			###LogSD		"Unable to build the workbook as: $key" ] );
		}
	}
	###LogSD	$phone->talk( level	=> 'trace', message =>[
	###LogSD		'Test for build success with:', $result,] );# ( $result ? $result->meta->dump(6) : undef)
	$self->_clear_file;# Too clean?
	if( !$result ){
		###LogSD	$phone->talk( level	=> 'debug', message =>[
		###LogSD		'Base workbook load failed' ] );
		$self->set_error( "|$file| didn't pass either the zip or xml file initial tests" );
		$self->_clear_file_name;
		return undef;
	}
	$self->_set_successful( 1 );
	###LogSD	$phone->talk( level	=> 'debug', message =>[
	###LogSD		"Setting the workbook interface of type: " . $result->get_file_type ] );
	$self->_set_workbook_file_interface( $result );
	###LogSD	$phone->talk( level	=> 'trace', message =>[
	###LogSD		"Workbook interface set to: ", $result ] );

	# Extract the workbook top level info
	for my $element ( qw(
			workbook_meta_interface		workbook_rels_interface		workbook_props_interface
			shared_strings_interface	styles_interface										) ){
		###LogSD	$phone->talk( level	=> 'debug', message =>[
		###LogSD		"Processing workbook level element: $element" ] );
		my $file_ref = clone( $parser_modules->{$element} );
		###LogSD	$phone->talk( level	=> 'debug', message =>[
		###LogSD		"element ref cloned:", $file_ref ] );
		my $meta_load = $file_ref->{meta_load};
		delete $file_ref->{meta_load};
		$result = $self->_build_file_interface( $element, $file_ref );
		###LogSD	$phone->talk( level	=> 'debug', message =>[
		###LogSD		"$element build attempt returned" ] );
		###LogSD	$phone->talk( level	=> 'trace', message =>[ $result ] );
		if( $result ){
			if( is_Object( $result ) and $result->loaded_correctly ){
				###LogSD	$phone->talk( level	=> 'debug', message =>[ "$element succesfully built", ] );
				if( $meta_load->[0] eq 'self' ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Loading the whole instance to the worksheet" ] );
					my $load_method = '_set_' . $element;
					$self->$load_method( $result );
					shift @$meta_load;# I'm not sure why you would want to load anything else after but just in case
				}
				$self->_load_meta_data( $result, $meta_load );
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Meta data loaded" ] );
			}else{
				###LogSD	$phone->talk( level	=> 'debug', message =>[
				###LogSD		"No $element available" ] );
			};
		}
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"..and final sheet master lookup:", $self->_get_sheet_lookup, ] );

	return $self;
}

sub demolish_the_workbook{
	my ( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_hidden::demolish_the_workbook', );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD			"Last recorded error: " . ($self->error//'none') ] );

	if( $self ){

		if( $self->_has_file ){
			print "closing general file (Used handle)\n";
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Clearing the top level file (used handle)" ] );
			$self->_clear_file;
		}

		if( $self->has_error_inst ){
			#~ print "closing the error instance\n";
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD			"closing the error instance" ] );
			$self->_clear_error_inst;
		}

		if( $self->has_shared_strings_interface ){
			#~ print "closing sharedStrings.xml\n";# . Dumper( $instance )
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD			"Clearing the sharedStrings.xml file" ] );
			$self->_clear_shared_strings_interface;
		}

		if( $self->has_styles_interface ){
			#~ print "closing styles.xml\n";# . Dumper( $instance )
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD			"Clearing the styles.xml file" ] );
			$self->_clear_styles_interface;
		}

		if( $self->_has_workbook_file_interface ){
			#~ print "closing workbook interface file\n";
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD			"Clearing the base workbook file interface" ] );
			$self->_clear_workbook_file_interface;
		}

		if( $self->_has_formatter_inst ){
			#~ print "closing the formatter\n";
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Clearing the formatter" ] );
			$self->_clear_formatter_inst;
		}
	}
	#~ print "~Reader::LibXML closed\n";
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _file_name =>(
		isa	=> XLSXFile,
		writer	=> '_set_file_name',
		clearer	=> '_clear_file_name',
		reader	=> 'file_name',
	);

has _successful =>(
		isa		=> Bool,
		writer	=> '_set_successful',
		reader	=> 'file_opened',
	);

has _epoch_year =>(
		isa			=> Enum[qw( 1900 1904 )],
		writer		=> '_set_epoch_year',
		reader		=> 'get_epoch_year',
		predicate	=> 'has_epoch_year',
		default		=> 1900,
	);

has _sheet_list =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		writer	=> '_set_sheet_list',
		clearer	=> '_clear_sheet_list',
		reader	=> 'get_sheet_names',
		handles	=>{
			get_sheet_name => 'get',
			sheet_count => 'count',
		},
		default	=> sub{ [] },
	);

has _sheet_lookup =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		writer	=> '_set_sheet_lookup',
		reader	=> '_get_sheet_lookup',
		clearer	=> '_clear_sheet_lookup',
		handles	=>{
			get_sheet_info => 'get',
			_set_sheet_info => 'set',
		},
		default	=> sub{ {} },
	);

has _rel_lookup =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		writer	=> '_set_rel_lookup',
		reader	=> '_get_rel_lookup',
		clearer	=> '_clear_rel_lookup',
		handles	=>{
			get_rel_info => 'get',
		},
		default	=> sub{ {} },
	);

has _id_lookup =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		writer	=> '_set_id_lookup',
		reader	=> '_get_id_lookup',
		clearer	=> '_clear_id_lookup',
		handles	=>{
			get_id_info => 'get',
		},
		default	=> sub{ {} },
	);

has _worksheet_list =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		clearer	=> '_clear_worksheet_list',
		writer	=> '_set_worksheet_list',
		reader	=> 'get_worksheet_names',
		handles	=>{
			worksheet_name  => 'get',
			worksheet_count => 'count',
		},
		default	=> sub{ [] },
	);

has _chartsheet_list =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		clearer	=> '_clear_chartsheet_list',
		writer	=> '_set_chartsheet_list',
		reader	=> 'get_chartsheet_names',
		handles	=>{
			chartsheet_name  => 'get',
			chartsheet_count => 'count',
		},
		default	=> sub{ [] },
	);

has _file_creator =>(
		isa		=> Str,
		reader	=> 'creator',
		writer	=> '_set_creator',
		clearer	=> '_clear_creator',
	);

has _file_modified_by =>(
		isa		=> Str,
		reader	=> 'modified_by',
		writer	=> '_set_modified_by',
		clearer	=> '_clear_modified_by',
	);

has _file_date_created =>(
		isa		=> StrMatch[qr/^\d{4}\-\d{2}\-\d{2}/],
		reader	=> 'date_created',
		writer	=> '_set_date_created',
		clearer	=> '_clear_date_created',
	);

has _file_date_modified =>(
		isa		=> StrMatch[qr/^\d{4}\-\d{2}\-\d{2}/],
		reader	=> 'date_modified',
		writer	=> '_set_date_modified',
		clearer	=> '_clear_date_modified',
	);

has _shared_strings_interface =>(
		isa => ConsumerOf[ 'Spreadsheet::Reader::ExcelXML::SharedStrings' ],
		predicate	=> 'has_shared_strings_interface',
		writer		=> '_set_shared_strings_interface',
		reader		=> '_get_shared_strings_interface',
		clearer		=> '_clear_shared_strings_interface',
		handles		=>{
			'get_shared_string' => 'get_shared_string',
			#~ 'start_the_ss_file_over' => 'start_the_file_over',
		},
	);

has _styles_insterface =>(
		isa => ConsumerOf[ 'Spreadsheet::Reader::ExcelXML::Styles' ],
		writer		=> '_set_styles_interface',
		reader		=> '_get_styles_interface',
		clearer		=> '_clear_styles_interface',
		predicate	=> 'has_styles_interface',
		handles		=>{
			get_format	=> 'get_format',
		},
	);

has _current_worksheet_position =>(
		isa			=> Int,
		writer		=> '_set_current_worksheet_position',
		reader		=> '_get_current_worksheet_position',
		clearer		=> 'start_at_the_beginning',
		predicate	=> 'in_the_list',
	);

has _workbook_file_interface =>(
		isa => ConsumerOf[ 'Spreadsheet::Reader::ExcelXML::WorkbookFileInterface' ],
		writer	=> '_set_workbook_file_interface',
		reader	=> '_get_workbook_file_interface',
		clearer	=> '_clear_workbook_file_interface',
		predicate => '_has_workbook_file_interface',
		handles =>{qw(
			_extract_file				extract_file
			_get_workbook_file_type		get_file_type
		)},
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

around set_formatter_inst => sub {
    my ( $method, $self, $instance ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new(
	###LogSD			name_space => $self->get_all_space . '::_hidden::set_formatter_inst', );
	###LogSD		$phone->talk( level => 'trace', message =>[ 'Arrived at set_formatter_inst' ] );

	# Set the workbook instance for observation
	if( $instance->can( 'set_workbook_inst' ) ){
		$instance->set_workbook_inst( $self );
		###LogSD	$phone->talk( level => 'trace', message =>[ 'Finished setting the workbook instance in the formatter inst:', $instance->dump(2) ] );#meta->
	}else{
		confess "Unable to set the formatter instance because it does not have an available method to set the workbook instance";
	}

	# Carry on
	$self->$method( $instance );
};

sub _build_file_interface{
	my( $self, $interface_type, $file_ref, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_hidden::_build_file_interface', );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Building interface: $interface_type" ] );
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"..with file definition ref:", $file_ref ] );
	if( exists $file_ref->{differentiation} ){
		my $sub_ref = $file_ref->{differentiation}->{$self->_get_workbook_file_type};
		delete $file_ref->{differentiation};
		my @key_list = keys %$sub_ref;
		@$file_ref{ @key_list } = @$sub_ref{ @key_list };
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Updated file ref:", $file_ref ] );
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Extracting file:", $file_ref->{file} ] );
	# Handle pulling multiple nodes for flat xml files or one file name for zip files
	my @file_extract = is_ArrayRef( $file_ref->{file} ) ? @{$file_ref->{file}}  : $file_ref->{file};
	my $file = $self->_extract_file( @file_extract );
	if( $file ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Returned the file:", $file, "..of size: " . (-s $file) ] );
		if( $self->_should_show_sub_file_size ){
			warn "Loading interface -$interface_type- with file (byte) size: " . (-s $file);
			if( $self->get_cache_size( $interface_type ) ){
				warn "against max allowable caching: " . $self->get_cache_size( $interface_type );
			}else{
				warn "The interface -$interface_type- does not currently have a non-caching path";
			}
			#~ warn "hit return to acknowledge!!!!";
			#~ my $wait = <>;
		}

		# Turn off caching for sub files over a defined size
		if( $self->has_cache_size( $interface_type ) ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Testing cache size for -$interface_type- with max of: " . $self->get_cache_size( $interface_type ) ] );
			$file_ref->{cache_positions} = -s $file > $self->get_cache_size( $interface_type ) ? 0 : 1 ;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Resolved cache setting: $file_ref->{cache_positions}" ] );
		}

		$file_ref->{file} = $file;
		###LogSD	$file_ref->{log_space} = $self->get_log_space;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Building an instance with (minus the workbook)" ] );
		###LogSD	$phone->talk( level => 'trace', message => [ $file_ref ] );
		$file_ref->{workbook_inst} = $self;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Workbook instance added" ] );
		my $built_instance = build_instance( $file_ref );
		###LogSD	$phone->talk( level => 'debug', message => [ "Built instance"] );
		###LogSD	$phone->talk( level => 'trace', message => [ $built_instance ] );
		#~ $built_instance->set_workbook_inst( $self );
		return $built_instance;
	}else{
		$self->set_error( "Unable to load Spreadsheet::Reader::ExcelXML::XMLReader with the attribute: $interface_type" );
		return undef;
	}
}

sub _load_meta_data{
	my( $self, $interface, $meta_settings ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_hidden::_load_meta_data', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Loading the meta data for:", $meta_settings ] );
	for my $method_base ( @$meta_settings ){
		my $setter = '_set_' . $method_base;
		my $getter = 'get_' . $method_base;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Retrieving from instance with   : $getter", ] );
		my $return = $interface->$getter;
		if( defined $return ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"..and loading to the parser with: $setter", $return ] );
			$self->$setter( $return );
		}
	}
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::Workbook - Complicated self referential worbook class

=head1 DESCRIPTION (TL;DR)

Don't use this module by itself.  Because it has a bit of twisty self referencing, it won't
L<garbage collect|http://www.perlmonks.org/?node_id=1156896> the way you expect unless you
use L<Spreadsheet::Reader::ExcelXML> to manage the garbage collection.  From a practical
standpoint the necessary end user attributes and methods in this code can be effectivly used
against L<Spreadsheet::Reader::ExcelXML>.  Thanks Moose for L<making that easy
|Moose::Manual::Delegation/DEFINING A MAPPING>.  As a consequence all the end user methods
and attributes contained in this module are documented in L<Spreadsheet::Reader::ExcelXML>
instead.  (the down side is the raw code and the documentation are two different files)

=head2 Methods

There are a few methods exported by this class that are not meant to be used by the end user
of the package but will still be delegated to L<Spreadsheet::Reader::ExcelXML> in order to
handle the twisty self referencing.  As a consequence they will be documented here.  (and not
there)

=head3 build_workbook( $file )

=over

B<Definition:> If the passed $file is not a file handle it will store the value for
retrieval by L<Spreadsheet::Reader::ExcelXML/file_name> later.  It will then coerce
the $file into a file handle.  At that point it will reset the whole workbook and extract
the meta data from the workbook file in preparation for reading the sheets.

B<Accepts:> $file which can either be a full file path string or a file handle

B<Returns:> a built and ready to use L<Spreadsheet::Reader::ExcelXML::Workbook> instance
or undef on fail.  It does not return a L<Spreadsheet::Reader::Excel> object even when
called as an exported method in L<Spreadsheet::Reader::Excel>.  (Part of the twisty
nature of this class)

=back

=head3 demolish_the_workbook

=over

B<Definition:> Perl would normally delay garbage cleanup for this class until the script
exits since this has twisty self references.  In order to allow the class to close and
clear when it goes out of scope L<Spreadsheet::Reader::ExcelXML> has to manually clear
this class when it goes out of scope.  This is the method it uses to do that.

B<Accepts:> nothing

B<Returns:> nothing but all the self referencing attributes in the instance are cleared
allowing perl garbage collection to work when the L<Spreadsheet::Reader::ExcelXML>
instance goes out of scope. (after this method is called)

=back

=head3 has_shared_strings_interface

=over

B<Definition:> Indicates if a shared_strings_interface file was loaded and is available for
content extraction

B<Accepts:> nothing

B<Returns:> true if the interface is stored

=back

=head3 get_shared_string

Delegated from L<Spreadsheet::Reader::ExcelXML::SharedStrings/get_shared_string( $positive_intE<verbar>$name )>

=head3 has_styles_interface

=over

B<Definition:> Indicates if a styles_interface file was loaded and is available for
content extraction

B<Accepts:> nothing

B<Returns:> true if the interface is stored

=back

=head3 get_format

Delegated from L<Spreadsheet::Reader::ExcelXML::SharedStrings/get_format( ($positionE<verbar>$name), [$header], [$exclude_header] )>

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

B<L<Spreadsheet::Reader::ExcelXML>> - 2003 xml style and 2007+ (.xlsx) excel sheet reader

B<L<Spreadsheet::Reader::ExcelXML::Worksheet>> - Worksheet level interface

B<L<Spreadsheet::Reader::ExcelXML::Cell>> - Cell level interface

L<Archive::Zip> - 1.30

L<Carp> - confess longmess

L<Clone> - clone

L<Data::Dumper>

L<FileHandle>

L<IO::File>

L<IO::Handle>

L<Modern::Perl> - 1.20150127

L<Moose>

L<MooseX::StrictConstructor>

L<MooseX::HasDefaults::RO>

L<MooseX::StrictConstructor>

L<MooseX::ShortCut::BuildInstance>

L<Spreadsheet::Reader::Format> - v0.2.010

L<Spreadsheet::Reader::Format::FmtDefault>

L<Spreadsheet::Reader::Format::ParseExcelFormatStrings>

L<Type::Library> - 1.000

L<Types::Utils>

L<Types::Standard> -  qw(
 		InstanceOf			Str       			StrMatch			Enum
		HashRef				ArrayRef			CodeRef				Int
		HasMethods			Bool				is_Object			is_HashRef
		ConsumerOf
    )

L<lib>

L<perl 5.010|https://metacpan.org/pod/release/RGARCIA/perl-5.10.0/pod/perl.pod>

L<strict>

L<version> - 0.77

L<warnings>

L<Spreadsheet::Reader::ExcelXML::ZipReader>

L<Spreadsheet::Reader::ExcelXML::CellToColumnRow>

L<Spreadsheet::Reader::ExcelXML::Chartsheet>

L<Spreadsheet::Reader::ExcelXML::Error>

L<Spreadsheet::Reader::ExcelXML::Row>

L<Spreadsheet::Reader::ExcelXML::SharedStrings>

L<Spreadsheet::Reader::ExcelXML::Styles>

L<Spreadsheet::Reader::ExcelXML::WorkbookFileInterface>

L<Spreadsheet::Reader::ExcelXML::WorkbookMetaInterface>

L<Spreadsheet::Reader::ExcelXML::WorkbookPropsInterface>

L<Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface>

L<Spreadsheet::Reader::ExcelXML::WorksheetToRow>

L<Spreadsheet::Reader::ExcelXML::XMLReader>

L<Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet>

L<Spreadsheet::Reader::ExcelXML::XMLReader::NamedSharedStrings>

L<Spreadsheet::Reader::ExcelXML::XMLReader::NamedStyles>

L<Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet>

L<Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings>

L<Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles>

L<Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookMeta>

L<Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookProps>

L<Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookRels>

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta>

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookProps>

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookRels>

L<Spreadsheet::Reader::ExcelXML::Types> - qw( XLSXFile IOFileType is_XMLFile )

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

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
