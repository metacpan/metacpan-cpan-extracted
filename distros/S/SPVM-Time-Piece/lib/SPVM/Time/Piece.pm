package SPVM::Time::Piece;

our $VERSION = "0.003";

1;

=head1 Name

SPVM::Time::Piece - Dates and Times

=head1 Description

The Time::Piece class in L<SPVM> has methods to manipulate dates and times.

=head1 Usage

  use Time::Piece;
  
  my $tp = Time::Piece->localtime;
  say "Time is " . $tp->cdate;
  say "Year is " . $tp->year;

=head2 Interfaces

=over 2

=item L<Cloneable|SPVM::Cloneable>

=back

=head1 Fields

=head2 is_localtime

C<has is_localtime : byte;>

The flag if the L</"tm"> field is interpreted as a local time.

=head2 tm

C<has tm : L<Sys::Time::Tm|SPVM::Sys::Time::Tm>;>

Time information.

=head2 epoch

C<has epoch : ro long;>

Seconds from epoch time.

=head1 Class Methods

=head2 localtime

C<static method localtime : L<Time::Piece|SPVM::Time::Piece> ($epoch : long = -1, $allow_minus : int = 0);>

Creates a bew L<Time::Piece|SPVM::Time::Piece> object given the epoch time, and returns it.

This instance represents the user's specified timezone.

If $allow_minus is 0 and $epoch is less than 0, $epoch is set to the current epoch time.

The L</"epoch">, L</"tm">, and L</"is_localtime"> fields are set to appropriate values.

=head2 localtime_tp

C<static method localtime_tp : L<Time::Piece|SPVM::Time::Piece> ($tp : L<Time::Piece|SPVM::Time::Piece>);>

Creates a new L<Time::Piece|SPVM::Time::Piece> object by interpreting $tp as the user's specified timezone, and returns it.

This instance represents the user's specified timezone,

The L</"epoch">, L</"tm">, and L</"is_localtime"> fields are set to appropriate values.

=head2 gmtime

C<static method gmtime : L<Time::Piece|SPVM::Time::Piece> ($epoch : long = -1, $allow_minus : int = 0);>

Creates a new L<Time::Piece|SPVM::Time::Piece> object given the epoch time, and returns it.

This instance represents UTC timezone,

If $allow_minus is 0 and $epoch is less than 0, $epoch is set to the current epoch time.

The L</"epoch">, L</"tm">, and L</"is_localtime"> fields are set to appropriate values.

=head2 gmtime_tp

C<static method gmtime_tp : L<Time::Piece|SPVM::Time::Piece> ($tp : L<Time::Piece|SPVM::Time::Piece>);>

Creates a new L<Time::Piece|SPVM::Time::Piece> object by interpreting $tp as UTC timezone, and returns it.

This instance represents UTC timezone,

The L</"epoch">, L</"tm">, and L</"is_localtime"> fields are set to appropriate values.

=head2 strptime

C<static method strptime : L<Time::Piece|SPVM::Time::Piece> ($string : string, $format : string);>

Parses the string $string according to the format $format.

This method calls L<std::get_time|https://en.cppreference.com/w/cpp/io/manip/get_time> in C++.

See the L<std::get_time|https://en.cppreference.com/w/cpp/io/manip/get_time> function about input field descriptors such as C<%Y>, C<%m>, C<%d>, C<%H>, C<%M>, C<%S>.

Exceptions:

$string must be defined. Otherwise an exception is thrown.

$format must be defined. Otherwise an exception is thrown.

If std::get_time failed, an exception is thrown.

=head1 Instance Methods

=head2 sec

C<method sec : int ();>

Returns the second. This is the value of L<tm_sec|SPVM::Sys::Time::Tm/"tm_sec"> in the Sys::Time::Tm class.

=head2 second

C<method second : int ();>

The same as the L</"sec"> method.

=head2 min

C<method min : int ();>

Returns the minute. This is the value of L<tm_min|SPVM::Sys::Time::Tm/"tm_min"> in the Sys::Time::Tm class.

=head2 minute

C<method minute : int ();>

The same as the L</"min"> method.

=head2 hour

C<method hour : int ();>

Returns the hour. This is the value of L<tm_hour|SPVM::Sys::Time::Tm/"tm_hour"> in the Sys::Time::Tm class.

