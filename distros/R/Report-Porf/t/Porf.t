# Perl 5
#
# Test for Report::Porf::*
#
# Perl Open Report Framework (Porf)
#
# Ralf Peine, Tue May 27 11:29:53 2014
#
#------------------------------------------------------------------------------

$VERSION = "2.001";

use strict;
use warnings;

$|=1;

use Time::HiRes;
use Data::Dumper;

use Report::Porf qw(:all);

use Report::Porf::Framework;
use Report::Porf::Util;
use Report::Porf::Table::Simple;
use Report::Porf::Table::Simple::HtmlReportConfigurator;
use Report::Porf::Table::Simple::TextReportConfigurator;
use Report::Porf::Table::Simple::CsvReportConfigurator;

#--------------------------------------------------------------------------------
#
#  Run
#
#--------------------------------------------------------------------------------

use Test::More tests => 62;
# use Test::Exception;

T001_simple_porf();

T010_create_instances();
T100_align();
T110_interprete_value_options();
T020_verbose();
T300_text_export();
T310_html_export();
T320_csv_export();
T400_auto_report();
T410_handle_undef_cell_values();
T800_use_framework();

#--------------------------------------------------------------------------------
#
#  create Test Data
#
#--------------------------------------------------------------------------------

# --- create persons as array, first entry is constant, following not -----------
sub create_persons_as_array {
	my $max_entries = shift;

	my $start_time = hires_current_time();
	my @rows;
	
	foreach my $l (1..$max_entries) {
		my $time = hires_diff_time($start_time, hires_current_time());
		$time = '8e-06' if $l == 1;
		my @data = (
			$l,
			"Vorname $l",
			"Name $l",
			($l/$max_entries)*100,
			$time,
		);

		push (@rows, \@data);	
	}

	return \@rows;
}

# --- create persons as hash, first entry is constant, following not -----------
sub create_persons_as_hash {
	my $max_entries = shift;

	my $start_time = hires_current_time();
	my @rows;
	
	foreach my $l (1..$max_entries) {
		my $time = hires_diff_time($start_time, hires_current_time());
		$time = '8e-06' if $l == 1;
		my %data = (
			id      => $l,
			prename => "Vorname $l",
			surname => "Name $l",
			number  => ($l/$max_entries)*100,
			time    => $time,
		);

		push (@rows, \%data);	
	}

	return \@rows;
}

#--------------------------------------------------------------------------------
#
#  Helper subs
#
#--------------------------------------------------------------------------------

# --- get hiresolution time, uses Time::HiRes ---
sub hires_current_time {
	return [Time::HiRes::gettimeofday];
}

# --- get difference from now to $start_time in hiresolution time, uses Time::HiRes ---
sub hires_diff_time {
	my $start_time = shift;
	my $end_time   = shift; # current time, if omitted
	return Time::HiRes::tv_interval ($start_time, $end_time); 
}

#--------------------------------------------------------------------------------
#
#  Configure tables
#
#--------------------------------------------------------------------------------

sub create_simple_test_table_columns_for_array_data {
	my $t_o = shift; # $test_object
	
	# --- Configure table ------------------------------------------------------------
	#
	# Order of calls gives order of columns in table
	$t_o->configure_column(-header => 'Count',      -align => 'Center', -value_indexed => 0 );
	$t_o->configure_column(-header => 'TimeStamp', -w => 10, -a => 'R', -val_idx       => 4 );
	$t_o->configure_column(-h      => 'Age',       -w =>  7, -a => 'C', -vi            => 3 );
	$t_o->configure_column(-h      => 'Prename',   -w => 11, -a => 'l', -value => sub { return $_[0]->[1]; } );
	$t_o->configure_column(-h      => 'Surname',   -width =>  8,        -v     =>             '$_[0]->[2]'   );
	
	# --- Configure table end --------------------------------------------------------

	$t_o->configure_complete();
}

