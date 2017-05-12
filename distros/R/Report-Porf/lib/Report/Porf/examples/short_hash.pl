# perl
#
# Minimal report example using shortest options,
# data rows given as hash references
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
    my $person_rows   = shift; # Param1: Reference to list of hashes
    my $format        = shift; # Param2: Optional: format of report

    $format = 'text' unless $format;

    # --- create Report -------------------------------------------------------
    my $report_frame_work = Report::Porf::Framework::get();
    my $r                 = $report_frame_work->create_report($format);

    # $r->set_verbose(3); # uncomment to see infos about configuring phase

    # --- Configure Report ----------------------------------------------------

    $r->cc(-h => 'Prename', -vn => 'Prename');
    $r->cc(-h => 'Surname', -vn => 'Surname');  
    $r->cc(-h => 'Age',     -vn => 'Age'    );  

    $r->configure_complete();

    # --- print out table -----------------------------------   

    $r->write_all($person_rows); # print STDOUT ...

    # --- return count of entries ---------------------------   

    return (scalar @{$person_rows});
}

1;
