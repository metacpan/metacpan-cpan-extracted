use warnings;
use strict;

use RPi::WiringPi;
use Test::More;

# RPi::RTC::DS3231 tests

if (! $ENV{RPI_RTC}){
    plan(skip_all => "Skipping: RPI_RTC environment variable not set");
}

$SIG{__DIE__} = sub {};

my $pi = RPi::WiringPi->new;
my $rtc = $pi->rtc;

{ # sec()

    for (0..59){
        is $rtc->sec($_), $_, "setting sec to '$_' result is ok";
        is $rtc->sec, $_, "...and reading is also '$_'"
    }

    for (-1, 60){
        is eval {$rtc->sec($_); 1}, undef, "sending '$_' results in failure ok";
        like $@, qr/out of bounds.*0-59/, "...and for '$_', error msg is sane";
    }
}

{ # min()

    is $rtc->sec(0), 0, "set seconds back to 0 ok";

    for (0..59){
        is $rtc->min($_), $_, "setting min to '$_' result is ok";
        is $rtc->min, $_, "...and reading is also '$_'"
    }

    for (-1, 60){
        is eval {$rtc->min($_); 1}, undef, "sending '$_' results in failure ok";
        like $@, qr/out of bounds.*0-59/, "...and for '$_', error msg is sane";
    }
}

{ # 24 hour clock

    $rtc->clock_hours(24);

    for (0..23){
        is $rtc->hour($_), $_, "setting 24-clock hour to '$_' result is ok";
        is $rtc->hour, $_, "...and reading is also '$_'"
    }

    for (-1, 25){
        is eval {$rtc->hour($_); 1}, undef, "sending '$_' results in failure ok";
        like $@, qr/out of bounds.*0-23/, "...and for '$_', error msg is sane";
    }
}

{ # 12 hour clock

    is $rtc->clock_hours(12), 12, "set to 12 hr clock ok";

    for (1..12){
        $rtc->hour($_);
        is $rtc->hour, $_, "setting hour to '$_' result is ok";
        is $rtc->hour, $_, "...and reading is also '$_'"
    }

    for (0, 13){
        is eval {$rtc->hour($_); 1}, undef, "sending '$_' results in failure ok";
        like $@, qr/out of bounds.*1-12/, "...and for '$_', error msg is sane";
    }
}

{ # clock_hours() bounds checking

    is $rtc->clock_hours(12), 12, "set to 12 ok";
    is $rtc->clock_hours(24), 24, "set to 24 ok";

    is eval { $rtc->clock_hours(13); 1 }, undef, "'13' is invalid ok";
    is eval { $rtc->clock_hours('a'); 1 }, undef, "'a' is invalid ok";
}

{ # clock_hours()

    $rtc->min(1);
    $rtc->sec(1);

    is $rtc->clock_hours(24), 24, "setting clock to 24 hr result ok";
    is $rtc->clock_hours, 24, "...and so is the return with no param";

    # 0

    is $rtc->hour(0), 0, "hr 0 in 24-hr mode ok";
    $rtc->clock_hours(12);
    is $rtc->clock_hours, 12, "set clock to 12-hr ok";
    is $rtc->hour, 12, "hr 0 in 12-hr mode ok";

    for (1..12){
        is $rtc->clock_hours(24), 24, "set clock to 24-hr ok";
        is $rtc->hour($_), $_, "hr $_ in 24-hr mode ok";
        is $rtc->clock_hours(12), 12, "set clock to 12-hr ok";
        is $rtc->hour, $_, "hr $_ in 12-hr mode ok";
    }

    for (13..23){
        is $rtc->clock_hours(24), 24, "set clock to 24-hr ok";
        is $rtc->hour($_), $_, "hr $_ in 24-hr mode ok";
        is $rtc->clock_hours(12), 12, "set clock to 12-hr ok";
        my $hr = $_ - 12;
        is $rtc->hour, $hr, "hr $_ == $hr in 12-hr mode ok";
    }
}

{ # am_pm()

    $rtc->clock_hours(12);
    is eval {$rtc->am_pm('X'); 1; }, undef, "am_pm() croaks with invalid param";
    like $@, qr/requires either 'AM' or 'PM'/, "...and error is sane";

    $rtc->clock_hours(24);
    is $rtc->min(13), 13, "set 24-hr clock to 13th min ok";
    is $rtc->sec(13), 13, "set 24-hr clock to 13th sec ok";

    # AM hours

    for (0..12){
        is $rtc->clock_hours(24), 24, "24 hr clock enabled ok";
        is $rtc->hour($_), $_, "set 24-hr clock to hour '$_' ok";
        is $rtc->clock_hours(12), 12, "12 hr clock enabled ok";
        is $rtc->am_pm, 'AM', "hr $_ in 24 clock mode is AM ok";
    }

    # PM hours

    for (13..23){
        is $rtc->clock_hours(24), 24, "24 hr clock enabled ok";
        is $rtc->hour($_), $_, "set 24-hr clock to hour '$_' ok";
        is $rtc->clock_hours(12), 12, "12 hr clock enabled ok";
        is $rtc->am_pm, 'PM', "hr $_ in 24 clock mode is PM ok";
    }

    is $rtc->clock_hours(24), 24, "set back to 24 hr clock ok";
}