sub create_simple_test_table_columns_for_hash_data {
	my $t_o = shift; # $test_object
	
	# --- Configure table ------------------------------------------------------------
	#
	# Order of calls gives order of columns in table
	$t_o->configure_column(-h      => 'Age',       -w =>  7, -a => 'C', -value_named => 'Age' );
	$t_o->configure_column(-h      => 'Prename',   -w => 11, -a => 'l', -val_nam     => 'Prename');
	$t_o->configure_column(-h      => 'Surname',   -width =>  8,        -vn          => 'Surname');
	
	# --- Configure table end --------------------------------------------------------

	$t_o->configure_complete();
}

#------------------------------------------------------------------------------
#
#  Tests
#
#------------------------------------------------------------------------------

# --- Test Creation --------------------------------------------------------
sub T001_simple_porf
{
	is (auto_report(create_persons_as_hash(10)),
		10, 'auto_report(\@data_hashed) prints to STDOUT and returns 10');
	
	is (auto_report(create_persons_as_array(10)),
			10, 'auto_report(\@data_of_arrays) prints to STDOUT and returns 10');

	is (auto_report([[ qw (bla blubber)],
					 [ qw ( A B C D EFGH IJKL),
				   ]]),
		2, 'auto_report() outputs 6 columns for 2 rows for array elements');
	
 # TODO:
 # 	{
 # 		local $TODO = "Not implemented";
 # 		create_report()->write_all(create_persons_as_hash());
 # 	}
}

# --- Test Creation --------------------------------------------------------
sub T010_create_instances {

	my $test_object;
	
	ok ($test_object = Report::Porf::Table::Simple->new(),
		'create instance');

	is ($test_object->get_max_col_width(),   0, 'initial MaxColWidth');
	is ($test_object->get_max_column_idx(), -2, 'initial MaxColumnIdx');
}

# --- Test verbose --------------------------------------------------------
sub T020_verbose {

	my $test_object = Report::Porf::Table::Simple->new();

	$test_object->set_verbose(0);
	is (verbose($test_object,  ), 0, 'verbose( ) 0 0');
	is (verbose($test_object, 1), 0, 'verbose(1) 0 0');
	is (verbose($test_object, 8), 0, 'verbose(8) 0 0');

	$test_object->set_verbose(2);
	is (verbose($test_object,  ), 2, 'verbose( ) 2 2');
	is (verbose($test_object, 1), 2, 'verbose(1) 2 0');
	is (verbose($test_object, 8), 0, 'verbose(8) 2 8');
}

# --- Test Align --------------------------------------------------------
sub T100_align {
	# --- left => L -----------------------------------------------------------
	is (interprete_alignment('left'  ), 'Left', "alignment 'left'");
	is (interprete_alignment('l'     ), 'Left', "alignment 'l'");
	is (interprete_alignment('  L'   ), 'Left', "alignment '  L'");
	is (interprete_alignment('lEfT'  ), 'Left', "alignment 'LeFt'");
	is (interprete_alignment('lEfT  '), 'Left', "alignment 'LeFt  '");

	# --- center => C -----------------------------------------------------------
	is (interprete_alignment('center'  ), 'Center', "alignment 'center'");
	is (interprete_alignment('c'       ), 'Center', "alignment 'c'");
	is (interprete_alignment(' C '     ), 'Center', "alignment ' C '");
	is (interprete_alignment('cEnTeR'  ), 'Center', "alignment 'cEnTeR'");
	is (interprete_alignment(' cEnTeR '), 'Center', "alignment ' cEnTeR '");

	# --- right => R -----------------------------------------------------------
	is (interprete_alignment('right'  ), 'Right', "alignment 'right'");
	is (interprete_alignment('r'      ), 'Right', "alignment 'r'");
	is (interprete_alignment('  R'    ), 'Right', "alignment '  R'");
	is (interprete_alignment('RiGHt'  ), 'Right', "alignment 'RiGHt'");
	is (interprete_alignment('  RiGHt'), 'Right', "alignment '  RiGHt'");

	# # --- bla => dies -----------------------------------------------------
	# throws_ok {
	#     interprete_alignment(' bla     ');
	# }
	# 	qr/cannot interprete alignment/i,
	# 		"configure align by unallowed value 'bla'";
}

