package PAB3::Utils;
# =============================================================================
# Perl Application Builder
# Module: PAB3::Utils
# use "perldoc PAB3::Utils" for documenation
# =============================================================================
use strict;
use warnings;
no warnings 'uninitialized';

use vars qw($VERSION $TID);

require Exporter;
our @EXPORT_GOOD = qw(
	setlocale set_locale set_user_locale set_timezone
	strftime strfmon number_format str_trim trim round
);
our @EXPORT_BAD = qw(localtime gmtime);
our @EXPORT_OK = ( @EXPORT_GOOD, @EXPORT_BAD );
our %EXPORT_TAGS = (
	'default' => \@EXPORT_GOOD,
);
*import = \&Exporter::import;

BEGIN {
	$VERSION = '2.0';
	require XSLoader;
	XSLoader::load( __PACKAGE__, $VERSION );
	
	my( $pn );
	$pn = '/auto/PAB3/Utils/';
	foreach( @INC ) {
		if( -d $_ . $pn . 'locale' ) {
			&_set_module_path( $_ . $pn );
			last;
		}
	}
	
	$TID = undef;
	
	*setlocale = \&set_locale;
	*trim = \&str_trim;
}

END {
	&_cleanup();
}

1;

sub DESTROY {
	my $this = shift or return;
	if( $$this ) {
		&_cleanup_class( $$this );
	}
}

sub set_locale {
	my $tid = &get_thread_id( \@_ );
	&_set_locale( $tid, @_ );
}

sub set_user_locale {
	my $tid = &get_thread_id( \@_ );
	&_set_user_locale( $tid, @_ );
}

sub set_timezone {
	my $tid = &get_thread_id( \@_ );
	&_set_timezone( $tid, @_ );
}

sub number_format {
	my $tid = &get_thread_id( \@_ );
	&_number_format( $tid, @_ );
}

sub localtime {
	my $tid = &get_thread_id( \@_ );
	&_localtime( $tid, @_ );
}

sub strftime {
	my $tid = &get_thread_id( \@_ );
	&_strftime( $tid, @_ );
}

sub strfmon {
	my $tid = &get_thread_id( \@_ );
	&_strfmon( $tid, @_ );
}

sub get_thread_id {
	#my( $arg ) = @_;
	if( ref( $_[0]->[0] ) eq __PACKAGE__ ) {
		return ${shift @{$_[0]}};
	}
	defined $TID or $TID = &_get_current_thread_id();
	return $TID;
}


__END__


=head1 NAME

PAB3::Utils - Utility functions for the PAB3 environment or as standalone

=head1 SYNOPSIS

  use PAB3::Utils qw(:default);
  
  # all functions should be thread safe and does NOT affect
  # to CORE::localtime or POSIX locale and time functions
  
  # create an object of PAB3::Utils
  $utils = PAB3::Utils->new();
  
  $locale = set_locale( @locale );
  
  set_user_locale( $hash_ref );
  
  $bool = set_timezone( $timezone );
  
  @ta = PAB3::Utils::localtime();
  @ta = PAB3::Utils::gmtime();
  
  # almost POSIX compatible
  $string = strftime( $format );
  $string = strftime( $format, $timestamp );
  $string = strftime( $format, $timestamp, $gmt );
  
  # almost POSIX compatible
  $string = strfmon( $format, $number );
  
  $string = number_format( $number );
  $string = number_format( $number, $right_prec );
  $string = number_format( $number, $right_prec, $dec_point );
  $string = number_format( $number, $right_prec, $dec_point, $thou_sep );
  $string = number_format(
      $number, $right_prec, $dec_point, $thou_sep, $neg_sign
  );
  $string = number_format(
      $number, $right_prec, $dec_point, $thou_sep, $neg_sign, $pos_sign
  );
  $string = number_format(
      $number, $right_prec, $dec_point, $thou_sep, $neg_sign, $pos_sign,
      $left_prec
  );
  $string = number_format(
      $number, $right_prec, $dec_point, $thou_sep, $neg_sign, $pos_sign,
      $left_prec, $fillchar
  );
  
  $newstr = str_trim( $string );
  
  $string = round( $number );
  $string = round( $number, $precision );


=head1 DESCRIPTION

PAB3::Utils implements thread safe locale and time support and some other useful
functions.

This module should be B<threadsafe, BUT:>

Under ModPerl or PerlEx environments several scripts may take access to the same
instance of the Perl interpreter. All module functions are interpreter global!
If you plan using several locale and time settings in your scripts which may
take access to the same interpreter you should use L<new()|PAB3::Utils/new> to
create independend objects. 


