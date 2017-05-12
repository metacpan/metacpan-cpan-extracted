package MusicRoom::Date;

=head1 NAME

MusicRoom::Date - Handle dates in the MusicRoom

=head1 DESCRIPTION

This package handles dates for the MusicRoom catalogue.  Dates associated 
with music files have a number of strange attributes, for example a song 
is normally dated accurate to a year, the birth date of a classical composer
may be known only to the nearest decade.  So the handling of dates 
has to be special and cannot rely on standard modules (which would break 
down for dates before the 17th Century anyway.

=head1 OVERVIEW

The package creates objects that hold dates, these have three attributes:

=over 4

=item *

C<j_day> - The "Julian Day"

=item *

C<gmt_sec> - The second within the day

=item *

C<accuracy> - How accurately the value has been measured

=back

=head2 Julian Day

The "Julian Day" is the number of days since 1 Jan 4711BC.  This is a standard 
date used by astronomers to ensure that all dates for reasonable historical 
events have positive numbers.  The calculations to convert various calendars 
to and from Julian days are quite well documented.

When handling dates associated with music some dates come from before 1752 
(which is when the UK and US switched to the Gregorian calendar).  So some kind
of special handling is required.

There is one aspect of "real" Julian days that this module ignores.  Astronomers 
start days at midday (that simplifies calculation for a discipline that mostly works
at night).  This module totally ignores timezones and assumes a day that starts at 
midnight.

=head2 GMT Seconds

For MusicRoom purposes the time zone is not very important, so long as all 
times are measured in the same one.  So the date structure just includes a value 
for the number of seconds since midnight.

If you have parts of you music collection in different timezones you will either 
have to live with the minor issues this causes or organise to convert times 
(for example on files) when data moves.

=head2 Accuracy

All dates have an associated accuracy that modifies how they are presented.  The 
accuracy values (and example default date renditions) are:

=over 4

=item * 

B<second> - " 8 Mar 1993 05:20:27"

=item * 

B<minute> - " 8 Mar 1993 05:20"

=item * 

B<hour> - " 8 Mar 1993 5am"

=item * 

B<day> - " 8 Mar 1993"

=item * 

B<week> - "Week 14 1993"

=item * 

B<month> - "Mar 1993"

=item * 

B<quarter> - "Q1 1993",

=item * 

B<year> - "1993"

=item * 

B<decade> - "1990s"

=item * 

B<century> - "20th Century"

=back

=head2 Conversion Routines

There are a number of routines in the package that convert between 
various types of information.  These do not generally take date objects 
and all have names of the form convert_I<from>2I<to>

The formats implied by these functions are:

=over 4

=item *

B<mrd> - A MusicRoom::Date object

=item *

B<mrdfields> - The three fields in a MusicRoom::Date

=item *

B<jday> - A Julian day

=item *

B<gmtsec> - The number of seconds since midnight

=item *

B<hms> - The time as hour, minute and second

=item *

B<accint> - The accuracy as an integer

=item *

B<accuracy> - The accuracy as a string

=item *

B<gdate> - A Gregorian year, month and day

=item *

B<jdate> - A Julian year, month and day

=item *

B<unix> - An integer giving the unix time value

=item *

B<text> - A string suitable for using as a date

=item *

B<rcal> - A year, month and date in a regular calendar (such as "gregorian")

=back

=head3 mrd

A standard MusicRoom::Date object.  These routines all have equivalent 
methods.  For example:

    $mrd = MusicRoom::Date->new();
    ...
    $mrd->convert_mrd2unix();
    # ...is the same as...
    $mrd->unix();

=head3 mrdfields

The three fields that make up a C<MusicRoom::Date> object.  For example:

    my($jday,$gmtsec,$accuracy) = $mrd->mrdfields();

=head3 jday

The Julian day represented by the date object.

    my $jday = $mrd->jday();

=head3 gmtsec

The number of seconds since midnight the date represents.

    my $gmtsec = $mrd->gmtsec();

=head3 hms

The time of day as hours, minutes and seconds.

    my($hour,$minute,$sec) = $mrd->hms();

=head3 accint

The accuracy of the time as an integer.  Normally it would be better to use the 
C<accuracy>.

    # Integer: 0 is seconds, 1 is minutes etc
    my $accint = $mrd->accint();

=head3 accuracy

The accuracy as a string

    my $accuracy = $mrd->accuracy();

=head3 gdate

The Gregorian date.  For most purposes this is the date you should use.

    my($year,$month,$day) = $mrd->gdate();

=head3 jdate

The Julian date.  Only really usefull for dates before 1752 (or possibly 1588)

    my($year,$month,$day) = $mrd->jdate();

=head3 unix

The UNIX time, this is seconds since 1 Jan 1970.  So the UNIX time only works 
for dates after 1969.  Dates associated with files (like the file creation 
date) should normally be OK, but "real" track dates (like release date) will 
probably not work.

    my $unixtime = $mrd->unix();

=head3 text

The date represented as a text string.  Normally this takes into account 
the accuracy.

    my $text = $mrd->text();

=head3 rcal

Dates in a "regular calendar".  This could potentially be expanded to cover all
sorts of strange calendars (anyone want to implement Islamic?).  Currently only 
Julian and Gregorian are supported.

    my($year,$month,$day) = $mrd->rcal("gregorian");

=head1 FUNCTIONS

=cut


use strict;
use warnings;
use Carp;

# No option to change the language yet but maybe one day...
my $language = "en";
my $obj_created = 0;

# We set up configuration values in pairs, first an array that
# converts an integer to a string, then a has that reverses
# the conversion
my(@accuracy,@long_months,@short_months,@long_days,@short_days,@quarters);
my(%accuracy,%long_months,%short_months,%long_days,%short_days,%quarters);

_define_strings();

# Calandar conversions based on D.A.Hatcher's algorithm from 1986
my %regular_calendar =
  (
    gregorian =>
      {
        y => 4716,   j => 1401,   m => 3,      n => 12,
        r => 4,      p => 1461,   q => 0,      v => 3,
        u => 5,      s => 153,    t => 2,      w => 2,
        a1 => 184,   g1 => -38,   b1 => 274277,k1 => 36524,
      },
    julian =>
      {
        y => 4716,   j => 1401,   m => 3,      n => 12,
        r => 4,      p => 1461,   q => 0,      v => 3,
        u => 5,      s => 153,    t => 2,      w => 2,
      },
  );

sub _define_strings
  {
    @accuracy =
      (
        # Changing the order of this list will mess up any
        # existing databases.  If you must change the list 
        # always append
        "second", "minute", "hour", "day",    "week", 
        "month", "quarter", "year", "decade", "century",
      );

    if($language eq "en")
      {
        
        @long_months = 
          (
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December",
          );
        
        @short_months = 
          (
            'Jan','Feb','Mar','Apr','May','Jun',
            'Jul','Aug','Sep','Oct','Nov','Dec'
          );
        
        @long_days = 
          (
            "Monday", "Tuesday", "Wednesday", "Thursday", 
            "Friday", "Saturday", "Sunday"
          );
        @short_days = 
          (
            "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
          );
        @quarters = 
          (
            "Winter", "Spring", "Summer", "Autumn",
          );
      }
    else
      {
        carp("Language $language not encoded yet");
        return;
      }

    for(my $i=0;$i<=$#accuracy;$i++)
      {
        $accuracy{$accuracy[$i]} = $i;
      }
    for(my $i=0;$i<=$#long_months;$i++)
      {
        $long_months{$long_months[$i]} = $i;
      }
    for(my $i=0;$i<=$#short_months;$i++)
      {
        $short_months{$short_months[$i]} = $i;
      }
    for(my $i=0;$i<=$#long_days;$i++)
      {
        $long_days{$long_days[$i]} = $i;
      }
    for(my $i=0;$i<=$#short_days;$i++)
      {
        $short_days{$short_days[$i]} = $i;
      }
    for(my $i=0;$i<=$#quarters;$i++)
      {
        $quarters{$quarters[$i]} = $i;
      }
  }

=head2 language($lang)

Change the language that the module uses.  Mainly used to set the names of 
months and days of the week.  At the moment only "en" is defined, so this 
function is quite useless.

=cut

sub language
  {
    if($#_ >= 0)
      {
        if($obj_created)
          {
            carp("Cannot change language after a Date object is created");
          }
        else
          {
            $language = $_[0];
            _define_strings();
          }
      }
    return $language;
  }

=head2 new()

Create a new C<MusicRoom::Date> object.  Here are some examples:

    # The current time with an accuracy of seconds
    my $mrd = MusicRoom::Date->new();

    # A set time to the nearest second
    my $mrd = MusicRoom::Date->new("12 Jan 2007 3:42:08");

    # Some time in the 60s
    my $mrd = MusicRoom::Date->new("1960s");

    # Set the fields
    my $mrd = MusicRoom::Date->new(j_day => "27 Nov 1960",
                           gmt_sec => 0, accuracy => "day");

    # Attach to a given unixtime
    my $mrd = MusicRoom::Date->new(unixtime => $filedate);

=cut


sub new
  {
    my $class = shift;
    my $self = bless 
      {
        j_day => -1,
        gmt_sec => -1, 
        accuracy => -1,
      },$class;

    # There are three cases, if we have no arguments then we create 
    # a date representing now with an accuracy of seconds
    # If we have a single argument it is a string we attempt to read
    # More arguments imply an option list
    if($#_ <= -1)
      {
        my $time = time;
        $self->{j_day} = convert_unix2jday($time);
        $self->{gmt_sec} = convert_unix2gmtsec($time);
        $self->{accuracy} = convert_accuracy2accint("second");
      }
    elsif($#_ == 0)
      {
        ($self->{j_day},$self->{gmt_sec},$self->{accuracy}) =
             convert_text2mrdfields($_[0]);
      }
    else
      {
        for(my $i=0;$i<=$#_;$i+=2)
          {
            if($_[$i] eq "j_day")
              {
                $self->{j_day} = convert_text2jday($_[$i+1]);
              }
            elsif($_[$i] eq "gmt_sec")
              {
                $self->{gmt_sec} = convert_text2gmtsec($_[$i+1]);
              }
            elsif($_[$i] eq "accuracy")
              {
                $self->{accuracy} = convert_accuracy2accint($_[$i+1]);
              }
            elsif($_[$i] eq "unixtime")
              {
                $self->{j_day} = convert_unix2jday($_[$i+1]);
                $self->{gmt_sec} = convert_unix2gmtsec($_[$i+1]);
                $self->{accuracy} = convert_accuracy2accint("second");
              }
            elsif($_[$i] eq "serial")
              {
                ($self->{j_day},$self->{gmt_sec},$self->{accuracy}) =
                                  convert_serial2mrdfields($_[$i+1]);
              }
            else
              {
                carp("Unknown option $_[$i] passed to new in Date");
              }
          }
      }
    return $self;
  }

=head2 dow()

Return the day of the week as a number in the range C<0..6>.  There are hardly 
any good reasons for needing this but, it's easy to do.

    my $dow = $mrd->dow();

=cut

sub dow
  {
    my($self) = @_;
    $self = MusicRoom::Date->new()
                      if(!defined $self);
    return ($self->{j_day}+1)%7;
  }

# ------------------------------------------------------------

=head2 convert_mrd2mrdfields()

Return the fields of the date.  Equivalent to the C<mrdfields()> function.

    my($jday,$gmtsec,$accuracy) = $mrd->convert_mrd2mrdfields();

=cut

sub convert_mrd2mrdfields
  {
    my($self) = @_;
    return($self->{j_day},$self->{gmt_sec},convert_accint2accuracy($self->{accuracy}));
  }

sub convert_mrd2accuracy
  {
    my($self) = @_;
    return convert_accint2accuracy($self->{accuracy});
  }

sub convert_mrd2gdate
  {
    my($self) = @_;
    return convert_jday2gdate($self->{j_day});
  }

sub convert_mrd2jday
  {
    my($self) = @_;
    return $self->{j_day};
  }

sub convert_mrd2jdate
  {
    my($self) = @_;
    return convert_jday2jdate($self->{j_day});
  }

sub convert_mrd2gmtsec
  {
    my($mrdate) = @_;
    return $mrdate->{gmt_sec};
  }

sub convert_mrd2hms
  {
    my($mrdate) = @_;
    return(-1,-1,-1) if($mrdate->{gmt_sec} == -1);
    if($mrdate->{gmt_sec} < 0 || $mrdate->{gmt_sec} >= 24*60*60)
      {
        carp("gmt_sec is out of valid range");
        return(-1,-1,-1);
      }
    my $sec = $mrdate->{gmt_sec} % 60;
    my $min = int(($mrdate->{gmt_sec} - $sec)/60) % 60;
    my $hour = int((($mrdate->{gmt_sec} - $sec)/60 - $min)/60);
    return($hour,$min,$sec);
  }

sub convert_mrd2rcal
  {
    my($mrdate,$cal) = @_;
    return convert_jday2rcal($mrdate->{j_day},$cal);
  }

sub convert_mrd2text
  {
    # Return a date as text, first which calendar shall we use
    my($mrdate,$format,$acc) = @_;

    # Switch calendar if before Sep 1752
    my $cal = "gregorian";
    $cal = "julian" if($mrdate->{j_day} < 2361221);

    my($hour,$min,$sec) = $mrdate->convert_mrd2hms();
    my($year,$month,$day) = convert_jday2rcal($mrdate->{j_day},$cal);

    my $accint = $acc;
    if(!defined $accint)
      {
        $accint = $mrdate->{accuracy};

        if($accint < 0)
          {
            carp("Bad accuracy reading in mrdate");
            $accint = 0;
          }
      }

    if(!defined $format || $format eq "")
      {
        my %default_format =
          (
            second => "%day0% %month_short% %year% %hour0%:%min0%:%sec0%",
            minute => "%day0% %month_short% %year% %hour0%:%min0%",
            hour => "%day0% %month_short% %year% %hour12%%ampm%",
            day => "%day0% %month_short% %year%",
            week => "Week %week0% %year%",
            month => "%month_short% %year%",
            quarter => "Q%quarter% %year%",
            year => "%year%",
            decade => "%decade%",
            century => "%century_ordinal% Century%bc%",
          );
        if(!defined $default_format{$accuracy[$accint]})
          {
            carp("Cannot find format for accuracy of \"$accuracy[$accint]\" ($accint)");
            $accint = 0;
          }
        $format = $default_format{$accuracy[$accint]};
      }

    my %format_elements =
      (
        bc => sub
          {
            my $bc = "";
            $bc = " BC" if($year <= 0);
            return $bc;
          },
        century => sub
          {
            my $y = $year;
            $y = 1-$year if($year <= 0);
            return int($y / 100);
          },
        century_ordinal => sub
          {
            my $y = $year;
            $y = 1-$year if($year <= 0);
            my $cent = 1+int($y / 100);
            my $end = "th";
            $end = "st" if(($cent % 10) == 1);
            $end = "nd" if(($cent % 10) == 2);
            $end = "rd" if(($cent % 10) == 3);
            $end = "th" if($cent == 11 || $cent == 12 || $cent == 13);
            return $cent.$end;
          },
        decade => sub
          {
            my $y = $year;
            $y = 1-$year if($year <= 0);
            return (10*int($y / 10))."s";
          },
        decade_ => sub
          {
            my $y = $year;
            $y = 1-$year if($year <= 0);
            return 10*int($y / 10);
          },
        year => sub
          {
            return $year;
          },
        quarter => sub
          {
            return 1+int(($month-1)/3);
          },
        quarter_long => sub
          {
            return $quarters[int(($month-1)/3)];
          },
        month0 => sub
          {
            return sprintf("%02d",$month);
          },
        month => sub
          {
            return $month;
          },
        month_ => sub
          {
            return sprintf("%2d",$month);
          },
        month_short => sub
          {
            return $short_months[$month-1];
          },
        month_long => sub
          {
            return $long_months[$month-1];
          },
        week0 => sub
          {
            my $year_start = convert_rcal2jday($cal,$year,1,1);
            my $week = int(($mrdate->{j_day}-$year_start)/7);
            return sprintf("%02d",$week);
          },
        week_ => sub
          {
            my $year_start = convert_rcal2jday($cal,$year,1,1);
            my $week = int(($mrdate->{j_day}-$year_start)/7);
            return sprintf("%2d",$week);
          },
        week => sub
          {
            my $year_start = convert_rcal2jday($cal,$year,1,1);
            my $week = int(($mrdate->{j_day}-$year_start)/7);
            return $week;
          },
        day0 => sub
          {
            return sprintf("%02d",$day);
          },
        day => sub
          {
            return $day;
          },
        day_ => sub
          {
            return sprintf("%2d",$day);
          },
        dow0 => sub
          {
            return sprintf("%02d",$mrdate->dow());
          },
        dow => sub
          {
            return $mrdate->dow();
          },
        dow_ => sub
          {
            return sprintf("%2d",$mrdate->dow());
          },
        dow_short => sub
          {
            return $short_days[$mrdate->dow()-1];
          },
        dow_long => sub
          {
            return $long_days[$mrdate->dow()-1];
          },
        day0 => sub
          {
            return sprintf("%02d",$day);
          },
        day => sub
          {
            return $day;
          },
        day_ => sub
          {
            return sprintf("%2d",$day);
          },
        hour0 => sub
          {
            return sprintf("%02d",$hour);
          },
        hour => sub
          {
            return $hour;
          },
        hour_ => sub
          {
            return sprintf("%2d",$hour);
          },
        hour120 => sub
          {
            return sprintf("%02d",$hour % 12);
          },
        hour12 => sub
          {
            return $hour % 12;
          },
        hour12_ => sub
          {
            return sprintf("%2d",$hour % 12);
          },
        ampm => sub
          {
            return "am" if($hour < 12 || $hour == 24);
            return "pm";
          },
        min0 => sub
          {
            return sprintf("%02d",$min);
          },
        min => sub
          {
            return sprintf("%2d",$min);;
          },
        min_ => sub
          {
            return $min;
          },
        sec0 => sub
          {
            return sprintf("%02d",$sec);
          },
        sec => sub
          {
            return sprintf("%d",$sec);
          },
        sec_ => sub
          {
            return $sec;
          },
        accuracy => sub
          {
            return convert_accint2accuracy($accint);
          },
        accint => sub
          {
            return $accint;
          },
      );

    while($format =~ /\%([^\%]+)\%/)
      {
        my $field = $1;
        my $val;

        if(!defined $format_elements{$field})
          {
            carp("Don't know how to format $field");
            $val = "";
          }
        else
          {
            $val = &{$format_elements{$field}}();
          }
        $format =~ s/\%$field\%/$val/g;
      }
    return $format;
  }

sub convert_unix2mrdfields
  {
    my($unixtime) = @_;
    return(convert_unix2jday($unixtime),
           convert_unix2gmtsec($unixtime),
           convert_accuracy2accint("second"));
  }

sub convert_unix2mrd
  {
    my($unixtime) = @_;
    $unixtime = time if(!defined $unixtime);
    return MusicRoom::Date->new(unixtime => $unixtime);
  }

sub convert_mrd2unix
  {
    my($this) = @_;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
      }
    return convert_jday2unix($this->{j_day})+$this->{gmt_sec};
  }

sub convert_jday2unix
  {
    my($jday) = @_;

    # Unix era starts 1 Jan 1970
    my $start_era = convert_gdate2jday(1970,1,1);
    if(!defined $jday || $jday =~ /[^0-9]/)
      {
        carp("Jday value of \"$jday\" is invalid");
        return time;
      }
    if($jday < $start_era)
      {
        carp("Unix values are invalid before 1970 (Jday $jday)");
        return 0;
      }
    return ($jday - $start_era)*24*60*60;
  }

sub convert_unix2jday
  {
    my($unixtime) = @_;

    # A UNIX time must be after 1970 and hence always Gregorian
    my($s,$mi,$h,$d,$mo,$y,$wd) = gmtime($unixtime);    
    $y += 2000 if($y < 70);
    $y += 1900 if($y < 200);
    return convert_gdate2jday($y,$mo+1,$d);
  }

sub convert_unix2gmtsec
  {
    my($unixtime) = @_;

    my($s,$mi,$h,$d,$mo,$y,$wd) = gmtime($unixtime);    
    return convert_hms2gmtsec($h,$mi,$s);
  }

sub convert_rcal2jday
  {
    my($cal,$year,$month,$day) = @_;

    if(!defined $cal || !defined $regular_calendar{$cal})
      {
        carp("Cannot find regular calendar $cal");
        return 0;
      }
    my $rcal = $regular_calendar{$cal};

    my $y1p = $year + $rcal->{y} - int(($rcal->{n} + $rcal->{m} - 1 - $month)/$rcal->{n});
    my $mp1 = ($month - $rcal->{m} + $rcal->{n})%$rcal->{n};
    my $dp1 = $day - 1;
    my $c = int(($rcal->{p}*$y1p + $rcal->{q})/$rcal->{r});
    my $d = int(($rcal->{s}*$mp1 + $rcal->{t})/$rcal->{u});
    my $jday = $c + $d + $dp1 - $rcal->{j};
    if(defined $rcal->{a1})
      {
        # Adjustment for gregorian type calandars
        my $g = int((3*int(($y1p + $rcal->{a1})/100))/4) + $rcal->{g1};
        $jday -= $g;
      }
    return $jday;
  }

sub convert_jday2rcal
  {
    my($jday,$cal) = @_;

    if(!defined $cal || !defined $regular_calendar{$cal})
      {
        carp("Cannot find regular calendar $cal");
        return 0;
      }
    my $rcal = $regular_calendar{$cal};
    if(defined $rcal->{a1})
      {
        # Adjustment for gregorian type calandars
        my $g = int((3*int((4*$jday+$rcal->{b1})/(4*$rcal->{k1}+1)))/4)+$rcal->{g1};
        $jday += $g;
      }

    my $jday_p = $jday + $rcal->{j};
    my $year_p = int(($rcal->{r} * $jday_p + $rcal->{v})/$rcal->{p});
    my $t1 = int((($rcal->{r} * $jday_p + $rcal->{v})%($rcal->{p}))/$rcal->{r});
    my $month_p = int(($rcal->{u}*$t1 + $rcal->{w})/$rcal->{s});
    my $day_p = int((($rcal->{u}*$t1 + $rcal->{w})%$rcal->{s})/$rcal->{u});

    my $day = $day_p + 1;
    my $month = 1+($month_p+$rcal->{m}-1)%$rcal->{n};
    my $year = int($year_p-$rcal->{y}+($rcal->{n}+$rcal->{m}-1-$month)/$rcal->{n});
    return($year,$month,$day);
  }
    
=head2 convert_jday2gdate

Converts a Julian day to a ($year,$month,$day) of Gregorian dates

=cut

sub convert_jday2gdate
  {
    # Convert a julian day to a gregorian year/month/day
    my($j_day) = @_;

    return convert_jday2rcal($j_day,"gregorian");
  }

sub convert_jday2jdate
  {
    # Convert a julian day to a gregorian year/month/day
    my($j_day) = @_;

    return convert_jday2rcal($j_day,"julian");
  }

sub convert_gdate2jday
  {
    my($year,$month,$day) = @_;

    return convert_rcal2jday("gregorian",$year,$month,$day);
  }

sub convert_jdate2jday
  {
    my($year,$month,$day) = @_;

    return convert_rcal2jday("julian",$year,$month,$day);
  }

sub convert_gdate2jdate
  {
    return convert_jday2jdate(convert_gdate2jday(@_));
  }

sub convert_gdate2rcal
  {
    my($year,$month,$day,$cal) = @_;
    return convert_jday2rcal(convert_gdate2jday($year,$month,$day),$cal);
  }

sub convert_jdate2rcal
  {
    my($year,$month,$day,$cal) = @_;
    return convert_jday2rcal(convert_jdate2jday($year,$month,$day),$cal);
  }

sub convert_jdate2gdate
  {
    return convert_jday2gdate(convert_jdate2jday(@_));
  }

sub convert_rcal2jdate
  {
    return convert_jday2jdate(convert_rcal2jday(@_));
  }

sub convert_rcal2gdate
  {
    return convert_jday2gdate(convert_rcal2jday(@_));
  }

sub convert_gmtsec2hms
  {
    my($gmtsec) = @_;
    my($hour,$min,$sec);

    if(!defined $gmtsec || $gmtsec =~ /[^0-9]/)
      {
        carp("Value of \"$gmtsec\" is not a valid gmtsec value");
        return(0,0,0);
      }
    if($gmtsec < 0 || $gmtsec > 24*60*60)
      {
        carp("Value of $gmtsec is outside valid gmtsec range");
        return(0,0,0);
      }
    $sec = $gmtsec % 60;
    $min = int($gmtsec/60) % 60;
    $hour = int($gmtsec/(60*60));
    return($hour,$min,$sec);
  }

sub convert_hms2gmtsec
  {
    my($hour,$min,$sec) = @_;

    # Special case for 24:00:00
    return 0 if($hour == 24 && $min == 0 && $sec == 0);

    if($hour < 0 || $hour > 23 || $min < 0 || 
                  $min > 59 || $sec < 0 || $sec > 59)
      {
        carp(sprintf("%02d:%02d:%02d is not a valid time",$hour,$min,$sec));
        return -1;
      }
    return ($hour*60+$min)*60+$sec;
  }

sub convert_accuracy2accint
  {
    my($accuracy) = @_;

    # Accuracy as a string
    return(-1) if($accuracy eq "-1" || $accuracy eq "unknown");

    if($accuracy =~ /^\d+$/)
      {
        if($accuracy > $#accuracy)
          {
            carp("Accuracy of $accuracy does not exist");
            return(-1);
          }
      }
    return $accuracy{lc($accuracy)} 
                           if(defined $accuracy{lc($accuracy)});
    carp("$accuracy is not a valid accuracy definition");
    return(-1);
  }

sub _possible_date
  {
    my($num1,$str,$num2) = @_;

    my($year,$month,$day);

    if($num1 > 31 && $num2 <= 31)
      {
        $year = $num1;
        $day = $num2;
      }
    elsif($num2 > 31 && $num1 <= 31)
      {
        $year = $num2;
        $day = $num1;
      }
    elsif($num1 <= 31 && $num2 <= 31)
      {
        $year = $num1+2000;
        $day = $num2;
      }
    else
      {
        return(-1,-1,-1);
      }

    if($str =~ /^\d+$/ && $str >= 1 && $str <= 12)
      {
        return($year,$str,$day);
      }

    if(defined $long_months{"\L\u$str"})
      {
        return($year,$long_months{"\L\u$str"}+1,$day);
      }
    if(defined $short_months{"\L\u$str"})
      {
        return($year,$short_months{"\L\u$str"}+1,$day);
      }
    return(-1,-1,-1);
  }

sub convert_text2mrdfields
  {
    my($text) = @_;
    # Scan a host of different input formats to create suitable
    # date objects

    # For the moment just parse the default formats
    if($text =~ /^\s*(\d+)[\s\/\-\,]+(\w+)[\s\/\-\,]+(\d+)\s*(\d+)[\s\:]+(\d+)[\s\:]+(\d+)\s*$/)
      {
        return(convert_text2jday("$1/$2/$3"),
               convert_text2gmtsec("$4:$5:$6"),
               $accuracy{second});
      }
    elsif($text =~ /^\s*(\d+)[\s\/\-\,]+(\w+)[\s\/\-\,]+(\d+)\s*(\d+)[\s\:]+(\d+)\s*$/)
      {
        return(convert_text2jday("$1/$2/$3"),
               convert_text2gmtsec("$4:$5"),
               $accuracy{minute});
      }
    elsif($text =~ /^\s*(\d+)[\s\/\-\,]+(\w+)[\s\/\-\,]+(\d+)\s*(\d+)[\s\:]*(am|pm)\s*$/i)
      {
        return(convert_text2jday("$1/$2/$3"),
               convert_text2gmtsec("$4$5"),
               $accuracy{hour});
      }
    elsif($text =~ /^\s*(\d+)[\s\/\-\,]+(\w+)[\s\/\-\,]+(\d+)\s*$/)
      {
        return(convert_text2jday("$1/$2/$3"),
               convert_text2gmtsec(0),
               $accuracy{day});
      }
    elsif($text =~ /^\s*week\s*(\d+)[\s\/\-\,]*(\d+)\s*$/i)
      {
        return(convert_text2jday("1 Jan $2")+7*$1,
               convert_text2gmtsec(0),
               $accuracy{week});
      }
    elsif($text =~ /^\s*q[\s\/\-\,]*(\d+)[\s\/\-\,]+(\d+)\s*$/i)
      {
        return(convert_text2jday("15/".$short_months[($1-1)*3+1]."/$2"),
               convert_text2gmtsec(0),
               $accuracy{quarter});
      }
    elsif($text =~ /^\s*(\d+)\s*s\s*$/i)
      {
        return(convert_text2jday("1/Jan/".($1+5)),
               convert_text2gmtsec(0),
               $accuracy{decade});
      }
    elsif($text =~ /^\s*(\w+)[\s\/\-\,]+(\d+)\s*$/)
      {
        return(convert_text2jday("15/$1/$2"),
               convert_text2gmtsec(0),
               $accuracy{month});
      }
    elsif($text =~ /^\s*(\d+)\s*$/)
      {
        return(convert_text2jday("1/Jun/$1"),
               convert_text2gmtsec(0),
               $accuracy{year});
      }
    elsif($text =~ /^\s*(\d+)(th|st|nd|rd)\s*century/i)
      {
        return(convert_text2jday("1/Jan/".($1*100-50)),
               convert_text2gmtsec(0),
               $accuracy{century});
      }
    else
      {
        carp("Cannot yet parse date $text");
        return(-1,-1,-1);
      }
  }

sub convert_text2jday
  {
    my($text) = @_;

    return $text if($text =~ /^\d+$/);

    my($year,$month,$day);

    if($text =~ /^\s*(\d+)[\s\/\-\,]*(\w+)[\s\/\-\,]*(\d+)\s*$/)
      {
        my($n1,$t1,$n2) = ($1,$2,$3);
        ($year,$month,$day) = _possible_date($n2,$t1,$n1);
      }
    elsif($text =~ /^\s*(\w+)[\s\/\-\,]*(\d+)[\s\/\-\,]*(\d+)\s*$/)
      {
        my($t1,$n1,$n2) = ($1,$2,$3);
        ($year,$month,$day) = _possible_date($n2,$t1,$n1);
      }
    elsif($text =~ /^\s*(\d+)[\s\/\-\,]*(\d+)[\s\/\-\,]*(\w+)\s*$/)
      {
        my($n1,$n2,$t1) = ($1,$2,$3);
        ($year,$month,$day) = _possible_date($n1,$t1,$n2);
      }
    elsif($text =~ /^\s*(\d+)[\s\/\-\,]*(\d+)[\s\/\-\,]*(\d+)\s*$/)
      {
        my @vals = ($1,$2,$3);

        foreach my $idx (2,0)
          {
            if($vals[$idx] > 31)
              {
                $year = $vals[$idx];
                splice(@vals,$idx,1);
                last;
              }
          }
        $year = pop @vals if($#vals == 2);
         
        foreach my $idx (0,1)
          {
            if($vals[$idx] > 12)
              {
                $day = $vals[$idx];
                splice(@vals,$idx,1);
                last;
              }
          }
        $day = shift @vals if($#vals == 1);
        $month = shift @vals;
      }
    else
      {
        $year = -1;
      }
    return -1 if($year == -1);

    my $cal = "gregorian";
    $cal = "julian" if($year < 1752);
    return convert_rcal2jday($cal,$year,$month,$day);
  }

sub convert_text2gmtsec
  {
    my($text) = @_;

    return $text if($text =~ /^\d+$/);
    if($text =~ /^\s*(\d+)\s*\:\s*(\d+)\s*\:\s*(\d+)\s*$/)
      {
        return convert_hms2gmtsec($1,$2,$3);
      }
    elsif($text =~ /^\s*(\d+)\s*\:\s*(\d+)\s*$/)
      {
        return convert_hms2gmtsec($1,$2,0);
      }
    elsif($text =~ /^\s*(\d{2})\s*(\d{2})\s*(\d{2})\s*$/)
      {
        return convert_hms2gmtsec($1,$2,$3);
      }
    elsif($text =~ /^\s*(\d{1})\s*(\d{2})\s*(\d{2})\s*$/)
      {
        return convert_hms2gmtsec($1,$2,3);
      }
    elsif($text =~ /^\s*(\d{2})\s*(\d{2})\s*$/)
      {
        return convert_hms2gmtsec($1,$2,0);
      }
    elsif($text =~ /^\s*(\d{1})\s*(\d{2})\s*$/)
      {
        return convert_hms2gmtsec($1,$2,0);
      }
    elsif($text =~ /^\s*(\d+)\:\s*(\d+)\s*(am|pm)\s*$/i)
      {
        my($h,$m,$f) = ($1,$2,$3);
        $h += 12 if(lc($f) eq "pm");
        return convert_hms2gmtsec($h,$m,0);
      }
    elsif($text =~ /^\s*(\d{1,2})\s*(am|pm)\s*$/i)
      {
        my($h,$f) = ($1,$2);
        $h += 12 if(lc($f) eq "pm");
        return convert_hms2gmtsec($h,0,0);
      }
    else
      {
        carp("Can't parse $text as a time");
        return -1;
      }
  }

sub convert_accint2accuracy
  {
    my($accint) = @_;
    return "unknown" if($accint == -1);
    if($accint < 0 || $accint > $#accuracy)
      {
        carp("Value of $accint is not a valid accuracy index");
        return "unknown";
      }
    return $accuracy[$accint];
  }

sub convert_mrd2serial
  {
    my($this) = @_;
    return convert_mrdfields2serial($this->{j_day},$this->{gmt_sec},
                                    $this->{accuracy});
  }

sub convert_serial2mrd
  {
    my($this) = @_;
    return MusicRoom::Date->new(serial => $this);
  }

sub convert_serial2mrdfields
  {
    my($this) = @_;
    if($this =~ /^(\d+)\:(\d+)\:(\d+)$/)
      {
        return($1,$2,$3);
      }
    carp("Cannot parse \"$this\" as serial");
    return(-1,-1,-1);
  }

sub convert_mrdfields2serial
  {
    my($jday,$gmtsec,$accint) = @_;
    return $jday.":".$gmtsec.":".$accint;
  }

# ------------------------------------------------------------

sub mrdfields
  {
    my($this) = @_;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
      }
    return $this->convert_mrd2mrdfields();
  }

sub accuracy
  {
    my($this) = shift;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
      }
    if(@_)
      {
        # Attempt to set the accuracy, should restrict the changes we can 
        # make (for example not allow an accuracy that requires info 
        # we don't have)
        $this->{accuracy} = convert_accuracy2accint($_[0]);
      }
    return convert_accint2accuracy($this->{accuracy});
  }

sub accint
  {
    my($this) = @_;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
      }
    if(@_)
      {
        # Attempt to set the accuracy, should restrict the changes we can 
        # make (for example not allow an accuracy that requires info 
        # we don't have)
        $this->{accuracy} = $_[0];
      }
    return $this->{accuracy};
  }

sub gmtsec
  {
    my($this) = @_;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
      }
    return $this->convert_mrd2gmtsec();
  }

sub hms
  {
    my($this) = @_;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
      }
    return $this->convert_mrd2hms();
  }

sub gdate
  {
    my($this) = @_;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
      }
    return $this->convert_mrd2gdate();
  }

sub jdate
  {
    my($this) = @_;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
      }
    return $this->convert_mrd2jdate();
  }

sub jday
  {
    my($this) = @_;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
      }
    return $this->convert_mrd2jday();
  }

sub text
  {
    my($this,$format) = @_;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
      }
    return $this->convert_mrd2text($format);
  }

sub unix
  {
    my($this) = @_;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
      }
    return $this->convert_mrd2unix();
  }

sub serial
  {
    my($this) = @_;
    if(!defined $this)
      {
        $this = MusicRoom::Date->new();
        return $this;
      }
    if(!ref($this))
      {
        return convert_serial2mrd($this);
      }
    return $this->convert_mrd2serial();
  }

# ------------------------------------------------------------

sub AUTOLOAD
  {
    my $this;
    my $typ = ref($_[0]);
    if(!defined $typ || !($typ =~ /Date/))
      {
        $this = MusicRoom::Date->new();
      }
    else
      {
        $this = shift;
      }

    my $name;
    my $type = ref($this) || berate("$this is not an object");
      {
        no strict;
        $name = $AUTOLOAD;
      }

    $name =~ s/.*://;
    if(defined $this->{$name})
      {
        $this->{$name} = shift if(@_);
        return $this->{$name};
      }
    return $this->text("\%$name\%");
  }

sub DESTROY
  {
  }

1;