# --- Test the interpreter for value options ----------------------------
sub T110_interprete_value_options {

    is (interprete_value_options ({ -value => '$bla;'}), '$bla;', '-value => $bla;');
    is (interprete_value_options ({ -val   => '$bla;'}), '$bla;', '-val   => $bla;');
    is (interprete_value_options ({ -v     => '$bla;'}), '$bla;', '-v     => $bla;');

    is (interprete_value_options ({ -value_indexed => 0 }), '$_[0]->[0]', '-value_indexed => 0');
    is (interprete_value_options ({ -val_idx       => 1 }), '$_[0]->[1]', '-val_idx       => 1');
    is (interprete_value_options ({ -vi            => 2 }), '$_[0]->[2]', '-vi            => 2');

    is (interprete_value_options ({ -value_named   => 'x'   }), '$_[0]->{\'x\'}',   "-value_named => 'x'  ");
    is (interprete_value_options ({ -val_nam       => 'x_y' }), '$_[0]->{\'x_y\'}', "-val_nam     => 'x_y'");
    is (interprete_value_options ({ -vn            => '_'   }), '$_[0]->{\'_\'}',   "-vn          => '_'  ");

    is (interprete_value_options ({ -value_object  => ' maximal () ' }), '$_[0]->maximal()', "-value_object => ' maximal () '");
    is (interprete_value_options ({ -val_obj       => 'Max_1A()'     }), '$_[0]->Max_1A()' , "-val_obj      => 'Max_1A()'    ");
    is (interprete_value_options ({ -vo            => 'min'          }), '$_[0]->min()'    , "-vo           => 'min'         ");
}

# --- Test text export --------------------------------------------------------
sub T300_text_export {

	my $text_report_configurator = Report::Porf::Table::Simple::TextReportConfigurator->new();
	my $test_object = Report::Porf::Table::Simple->new();
	# $test_object->set_verbose(3);
	# $test_object->set_verbose(2);
	
	# --- Test -------------------------------------------------------	
	ok ($text_report_configurator->configure_report($test_object), 'configure text report');

	# --- Test -------------------------------------------------------	

	# --- Test: prepare ---
	my $person_rows = create_persons_as_array(10);

	create_simple_test_table_columns_for_array_data($test_object);

	# --- Test: call and validate ---
	is ($test_object->get_row_output($person_rows->[0]),
		"|      1     |      8e-06 |    10   | Vorname 1   | Name 1   |\n",
		'create one row of text output');

	# --- Test -------------------------------------------------------	
	# --- Test: prepare ---
	# --- Test: call ---
	# --- Test validation ---
}

# --- Test Html export --------------------------------------------------------
sub T310_html_export {

	my $html_report_configurator = Report::Porf::Table::Simple::HtmlReportConfigurator->new();
	my $test_object = Report::Porf::Table::Simple->new();
	# $test_object->set_verbose(3);
	# $test_object->set_verbose(2);
	$html_report_configurator->set_verbose(3);
	
	# --- Test -------------------------------------------------------	
	ok ($html_report_configurator->configure_report($test_object), 'configure text report');

	# --- Test -------------------------------------------------------	

	# --- Test: prepare ---
	my $person_rows = create_persons_as_array(10);

	create_simple_test_table_columns_for_array_data($test_object);

	# --- Test: call and validate ---
	is ($test_object->get_row_output($person_rows->[0]),
		'<tr><td  align="center">1</td><td  align="right">8e-06</td><td  align="center">10</td>'
			.'<td  align="left">Vorname 1</td><td  align="left">Name 1</td></tr>'
				."\n",
		'create one row of hmtl output');

	# --- Test -------------------------------------------------------	

	# --- Test: prepare ---
	$test_object = Report::Porf::Framework::get()->create_report('html');
	# $test_object->set_verbose(3);

	my $person = {
		Prename => 'Ralf',
		Age => 48,
		Surname => "<Title>&<Name>&...",
	};
	
	create_simple_test_table_columns_for_hash_data($test_object);

	# --- Test: call and validate ---
	is ($test_object->get_row_output($person),
		'<tr bgcolor="#FFFFFF"><td  align="center">48</td><td  align="left">Ralf</td>'
            .'<td  align="left">&lt;Title&gt;&amp;&lt;Name&gt;&amp;...</td></tr>'
				."\n",
		'create one row of html output with special chars escaped');

	# --- Test -------------------------------------------------------	
	# --- Test: prepare ---
	# --- Test: call ---
	# --- Test validation ---
}