{ # wday()

    my %days = (
        1 => "Monday",
        2 => "Tuesday",
        3 => "Wednesday",
        4 => "Thursday",
        5 => "Friday",
        6 => "Saturday",
        7 => "Sunday",
    );

    { # set/get

        for (1..7){
            is $rtc->day($_), $days{$_}, "$_ == $days{$_} ok";
        }
    }

    {   # out of bounds/illegal chars

        for (qw(8 0)){
            is eval { $rtc->day($_); 1; }, undef, "setting dow to '$_' fails ok";
        }
    }
}

{ # day()

    for (1..31){
        is $rtc->mday($_), $_, "setting mday to $_ ok";
    }
}

{  # day() out of bounds

    for (qw(0 32)){
        is eval { $rtc->mday($_); 1; }, undef, "setting dom to '$_' fails ok";
    }
}

{ # month()

    for (1..12){
        is $rtc->month($_), $_, "setting month to $_ ok";
    }
}

{   # month() out of bounds/illegal chars

    for (qw(0 13)){
        is eval { $rtc->month($_); 1; }, undef, "setting month to '$_' fails ok";
    }
}

{ # year()

    for (2000..2099){
        is $rtc->year($_), $_, "setting year to $_ ok";
    }
}

{   # year() out of bounds/illegal chars

    for (qw(1999 2100)){
        is eval { $rtc->year($_); 1; }, undef, "setting year to '$_' fails ok";
    }
}

{ # temp() - celcius

    my $temp = $rtc->temp;
    like $temp, qr/\d+(?:\.\d{2})?/, "temp() return is ok";
}

{ # temp() - farenheit

    my $f = $rtc->temp('f');
    like $f, qr/\d+(?:\.\d{2})?/, "temp('f') return is ok";
}

{ # hms()

    $rtc->clock_hours(24);

    $rtc->year(2018);
    $rtc->month(5);
    $rtc->mday(17);
    $rtc->hour(23);
    $rtc->min(55);
    $rtc->sec(01);

    like $rtc->hms, qr/^23:55:\d{2}$/, "hms() in 24-hr mode ok";

    $rtc->clock_hours(12);

    like $rtc->hms, qr/^11:55:\d{2} PM$/, "hms() in 12-hr PM mode ok";

    $rtc->hour(1);
    $rtc->am_pm('AM');

    like $rtc->hms, qr/^01:55:\d{2} AM$/, "hms() in 12-hr AM mode ok";
}

{ # date_time()

    $rtc->clock_hours(24);

    $rtc->year(2018);
    $rtc->month(5);
    $rtc->mday(17);
    $rtc->hour(23);
    $rtc->min(55);
    $rtc->sec(01);

    like
        $rtc->date_time,
        qr/^2018-05-17 23:55:\d{2}$/,
        "date_time() in 24-hr mode ok";

    $rtc->clock_hours(12);

    like
        $rtc->date_time,
        qr/^2018-05-17 23:55:\d{2}$/,
        "date_time() in 12-hr PM mode ok";

    $rtc->hour(1);
    $rtc->am_pm('AM');

    like
        $rtc->date_time,
        qr/^2018-05-17 01:55:\d{2}$/,
        "date_time() in 12-hr AM mode ok";

    $rtc->clock_hours(24);
}

{ # dt_hash()

    $rtc->clock_hours(24);

    $rtc->year(2018);
    $rtc->month(5);
    $rtc->mday(17);
    $rtc->hour(23);
    $rtc->min(55);
    $rtc->sec(01);

    my %dt = $rtc->dt_hash;

    my @valid = qw(year month day hour minute second);

    for (keys %dt){
        is exists $dt{$_}, 1, "$_ key exists ok";

        if ($_ eq 'year'){
            is $dt{$_}, 2018, "$_ ok";
            next;
        }

        like $dt{$_}, qr/^\d{2}$/, "$_ contains the proper values ok";
    }

    $rtc->clock_hours(24);
}


{ # date_time() set

    is
        eval { $rtc->date_time($rtc->date_time); 1; },
        1,
        "using properly formatted date ok";

    is
        eval { $rtc->date_time("blah"); 1; },
        undef,
        "croak ok if datetime format invalid";

    like $@, qr/parameter must be in the format/, "...and error is sane";
}

done_testing();
