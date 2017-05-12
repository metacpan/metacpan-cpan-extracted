# -*- perl -*-

use Test::More tests => 766;

use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;
use TaskForest::Calendar;
use TaskForest::LocalTime;

BEGIN {
    use_ok( 'TaskForest::Calendar'  );
}

my $got;
my ($y, $m, $dow);
my $expected = [];


&TaskForest::LocalTime::setTime( { year  => 2000,
                                   month => 02,
                                   day   => 01,
                                   hour  => 10,
                                   min   => 10,
                                   sec   => 10,
                                   tz    => 'America/Chicago',
                                 });
                                       
my $tz    = "America/Chicago";
my $rules = [ "+ 2000/02/*" ];
my $can_run_today;

$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run");

$rules = [ "+ 2000/01/* " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "-", "Can't run");

$rules = [ "+ 2000/01/* ", "+ 2000/02/*" ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run");

$rules = [ "+ first Tuesday 2000/02 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run first Tuesday");

$rules = [ "+ every Tue 2000/02 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run every Tuesday");

$rules = [ "+ last Tuesday 2000/02 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "-", "Can't run on 1st Tuesday");

&TaskForest::LocalTime::setTime( { year  => 2000,
                                   month => 02,
                                   day   => 29,
                                   hour  => 10,
                                   min   => 10,
                                   sec   => 10,
                                   tz    => 'America/Chicago',
                                 });

$rules = [ "+ last Tue 2000/02 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run last Tuesday");

$rules = [ "+ 2000/02/29 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on date");

$rules = [ " 2000/02/29 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on date without +");

$rules = [ " - 2000/02/*", " 2000/02/29 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on date without + as an exception");

$rules = [ " 2000/02/*", "- 2000/02/29 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "-", "Won't run on date because of an exception");

$rules = [ " 2000/02/*", "- 2000/02/28 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Will run today because of a last N/A specific");

$rules = [ " 2000/02/*", "- every Thu 2000/02 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Will run today because of a last N/A nth");

$rules = [ " 2000/02/*", "- second Tue 2000/02 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Will run today because of a last N/A nth with same wday");

# non-existing fifth
print "________________________________________________________________________________\n";
&TaskForest::LocalTime::setTime( { year  => 2000,
                                   month => 03,
                                   day   => 01,
                                   hour  => 10,
                                   min   => 10,
                                   sec   => 10,
                                   tz    => 'America/Chicago',
                                 });

$rules = [ "+ fifth Wed 2000/02 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "-", "Non-existent fifth dow but months differ");

$rules = [ "+ fifth Wed 2000/* " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "-", "Non-existent fifth dow");

$rules = [ "+ fifth Wed */* " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "-", "Non-existent fifth dow");

&TaskForest::LocalTime::setTime( { year  => 2000,
                                   month => 02,
                                   day   => 02,
                                   hour  => 10,
                                   min   => 10,
                                   sec   => 10,
                                   tz    => 'America/Chicago',
                                 });

$rules = [ "+ fifth Wed 2000/02 " ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "-", "Non-existent fifth dow");


# comprehensive 
$rules = [];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "-", "Won't run on date because of an empty rules set");

$rules = [''];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "-", "Won't run on date because of an empty rules set");

$rules = ['+'];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "No components after plus or minus", "Won't run on date because of an empty rules set");

$rules = ['-'];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "No components after plus or minus", "Won't run on date because of an empty rules set");

$rules = [' + '];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "No components after plus or minus", "Won't run on date because of an empty rules set");

$rules = [' - '];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "No components after plus or minus", "Won't run on date because of an empty rules set");

$rules = [' + ', ' -    '];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "No components after plus or minus", "Won't run on date because of an empty rules set");

foreach my $offset (qw (first second third fourth fifth every last)) { 
    $rules = [" + $offset"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, "No components after offset", "Rule is incomplete");
}

foreach my $offset (qw (first second third fourth fifth every last)) { 
    $rules = [" + $offset last"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, "No components after offset last", "Rule is incomplete");
}


foreach my $offset (qw (first second third fourth fifth every last)) {
    foreach my $dow (qw (Mon Tue Wed thu fri sat Sun)) {
        foreach my $modifier ("", "last") { 
            $rules = [" + $offset $modifier Friday 2009/01/01"];
            $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
            is($can_run_today, "Date of month not allowed when specifying day of week", "Date of month not allowed");
        }
    }
}


$rules = [" + 20090101"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "Date not specified in a valid format", "Date not in a valid format");



foreach my $offset (qw (first second third fourth fifth every last)) {
    foreach my $dow (qw (Mon Tue Wed thu fri sat Sun)) {
        foreach my $modifier ("", "last") { 
            $rules = [" + $offset $modifier Friday //*"];
            $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
            is($can_run_today, "Date of month not allowed when specifying day of week", "Date of month not allowed");
        }
    }
}



