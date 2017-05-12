# perl
#
# Minimal report example using shortest options,
# data rows given as object instance
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
    my $person_rows   = shift; # Param1: Reference to list of objects
    my $format        = shift; # Param2: Optional: format of report

    $format = 'text' unless $format;

    # --- create Report -------------------------------------------------------
    my $report_frame_work = Report::Porf::Framework::get();
    my $r                 = $report_frame_work->create_report($format);

    # $r->set_verbose(3); # uncomment to see infos about configuring phase

    # --- Configure Report ----------------------------------------------------

    $r->cc(-h => 'Prename', -vo => 'get_prename()');
    $r->cc(-h => 'Surname', -vo => 'get_surname()');  
    $r->cc(-h => 'Age',     -vo => 'get_age()'    );  

    $r->configure_complete();

    # --- print out table -----------------------------------   

    $r->write_all($person_rows); # print STDOUT ...

    # --- return count of entries ---------------------------   

    return (scalar @{$person_rows});
}

1;
