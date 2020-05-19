# -*- perl -*-
##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/DateTime.pm
## Version v0.100.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/12/15
## Modified 2020/05/16
## 
##----------------------------------------------------------------------------
package Net::API::REST::DateTime;
BEGIN
{
	use strict;
	use common::sense;
	use parent qw( Module::Generic );
	use TryCatch;
	use Devel::Confess;
	our @DoW = qw( Sun Mon Tue Wed Thu Fri Sat );
	our @MoY = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
	our $MoY = {};
	@$MoY{ @MoY } = ( 1..12 );
	our $GMT_ZONE = { 'GMT' => 1, 'UTC' => 1, 'UT' => 1, 'Z' => 1 };
	our $VERSION = 'v0.100.1';
};

sub format_datetime
{
    my( $self, $dt ) = @_;
    $dt = DateTime->now unless( defined( $dt ) );
    $dt = $dt->clone->set_time_zone( 'GMT' );
    return( $dt->strftime( '%a, %d %b %Y %H:%M:%S GMT' ) );
}

## How about using APR::Date::parse_http instead?
## https://perl.apache.org/docs/2.0/api/APR/Date.html#toc_C_parse_http_
sub parse_date
{
	my $self = shift( @_ );
    my $date = shift( @_ ) || return( $self->error( "No date to parse was provided." ) );
    
    ## More lax parsing below
    ## kill leading space
    $date =~ s/^\s+//;
    ## Useless weekday
    $date =~ s/^(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)[a-z]*,?\s*//i;
    
    my( $day, $mon, $yr, $hr, $min, $sec, $tz, $ampm );
    
    ## Then we are able to check for most of the formats with this regexp
    ( ( $day, $mon, $yr, $hr, $min, $sec, $tz ) = $date =~ 
        /^
     (\d\d?)               # day
        (?:\s+|[-\/])
     (\w+)                 # month
        (?:\s+|[-\/])
     (\d+)                 # year
     (?:
           (?:\s+|:)       # separator before clock
        (\d\d?):(\d\d)     # hour:min
        (?::(\d\d))?       # optional seconds
     )?                    # optional clock
        \s*
     ([-+]?\d{2,4}|(?![APap][Mm]\b)[A-Za-z]+)? # timezone
        \s*$
    /x )

    ||
    
    ## Try the ctime and asctime format
    ( ( $mon, $day, $hr, $min, $sec, $tz, $yr ) = $date =~ 
    /^
     (\w{1,3})             # month
        \s+
     (\d\d?)               # day
        \s+
     (\d\d?):(\d\d)        # hour:min
     (?::(\d\d))?          # optional seconds
        \s+
     (?:([A-Za-z]+)\s+)?   # optional timezone
     (\d+)                 # year
        \s*$               # allow trailing whitespace
    /x )

    ||
    
    ## Then the Unix 'ls -l' date format
    ( ( $mon, $day, $yr, $hr, $min, $sec ) = $date =~ 
    /^
     (\w{3})               # month
        \s+
     (\d\d?)               # day
        \s+
     (?:
        (\d\d\d\d) |       # year
        (\d{1,2}):(\d{2})  # hour:min
            (?::(\d\d))?       # optional seconds
     )
     \s*$
       /x )

    ||
    
    ## ISO 8601 format '1996-02-29 12:00:00 -0100' and variants
    ( ( $yr, $mon, $day, $hr, $min, $sec, $tz ) = $date =~ 
    /^
      (\d{4})              # year
         [-\/]?
      (\d\d?)              # numerical month
         [-\/]?
      (\d\d?)              # day
     (?:
           (?:\s+|[-:Tt])  # separator before clock
        (\d\d?):?(\d\d)    # hour:min
        (?::?(\d\d))?      # optional seconds
     )?                    # optional clock
        \s*
     ([-+]?\d\d?:?(:?\d\d)?
      |Z|z)?               # timezone  (Z is "zero meridian", i.e. GMT)
        \s*$
    /x)

    ||
    
    ## Windows 'dir' 11-12-96  03:52PM
    ( ( $mon, $day, $yr, $hr, $min, $ampm ) = $date =~ 
        /^
          (\d{2})                # numerical month
             -
          (\d{2})                # day
             -
          (\d{2})                # year
             \s+
          (\d\d?):(\d\d)([APap][Mm])  # hour:min AM or PM
             \s*$
        /x )

    ||
    ## unrecognized format
    return( $self->return( "Unrecognised http date format '$date'." ) );
    
    ## Translate month name to number
    $mon = $MoY->{ $mon } ||
           $MoY->{ "\u\L$mon" } ||
       ( $mon >= 1 && $mon <= 12 && int( $mon ) ) ||
           return;

    ## If the year is missing, we assume first date before the current,
    ## because of the formats we support such dates are mostly present
    ## on "ls -l" listings.
    unless( defined( $yr ) ) 
    {
    	my $d = DateTime->now;
        my $cur_mon = $d->month;
        $yr = $d->year;
        $yr-- if( $mon > $cur_mon );
    }
    elsif( length( $yr ) < 3 ) 
    {
        ## Find "obvious" year
    	my $d = DateTime->now;
        my $cur_yr = $d->year;
        ## What is the millenium?
        my $m = $cur_yr % 100;
        my $tmp = $yr;
        $yr += $cur_yr - $m;
        $m -= $tmp;
        $yr += ( $m > 0 ) ? 100 : -100 if( abs( $m ) > 50 );
    }
    
    ## Make sure clock elements are defined
    $hr  = 0 unless( defined( $hr ) );
    $min = 0 unless( defined( $min ) );
    $sec = 0 unless( defined( $sec ) );
    
    ## Compensate for AM/PM
    if( $ampm ) 
    {
        $ampm = uc( $ampm );
		$hr   = 0 if( $hr == 12 && $ampm eq 'AM' );
		$hr  += 12 if( $ampm eq 'PM' && $hr != 12 );
    }
    
    return( $yr, $mon, $day, $hr, $min, $sec, $tz ) if( wantarray() );
    
    if( defined( $tz ) ) 
    {
        $tz = 'Z' if( $tz =~ /^(GMT|UTC?|[-+]?0+)$/ );
    } 
    else 
    {
        $tz = '';
    }
    $self->messagef( 3, "Returning: %04d-%02d-%02d %02d:%02d:%02d%s", $yr, $mon, $day, $hr, $min, $sec, $tz );
    return( sprintf( "%04d-%02d-%02d %02d:%02d:%02d%s",
           $yr, $mon, $day, $hr, $min, $sec, $tz ) );
}