=head1 EXAMPLES

=head2 Standard Use

  use PAB3::Utils;
  
  &PAB3::Utils::set_timezone( 'Europe/Berlin' );
  &PAB3::Utils::set_locale( 'de_DE.UTF-8' );
  
  print &PAB3::Utils::strftime( '%c', time ), "\n";

=head2 Exporting goodies

  use PAB3::Utils qw(:default); # localtime and gmtime are not exported
  
  set_timezone( 'Europe/Berlin' );
  set_locale( 'de_DE.UTF-8' );
  
  print strftime( '%c', time ), "\n";

=head2 OO design

  use PAB3::Utils;
  
  $utils = PAB3::Utils->new();
  $utils->set_timezone( 'America/New_York' );
  $utils->set_locale( 'en_US' );
  print $utils->strftime( '%c' ), "\n";

=head1 METHODS

=over 2

=item new ()

Creates a new class of PAB3::Utils and returns it.


=item setlocale ( @locals )

=item set_locale ( @locals )

Set locale information. setlocale is a synonym for set_locale.

B<Parameters>

I<@locals>

One or more locale strings. Each parameter is tried to be set as new locale
until success.

For example:

  $localestr = set_locale( 'en', 'en_EN', 'en_US' );
  print "New locale is $localestr\n";

B<Return Values>

Returns the new locale set, or FALSE if no locale could be found.


=item set_user_locale ( $hash_ref )

Set userdefined locale information.

B<Parameters>

I<$hash_ref>

A hashref with locale information. Following fields are used in short or
long version:

  'dp'  or 'decimal_point'         => decimal point character
  'ts'  or 'thousands_sep'         => thousands separator
  'grp' or 'grouping'              => numeric grouping, (i.e. [3, 2])
  'cs'  or 'currency_symbol'       => local currency symbol (i.e. $)
  'ics' or 'int_curr_symbol'       => international currency symbol (i.e. USD)
  'csa' or 'curr_symb_align'       => currency symbol alignment:
                                      'l' = left side, 'r' = right side
  'css' or 'curr_symb_space'       => space between currency symbol and value:
                                      true or false
  'fd'  or 'frac_digits'           => local fractional digits
  'ifd' or 'int_frac_digits'       => international fractional digits
  'ns'  or 'negative_sign'         => sign for negative values
  'ps'  or 'positive_sign'         => sign for positive values
  'aml' or 'am_lower'              => A.M. string in lower case (i.e. am)
  'pml' or 'pm_lower'              => P.M. string in lower case (i.e. pm)
  'amu' or 'am_upper'              => A.M. string in upper case (i.e. AM)
  'pmu' or 'pm_upper'              => P.M. string in upper case (i.e. PM)
  'apf' or 'ampm_format'           => am/pm format string (i.e. %I:%M:%S %p)
  'df' or 'date_format'            => date format (i.e. %m/%d/%Y)
  'tf' or 'time_format'            => time format (i.e. %H:%M:%S)
  'dtf' or 'datetime_format'       => datetime format (i.e. %a %d %b %Y %r %Z)
  'sdn' or 'short_day_names'       => array with short day names
  'ldn' or 'long_day_names'        => array with long day names
  'smn' or 'short_month_names'     => array with short month names
  'lmn' or 'long_month_names'      => array with long month names

B<Return Values>

Returns nothing.

B<Example>

  my %locale = (
      'dp'  => '.',
      'ts'  => ',',
      'grp' => [3, 3],
      'cs'  => '$',
      'ics' => 'USD',
      'csa' => 'l',
      'css' => 0,
      'fd'  => 2,
      'ifd' => 2,
      'ns'  => '-',
      'ps'  => '+',
      'aml' => 'am',
      'pml' => 'pm',
      'amu' => 'AM',
      'pmu' => 'PM',
      'apf' => '%I:%M:%S %p',
      'df'  => '%m/%d/%Y',
      'tf'  => '%H:%M:%S',
      'dtf' => '%a %d %b %Y %r %Z',
      'sdn' => ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      'ldn' => ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
                'Friday', 'Saturday'],
      'smn' => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep',
                'Oct', 'Nov', 'Dec'],
      'lmn' => ['January', 'February', 'March', 'April', 'May', 'June', 'July',
                'August', 'September', 'October', 'November', 'December'],
  );
  
  set_user_locale( \%locale );
  
  print strftime( '%c' ), "\n";


