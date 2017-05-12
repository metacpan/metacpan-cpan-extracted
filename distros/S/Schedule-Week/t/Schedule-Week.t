#!/usr/bin/perl

use strict;
use FindBin;
use lib "${FindBin::Bin}/lib";
use lib "${FindBin::Bin}/../lib";

use Test::More tests => 884;

BEGIN{ use_ok('Schedule::Week') };
use Schedule::Week qw(:days);

my $schedule = Schedule::Week->new();

isa_ok($schedule, 'Schedule::Week');

my %NUM4 = (
    'sunday'    => 0,
    'monday'    => 1,
    'tuesday'   => 2,
    'wednesday' => 3,
    'thursday'  => 4,
    'friday'    => 5,
    'saturday'  => 6,
);

my %NAM4 = (
    0 => 'sunday',
    1 => 'monday',
    2 => 'tuesday',
    3 => 'wednesday',
    4 => 'thursday',
    5 => 'friday',
    6 => 'saturday',
);

for my $day (qw(sunday monday tuesday wednesday thursday friday saturday)) {
    cmp_ok($schedule->has_hours($NUM4{$day}), '==', 0, "$day initially 0");
    #  Turn on 10 AM
    $schedule->$day([10], 1); 
    my @hours = $schedule->$day();
    cmp_ok($schedule->has_hours($NUM4{$day}), '==', 1, "$day now has hours");
    cmp_ok($hours[10], '==', 1, "$day now has 10 AM on");
}

#  Adds 7 tests
reset_schedule($schedule);

eval {
    $schedule->hours();
};

cmp_ok($@, '=~', 'Missing reference',
       "hours() method requires a reference to an array of hours");

eval {
    $schedule->hours('foo');
};

cmp_ok($@, '=~', 'is not a reference',
       "hours() method requires a reference to an array of hours");

for my $hour (0 ... 23) {


    my @hour4day = $schedule->hours([$hour]);

    for my $day ($SUNDAY ... $SATURDAY) {
        cmp_ok($hour4day[$day]->[0], '==', 0, 
               "Hour $hour initially set to 0 for $NAM4{$day}");
    }

    #  Now turn on the hour
    $schedule->hours([$hour], 1);

    #  Verify
    @hour4day = $schedule->hours([$hour]);
    for my $day ($SUNDAY ... $SATURDAY) {
        cmp_ok($hour4day[$day]->[0], '==', 1, 
               "Hour $hour now set to 1 for $NAM4{$day}");
    }

}

reset_schedule($schedule);

#  Now set and get lists of hours
test_hour_sets();

#  Test day mixes
test_hours_for_day();

test_is_active_method();

test_serialization();
test_deserialization();

exit;

########
# SUBS #
########

sub reset_schedule {

    my $s = shift;
    $s->reset();

    for my $day ($SUNDAY ... $SATURDAY) {
        cmp_ok($schedule->has_hours($day), '==', 0, "Day $day has no hours");
    }

}

sub test_hour_sets {

    my $s = Schedule::Week->new();

    #  Midnight, 5 AM, 9 AM
    my @hour_set = (0, 5, 9);

    #  Set across all days in one call
    $s->hours(\@hour_set, 1);

    for my $day ($SUNDAY ... $SATURDAY) {

        my $name = $NAM4{$day};

        #  Verify
        my @hours4day = $s->hours_for_day($day, \@hour_set);

        my $i = 0;
        for my $h (@hours4day) {
            cmp_ok($h, '==', 1, "$name - hour $hour_set[$i] is now 1");
            $i++;
        }

        #  Reset to 0 and verify
        @hours4day = $s->hours_for_day($day, \@hour_set, 0);

        $i = 0;
        for my $h (@hours4day) {
            cmp_ok($h, '==', 0, "$name - hour $hour_set[$i] reset to 0");
            $i++;
        }

        #  Ensure reset worked by retrieving one at a time
        $i = 0;
        for my $h (@hours4day) {
            my @hr = $s->hours_for_day($day, [$h]);
            cmp_ok($hr[0], '==', 0, 
                           "$name - get hour $hour_set[$i] - set to 0");
            $i++;
        }

        #  Set a day at a time to make sure that works as well
        my @day_hours = $s->$name(\@hour_set, 1);

        $i = 0;
        for my $h (@day_hours) {
            cmp_ok($h, '==', 1, "$name - hour $hour_set[$i] is now 1");
            $i++;
        }

        #  Reset to 0 and verify
        @hours4day = $s->$name(\@hour_set, 0);

        $i = 0;
        for my $h (@hours4day) {
            cmp_ok($h, '==', 0, "$name - hour $hour_set[$i] reset to 0");
            $i++;
        }

        #  Ensure reset worked by retrieving one at a time
        $i = 0;
        for my $h (@hours4day) {
            my @hr = $s->$name([$h]);
            cmp_ok($hr[0], '==', 0, 
                           "$name - get hour $hour_set[$i] - set to 0");
            $i++;
        }
    }
}

