package Moment;
$Moment::VERSION = '1.3.2';
# ABSTRACT: class that represents the moment in time

use strict;
use warnings FATAL => 'all';

use Carp qw(croak);
use Time::Local qw(timegm_nocheck);
use Scalar::Util qw(blessed);




sub new {
    my ($class, @params) = @_;

    if (@params == 0) {
        croak "Incorrect usage. new() must get some params: dt, timestamp, iso_string or year/month/day/hour/minute/second. Stopped"
    }

    if (@params % 2 != 0) {
        croak 'Incorrect usage. new() must get hash like: `new( timestamp => 0 )`. Stopped';
    }

    my %params = @params;

    if (blessed($class)) {
        croak "Incorrect usage. You can't run new() on a variable. Stopped";
    }

    my $self = {};
    bless $self, $class;

    my $input_year = delete $params{year};
    my $input_month = delete $params{month};
    my $input_day = delete $params{day};
    my $input_hour = delete $params{hour};
    my $input_minute = delete $params{minute};
    my $input_second = delete $params{second};

    my $input_iso_string = delete $params{iso_string};

    my $input_dt = delete $params{dt};

    my $input_timestamp = delete $params{timestamp};

    if (%params) {
        croak "Incorrect usage. new() got unknown params: '" . join("', '", (sort keys %params)) . "'. Stopped";
    }

    my $way = 0;

    if (defined($input_iso_string)) {
        $way++;

        if ($input_iso_string =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z\z/) {
            $self->{_year} = $1;
            $self->{_month} = $2 + 0;
            $self->{_day} = $3 + 0;
            $self->{_hour} = $4 + 0;
            $self->{_minute} = $5 + 0;
            $self->{_second} = $6 + 0;
        } else {
            my $safe_iso_string = 'undef';
            $safe_iso_string = "'$input_iso_string'" if defined $input_iso_string;
            croak "Incorrect usage. iso_string $safe_iso_string is not in expected format 'YYYY-MM-DDThh:mm:ssZ'. Stopped";
        }

        $self->_get_range_value_or_die( 'year', $self->{_year}, 1800, 2199 );
        $self->_get_range_value_or_die( 'month', $self->{_month}, 1, 12 );
        $self->_get_range_value_or_die( 'day', $self->{_day}, 1, $self->_get_last_day_in_year_month( $self->{_year}, $self->{_month}) );
        $self->_get_range_value_or_die( 'hour', $self->{_hour}, 0, 23 );
        $self->_get_range_value_or_die( 'minute', $self->{_minute}, 0, 59 );
        $self->_get_range_value_or_die( 'second', $self->{_second}, 0, 59 );

        $self->{_timestamp} = timegm_nocheck(
            $self->{_second},
            $self->{_minute},
            $self->{_hour},
            $self->{_day},
            $self->{_month}-1,
            $self->{_year},
        );

        $self->{_dt} = sprintf(
            "%04d-%02d-%02d %02d:%02d:%02d",
            $self->{_year},
            $self->{_month},
            $self->{_day},
            $self->{_hour},
            $self->{_minute},
            $self->{_second},
        );

    }

    if (defined($input_timestamp)) {
        $way++;

        $self->{_timestamp} = $self->_get_range_value_or_die( 'timestamp', $input_timestamp, -5_364_662_400, 7_258_118_399 );

        my ($second,$minute,$hour,$day,$month,$year,$wday,$yday,$isdst)
            = gmtime($self->{_timestamp});

        $self->{_year} = $year + 1900;
        $self->{_month} = $month + 1;
        $self->{_day} = $day;
        $self->{_hour} = $hour;
        $self->{_minute} = $minute;
        $self->{_second} = $second;

        $self->{_dt} = sprintf(
            "%04d-%02d-%02d %02d:%02d:%02d",
            $self->{_year},
            $self->{_month},
            $self->{_day},
            $self->{_hour},
            $self->{_minute},
            $self->{_second},
        );

    }

    if (defined($input_year) or defined($input_month) or defined($input_day)
        or defined($input_hour) or defined($input_minute) or defined($input_second)) {

        $way++;

        if (defined($input_year) and defined($input_month) and defined($input_day)
            and defined($input_hour) and defined($input_minute) and defined($input_second)) {
            # ok
        } else {
            croak "Must specify all params: year, month, day, hour, minute, second. Stopped";
        }

        $self->{_year} = $self->_get_range_value_or_die( 'year', $input_year, 1800, 2199 );
        $self->{_month} = $self->_get_range_value_or_die( 'month', $input_month, 1, 12 );
        $self->{_day} = $self->_get_range_value_or_die( 'day', $input_day, 1, $self->_get_last_day_in_year_month( $self->{_year}, $self->{_month}) );
        $self->{_hour} = $self->_get_range_value_or_die( 'hour', $input_hour, 0, 23 );
        $self->{_minute} = $self->_get_range_value_or_die( 'minute', $input_minute, 0, 59 );
        $self->{_second} = $self->_get_range_value_or_die( 'second', $input_second, 0, 59 );

        $self->{_timestamp} = timegm_nocheck(
            $self->{_second},
            $self->{_minute},
            $self->{_hour},
            $self->{_day},
            $self->{_month}-1,
            $self->{_year},
        );

        $self->{_dt} = sprintf(
            "%04d-%02d-%02d %02d:%02d:%02d",
            $self->{_year},
            $self->{_month},
            $self->{_day},
            $self->{_hour},
            $self->{_minute},
            $self->{_second},
        );

    }

    if (defined($input_dt)) {
        $way++;

        if ($input_dt =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})\z/) {
            $self->{_year} = $1;
            $self->{_month} = $2 + 0;
            $self->{_day} = $3 + 0;
            $self->{_hour} = $4 + 0;
            $self->{_minute} = $5 + 0;
            $self->{_second} = $6 + 0;
        } else {
            my $safe_dt = 'undef';
            $safe_dt = "'$input_dt'" if defined $input_dt;
            croak "Incorrect usage. dt $safe_dt is not in expected format 'YYYY-MM-DD hh:mm:ss'. Stopped";
        }

        $self->_get_range_value_or_die( 'year', $self->{_year}, 1800, 2199 );
        $self->_get_range_value_or_die( 'month', $self->{_month}, 1, 12 );
        $self->_get_range_value_or_die( 'day', $self->{_day}, 1, $self->_get_last_day_in_year_month( $self->{_year}, $self->{_month}) );
        $self->_get_range_value_or_die( 'hour', $self->{_hour}, 0, 23 );
        $self->_get_range_value_or_die( 'minute', $self->{_minute}, 0, 59 );
        $self->_get_range_value_or_die( 'second', $self->{_second}, 0, 59 );

        $self->{_timestamp} = timegm_nocheck(
            $self->{_second},
            $self->{_minute},
            $self->{_hour},
            $self->{_day},
            $self->{_month}-1,
            $self->{_year},
        );

        $self->{_dt} = sprintf(
            "%04d-%02d-%02d %02d:%02d:%02d",
            $self->{_year},
            $self->{_month},
            $self->{_day},
            $self->{_hour},
            $self->{_minute},
            $self->{_second},
        );

    }

    if ($way == 1) {
        # this is the correct usage of new()
    } else {
        croak "Incorrect usage. new() must get one thing from the list: dt, timestamp or year/month/day/hour/minute/second. Stopped"
    }

    $self->{_d} = substr($self->{_dt}, 0, 10);
    $self->{_t} = substr($self->{_dt}, 11, 8);

    my %wday2name = (
        0 => 'sunday',
        1 => 'monday',
        2 => 'tuesday',
        3 => 'wednesday',
        4 => 'thursday',
        5 => 'friday',
        6 => 'saturday',
    );

    $self->{_weekday_number} = $self->_get_weekday_number($self->{_timestamp});
    $self->{_weekday_name} = $wday2name{$self->{_weekday_number}};

    return $self;
}