=item set_timezone ( $zone )

Sets the timezone used by all date and time functions from here.

B<Parameters>

I<$zone>

The timezone identifier, like 'UTC' or 'Europe/Lisabon'. A list of
identifiers can be found here: L<http://php.net/manual/timezones.php>. 


=item localtime ()

=item localtime ( $timestamp )

Converts a time as returned by the time function to a 9-element list with the
time analyzed for the local time zone.
Typically used as follows:

    #  0    1    2     3     4    5     6     7     8
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                     localtime(time);


=item gmtime ()

=item gmtime ( $timestamp )

Converts a time as returned by the time function to an 9-element list with the
time localized for the standard Greenwich time zone.
Typically used as follows:

    #  0    1    2     3     4    5     6     7     8
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                     gmtime(time);


=item strftime ( $format )

=item strftime ( $format, $timestamp )

=item strftime ( $format, $timestamp, $gmt )

Format a local time/date according to locale or gmt settings

B<Parameters>

I<$format>

The following conversion specifiers are recognized in the format string:

     %A    is replaced by the locale's full weekday name.
     
     %a    is replaced by the locale's abbreviated weekday name.
     
     %B    is replaced by the locale's full month name.
     
     %b or %h
           is replaced by the locale's abbreviated month name.
     
     %C    is replaced by the century (a year divided by 100 and truncated to
           an integer) as a decimal number [00,99].
     
     %c or %+
           is replaced by the locale's appropriate date and time representa-
           tion.
     
     %D    is replaced by the date in the format ``%m/%d/%y''.
     
     %d    is replaced by the day of the month as a decimal number [01,31].
     
     %e    is replaced by the day of month as a decimal number [1,31]; single
           digits are preceded by a blank.
     
     %F    is replaced by the date in the format ``%Y-%m-%d'' (the ISO 8601
           date format).
     
     %G    is replaced by the ISO 8601 year with century as a decimal number.
     
     %g    is replaced by the ISO 8601 year without century as a decimal num-
           ber (00-99).  This is the year that includes the greater part of
           the week.  (Monday as the first day of a week).  See also the `%V'
           conversion specification.
     
     %H    is replaced by the hour (24-hour clock) as a decimal number
           [00,23].
     
     %I    is replaced by the hour (12-hour clock) as a decimal number
           [01,12].
     
     %j    is replaced by the day of the year as a decimal number [001,366].
     
     %k    is replaced by the hour (24-hour clock) as a decimal number [0,23];
           single digits are preceded by a blank.
     
     %l    is replaced by the hour (12-hour clock) as a decimal number [1,12];
           single digits are preceded by a blank.
     
     %M    is replaced by the minute as a decimal number [00,59].
     
     %m    is replaced by the month as a decimal number [01,12].
     
     %n    is replaced by a newline.
     
     %o or %O
           is replaced by the offset from UTC in seconds.
     
     %p    is replaced by the locale's equivalent of either ``AM'' or ``PM''.
     
     %P    is replaced by the locale's equivalent of either ``AM'' or ``PM''
           represented in lower case format.
     
     %R    is replaced by the time in the format ``%H:%M''.
     
     %r    is replaced by the locale's representation of 12-hour clock time
           using AM/PM notation.
     
     %S    is replaced by the second as a decimal number [00,61].  The range
           of seconds is (00-61) instead of (00-59) to allow for the periodic
           occurrence of leap seconds and double leap seconds.
     
     %s    is replaced by the number of seconds since the Epoch, UTC (see
           mktime(3)).
     
     %T    is replaced by the time in the format ``%H:%M:%S''.
     
     %t    is replaced by a tab.
     
     %U    is replaced by the week number of the year (Sunday as the first day
           of the week) as a decimal number [00,53].
     
     %u    is replaced by the weekday (Monday as the first day of the week) as
           a decimal number [1,7].
     
     %V    is replaced by the week number of the year (Monday as the first day
           of the week) as a decimal number [01,53]. According to ISO 8601 the
           week containing January 1 is week 1 if it has four or more days in
           the new year, otherwise it is week 53 of the previous year, and the
           next week is week 1.  The year is given by the `%G' conversion
           specification.
     
     %v    is replaced by the date in the format ``%e-%b-%Y''.
     
     %W    is replaced by the week number of the year (Monday as the first day
           of the week) as a decimal number [00,53].
     
     %w    is replaced by the weekday (Sunday as the first day of the week) as
           a decimal number [0,6].
     
     %X    is replaced by the locale's appropriate time representation.
     
     %x    is replaced by the locale's appropriate date representation.
     
     %Y    is replaced by the year with century as a decimal number.
     
     %y    is replaced by the year without century as a decimal number
           [00,99].
     
     %Z    is replaced by the time zone name.
     
     %z    is replaced by the offset from ITC in the ISO 8601 format
           ``[-]hhmm''.
     
     %%    is replaced by `%'.

I<$timestamp>

The optional timestamp parameter is an integer Unix timestamp that defaults to
the current time if a timestamp is not given. In other words, it defaults
to the value of time().

I<$gmt>

Optional gmt parameter indicates to use timestamp localized for the standard
Greenwich time zone.


=item strfmon ( $format, $value )

The strfmon() function converts a numeric value to monetary strings according
to the specifications in the I<$format> parameter. The function converts
the double-precision floating-point value parameter under the control of
the I<$format> parameter and returns the result.

B<Parameters>

I<$format>

Contains characters and conversion specifications.

The application shall ensure that a conversion specification consists of the
following sequence:

  -  A '%' character
  -  Optional flags
  -  Optional field width
  -  Optional left precision
  -  Optional right precision
  -  A required conversion specifier character that determines the conversion
     to be performed

B<I<Flags>>

One or more of the following optional flags can be specified to control the
conversion:

  =f  An '=' followed by a single character f which is used as the numeric fill
      character. In order to work with precision or width counts, the fill
      character shall be a single byte character; if not, the behavior is
      undefined. The default numeric fill character is the <space>. This flag
      does not affect field width filling which always uses the <space>. This
      flag is ignored unless a left precision (see below) is specified. 
  
  ^   Do not format the currency amount with grouping characters. The default
      is to insert the grouping characters if defined for the current locale. 
  
  + or ( 
      Specify the style of representing positive and negative currency amounts.
      Only one of '+' or '(' may be specified. If '+' is specified, the
      locale's equivalent of '+' and '-' are used (for example, in the U.S.,
      the empty string if positive and '-' if negative). If '(' is specified,
      negative amounts are enclosed within parentheses. If neither flag is
      specified, the '+' style is used. 
  
  !   Suppress the currency symbol from the output conversion. 
  
  -   Specify the alignment. If this flag is present the result of the
      conversion is left-justified (padded to the right) rather than
      right-justified. This flag shall be ignored unless a field width
      (see below) is specified. 

B<I<Field Width>>

  w   A decimal digit string w specifying a minimum field width in bytes
      in which the result of the conversion is right-justified
      (or left-justified if the flag '-' is specified). The default is 0. 

B<I<Left Precision>>

  #n  A '#' followed by a decimal digit string n specifying a maximum number
      of digits expected to be formatted to the left of the radix character.
      This option can be used to keep the formatted output from multiple
      calls to the strfmon() function aligned in the same columns. It can
      also be used to fill unused positions with a special character
      as in "$***123.45". This option causes an amount to be formatted
      as if it has the number of digits specified by n. If more than
      n digit positions are required, this conversion specification is
      ignored. Digit positions in excess of those actually required are
      filled with the numeric fill character (see the =f flag above). 
     
      If grouping has not been suppressed with the '^' flag, and it is
      defined for the current locale, grouping separators are inserted before
      the fill characters (if any) are added. Grouping separators are not
      applied to fill characters even if the fill character is a digit.
     
      To ensure alignment, any characters appearing before or after the
      number in the formatted output such as currency or sign symbols
      are padded as necessary with <space>s to make their positive and
      negative formats an equal length.

B<I<Right Precision>>

  .p  A period followed by a decimal digit string p specifying the number
      of digits after the radix character. If the value of the right
      precision p is 0, no radix character appears. If a right precision
      is not included, a default specified by the current locale is used.
      The amount being formatted is rounded to the specified number of
      digits prior to formatting. 

B<I<Conversion Specifier Characters>>

The conversion specifier characters and their meanings are:

  i   The double argument is formatted according to the locale's
      international currency format (for example, in the U.S.: USD 1,234.56).
  
  n   The double argument is formatted according to the locale's national
      currency format (for example, in the U.S.: $1,234.56).
  
  %   Convert to a '%' ; no argument is converted. The entire conversion
      specification shall be %%. 


I<$value>

Specifies the double data to be converted according to the format
parameter.

B<Return Values>

Returns the converted double-precision floating-point value parameter under
the control of the I<$format> parameter.

B<Examples>

  strfmon( '%n', 123.45 );

Given a locale for the U.S. and the values 123.45, -123.45, and 3456.781, the
following output might be produced. Square brackets ( "[]" ) are used in this
example to delimit the output.

  %n         [$123.45]         Default formatting 
             [-$123.45]
             [$3,456.78]
  
  %11n       [    $123.45]     Right align within an 11-character field 
             [   -$123.45]
             [  $3,456.78]
  
  %#5n       [ $   123.45]     Aligned columns for values up to 99999 
             [-$   123.45]
             [ $ 3,456.78]
  
  %=*#5n     [ $***123.45]     Specify a fill character 
             [-$***123.45]
             [ $*3,456.78]
  
  %=0#5n     [ $000123.45]     Fill characters do not use grouping 
             [-$000123.45]     even if the fill character is a digit 
             [ $03,456.78]
  
  %^#5n      [ $  123.45]      Disable the grouping separator 
             [-$  123.45]
             [ $ 3456.78]
  
  %^#5.0n    [ $  123]         Round off to whole units 
             [-$  123]
             [ $ 3457]
  
  %^#5.4n    [ $  123.4500]    Increase the precision 
             [-$  123.4500]
             [ $ 3456.7810]
  
  %(#5n      [ $   123.45 ]    Use an alternative pos/neg style 
             [($   123.45)]
             [ $ 3,456.78 ]
  
  %!(#5n     [    123.45 ]     Disable the currency symbol 
             [(   123.45)]
             [  3,456.78 ]
  
  %-14#5.4n  [ $   123.4500 ]  Left-justify the output 
             [-$   123.4500 ]
             [ $ 3,456.7810 ]
  
  %14#5.4n   [  $   123.4500]  Corresponding right-justified output 
             [ -$   123.4500]
             [  $ 3,456.7810]


=item number_format ( $number )

=item number_format ( $number, $decimals )

=item number_format ( $number, $right_prec, $dec_point )

=item number_format ( $number, $right_prec, $dec_point, $thou_sep )

=item number_format ( $number, $right_prec, $dec_point, $thou_sep, $neg_sign )

=item number_format (
      $number, $right_prec, $dec_point, $thou_sep, $neg_sign, $pos_sign
  )

=item number_format (
      $number, $right_prec, $dec_point, $thou_sep, $neg_sign, $pos_sign,
      $left_prec
  )

=item number_format (
      $number, $right_prec, $dec_point, $thou_sep, $neg_sign, $pos_sign,
      $left_prec, $fillchar
  )

Format a number with grouped thousands and other formatings.

B<Parameters>

I<$number>

The number to be formated

I<$right_prec>

Specifying the number of digits after the radix character. Default is 0.

I<$dec_point>

Decimal point character.
The default value is used from current locale.

I<$thou_sep>

Thousands separator (1 character).
The default value is used from current locale.

I<$neg_sign>

Sign for negative values.
The default value is used from current locale.

I<$pos_sign>

Sign for positive values.
The default value is used from current locale.

I<$left_prec>

Specifying a maximum number of digits expected to be formatted to the
left of the radix character. Default is 0.

I<$fillchar>

A single character which is used as the fill character. The default fill
character is the <space>.

B<Return Values>

Returns a formatted version of I<$number>

B<Examples>

  $number = 1234.56;
  
  # english notation (default locale)
  number_format( 1234.56 );
  # 1,235
  
  # french notation
  number_format( $number, 2, ',', ' ' );
  # 1 234,56
  
  # financial notation
  number_format( $number, 2, '.', ',', '-', '+', 7, '0' );
  # +00001,234.56


=item round ( $val )

=item round ( $val, $precision )

Returns the rounded value of val to specified precision
(number of digits after the decimal point). Default precision is 0. 


=item trim ( $str )

=item str_trim ( $str )

This function returns a string with whitespace stripped from the beginning and
end of str. trim() will strip these characters: 

  " "    (ASCII 32 (0x20)), an ordinary space. 
  "\t"   (ASCII  9 (0x09)), a tab. 
  "\n"   (ASCII 10 (0x0A)), a new line (line feed). 
  "\r"   (ASCII 13 (0x0D)), a carriage return. 
  "\0"   (ASCII  0 (0x00)), the NUL-byte. 
  "\x0B" (ASCII 11 (0x0B)), a vertical tab. 


=back

=head1 AUTHORS

Christian Mueller <christian_at_hbr1.com>

=head1 COPYRIGHT

The PAB3::Utils module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=cut

