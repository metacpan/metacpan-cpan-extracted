# perl
#
# Minimal report example using shortest options,
# data rows given as array reference
#
# PORF Perl Open Report Framework
#
# Ralf Peine, Wed May 14 10:39:49 2014
#
#------------------------------------------------------------------------------

use warnings;
use strict;

use Report::Porf::Framework;

sub run_example {
    my $person_rows   = shift; # Param1: Reference to list of arrays
    my $format        = shift; # Param2: Optional: format of report

    $format = 'text' unless $format;

    # --- create Report -------------------------------------------------------
    my $report_frame_work = Report::Porf::Framework::get();
    my $r                 = $report_frame_work->create_report($format);

    # $r->set_verbose(3); # uncomment to see infos about configuring phase

    # --- Configure Report ----------------------------------------------------

    # store info about data columns
    # my $count_idx = 0;            # not used!
    my $prename_idx = 1;
    my $surname_idx = 2;
    my $age_idx     = 3;
    # my $time_idx  = 4;            # not used!
    
    $r->cc(-h => 'Prename', -vi => $prename_idx);
    $r->cc(-h => 'Surname', -vi => $surname_idx);       
    $r->cc(-h => 'Age',     -vi => $age_idx    );       

    $r->configure_complete();

    # --- print out table -----------------------------------   

    $r->write_all($person_rows); # print STDOUT ...

    # --- return count of entries ---------------------------   

    return (scalar @{$person_rows});
}

1;
