# perl
#
# Minimal report example, data rows given as object reference
#
# PORF Perl Open Report Framework
#
# Ralf Peine, Wed May 14 10:39:48 2014
#
#------------------------------------------------------------------------------

use warnings;
use strict;

use Report::Porf::Framework;

sub run_example {
	my $person_rows   = shift; # Param1: Reference to list of objectes
	my $format        = shift; # Param2: Optional: format of report

	$format = 'text' unless $format;

	my $count_rows    = scalar @{$person_rows};
	my $out_file_name = "result_minimal_object_${count_rows}.${format}";

	# --- create Report -------------------------------------------------------
	my $report_frame_work = Report::Porf::Framework::get();
	my $report            = $report_frame_work->create_report($format);

	# $report->set_verbose(3); # uncomment to see infos about configuring phase

	# --- Configure Report ----------------------------------------------------

	$report->configure_column(-header => 'Prename', -value_object => 'get_prename()' ); # long
	$report->conf_col        (-h      => 'Surname', -val_obj      => 'get_surname()' ); # short
	$report->cc             (-h      => 'Age',     -vo           => 'get_age()'     ); # minimal

	$report->configure_complete();

	# --- print out table -----------------------------------	

	$report->write_all($person_rows, $out_file_name);

	# --- return count of entries ---------------------------	

	return ($count_rows);
}

1;