=head2 mday

C<method mday : int ();>

Returns the day of the month. This is the value of L<tm_mday|SPVM::Sys::Time::Tm/"tm_mday"> in the Sys::Time::Tm class.

=head2 day_of_month

C<method day_of_month : int ();>

=head2 mon

C<method mon : int ();>

Returns the month. This is the value of L<tm_mon|SPVM::Sys::Time::Tm/"tm_mon"> plus 1 in the Sys::Time::Tm class.

=head2 _mon

C<method _mon : int ();>

Returns the value of L<tm_mon|SPVM::Sys::Time::Tm/"tm_mon"> in the Sys::Time::Tm class.

=head2 monname

C<method monname : string ($mon_list : string[] = undef);>

Returns the month name given $mon_list.

The default $mon_list:

  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

=head2 month

C<method month : string ($mon_list : string[] = undef);>

The same as the L</"monname"> method.

=head2 fullmonth

C<method fullmonth : string ($mon_list : string[] = undef);>

Returns the full month name given $mon_list.

The default $mon_list:

  ["January", "February", "March", "April", "May", "June", "July", 
                      "August", "September", "October", "November", "December"]
=head2 year

C<method year : int ();>

Returns the year. This is the value of L<tm_mday|SPVM::Sys::Time::Tm/"tm_mday"> plus 1900 in the Sys::Time::Tm class.

=head2 _year

C<method _year : int ();>

Returns the value of L<tm_year|SPVM::Sys::Time::Tm/"tm_year"> in the Sys::Time::Tm class.

=head2 yy

C<method yy : int ();>

Returns the the last two digits of L</"year">.

=head2 wday

C<method wday : int ();>

Returns the week number, interpreting Sunday as 1. This is the value of L<tm_wday|SPVM::Sys::Time::Tm/"tm_wday"> plus 1 in the Sys::Time::Tm class.

=head2 _wday

C<method _wday : int ();>

The same as the L</"day_of_week"> method.

=head2 day_of_week

C<method day_of_week : int ();>

Returns the week number, interpreting Sunday as 0. This is the value of L<tm_wday|SPVM::Sys::Time::Tm/"tm_wday"> in the Sys::Time::Tm class.

=head2 wdayname

C<method wdayname : string ($day_list : string[] = undef);>

Returns the name of the day of the week given $day_list.

The default $day_list:

  ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

=head2 day

C<method day : string ($day_list : string[] = undef);>

The same as the L</"wdayname"> method.

=head2 fullday

C<method fullday : string ($day_list : string[] = undef);>

Returns the full name of the day of the week given $day_list.

The default $day_list:

  ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

=head2 yday

C<method yday : int ();>

Returns the day in the year. This is the value of L<tm_yday|SPVM::Sys::Time::Tm/"tm_yday"> in the Sys::Time::Tm class.

=head2 day_of_year

C<method day_of_year : int ();>

The same as the L</"yday"> method.

=head2 isdst

C<method isdst : int ();>

Returns the flag thats indicate daylight saving time. This is the value of L<tm_isdst|SPVM::Sys::Time::Tm/"tm_isdst"> in the Sys::Time::Tm class.

=head2 daylight_savings

C<method daylight_savings : int ();>

The same as the L</"isdst"> method.

=head2 hms

C<method hms : string ($sep : string = undef);>

Formats the hour, the minute, and the second into a two-digit string respectively, and concatenates them with the given separator $sep, and returns it.

If $sep is not defined, $sep is set to C<:>.

=head2 time

C<method time : string ($sep : string = undef);>

The same as the L</"hms"> method.

=head2 ymd

C<method ymd : string ($sep : string = undef);>

Formats the year, the month, and the day of the month into a four-digit string, a two-digit string, a two-digit string respectively, and concatenates them with the given separator $sep, and returns it.

If $sep is not defined, $sep is set to C<->.

=head2 date

C<method date : string ($sep : string = undef);>

The same as the L</"ymd"> method.

=head2 mdy

C<method mdy : string ($sep : string = undef);>

Formats the month, the day of the month, and the year into a two-digit string, a two-digit string, a four-digit string respectively, and concatenates them with the given separator $sep, and returns it.