# --- Test csv export --------------------------------------------------------
sub T320_csv_export {

	my $csv_report_configurator = Report::Porf::Table::Simple::CsvReportConfigurator->new();
	my $test_object = Report::Porf::Table::Simple->new();
	# $test_object->set_verbose(3);
	# $test_object->set_verbose(2);
	
	# --- Test -------------------------------------------------------	
	ok ($csv_report_configurator->configure_report($test_object), 'configure csv report');

	# --- Test -------------------------------------------------------	

	# --- Test: prepare ---
	my $person_rows = create_persons_as_array(10);

	create_simple_test_table_columns_for_array_data($test_object);

	# --- Test: call and validate ---
	is ($test_object->get_row_output($person_rows->[0]),
		"1,8e-06,10,Vorname 1,Name 1\n",
		'create one row of csv output');

	# --- Test -------------------------------------------------------	
	# --- Test: prepare ---
	# --- Test: call ---
	# --- Test validation ---
}

# --- Auto Report ----------------------------------------------

sub T400_auto_report {
    my $sfh = new FileHandle('>/dev/null');
    my $data_rows = [{Vorname    => 'Ralf',
		      Nachname   => 'Peine',
		      Geburtstag => '29.12.1965',
		      Wohnort    => 'Bocholt'
		     },
		     {bla => 'bla'},
		     {bla => 'bla'},
		     {bla => 'bla'},
		     {Vorname    => 'Ralf',
		      Nachname   => 'Peine',
		      Geburtstag => '29.12.1965',
		      Wohnort    => 'Bocholt',
			  PLZ        => '4639x',
		     },
		     {bla => 'bla'},
		     {bla => 'bla'},
		     {bla => 'bla'},
		     {bla => 'bla'},
		     {bla => 'bla'},
		     {bla => 'bla'},
		     {Vorname    => 'Ralf',
		      Nachname   => 'Peine',
		      Geburtstag => '29.12.1965',
		      Wohnort    => 'Bocholt',
			  Blubber    => 'Must not be shown'
		     },
	];
		      

    # --- Test -------------------------------------------------------	
	is (Report::Porf::Framework::auto_report(
		[{Vorname    => 'Ralf',
		  Nachname   => 'Peine',
		  Geburtstag => '29.12.1965',
		  Wohnort    => 'Bocholt'
	  }],
		-file => $sfh),
		1, "Auto Report gives out single row");
    
    # --- Test -------------------------------------------------------	
	is (Report::Porf::Framework::auto_report(),
		0, "Auto Report without list");
	
    # --- Test -------------------------------------------------------	
	is (Report::Porf::Framework::auto_report([]),
		0, "Auto Report without empty list");
	
    # --- Test -------------------------------------------------------	
    my $result;
	is (Report::Porf::Framework::auto_report(
		$data_rows,
		-file     => $sfh),
		12, "Auto Report gives out all 12 rows");

    # --- Test -------------------------------------------------------	
	is (Report::Porf::Framework::auto_report(
		$data_rows,
		-max_rows => 4,
		-file     => $sfh),
		4, "Auto Report -max_rows == 4");
    
	# --- Test -------------------------------------------------------	
	is (Report::Porf::Framework::auto_report($data_rows),
		10, "Auto Report gives out max 10 rows without file handle");

    # diag ('Auto Report complete.');

	# --- Test -------------------------------------------------------	
	# --- Test: call ---
	my $report_configuration = Report::Porf::Framework::create_auto_report_configuration($data_rows);
	
	# --- Test validation ---
	is (scalar @$report_configuration,
		6, "create_auto_report_configuration creates 6 columns");
	is ($report_configuration->[0]->{-h},
		'Geburtstag', "create_auto_report_configuration, check name of first of 6 columns");

	# --- Test --- use all list entries for column setup --------------------------------------------
	# --- Test: call ---
	$report_configuration = Report::Porf::Framework::create_auto_report_configuration($data_rows, -1);
	
	# --- Test validation ---
	is (scalar @$report_configuration,
		7, "create_auto_report_configuration creates all columns");
	is ($report_configuration->[0]->{-h},
		'Blubber', "create_auto_report_configuration, check name of first of all columns");

	# diag( Dumper($report_configuration));

	# --- Test --- ReportConfigurationAsString ----------------------------------------------------	
	# --- Test: call ---
	$report_configuration = Report::Porf::Framework::report_configuration_as_string($data_rows);
	
	# --- Test validation ---
	is (scalar @$report_configuration,
		6, "create_auto_report_configuration creates 6 columns");
	is ($report_configuration->[0],
		'$report->cc(  -a => l,  -h => Geburtstag,  -vn => Geburtstag,  -w => 10, );',
		"create_auto_report_configuration, check name of first of 6 columns");

    # diag ('Auto Report complete.');
}