sub test_hours_for_day {

    my $s = Schedule::Week->new();

    my @hour_set = (9 ... 21);

    for my $day ($MONDAY, $TUESDAY, $WEDNESDAY) {
        my $name = $NAM4{$day};
        $s->hours_for_day($day, \@hour_set, 1);
        my @hours4day =  $s->hours_for_day($day, \@hour_set);

        cmp_ok(scalar(@hours4day), '==', scalar(@hour_set),
               "$name - hour array set and returned are same size");

        my $i = 0;

        for my $h (@hours4day) {
            cmp_ok($h, '==', 1, "$name - hour $hour_set[$i] is set to 1");
            $i++;
        }

    }

    #  Hours in these days should all be unset still!
    for my $day ($SUNDAY, $THURSDAY, $FRIDAY, $SATURDAY) {
        my $name = $NAM4{$day};
        my $i = 0;

        my @hours4day =  $s->hours_for_day($day, \@hour_set);
        for my $h (@hours4day) {
            cmp_ok($h, '==', 0, "$name - hour $hour_set[$i] is set to 0");
            $i++;
        }
    }

}

sub test_is_active_method {

    my $s = Schedule::Week->new();

    my $now = time();

    cmp_ok($s->is_active(), '==', 0,
           "is_active() returns 0 this since new schedule is all off");

    cmp_ok($s->is_active($now), '==', 0,
           "is_active($now) returns 0 this since new schedule is all off");

    #  Turn on every hour
    $s->hours([0 ... 23], 1);

    cmp_ok($s->is_active(), '==', 1,
           "is_active() returns 0 this since all hours are now on");

    cmp_ok($s->is_active($now), '==', 1,
           "is_active($now) returns 0 this since all hours are now on");

}