$rules = [" + 111/12/30"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "Invalid year", "Invalid year");

$rules = [" + 2009/13/30"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "Invalid month", "Invalid month");

$rules = [" + 2009/12/33"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "Invalid day", "Invalid day");



foreach my $offset (qw (first second third fourth fifth every last)) {
    foreach my $dow (qw (Mon Tue Wed thu fri sat Sun)) {
        foreach my $modifier ("", "last") { 
            $rules = [" + $offset $modifier Friday 111/12"];
            $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
            is($can_run_today, "Invalid year", "Invalid year");

            $rules = [" + $offset $modifier Friday 2009/13"];
            $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
            is($can_run_today, "Invalid month", "Invalid month");

            $rules = [" + $offset $modifier Friday 2009/12/33"];
            $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
            is($can_run_today, "Date of month not allowed when specifying day of week", "Date of month not allowed");

            $rules = [" + $offset $modifier Friday 2009/12/*"];
            $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
            is($can_run_today, "Date of month not allowed when specifying day of week", "Date of month not allowed");

            $rules = [" + $offset $dow"];
            $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
            is($can_run_today, "Applicable date range not present", "Date not present");

        }
    }
}



# it is 2/2/2000
foreach my $plus_minus ("+", "-") { 
    $rules = [" $plus_minus 2000/02/01"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, "-", "- - day");

    $rules = [" $plus_minus 2000/03/*"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, "-", "- - month");
    
    $rules = [" $plus_minus 2003/*/*"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, "-", "- - year");
    

    $rules = [" $plus_minus 2000/02/02"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, $plus_minus, "$plus_minus - exact");

    $rules = [" $plus_minus 2000/02/*"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, $plus_minus, "$plus_minus - d_");

    $rules = [" $plus_minus 2000/*/2"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, $plus_minus, "$plus_minus - m_");

    $rules = [" $plus_minus 2000/*/*"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, $plus_minus, "$plus_minus - m_d_");

    $rules = [" $plus_minus */*/*"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, $plus_minus, "$plus_minus - y_m_d_");

    $rules = [" $plus_minus */2/*"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, $plus_minus, "$plus_minus - y_d_");

    $rules = [" $plus_minus */*/2"];
    $can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
    is($can_run_today, $plus_minus, "$plus_minus - y_m_");

}

$rules = [" + 2000/02/02", " - 2000/02/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "-", "plus then minus exact");




$rules = ["first wed 2000/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on first wed");

$rules = ["fourth last wed 2000/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on fourth last wed");



&TaskForest::LocalTime::setTime( { year => 2000, month => 02, day => 9, hour => 10, min => 10, sec => 10, tz => 'America/Chicago', });

$rules = ["second wed 2000/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on second wed");

$rules = ["third last wed 2000/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on third last wed");



&TaskForest::LocalTime::setTime( { year => 2000, month => 02, day => 16, hour => 10, min => 10, sec => 10, tz => 'America/Chicago', });

$rules = ["third wed 2000/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on third wed");

$rules = ["second last wed 2000/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on second last wed");



&TaskForest::LocalTime::setTime( { year => 2000, month => 02, day => 23, hour => 10, min => 10, sec => 10, tz => 'America/Chicago', });

$rules = ["fourth wed 2000/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on fourth wed");

$rules = ["last wed 2000/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on last wed");

$rules = ["first last wed 2000/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on first last wed");

$rules = ["last last wed 2000/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on last last wed");

$rules = ["every last wed 2000/02"];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run on every last wed");


&TaskForest::LocalTime::setTime( { year => 2009, month => 05, day => 03, hour => 10, min => 10, sec => 10, tz => 'America/Chicago', });

$rules = [ " */*/*", "- every Sat */* ", "- every Sun */* "  ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "-", "Won't run on date because today's not a weekday");



# ################################################################################
# DST
&TaskForest::LocalTime::setTime( { year => 2009, month => 03, day => 8, hour => 10, min => 10, sec => 10, tz => 'America/Chicago', });

$rules = [ " second Sun */3 "];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "DST Start US");



&TaskForest::LocalTime::setTime( { year => 2009, month => 11, day => 01, hour => 10, min => 10, sec => 10, tz => 'America/Chicago', });

$rules = [ " First Sun */11 "];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "DST End US");




&TaskForest::LocalTime::setTime( { year => 2009, month => 5, day => 4, hour => 10, min => 10, sec => 10, tz => 'America/Chicago', });

$rules = [ " second Sun */3 ", " */*/*" ];
$can_run_today = &TaskForest::Calendar::canRunToday( { tz => $tz, rules => $rules} );
is($can_run_today, "+", "Can run after ignoring first NA");