sub now {
    my ($class, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. now() shouldn\'t get any params. Stopped';
    }

    if (blessed($class)) {
        croak "Incorrect usage. You can't run now() on a variable. Stopped";
    }

    my $self = $class->new(
        timestamp => time(),
    );

    return $self;
};


sub get_timestamp {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_timestamp() shouldn\'t get any params. Stopped';
    }

    return $self->{_timestamp};
}


sub get_dt {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_dt() shouldn\'t get any params. Stopped';
    }

    return $self->{_dt};
}


sub get_iso_string {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_iso_string() shouldn\'t get any params. Stopped';
    }

    my $iso_string = $self->{_dt};
    $iso_string =~ s/ /T/;
    $iso_string .= 'Z';

    return $iso_string;
}


sub get_d {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_d() shouldn\'t get any params. Stopped';
    }

    return $self->{_d};
}


sub get_t {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_t() shouldn\'t get any params. Stopped';
    }

    return $self->{_t};
}


sub get_year {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_year() shouldn\'t get any params. Stopped';
    }

    return $self->{_year};
}


sub get_month {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_month() shouldn\'t get any params. Stopped';
    }

    return $self->{_month};
}


sub get_day {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_day() shouldn\'t get any params. Stopped';
    }

    return $self->{_day};
}