If $sep is not defined, $sep is set to C<->.

=head2 dmy

C<method dmy : string ($sep : string = undef);>

Formats the day of the month, the month, and the year into a two-digit string, a two-digit string, a four-digit string respectively, and concatenates them with the given separator $sep, and returns it.

If $sep is not defined, $sep is set to C<->.

=head2 datetime

C<method datetime : string ();>

Formats the time information into ISO 8601 format like C<2000-02-29T12:34:56>, and returns it.

=head2 tzoffset

C<method tzoffset : L<Time::Seconds|SPVM::Time::Seconds> ();>

Calculates the timezone offset, and returns it.

=head2 julian_day

C<method julian_day : double ();>

Calculates the number of days since Julian period began, and returns it.

=head2 mjd

C<method mjd : double ();>

Calculates the modified Julian date (JD minus 2400000.5 days).

=head2 week

C<method week : int ();>

Calculate the week number (ISO 8601), and returns it.

=head2 is_leap_year

C<method is_leap_year : int ();>

If the year is a leap year, returns 1, otherwise returns 0.

=head2 month_last_day

C<method month_last_day : int ();>

Returns the last day of the month.

=head2 cdate

C<method cdate : string ();>

Formats the time information into the string like C<Tue Feb 29 12:34:56 2000>.

=head2 strftime

C<method method strftime : string ($format : string = undef);>

Formats the time information into a string according to the format $format, and returns it.

See the L<strftime|https://linux.die.net/man/3/strftime> function about conversion specifications such as C<%Y>, C<%m>, C<%d>, C<%H>, C<%M>, C<%S>.

If $format is not defined, it is set to C<%a, %d %b %Y %H:%M:%S %Z>.

Exceptions:

The length of $format must be greater than 1. Otherwise an exception is thrown.

If too many memory is allocated, an exception is thrown.

=head2 add

C<method add : L<Time::Piece|SPVM::Time::Piece> ($tsec : L<Time::Seconds|SPVM::Time::Seconds>);>

Creates a new L<Time::Piece|SPVM::Time::Piece> object with the given seconds $tsec added, and returns it.

=head2 subtract

C<method subtract : L<Time::Piece|SPVM::Time::Piece> ($tsec : L<Time::Seconds|SPVM::Time::Seconds>);>

Creates a new L<Time::Piece|SPVM::Time::Piece> object with the given seconds $tsec subtracted, and returns it.

=head2 subtract_tp

C<method subtract_tp : L<Time::Seconds|SPVM::Time::Seconds> ($tp : L<Time::Piece|SPVM::Time::Piece>);>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object given the seconds that is L</"seconds"> fields to the L</"epoch"> field of this instance munus the L</"epoch"> field of $tp.

=head2 compare

C<method compare : int ($tp : L<Time::Piece|SPVM::Time::Piece>);>

If the L</"epoch"> field of this instance is greater than the L</"epoch"> field of $tp, returns 1.

If the L</"epoch"> field of this instance is less than the L</"epoch"> field of $tp, returns -1.

If the L</"epoch"> field of this instance is equal to the L</"epoch"> field of $tp, returns 0.

=head2 add_months

C<method add_months : L<Time::Piece|SPVM::Time::Piece> ($num_months : int);>

Returns a new L<Time::Piece|SPVM::Time::Piece> object with the month added by $num_months.

=head2 add_years

C<method add_years : L<Time::Piece|SPVM::Time::Piece> ($years : int);>

Returns a new L<Time::Piece|SPVM::Time::Piece> object with the year added by $years.

=head2 truncate

C<method truncate : L<Time::Piece|SPVM::Time::Piece> ($options : object[]);>

Calling the truncate method returns a copy of the object but with the time truncated to the start of the supplied unit C<to>.

Options:

=over 2

=item C<to> : string

"year", "quarter", "month", "day", "hour", "minute", and "second".

=back

Excamples:

  $tp = $tp->truncate({to => "day"});

=head2 clone

C<method clone : L<Time::Piece|SPVM::Time::Piece> ();>

Clones this instance, and returns it.

=head1 Repository

L<SPVM::Time::Piece - Github|https://github.com/yuki-kimoto/SPVM-Time-Piece>

=head1 Author

Yuki Kimoto C<method kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