sub str2datetime
{
	my $self = shift( @_ );
    my $str = shift( @_ ) || return( $self->error( "No datetime string was provided to convert to unix time." ) );
    
    ## fast exit for strictly conforming string
    ## e.g. Sun, 06 Oct 2019 06:41:11 GMT
    if( $str =~ /^[SMTWF][a-z][a-z], (\d{2}) ([JFMAJSOND][a-z][a-z]) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$/ )
    {
    	$self->message( 3, "Found a strictl compliant http date string: '$str'." );
    	my $d;
    	try
    	{
    		$d = DateTime->new(
				year => $3,
				month => $MoY->{ $2 },
				day => $1,
				hour => $4,
				minute => $5,
				second => $6,
				time_zone => 'GMT'
			);
			return( $d );
		}
		catch( $e )
		{
			return( $self->error( "Unable to parse date '$str': $e" ) );
		}
    }
    
    my @d = $self->parse_date( $str );
    $self->message( 3, "Parsing string '$str' yielded: ", sub{ $self->dumper( \@d ) } );
    return if( !scalar( @d ) );
#     $d[ 0 ] -= 1900;  ## year
#     $d[ 1 ]--;        ## month
    
    my $tz = pop( @d );
    unless( defined( $tz ) ) 
    {
        unless( defined( $tz = shift( @_ ) ) ) 
        {
        	try
        	{
        		my $dt = DateTime->new(
        			year => $d[0],
        			month => $d[1],
        			day => $d[2],
        			hour => $d[3],
        			minute => $d[4],
        			second => $d[5],
        		);
        		return( $dt );
        	}
        	catch( $e )
        	{
        		return( $self->error( "Unable to parse date string '$str': $e" ) );
        	}
        }
    }
    
    my $offset = 0;
    if( $GMT_ZONE->{ uc( $tz ) } ) 
    {
        ## offset already zero
    }
    elsif( $tz =~ /^([-+])?(\d\d?):?(\d{2})?$/ ) 
    {
        $offset = 3600 * $2;
        $offset += 60 * $3 if( $3 );
        $offset *= -1 if( $1 && $1 ne '-' );
    }
	elsif( $tz =~ /^(([\-\+])\d\d?)(\d{2})$/ ) 
	{
		my $v = $2 . $3;
		$offset = ( $1 * 3600 + $v * 60 );
	}
    else
    {
		try
		{
			my $dt = DateTime->now(
				year => $d[0],
				month => $d[1],
				day => $d[2],
				hour => $d[3],
				minute => $d[4],
				second => $d[5],
				time_zone => $tz
			);
			return( $dt );
		}
		catch( $e )
		{
			return( $self->error( "Unable to parse date string '$str' with time zone '$tz': $e" ) );
		}
    }
    
    ## $self->message( 3, "Generating a DateTime object." );
	try
	{
		my $dt = DateTime->new(
			year => $d[0],
			month => $d[1],
			day => $d[2],
			hour => $d[3],
			minute => $d[4],
			second => $d[5],
		);
		$dt->add( seconds => $offset );
		return( $dt );
	}
	catch( $e )
	{
		return( $self->error( "Unable to parse date string '$str': $e" ) );
	}
}