sub get_hour {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_hour() shouldn\'t get any params. Stopped';
    }

    return $self->{_hour};
}


sub get_minute {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_minute() shouldn\'t get any params. Stopped';
    }

    return $self->{_minute};
}


sub get_second {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_second() shouldn\'t get any params. Stopped';
    }

    return $self->{_second};
}


sub get_weekday_name {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_weekday_name() shouldn\'t get any params. Stopped';
    }

    return $self->{_weekday_name};
}


sub get_weekday_number {
    my ($self, @params) = @_;

    if (@params == 0) {
        croak "Incorrect usage. get_weekday_number() must get param: first_day. Stopped";
    }

    if (@params % 2 != 0) {
        croak "Incorrect usage. get_weekday_number() must get hash like: `get_weekday_number( first_day => 'monday' )`. Stopped";
    }

    my %params = @params;

    my $first_day = delete $params{first_day};

    if (%params) {
        croak "Incorrect usage. get_weekday_number() got unknown params: '" . join("', '", (sort keys %params)) . "'. Stopped";
    }

    my %name2number = (
        sunday => 1,
        monday => 0,
        tuesday => -1,
        wednesday => -2,
        thursday => -3,
        friday => -4,
        saturday => -5,
    );

    if (not exists $name2number{$first_day}) {
        croak "Incorrect usage. get_weekday_number() got unknown value '$first_day' for first_day. Stopped";
    }

    my $number = $self->{_weekday_number} + $name2number{$first_day};

    if ($number < 1) {
        $number+=7;
    }

    return $number;
}


sub is_monday {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. is_monday() shouldn\'t get any params. Stopped';
    }

    return $self->get_weekday_name() eq 'monday';
}


sub is_tuesday {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. is_tuesday() shouldn\'t get any params. Stopped';
    }

    return $self->get_weekday_name() eq 'tuesday';
}


sub is_wednesday {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. is_wednesday() shouldn\'t get any params. Stopped';
    }

    return $self->get_weekday_name() eq 'wednesday';
}


sub is_thursday {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. is_thursday() shouldn\'t get any params. Stopped';
    }

    return $self->get_weekday_name() eq 'thursday';
}


sub is_friday {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. is_friday() shouldn\'t get any params. Stopped';
    }

    return $self->get_weekday_name() eq 'friday';
}


sub is_saturday {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. is_saturday() shouldn\'t get any params. Stopped';
    }

    return $self->get_weekday_name() eq 'saturday';
}


sub is_sunday {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. is_sunday() shouldn\'t get any params. Stopped';
    }

    return $self->get_weekday_name() eq 'sunday';
}


sub is_leap_year {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. is_leap_year() shouldn\'t get any params. Stopped';
    }

    return $self->_is_leap_year( $self->get_year() );
}


sub cmp {
    my ($self, @params) = @_;

    if (@params != 1) {
        croak "Incorrect usage. cmp() must get one parameter. Stopped"
    }

    my $moment_2 = $params[0];

    if (blessed($moment_2) and $moment_2->isa('Moment')) {
        return $self->get_timestamp() <=> $moment_2->get_timestamp();
    } else {
        croak "Incorrect usage. cmp() must get Moment object as a parameter. Stopped";
    }

}