# --- Test handling of undefined cell values using default values -----------------------

sub T410_handle_undef_cell_values {

    my $sfh = new FileHandle('>/dev/null');
	my $person = {
		Prename  => Clark =>
		Surname  => Kent =>
		Fullname => undef
	};

	# catch warnings by some module ...
		Report::Porf::Framework::auto_report(
			[$person, {Prename => undef, Surname => 'bla', blubber => 1}],
			-file => $sfh
		);
	#

	my $warnings = '';
	
	is ($warnings,
		'', "No warnings for undefined values should appear");

	# --- Test ---
	
	Report::Porf::Framework::auto_report(
		[$person, {Prename => undef, Surname => 'bla', blubber => 1}],
		-format => 'html',
		-file   => $sfh
	);

	# --- Test ---
	Report::Porf::Framework::auto_report(
		[$person, {Prename => undef, Surname => 'bla', blubber => 1}],
		-format => 'csv',
		-file   => $sfh
	);
}
	
# --- Test framework class -------------------------------------------
sub T800_use_framework {

	my $test_object;

	# --- Test Text -------------------------------------------------------	

	# --- Test: prepare ---
	$test_object = Report::Porf::Framework::get();
	my $person_rows = create_persons_as_array(10);

	# --- Test: call ---
	my $text_report = $test_object->create_report('text');

	# --- Test: validate ---
	create_simple_test_table_columns_for_array_data($text_report);
	is ($text_report->get_row_output($person_rows->[0]),
		"|      1     |      8e-06 |    10   | Vorname 1   | Name 1   |\n",
		'create text report by default framework');

	# --- Test Html -------------------------------------------------------	

	# --- Test: prepare ---
	$test_object = Report::Porf::Framework::create(-name => 'T800');
	$person_rows = create_persons_as_array(10);

	# --- Test: call ---
	my $html_report = $test_object->create_report('html');

	# --- Test: validate ---
	create_simple_test_table_columns_for_array_data($html_report);
	is ($html_report->get_row_output($person_rows->[0]),
		'<tr bgcolor="#FFFFFF"><td  align="center">1</td>'
	    .'<td  align="right">8e-06</td><td  align="center">10</td>'
		.'<td  align="left">Vorname 1</td><td  align="left">Name 1</td></tr>'
		."\n",
		'create html report by default framework');

	# --- Test Csv -------------------------------------------------------	

	# --- Test: prepare ---
	$test_object = Report::Porf::Framework::get();
	$person_rows = create_persons_as_array(10);

	# --- Test: call ---
	my $csv_report = $test_object->create_report('csv');

	# --- Test: validate ---
	create_simple_test_table_columns_for_array_data($csv_report);
	is ($csv_report->get_row_output($person_rows->[0]),
		"1,8e-06,10,Vorname 1,Name 1\n",
		'create csv report by default framework');
}