sub str2time
{
	my $self = shift( @_ );
	my $dt = $self->str2datetime( @_ );
	return if( !defined( $dt ) );
	return( $dt->epoch );
}

sub time2datetime
{
	my $self = shift( @_ );
    my $time = shift( @_ );
    $time = time() unless( defined( $time ) );
    ## We set the time zone to local, so that when we move it to GMT, it moves the time appropriately
    ## If we did not and now is 19:00 local time and the time zone is set to GMT and our local time zone is Tokyo (+9)
    ## then our datetime would inadvertently jumpt to 24:00 local time which would be the future.
    ## This is unfortunate and could create problem for setting cookies
    my $dt = DateTime->from_epoch( epoch => $time, time_zone => 'local' );
	$dt->set_formatter( $self );
	return( $dt );
}

sub time2str
{
	my $self = shift( @_ );
	my $dt = $self->time2datetime( @_ );
	$dt->set_formatter( $self );
	my $str = "$dt";
	return( $str );
}

1;

__END__

=encoding utf8

=head1 NAME

Net::API::REST::DateTime - HTTP DateTime Manipulation and Formatting

=head1 SYNOPSIS

	use Net::API::REST::DateTime;
	my $d = Net::API::REST::DateTime->new( debug => 3 );
	my $dt = DateTime->now;
	$dt->set_formatter( $d );
	print( "$dt\n" );
	## will produce
	Sun, 15 Dec 2019 15:32:12 GMT
	
	my( @parts ) = $d->parse_date( $date_string );
	
	my $datetime_object = $d->str2datetime( $date_string );
	$datetime_object->set_formatter( $d );
	my $timestamp_in_seconds = $d->str2time( $date_string );
	my $datetime_object = $d->time2datetime( $timestamp_in_seconds );
	my $datetime_string = $d->time2str( $timestamp_in_seconds );

=head1 VERSION

    v0.100.1

=head1 DESCRIPTION

This module contains methods to create and manipulate datetime representation from and to C<DateTime> object or unix timestamps.

When using it as a formatter to a C<DateTime> object, this will make sure it is properly formatted for its use in http headers and cookies.

=head1 METHODS

=head2 new( hash )

This initiates the package and take the following parameters:

=over 4

=item I<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=back

=head2 format_datetime( $date_time_object )

Provided a C<DateTime> object, this returns a http compliant string representation, such as:

	Sun, 15 Dec 2019 15:32:12 GMT

that can be used in http headers and cookies' expires property as per rfc6265.

=head2 parse_date( string )

Given a datetime string, this returns, in list context, a list of day, month, year, hour, minute, second and time zone or an iso 8601 datetime string in scalar context.

This is used by the method B<str2datetime>

=head2 str2datetime( string )

Given a string that looks like a date, this will parse it and return a C<DateTime> object.

=head2 str2time( string )

Given a string that looks like a date, this returns its representation as a unix timestamp in second since epoch.

In the background, it calls B<str2datetime> for parsing.

=head2 time2datetime( timestamp in seconds )

Given a unix timestamp in seconds since epoch, this returns a C<DateTime> object.

=head2 time2str( timestamp in seconds )

Given a unix timestamp in seconds since epoch, this returns a string representation of the timestamp suitable for http headers and cookies. The format is like C<Sat, 14 Dec 2019 22:12:30 GMT>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

https://git.deguest.jp/jack/Net-API-REST

=head1 SEE ALSO

C<DateTime>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