sub plus {
    my ($self, @params) = @_;

    if (@params == 0) {
        croak 'Incorrect usage. plus() must get some params. Stopped';
    }

    if (@params % 2 != 0) {
        croak 'Incorrect usage. plus() must get hash like: `plus( hour => 1 )`. Stopped';
    }

    my %params = @params;

    my $day = $self->_get_value_or_die('plus', 'day', delete($params{day}));
    my $hour = $self->_get_value_or_die('plus', 'hour', delete($params{hour}));
    my $minute = $self->_get_value_or_die('plus', 'minute', delete($params{minute}));
    my $second = $self->_get_value_or_die('plus', 'second', delete($params{second}));

    if (%params) {
        croak "Incorrect usage. plus() got unknown params: '" . join("', '", (sort keys %params)) . "'. Stopped";
    }

    my $new_timestamp = $self->get_timestamp()
        + $day * 86400
        + $hour * 3600
        + $minute * 60
        + $second
        ;

    my $new_moment = ref($self)->new( timestamp => $new_timestamp );

    return $new_moment;
}


sub minus {
    my ($self, @params) = @_;

    if (@params == 0) {
        croak 'Incorrect usage. minus() must get some params. Stopped';
    }

    if (@params % 2 != 0) {
        croak 'Incorrect usage. minus() must get hash like: `minus( hour => 1 )`. Stopped';
    }

    my %params = @params;

    my $day = $self->_get_value_or_die('minus', 'day', delete($params{day}));
    my $hour = $self->_get_value_or_die('minus', 'hour', delete($params{hour}));
    my $minute = $self->_get_value_or_die('minus', 'minute', delete($params{minute}));
    my $second = $self->_get_value_or_die('minus', 'second', delete($params{second}));

    if (%params) {
        croak "Incorrect usage. minus() got unknown params: '" . join("', '", (sort keys %params)) . "'. Stopped";
    }

    my $new_timestamp = $self->get_timestamp()
        - $day * 86400
        - $hour * 3600
        - $minute * 60
        - $second
        ;

    my $new_moment = ref($self)->new( timestamp => $new_timestamp );

    return $new_moment;
}


sub get_month_start {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_month_start() shouldn\'t get any params. Stopped';
    }

    my $start = ref($self)->new(
        year => $self->get_year(),
        month => $self->get_month(),
        day => 1,
        hour => 0,
        minute => 0,
        second => 0,
    );

    return $start;
}


sub get_month_end {
    my ($self, @params) = @_;

    if (@params) {
        croak 'Incorrect usage. get_month_end() shouldn\'t get any params. Stopped';
    }

    my $end = ref($self)->new(
        year => $self->get_year(),
        month => $self->get_month(),
        day => $self->_get_last_day_in_year_month( $self->get_year(), $self->get_month() ),
        hour => 23,
        minute => 59,
        second => 59,
    );

    return $end;
}

sub _get_weekday_number {
    my ($self, $timestamp) = @_;

    my ($second,$minute,$hour,$day,$month,$year,$wday,$yday,$isdst)
        = gmtime($timestamp);

    return $wday;
}

# https://metacpan.org/pod/Data::Printer#MAKING-YOUR-CLASSES-DDP-AWARE-WITHOUT-ADDING-ANY-DEPS
sub _data_printer {
    my ($self, $properties) = @_;

    require Term::ANSIColor;

    return Term::ANSIColor::colored($self->get_iso_string(), 'yellow');
}

sub _is_int {
    my ($self, $maybe_int) = @_;

    return $maybe_int =~ /\A0\z|\A-?[1-9][0-9]*\z/;
}

sub _get_value_or_die {
    my ($self, $method_name, $key, $input_value) = @_;

    my $value = $input_value;

    $value = 0 if not defined $value;

    if (not $self->_is_int($value)) {
        croak "Incorrect usage\. $method_name\(\) must get integer for '$key'. Stopped";
    }

    return $value;
}

sub _get_range_value_or_die {
    my ($self, $key, $input_value, $min, $max) = @_;

    my $safe_value = 'undef';
    $safe_value = "'$input_value'" if defined $input_value;

    if (not $self->_is_int($input_value)) {
        croak "Incorrect usage\. The $key $safe_value is not an integer number. Stopped";
    };

    if ( ($input_value < $min) or ($input_value > $max) ) {
        croak "Incorrect usage. The $key $safe_value is not in range [$min, $max]. Stopped";
    }

    return $input_value;
}