sub test_serialization {

    my $s = Schedule::Week->new();

    my $serialized = $s->serialize();

    cmp_ok(length($serialized), '==', 168,
           "Serialized schedule should always be 168 chars long");

    cmp_ok(scalar($serialized =~ s/0//gsm), '==', 168,
           "Serialized schedule should be all 0s immediately after new()");

    #  Set an hour across all days, get serialized copy, ensure it matches
    #  what we think should be set
    $s->hours([12], 1);

    my $noon_everyday = $s->serialize();

    my $offset = 12;   # Noon is element 13

    for my $day ($SUNDAY ... $SATURDAY) {
        my $name = $NAM4{$day};
        my $hour_char = substr($noon_everyday, $offset, 1);
        cmp_ok($hour_char, 'eq', '1', "$name - noon is set to 1");
        $offset += 24;
    }

    reset_schedule($s);

    my $clean_slate = $s->serialize();

    $offset = 0;
    for my $day ($SUNDAY ... $SATURDAY) {
        my $name = $NAM4{$day};
        my $hour_char = substr($clean_slate, $offset, 1);
        cmp_ok($hour_char, 'eq', '0', "$name - noon reset to 0");
        $offset += 24;
    }

}

sub test_deserialization {

    my $s = Schedule::Week->new();

    eval {
        Schedule::Week::deserialize();
    };
    cmp_ok($@, '=~', 'Must pass in a',
           'deserialize() function requires a schedule be passed in');

    eval {
        Schedule::Week::deserialize('000');
    };
    cmp_ok($@, '=~', 'is not 168 hours',
           'Serialized schedule must 168 characters long');

    eval {
        Schedule::Week::deserialize('f' x 168);
    };
    cmp_ok($@, '=~', 'must be all 1s and 0s',
           'Serialized schedule must contain only 1s and 0s');


    my $serialized = '000000000000000000000000' .
                     '000000000000000000000000' .
                     '000000000000000000000000' .
                     '000000000000000000000000' .
                     '000000000000000000000000' .
                     '000000000000000000000000' .
                     '000000000000000000000000';

    $s = undef;
    
    eval {
        $s = Schedule::Week::deserialize($serialized);
    };
    cmp_ok($@, 'eq', '', 'Valid serialized schedule should not throw errors');
    isa_ok($s, 'Schedule::Week');

    #  Ensure that all hours are set to 0
    for my $day ($SUNDAY ... $SATURDAY) {
        my $name = $NAM4{$day};
        my @day_hours = $s->hours_for_day($SUNDAY);
        cmp_ok(grep(/1/, @day_hours), '==', 0,
               "$name - all hours should be set to 0");
    }

    #  Now deserialize a schedule with specific hours set and make
    #  sure we can access those hours properly through object methods

    #  Morning (6 AM) on Monday Wednesday Saturday
    #  Noon on all days
    #  7 PM through 11 PM on weekends

    my $morning_noon_and_night = '000000000000100000011111' .
                                 '000000100000100000000000' .
                                 '000000000000100000000000' .
                                 '000000100000100000000000' .
                                 '000000000000100000000000' .
                                 '000000000000100000000000' .
                                 '000000100000100000011111';

    my $mnn = undef;

    eval {
        $mnn = Schedule::Week::deserialize($morning_noon_and_night);
    };

    cmp_ok($@, 'eq', '', 'Valid serialized schedule should not throw errors');
    isa_ok($mnn, 'Schedule::Week');

    #  Noon on every day should be set

    #  Try with single hours call
    my @noon_set = $mnn->hours([12]);

    for my $day ($SUNDAY ... $SATURDAY) {
        my $name = $NAM4{$day};

        #  Verify from all hours call
        cmp_ok($noon_set[$day]->[0], '==', '1', 
               "hours() - $name - noon is set to 1");

        #  Verify by calling hours_for_day
        my @hfd = $mnn->hours_for_day($day, [12]);
        cmp_ok($hfd[0], '==', '1', 
               "hours_for_day() - $name - noon is set to 1");

        #  Verify by calling function named for day
        my $day_func = lc($name);
        my @hdf = $mnn->$day_func([12]);
        cmp_ok($hdf[0], '==', '1', 
               "${day_func}() - $name - noon is set to 1");
    }

    #  Verify 6 AM on Monday, Wednesday, and Saturday
    my @six_am = $mnn->hours([6]);

    for my $day ($SUNDAY ... $SATURDAY) {
        my $name = $NAM4{$day};

        my $state = 0;

        if (($day == $MONDAY) || ($day == $WEDNESDAY) ||
            ($day == $SATURDAY)) {
            $state = 1;
        }

        #  Verify from all hours call
        cmp_ok($six_am[$day]->[0], '==', $state, 
               "hours() - $name - 6 AM is set to $state");

        #  Verify by calling hours_for_day
        my @hfd = $mnn->hours_for_day($day, [6]);
        cmp_ok($hfd[0], '==', $state,
               "hours_for_day() - $name - 6 AM is set to $state");

        #  Verify by calling function named for day
        my $day_func = lc($name);
        my @hdf = $mnn->$day_func([6]);
        cmp_ok($hdf[0], '==', $state,
               "${day_func}() - $name - 6 AM is set to $state");
    }

    #  Verify 7 through 11 PM on weekends
    my @weekend_hours = $mnn->hours([19 ... 23]);

    for my $day ($SUNDAY ... $SATURDAY) {
        my $name = $NAM4{$day};

        my $state = 0;

        if (($day == $SATURDAY) || ($day == $SUNDAY)) {
            $state = 1;
        }

        my $day_func = lc($name);

        my $i = 0;
        for my $hour (19 ... 23) {
            #  Verify from all hours call
            cmp_ok($weekend_hours[$day]->[$i], '==', $state, 
                   "hours() - $name - $hour is set to $state");

            #  Verify by calling hours_for_day
            my @hfd = $mnn->hours_for_day($day, [$hour]);
            cmp_ok($hfd[0], '==', $state,
                   "hours_for_day() - $name - $hour is set to $state");

            #  Verify by calling function named for day
            my @hdf = $mnn->$day_func([$hour]);
            cmp_ok($hdf[0], '==', $state,
                   "${day_func}() - $name - $hour is set to $state");
            $i++;
        }

        #  Test by calling range on day function
        my @weekend_day_func = $mnn->$day_func([19 ... 23]);

        $i = 0;
        for my $hour (19 ... 23) {
            cmp_ok($weekend_hours[$day]->[$i], '==', $state, 
                   "$day_func([19 ... 23]) - $name - $hour set to 1");
            $i++;
        }

        #  Test by calling range on hours_per_day
        my @weekend_hours_for_day = $mnn->hours_for_day($day, [19 ... 23]);

        $i = 0;
        for my $hour (19 ... 23) {
            cmp_ok($weekend_hours[$day]->[$i], '==', $state, 
                   "hours_for_day([19 ... 23]) - $name - $hour set to 1");
            $i++;
        }


    }

    #  Test the weekends using the weekend_hours function

    my @weekend_hours_func = $mnn->weekend_hours([19 ... 23]);

    my $di = 0;
    for my $day ($SATURDAY, $SUNDAY) {

        my $name = $NAM4{$day};
        my $day_func = lc($name);

        my $hi = 0;
        for my $hour (19 ... 23) {
            #  Verify from all hours call
            cmp_ok($weekend_hours_func[$di]->[$di], '==', 1,
                   "weekend_hours() - $name - $hour is set to 1");

            #  Verify by calling hours_for_day
            my @hfd = $mnn->hours_for_day($day, [$hour]);
            cmp_ok($hfd[0], '==', 1,
                   "hours_for_day() - $name - $hour is set to 1");

            #  Verify by calling function named for day
            my @hdf = $mnn->$day_func([$hour]);
            cmp_ok($hdf[0], '==', 1,
                   "${day_func}() - $name - $hour is set to 1");
            $hi++;
        }

        $di++;
    }

    #  Finally, pull out serialized copy again and verify that it matches
    #  what we started with

    my $mnn_serialized = $mnn->serialize();

    cmp_ok($mnn_serialized, 'eq', $morning_noon_and_night,
           "Serialized version of schedule matches original serialized ver");

}
