# perl
#
# Minimal report example, data rows given as array reference
#
# PORF Perl Open Report Framework
#
# Ralf Peine, Wed May 14 10:39:47 2014
#
#------------------------------------------------------------------------------

use warnings;
use strict;

use Report::Porf::Framework;

# --- Run The Example ----------------------------------------
sub run_example {
    my $person_rows   = shift; # Param1: Reference to list of arrays
    my $format        = shift; # Param2: Optional: format of report

    $format = 'text' unless $format;

    my $count_rows    = scalar @{$person_rows};
    my $out_file_name = "result_minimal_array_${count_rows}.${format}";
    my $file_handle   = FileHandle->new($out_file_name, 'w');

    print "Write into result file: $out_file_name\n";

    # --- create Report -------------------------------------------------------
    my $report_frame_work = Report::Porf::Framework::get();
    my $report            = $report_frame_work->create_report($format);

    # $report->set_verbose(3); # uncomment to see infos about configuring phase

    # --- Configure Report ----------------------------------------------------

    my %idx = get_person_row_index_info();
    
    $report->configure_column(-header => 'Prename', -value_indexed => $idx{Prename} ); # long
    $report->conf_col        (-h      => 'Surname', -val_idx       => $idx{Surname} ); # short
    $report->cc             (-h      => 'Age',     -vi            => $idx{Age}     ); # minimal

    $report->configure_complete();

    # --- print out table -----------------------------------   

    $report->write_all($person_rows, $file_handle);

    # --- return count of entries ---------------------------   

    return ($count_rows);
}

# --- can be defined anywhere and global for person_rows ---
sub get_person_row_index_info {
    my %idx = (
        Count => 0,            # not used!
        Prename => 1,
        Surname => 2,
        Age     => 3,
        Time  => 4,            # not used!
        );

    return %idx;
}

1;
