# perl
#
# Minimal report example, data rows given as hash reference
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
    my $person_rows   = shift; # Param1: Reference to list of hashes
    my $format        = shift; # Param2: Optional: format of report

    $format = 'text' unless $format;

    my $count_rows    = scalar @{$person_rows};
    my $out_file_name = "result_presentation_mini_${count_rows}.${format}";

    # --- Write A Report In 4+n Statements ! ---------------------------   

    my $report_framework = Report::Porf::Framework::get();
    my $report = $report_framework->create_report($format);

    $report->configure_column (-header => 'Vorname',  -value_named => 'Prename' );
    $report->conf_col         (-h      => 'Nachname', -val_nam     => 'Surname');
    $report->cc              (-h      => 'Alter',    -vn          => 'Age');
    
    $report->configure_complete();
    $report->write_all($person_rows, $out_file_name);

    # --- return count of entries ---------------------------   

    return ($count_rows);
}

1;
