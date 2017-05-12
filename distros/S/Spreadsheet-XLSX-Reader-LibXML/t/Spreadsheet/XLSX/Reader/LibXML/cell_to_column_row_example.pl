#!/usr/bin/env perl
use MooseX::ShortCut::BuildInstance qw( build_class );
use Spreadsheet::XLSX::Reader::LibXML::CellToColumnRow;
use Spreadsheet::XLSX::Reader::LibXML::Error;
use Types::Standard qw( Bool );

my $parser = build_class(
		package => 'MyPackage',
		add_roles_in_sequence =>[ 
			'Spreadsheet::XLSX::Reader::LibXML::CellToColumnRow',
		],
		add_attributes =>{ 
			error_inst =>{
				handles =>[ qw( error set_error clear_error set_warnings if_warn ) ],
				default	=>	sub{ Spreadsheet::XLSX::Reader::LibXML::Error->new(
								#~ should_warn => 1,
								should_warn => 0,# to turn off cluck when the error is set
							) },
			},
			count_from_zero =>{
				isa		=> Bool,
				reader	=> 'counting_from_zero',
				writer	=> 'set_count_from_zero',
			},
			
		},
	);

$parser = MyPackage->new( count_from_zero	=> 0 );
print '(' . join( ', ', $parser->parse_column_row( 'B2' ) ) . ")\n";