sub _is_leap_year {
    my ($self, $year) = @_;

    return '' if $year % 4;
    return 1 if $year % 100;
    return '' if $year % 400;
    return 1;
}

sub _get_last_day_in_year_month {
    my ($self, $year, $month) = @_;

    my %days_in_month = (
        1 => 31,
        # no february
        3 => 31,
        4 => 30,
        5 => 31,
        6 => 30,
        7 => 31,
        8 => 31,
        9 => 30,
        10 => 31,
        11 => 30,
        12 => 31,
    );

    my $last_day;

    if ($month == 2) {
        if ($self->_is_leap_year($year)) {
            $last_day = 29;
        } else {
            $last_day = 28;
        }
    } else {
        $last_day = $days_in_month{$month};
    }

    return $last_day;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moment - class that represents the moment in time

=head1 VERSION

version 1.3.2

=head1 SYNOPSIS

Moment is a Perl library. With this library you can create object that
represent some moment in time.

The library works with date and time in the UTC timezone. The purpose of not
supporting other timezones is to force good practice in working with time.
The best way to manage time in program is to store and to work with time in
UTC.

There are 4 ways you can create new object with the new() constructor:

    my $some_moment = Moment->new(
        # dt format is 'YYYY-MM-DD hh:mm:ss'
        dt => '2014-11-27 03:31:23',
    );

    my $other_moment = Moment->new(
        year => 2014,
        month => 1,
        day => 3,

        hour => 4,
        minute => 2,
        second => 10,
    );

    my $one_more_moment = Moment->new(
        # Unix time (a.k.a. POSIX time or Epoch time)
        timestamp => 1000000000,
    );

    my $moment_from_iso_string = Moment->new(
        # ISO 8601
        iso_string => '2015-11-07T10:51:22Z',
    );

You can also use now() constructor to create object that points to the current
moment in time:

    my $now = Moment->now();

When you have an object you can you use methods from it.

Here are the methods to get the values that was used in constructor:

    #'2014-11-27 03:31:23'
    my $dt = $moment->get_dt();
    my $d = $moment->get_d();
    my $t = $moment->get_t();

    my $year = $moment->get_year();
    my $month = $moment->get_month();
    my $day = $moment->get_day();
    my $hour = $moment->get_hour();
    my $minute = $moment->get_minute();
    my $second = $moment->get_second();

    # Unix time (a.k.a. POSIX time or Epoch time)
    my $number = $moment->get_timestamp();

    # ISO 8601
    my $iso_string => $moment->get_iso_string();

You can find out what is the day of week of the moment that is stored in the
object. You can get scalar with the weekday name:

    # 'monday', 'tuesday' and others
    my $string = $moment->get_weekday_name();

Or you can get weekday number (specifying what weekday should be number one):

    my $number = $moment->get_weekday_number( first_day => 'monday' );

Or you can test if the weekday of the moment is some specified weekday:

    $moment->is_monday();
    $moment->is_tuesday();
    $moment->is_wednesday();
    $moment->is_thursday();
    $moment->is_friday();
    $moment->is_saturday();
    $moment->is_sunday();

You can test if the year of the moment is leap with the method:

    $moment->is_leap_year();

If you have 2 Moment objects you can compare them with the cmp() method. The
method cmp() works exaclty as cmp builtin keyword and returns -1, 0, or 1:

    my $result = $moment_1->cmp($moment_2);

The Moment object is immutable. You can't change it after it is created. But
you can create new objects with the methods plus(), minus() and
get_month_start(), get_month_end():

    my $in_one_day = $moment->plus( day => 1 );
    my $ten_seconds_before = $moment->minus( second => 10 );

    # create object with the moment '2014-11-01 00:00:00'
    my $moment = Moment->new(dt => '2014-11-27 03:31:23')->get_month_start();

    # create object with the moment '2014-11-30 23:59:59'
    my $moment = Moment->new(dt => '2014-11-27 03:31:23')->get_month_end();

=head1 DESCRIPTION

Features and limitations of this library:

=over

=item * Library is as simple as possible

=item * Class represents only UTC time, no timezone info

=item * Object orentied design

=item * Object can't be changed after creation

=item * The precise is one seond

=item * Working with dates in the period from '1800-01-01 00:00:00' to
'2199-12-31 23:59:59'

=item * Dies in case of any errors

=item * No dependencies, but perl and its core modules

=item * Plays well with L<Data::Printer>

=item * Using SemVer for version numbers

=back

=head1 METHODS

=head2 new()

Constructor. Creates new Moment object that points to the specified moment
of time. Can be used in 4 different ways:

    my $some_moment = Moment->new(
        # dt format is 'YYYY-MM-DD hh:mm:ss'
        dt => '2014-11-27 03:31:23',
    );

    my $other_moment = Moment->new(
        year => 2014,
        month => 1,
        day => 3,

        hour => 4,
        minute => 2,
        second => 10,
    );

    my $one_more_moment = Moment->new(
        # Unix time (a.k.a. POSIX time or Epoch time)
        timestamp => 1000000000,
    );

    my $moment_from_iso_string = Moment->new(
        # ISO 8601
        iso_string => '2015-11-07T10:51:22Z',
    );

Dies in case of errors.

=head2 now()

Constructor. Creates new Moment object that points to the current moment
of time.

    my $current_moment = Moment->now();

=head2 get_timestamp()

Returns the timestamp of the moment stored in the object.

The timestamp is also known as Unix time, POSIX time, Epoch time.

This is the number of seconds passed from '1970-01-01 00:00:00'.

This number can be negative.

    say Moment->new( dt => '1970-01-01 00:00:00' )->get_timestamp(); # 0
    say Moment->new( dt => '2000-01-01 00:00:00' )->get_timestamp(); # 946684800
    say Moment->new( dt => '1960-01-01 00:00:00' )->get_timestamp(); # -315619200

The value that return this method is in the range [-5_364_662_400, 7_258_118_399].

=head2 get_dt()

Returns the scalar with date and time of the moment stored in the object.
The data in scalar is in format 'YYYY-MM-DD hh:mm:ss'.

    say Moment->now()->get_dt(); # 2014-12-07 11:50:57

The value that return this method is in the range ['1800-01-01 00:00:00',
'2199-12-31 23:59:59'].

=head2 get_iso_string()

Returns the scalar with date and time of the moment stored in the object.
The data in scalar is in ISO 8601 format 'YYYY-MM-DDThh:mm:ssZ'.

    say Moment->now()->get_iso_string(); # 2014-12-07T11:50:57Z

The value that return this method is in the range ['1800-01-01T00:00:00Z',
'2199-12-31T23:59:59Z'].

=head2 get_d()

Returns the scalar with date of the moment stored in the object.
The data in scalar is in format 'YYYY-MM-DD'.

    say Moment->now()->get_d(); # 2014-12-07

The value that return this method is in the range ['1800-01-01',
'2199-12-31'].

=head2 get_t()

Returns the scalar with time of the moment stored in the object.
The data in scalar is in format 'hh:mm:ss'.

    say Moment->now()->get_t(); # 11:50:57

The value that return this method is in the range ['00:00:00',
'23:59:59'].

=head2 get_year()

Returns the scalar with year of the moment stored in the object.

    say Moment->now()->get_year(); # 2014

The value that return this method is in the range [1800, 2199].

=head2 get_month()

Returns the scalar with number of month of the moment stored in the object.

    say Moment->now()->get_month(); # 12

The value that return this method is in the range [1, 12].

Method return '9', not '09'.

=head2 get_day()

Returns the scalar with number of day since the beginning of month of the
moment stored in the object.

    say Moment->now()->get_day(); # 7

The value that return this method is in the range [1, MAX_DAY]. Where the
MAX_DAY depend on the month:

    1 => 31,
    2 => 28, # 29 on leap years
    3 => 31,
    4 => 30,
    5 => 31,
    6 => 30,
    7 => 31,
    8 => 31,
    9 => 30,
    10 => 31,
    11 => 30,
    12 => 31,

Method return '7', not '07'.

=head2 get_hour()

Returns the scalar with hour of the moment stored in the object.

    say Moment->now()->get_hour(); # 11

The value that return this method is in the range [0, 23].

Method return '9', not '09'.

=head2 get_minute()

Returns the scalar with minute of the moment stored in the object.

    say Moment->now()->get_minute(); # 50

The value that return this method is in the range [0, 59].

Method return '9', not '09'.

=head2 get_second()

Returns the scalar with second of the moment stored in the object.

    say Moment->now()->get_second(); # 57

The value that return this method is in the range [0, 59].

Method return '9', not '09'.

=head2 get_weekday_name()

Return scalar with the weekday name. Here is the full list of strings that
this method can return: 'monday', 'tuesday', 'wednesday', 'thursday',
'friday', 'saturday', 'sunday'.

    say Moment->now()->get_weekday_name(); # sunday

=head2 get_weekday_number()

    my $number = $moment->get_weekday_number( first_day => 'monday' );

Returns scalar with weekday number.

The value that return this method is in the range [1, 7].

You must specify value for the first_day parameter. It should be one of:
'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'.

    my $m = Moment->new( dt => '2015-04-27 00:00:00');  # monday

    $m->get_weekday_number( first_day => 'monday' ); # 1
    $m->get_weekday_number( first_day => 'sunday' ); # 2

=head2 is_monday()

Returns true value is the weekday of the moment is monday. Otherwise returns
false value.

=head2 is_tuesday()

Returns true value is the weekday of the moment is tuesday. Otherwise returns
false value.

=head2 is_wednesday()

Returns true value is the weekday of the moment is wednesday. Otherwise returns
false value.

=head2 is_thursday()

Returns true value is the weekday of the moment is thursday. Otherwise returns
false value.

=head2 is_friday()

Returns true value is the weekday of the moment is friday. Otherwise returns
false value.

=head2 is_saturday()

Returns true value is the weekday of the moment is saturday. Otherwise returns
false value.

=head2 is_sunday()

Returns true value is the weekday of the moment is sunday. Otherwise returns
false value.

=head2 is_leap_year()

Returns true value is the year of the moment is leap. Otherwise returns
false value.

=head2 cmp()

Method to compare 2 object. It works exactly as perl builtin 'cmp' keyword.

    my $result = $moment_1->cmp($moment_2);

It returns -1, 0, or 1 depending on whether the $moment_1 is stringwise less
than, equal to, or greater than the $moment_2

    say Moment->new(dt=>'1970-01-01 00:00:00')->cmp( Moment->new(dt=>'2000-01-01 00:00') ); # -1
    say Moment->new(dt=>'2000-01-01 00:00:00')->cmp( Moment->new(dt=>'2000-01-01 00:00') ); # 0
    say Moment->new(dt=>'2010-01-01 00:00:00')->cmp( Moment->new(dt=>'2000-01-01 00:00') ); # 1

=head2 plus()

Method plus() returns new object that differ from the original to the
specified time. The class of the new object is the same as the class of the
variable on which you run method.

    my $new_moment = $moment->plus(
        day => 1,
        hour => 2,
        minute => 3,
        second => 4,
    );

You can also use negative numbers.

    my $two_hours_ago = $moment->plus( hour => -2 );

Here is an example:

    say Moment->new(dt=>'2010-01-01 00:00:00')
        ->plus( day => 1, hour => 2, minute => 3, second => 4 )
        ->get_dt()
        ;
    # 2010-01-02 02:03:04

=head2 minus()

Method minus() returns new object that differ from the original to the
specified time. The class of the new object is the same as the class of the
variable on which you run method.

    my $new_moment = $moment->minus(
        day => 1,
        hour => 2,
        minute => 3,
        second => 4,
    );

You can also use negative numbers.

    my $two_hours_behind = $moment->minus( hour => -2 );

Here is an example:

    say Moment->new(dt=>'2010-01-01 00:00:00')
        ->minus( day => 1, hour => 2, minute => 3, second => 4 )
        ->get_dt()
        ;
    # 2009-12-30 21:56:56

=head2 get_month_start()

Method get_month_start() returns new object that points to the moment
the month starts. The class of the new object is the same as the class of the
variable on which you run method.

    # 2014-12-01 00:00:00
    say Moment->new(dt=>'2014-12-07 11:50:57')->get_month_start()->get_dt();

The time of the new object is always '00:00:00'.

=head2 get_month_end()

Method get_month_end() returns new object that points to the moment
the month end. The class of the new object is the same as the class of the
variable on which you run method.

    # 2014-12-31 23:59:59
    say Moment->new(dt=>'2014-12-07 11:50:57')->get_month_end()->get_dt();

The time of the new object is always '23:59:59'.

=head1 SAMPLE USAGE

Find the last day of the current month (for december 2014 it is 31):

    my $day = Moment->now()->get_month_end()->get_day();

Loop for every day in month:

    my $start = Moment->now()->get_month_start();
    my $end = $start->get_month_end();

    my $current = $start;
    while ( $current->cmp($end) == -1 ) {
        say $current->get_day();
        $current = $current->plus( day => 1 );
    }

Find out the weekday name for given date (for 2014-01-01 it is wednesday):

    my $weekday = Moment->new( dt => '2014-01-01 00:00:00' )->get_weekday_name();

Find out how many seconds in one day (the answer is 86400):

    my $moment = Moment->now();
    my $seconds_in_a_day = $moment->get_timestamp() - $moment->minus( day => 1 )->get_timestamp();

=head1 FAQ

Q: Why there is no parameters 'month' and 'year' in plus() and minus()
methods?

A: It is easy to add or substidude second, minute, hour or day from some
date. But month and year are different. The number of days in month and year
differ from one to anoter. Because of that some touth questions appear. For
example what should we get if we add 1 year to the date 2000-02-29? To make
this library as simple as possible, I've desided not to implement this
feature.

Q: How does this library works with leap seconds?

A: It does not. This library knows nothing about leap seconds.

Q: How should I handle timezones with this module?

A: The best practice to work with time is to work witn time in UTC timezone.
This means converting all inputs to UTC timezone and converting it to the
desired timezones on output.

You must find out the offset from the UTC timezone and use plus() or minus()
methods to create object with UTC time.

For example, if you have time '2014-12-20 18:51:20 +0300' you should create
Moment object with the code:

    my $m = Moment->new( dt => '2014-12-20 18:51:20' )->minus( hour => 3 );

And if you need to output the time in some special timezone you shlould to
the same thing:

    say $m->plus( hour => 5, minute => 30 )->get_dt();

Q: Why there are no methods to find out the week number?

A: There are several ways to define what is the first week in year. To make
this library as simple as possible, I've desided not to implement this
feature.

Q: How to serialize this object and deserialize it?

A: There are 3 ways. To use timestamp as the serialised string, to use ISO
string, or to use dt. Timestamp, ISO string or dt contaings all the needed
data to recreate the object with the exact same state.

Serialize timestamp:

    my $serialized_timestamp = $moment->get_timestamp();

Restore timestamp:

    my $restored_moment = Moment->new( timestamp => $serialized_timestamp );

Serialize ISO string:

    my $serialized_iso_string = $moment->get_iso_string();

Restore ISO string:

    my $restored_moment = Moment->new( iso_string => $serialized_iso_string );

Serialize dt:

    my $serialized_dt = $moment->get_dt();

Restore dt:

    my $restored_moment = Moment->new( dt => $serialized_dt );

Q: I need my own output format.

A: This is simple. Just write your own class using Moment as the parent and
implement method that you need.

Q: Why there is a limitation that this module work only with dates in the
range from '1800-01-01 00:00:00' to '2199-12-31 23:59:59'?

A: One of the main ideas behind this libraray is simplicity. Adding this
limitations makes the creation and testing of this library simplier. And this
limits are enouth for real life problems.

=head1 SEE ALSO

=over

=item * L<DateTime> - excellent library. If library Moment does not suit you,
please consider using DateTime

=item * L<https://what-if.xkcd.com/26/> - great explanation of the leap
seconds

=item * L<https://en.wikipedia.org/wiki/ISO_8601> - international standard
covering the exchange of date and time-related data

=back

=head1 SOURCE CODE

The source code for this library is hosted on GitHub
L<https://github.com/bessarabov/Moment>

=head1 BUGS

Please report any bugs or feature requests in GitHub Issues
L<https://github.com/bessarabov/Moment/issues>

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
