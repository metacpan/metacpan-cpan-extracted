# perl
#
# Report example, data rows given as array reference
#
# PORF Perl Open Report Framework
#
# Ralf Peine, Wed May 14 10:39:23 2014
#
#------------------------------------------------------------------------------

use warnings;
use strict;

use Report::Porf::Framework;

sub run_example {
    my $person_rows   = shift; # Param1: Reference to list of arrays
    my $format        = shift; # Param2: Optional: format of report

    my $count_rows    = scalar @{$person_rows};

    $format = 'text' unless $format;

    # --- create Report -------------------------------------------------------
    my $report_frame_work   = Report::Porf::Framework::get();
    my $report_configurator = $report_frame_work->create_report_configurator($format);

    # $report->set_verbose(3); # uncomment to see infos about configuring phase

    # --- Configure Report ----------------------------------------------------

    $report_configurator->set_alternate_row_colors('#EEEEEE', '#FFFFFF', '#DDDDFF')
        if $report_configurator->can ('set_alternate_row_colors');

    my $report = $report_configurator->create_and_configure_report();

    # store info about data columns
    my $count_idx   = 0;
    my $prename_idx = 1;
    my $surname_idx = 2;
    my $age_idx     = 3;
    my $time_idx    = 4;

    if ( lc($format) eq 'text') {
        $report->set_header_row_start("@");  # overwrite default
        $report->set_header_end     (" @"); # overwrite default
    }

    # --- configure table -----------------------------------   
    
    $report->configure_column(-header => 'Count',      -align => 'Center', -value  => sub { return $_[0]->[$count_idx      ]; } );
    $report->configure_column(-header => 'TimeStamp', -w => 16, -a => 'R', -format => "%.5e sec",
                             -color  => "#CCEECC",                        -v      =>             '$_[0]->['.$time_idx.   ']'   );
    $report->configure_column(-h      => 'Age',       -w => 15, -a => 'R',
                             -f      => "%.3f years",                     -value_indexed => $age_idx     );
    $report->configure_column(-h      => 'Prename',   -w => 11, -a => 'l', -val_idx       => $prename_idx );
    $report->configure_column(-h      => 'Surname',   -width =>  8,        -vi            => $surname_idx );   
    
    $report->configure_complete();

    # --- print out table under own control ----------------------------------- 

    print($report->get_output_start());
    
    foreach my $data (@{$person_rows}) {
        print($report->get_row_output($data));
    }
    
    print($report->get_output_end()); 
    
    # --- return count of entries ---------------------------   

    return ($count_rows);
}

1;
