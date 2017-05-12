# ABSTRACT: Simple syslog line parser

package Parse::Syslog::Line;

use warnings;
use strict;

use Carp;
use Const::Fast;
use DateTime;
use DateTime::Format::HTTP;
use DateTime::TimeZone;
use English qw/-no_match_vars/;
use Exporter;
use HTTP::Date qw/parse_date str2time/;
use Time::Moment;

our $VERSION = '3.6';

# Default for Handling Parsing
our $DateParsing     = 1;
our $DateTimeCreate  = 1;
our $EpochCreate     = 1;
our $NormalizeToUTC  = 0;
our $IgnoreTimeZones = 0;
our $ExtractProgram  = 1;
our $PruneRaw        = 0;
our $PruneEmpty      = 0;
our @PruneFields     = ();
our $FmtDate;


my %INT_PRIORITY = (
    'emerg'         => 0,
    'alert'         => 1,
    'crit'          => 2,
    'err'           => 3,
    'warn'          => 4,
    'notice'        => 5,
    'info'          => 6,
    'debug'         => 7,
);

my %INT_FACILITY = (
    #
    # POSIX Facilities
    'kern'          => 0 << 3,
    'user'          => 1 << 3,
    'mail'          => 2 << 3,
    'daemon'        => 3 << 3,
    'auth'          => 4 << 3,
    'syslog'        => 5 << 3,
    'lpr'           => 6 << 3,
    'news'          => 7 << 3,
    'uucp'          => 8 << 3,
    'cron'          => 9 << 3,
    'authpriv'      => 10 << 3,
    'ftp'           => 11 << 3,
    #
    # Local Reserved
    'local0'        => 16 << 3,
    'local1'        => 17 << 3,
    'local2'        => 18 << 3,
    'local3'        => 19 << 3,
    'local4'        => 20 << 3,
    'local5'        => 21 << 3,
    'local6'        => 22 << 3,
    'local7'        => 23 << 3,
    #
    # Apple Additions
    'netinfo'       => 12 << 3,
    'remoteauth'    => 13 << 3,
    'install'       => 14 << 3,
    'ras'           => 15 << 3,
    'launchd'       => 24 << 3,
);

const our %LOG_PRIORITY => (
    %INT_PRIORITY,
    reverse(%INT_PRIORITY),
);

const our %LOG_FACILITY => (
    %INT_FACILITY,
    reverse(%INT_FACILITY),
);

const our %CONV_MASK => (
    priority        => 0x07,
    facility        => 0x03f8,
);


our @ISA = qw(Exporter);
our @EXPORT = qw(parse_syslog_line);
our @EXPORT_OK = qw(
    parse_syslog_line
    preamble_priority preamble_facility
    %LOG_FACILITY %LOG_PRIORITY
    get_syslog_timezone set_syslog_timezone
    use_utc_syslog
);
our %EXPORT_TAGS = (
    constants       => [ qw( %LOG_FACILITY %LOG_PRIORITY ) ],
    preamble        => [ qw(preamble_priority preamble_facility) ],
    with_timezones  => [ qw(parse_syslog_line set_syslog_timezone get_syslog_timezone use_utc_syslog) ],
);

# Regex to Extract Data
const my %RE => (
    IPv4            => qr/(?:[0-9]{1,3}\.){3}[0-9]{1,3}/,
    preamble        => qr/^\<(\d+)\>/,
    year            => qr/^(\d{4}) /,
    date            => qr/^([a-zA-Z]{3}\s+[0-9]+\s+[0-9]{1,2}(?:\:[0-9]{2}){1,2})/,
    date_long => qr/^
            (?:[0-9]{4}\s+)?                # Year: Because, Cisco
            ([.*])?                         # Cisco adds a * for no ntp, and a . for configured but out of sync
            [a-zA-Z]{3}\s+[0-9]+            # Date: Jan  1
            (?:\s+[0-9]{4})?                # Year: Because, Cisco
            \s+                             # Date Separator: spaces
            [0-9]{1,2}(?:\:[0-9]{2}){1,2}   # Time: HH:MM or HH:MM:SS
            (?:\.[0-9]{3,6})?               # Time: .DDD(DDD) ms resolution
            (?:\s+[A-Z]{3,4})?              # Timezone, ZZZ or ZZZZ
            (?:\:?)                         # Cisco adds a : after the second timestamp
    /x,
    date_iso8601    => qr/^(
            [0-9]{4}(\-[0-9]{2}){2}         # Date YYYY-MM-DD
            (\s|T)                          # Date Separator T or ' '
            [0-9]{2}(\:[0-9]{2}){1,2}       # Time HH:MM:SS
            (?:\.(?:[0-9]{3}){1,2})?        # Time: .DDD millisecond or .DDDDDD microsecond resolution
            ([Zz]|[+\-][0-9]{2}\:[0-9]{2})  # UTC Offset +DD:MM or 'Z' indicating UTC-0
    )/x,
    host            => qr/^\s*([^:\s]+)\s+/,
    cisco_hates_you => qr/^\s*[0-9]*:\s+/,
    program_raw     => qr/^\s*([^\[][^:]+):\s*/,
    program_name    => qr/^([^\[\(\ ]+)/,
    program_sub     => qr/\(([^\)]+)\)/,
    program_pid     => qr/\[([^\]]+)\]/,
    program_netapp  => qr/\[([^\]]+)\]:\s*/,
);


my %_empty_msg = map { $_ => undef } qw(
    preamble priority priority_int facility facility_int
    datetime_raw date_raw date time datetime_str datetime_obj epoch
    host_raw host domain
    program_raw program_name program_pid program_sub
);


# Initialize syslog timezone
# It can be changed by set_syslog_timezone() later.
my $SYSLOG_TIMEZONE = 'local';

sub parse_syslog_line {
    my ($raw_string) = @_;

    # Initialize everything to undef
    my %msg =  $PruneEmpty ? () : %_empty_msg;
    $msg{message_raw} = $raw_string unless $PruneRaw;

    #
    # grab the preamble:
    if( $raw_string =~ s/$RE{preamble}//o ) {
        # Cast to integer
        $msg{preamble} = int $1;

        # Extract Integers
        $msg{priority_int} = $msg{preamble} & $CONV_MASK{priority};
        $msg{facility_int} = $msg{preamble} & $CONV_MASK{facility};

        # Lookups
        $msg{priority} = $LOG_PRIORITY{ $msg{priority_int} };
        $msg{facility} = $LOG_FACILITY{ $msg{facility_int} };
    }

    #
    # Handle Date/Time
    my $year;
    if( $raw_string =~ s/$RE{year}//o ) {
        $year = $1;
    }
    if( $raw_string =~ s/$RE{date}//o) {
        $msg{datetime_raw} = $1;
    }
    elsif( $raw_string =~ s/$RE{date_iso8601}//o) {
        $msg{datetime_raw} = $1;
    }
    if( exists $msg{datetime_raw} && length $msg{datetime_raw} ) {
        $msg{date_raw} = $msg{datetime_raw};

        if ( $DateParsing ) {

            # if User wants to fight with dates himself, let him :)
            if( $FmtDate && ref $FmtDate eq 'CODE' ) {
                @msg{qw(date time epoch datetime_str datetime_utc)} = $FmtDate->($msg{datetime_raw});
            }
            elsif( $DateTimeCreate ) {
                # We need DateTime to interpret missing timezone offsets taking DST into account
                my $dt = DateTime::Format::HTTP->parse_datetime(
                        $msg{datetime_raw} . (defined $year ? " $year" : ''),
                        $NormalizeToUTC
                            ? _get_timezone_from_cache(get_syslog_timezone())
                            : (),
                );

                my $tm;
                if ($NormalizeToUTC) {
                    eval {
                        $tm = Time::Moment->from_object($dt);
                    };

                    if (not $EVAL_ERROR) {

                        $msg{date}         = $tm->strftime("%F");
                        $msg{'time'}       = $tm->strftime("%T%f");
                        $msg{offset}       = $tm->strftime("%Z");
                        $msg{epoch}        = $tm->epoch;
                        $msg{datetime_str} = "$tm";
                        $msg{datetime_obj} = $tm;
                        $msg{datetime_utc} = '' . $tm->at_utc
                    }
                    else {
                        carp sprintf(qq/Error parsing "%s" - "%s"/, $msg{datetime_raw}, $EVAL_ERROR);
                        @msg{qw/date time epoch datetime_str datetime_utc datetime_obj/} = undef;
                    }
                } else {
                    $msg{date}         = $dt->ymd('-');
                    $msg{'time'}       = $dt->hms;
                    $msg{epoch}        = $dt->epoch if $EpochCreate;

                    $msg{datetime_obj} = $dt;
                    $msg{datetime_str} = $dt->ymd('-') . ' ' . $dt->hms;
                }
            }
            elsif ( $EpochCreate ) {
                $msg{epoch}        = HTTP::Date::str2time($msg{datetime_raw} . (defined $year ? " $year" : ''));
                $msg{datetime_str} = HTTP::Date::time2iso($msg{epoch});
            }
            elsif ( $IgnoreTimeZones ) {

                # qw/year month day hour minute second/;
                my @parsed = HTTP::Date::parse_date($msg{datetime_raw} . (defined $year ? " $year" : ''));

                # if raw string contained timezone, ignore it explicitly
                $msg{date}          = sprintf("%d-%02d-%02d", @parsed[0..2]);
                $msg{'time'}        = sprintf("%02d:%02d:%02d", @parsed[3..5]);
                $msg{datetime_str}  = sprintf("%s %s", $msg{date}, $msg{'time'});
            }
            elsif ($NormalizeToUTC) {

                my $tm;
                eval {
                    $tm = Time::Moment->from_string($msg{datetime_raw}, lenient => 1);
                };
                if (not $EVAL_ERROR) {
                    $tm->year($year) if defined $year;

                    $msg{date}         = $tm->strftime("%F");
                    $msg{'time'}       = $tm->strftime("%T%f");
                    $msg{offset}       = $tm->strftime("%Z");
                    $msg{epoch}        = $tm->epoch;
                    $msg{datetime_str} = "$tm";
                    $msg{datetime_obj} = $tm;
                    $msg{datetime_utc} = '' . $tm->at_utc
                }
                else {
                    carp sprintf(qq/Error parsing "%s" - "%s"/, $msg{datetime_raw}, $EVAL_ERROR);
                    @msg{qw/date time epoch datetime_str datetime_utc datetime_obj/} = undef;
                }
            }
        }
    }

    #
    # Host Information:
    if( $raw_string =~ s/$RE{host}//o ) {
        my $hostStr = $1;
        my($ip) = ($hostStr =~ /($RE{IPv4})/o);
        if( defined $ip && length $ip ) {
            $msg{host_raw} = $hostStr;
            $msg{host} = $ip;
        }
        elsif( length $hostStr ) {
            my ($host,$domain) = split /\./, $hostStr, 2;
            $msg{host_raw} = $hostStr;
            $msg{host} = $host;
            $msg{domain} = $domain;
        }
    }
    if( $raw_string =~ s/$RE{cisco_hates_you}//o ) {
        # Yes, Cisco adds a second timestamp to it's messages, because it hates you.
        if( $raw_string =~ s/$RE{date_long}//o ) {
            # Cisco encodes the status of NTP in the second datestamp, so let's pass it back
            if ( my $ntp = $1 ) {
                $msg{ntp} = $ntp eq '.' ? 'out of sync'
                          : $ntp eq '*' ? 'not configured'
                          : 'unknown';
            }
            else {
                $msg{ntp} = 'ok';
            }
        }
    }

    #
    # Parse the Program portion
    if( $ExtractProgram ) {
        if( $raw_string =~ s/$RE{program_raw}//o ) {
            $msg{program_raw} = $1;
            my $progStr = join ' ', grep {!exists $INT_PRIORITY{$_}} split /\s+/, $msg{program_raw};
            if( defined $progStr && length $progStr) {
                if( ($msg{program_name}) = ($progStr =~ /$RE{program_name}/o) ) {
                    if (length $msg{program_name} != length $msg{program_raw} ) {
                        (($msg{program_pid}) = ($progStr =~ /$RE{program_pid}/o))
                            || (($msg{program_sub}) = ($progStr =~ /$RE{program_sub}/o))
                    }
                }
            }
        }
        elsif( $raw_string =~ s/$RE{program_netapp}//o ) {
            # Check for a [host thing.subthing:level]: tag
            #          or [host:thing.subthing:level]: tag, Thanks NetApp.
            my $subStr = $1;
            $msg{program_raw} = qq{[$subStr]};
            my ($host,$program,$level) = split /[: ]+/, $subStr;
            $msg{program_name} = $program;
            if(!exists $msg{priority} && exists $LOG_PRIORITY{$level}) {
                $msg{priority} = $level;
                $msg{priority_int} = $LOG_PRIORITY{$level};
            }
            $raw_string =~ s/^[ :]+//;
        }
    }
    else {
        $raw_string =~ s/^\s+//;
    }

    # The left overs should be the message
    $msg{content} = $raw_string;
    chomp $msg{content};
    $msg{message} = defined $msg{program_raw} ? "$msg{program_raw}: $msg{content}" : $msg{content};

    if( $PruneRaw ) {
        delete $msg{$_} for grep { $_ =~ /_raw$/ } keys %msg;
    }
    if( $PruneEmpty ) {
        delete $msg{$_} for grep { !defined $msg{$_} } keys %msg;
    }
    if( @PruneFields ) {
        no warnings;
        delete $msg{$_} for @PruneFields;
    }

    #
    # Return our hash reference!
    return \%msg;
}


sub preamble_priority {
    my $preamble = int shift;

    my %hash = (
        preamble => $preamble,
    );

    $hash{as_int} = $preamble & $CONV_MASK{priority};
    $hash{as_text} = $LOG_PRIORITY{ $hash{as_int} };

    return \%hash;
}


sub preamble_facility {
    my $preamble = int shift;

    my %hash = (
        preamble => $preamble,
    );

    $hash{as_int} = $preamble & $CONV_MASK{facility};
    $hash{as_text} = $LOG_FACILITY{ $hash{as_int} };

    return \%hash;

}

# in    - timezone name (or offset from UTC), defaults to 'local' if no parameter is passed
# out   - DateTime::TimeZone object, also places a copy of the timezone in cache.
#
# NOTE: using offset (e.g. +01:00) instead of named timezone causes the parser to ignore Dayliving Saving Time
# and instead use the offset provided (when the offset is not present in the log file) - which is
# probably not what you want.
#
# NOTE: It automatically sets the DateTimeCreate and NormalizeToUTC variables for convenience. You can change them later
# if you wish to use the timezone in Epoch only  calculations, for example.
sub set_syslog_timezone {
    my ( $tz_name ) = @_;
    $SYSLOG_TIMEZONE = $tz_name // 'local';

    # ensure we're going the right path in that big "if tree"
    $DateTimeCreate = 1;
    $NormalizeToUTC = 1;

    return _get_timezone_from_cache($SYSLOG_TIMEZONE);
}

sub get_syslog_timezone {
    return $SYSLOG_TIMEZONE;
}

# timezone object cache
my %tz_cache;

# retrieves DateTime::TimeZone object of for a timezone $tz_name from cache.
# if not found, it will be instantiated and put in cache
sub _get_timezone_from_cache {
    my ($tz_name) = @_;

    $tz_name //= 'local';

    return $tz_cache{$tz_name} if ( exists $tz_cache{$tz_name} );
    $tz_cache{$tz_name} = DateTime::TimeZone->new(name => $tz_name);

    return $tz_cache{$tz_name};
}

# If you have a syslog which logs dates in UTC, then processing will be much, much faster
sub use_utc_syslog {

    set_syslog_timezone('UTC');
    $DateTimeCreate     = 0;
    $EpochCreate        = 0;
    $IgnoreTimeZones    = 0;
    $NormalizeToUTC     = 1;
    return;
}

1; # End of Parse::Syslog::Line

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Syslog::Line - Simple syslog line parser

=head1 VERSION

version 3.6

=head1 SYNOPSIS

I wanted a very simple log parser for network based syslog input.
Nothing existed that simply took a line and returned a hash ref all
parsed out.

    use Parse::Syslog::Line qw(parse_syslog_line);

    $Parse::Syslog::Line::DateTimeCreate = 1;

    my $href = parse_syslog_line( $msg );
    #
    # $href = {
    #       preamble        => '13',
    #       priority        => 'notice',
    #       priority_int    => 5,
    #       facility        => 'user',
    #       facility_int    => 8,
    #       date            => 'YYYY-MM-DD',
    #       time            => 'HH::MM:SS',
    #       epoch           => 1361095933,
    #       datetime_str    => 'YYYY-MM-DD HH:MM:SS',
    #       datetime_obj    => new C<DateTime()> or C<Time::Moment> object, depending on the NormalizeToUTC switch
    #       datetime_utc    => ISO 8601 UTC datetime # If $NormalizeToUTC or returned by FmtDate formatter
    #       datetime_raw    => 'Feb 17 11:12:13'
    #       date_raw        => 'Feb 17 11:12:13'
    #       host_raw        => 'hostname',  # Hostname as it appeared in the message
    #       host            => 'hostname',  # Hostname without domain
    #       domain          => 'blah.com',  # if provided
    #       program_raw     => 'sshd(blah)[pid]',
    #       program_name    => 'sshd',
    #       program_sub     => 'pam_unix',
    #       program_pid     => 20345,
    #       content         => 'the rest of the message'
    #       message         => 'program[pid]: the rest of the message',
    #       message_raw     => 'The message as it was passed',
    #       ntp             => 'ok',           # Only set for Cisco messages
    # };
    ...

=head1 EXPORT

Exported by default:
       parse_syslog_line( $one_line_of_syslog_message );

Optional Exports:
  :preamble
       preamble_priority
       preamble_facility

  :constants
       %LOG_FACILITY
       %LOG_PRIORITY

  :with_timezones
       set_syslog_timezone
       get_syslog_timezone
       use_utc_syslog

=head1 VARIABLES

=head2 ExtractProgram

If this variable is set to 1 (the default), parse_syslog_line() will try it's
best to extract a "program" field from the input.  This is the most expensive
set of regex in the module, so if you don't need that pre-parsed, you can speed
the module up significantly by setting this variable.

Vendors who do proprietary non-sense with their syslog formats are to blame for
this setting.

Usage:

  $Parse::Syslog::Line::ExtractProgram = 0;

=head2 DateParsing

If this variable is set to 0 raw date will not be parsed further into components (datetime_str date time epoch).
Default is 1 (parsing enabled).

Usage:

  $Parse::Syslog::Line::DateParsing = 0;

=head2 DateTimeCreate

If this variable is set to 1 (the default), a DateTime object will be returned in the
$m->{datetime_obj} field.  Otherwise, this will be skipped.

NOTE: DateTime timezone calculation is fairly slow. Unless you really need to
take timezones into account, you're better off using other modes (below).

Usage:

  $Parse::Syslog::Line::DateTimeCreate = 0;

=head2 EpochCreate

If this variable is set to 1, the number of seconds from UNIX epoch
will be returned in the $m->{epoch} field.  If DateTimeCreate is
not set, the parser will use C<HTTP::Date> to perform the parsing.
This is faster but assumes B<local> timezone if its not present in parsed string.
In other words it ignores the timezone you set for syslog with set_syslog_timezone.

Usage:

  $Parse::Syslog::Line::EpochCreate = 1;

=head2 NormalizeToUTC

Coerces dates to ISO8601 format, using C<Time::Moment>. There are two possible modes of operation:

=head3 If your syslog does not have UTC ISO 8601 timestamps

Using costly C<DateTime> math we calculate the UTC version of the incomplete date for a given timezone
and then parse the resulting C<DateTime> object using C<Time::Moment>.

Usage:
  $Parse::Syslog::Line::DateTimeCreate  = 1; # default
  $Parse::Syslog::Line::NormalizeToUTC  = 1;

See also: set_syslog_timezone.

=head3 If your syslog timestamps are ISO 8601 compliant

This allows us to skip costly datetime DST calculations, and is very fast.
You get the same amount of date information as with the defaults.

Usage:
  $Parse::Syslog::Line::DateTimeCreate  = 0;
  $Parse::Syslog::Line::EpochCreate     = 0;
  $Parse::Syslog::Line::IgnoreTimeZones = 0;
  $Parse::Syslog::Line::NormalizeToUTC  = 1;

  # or

  use Parse::Syslog::Line qw/:with_timezones/;
  use_utc_syslog(); # sets syslog_timezone to 'UTC' and above variables

See also: set_syslog_timezone()

=head2 IgnoreTimeZones

Similarly to EpochCreate, parser will use C<HTTP::Date> to perform the parsing, but this time using "parse_date"
function. We then discard the timezone part from created dates. Even if the timezone is present in the message
it will not be used to construct the date string and components (date, time, datetime_str).

=head2 FmtDate

You can pass your own formatter/parser here. Given a raw datetime string it should output a list
containing date, time, epoch, datetime_str, datetime_utc in your wanted format.
NOTE: No further date processing will be done, you're on your own here.

=head2 PruneRaw

This variable defaults to 0, set to 1 to delete all keys in the return hash ending in "_raw"

Usage:

  $Parse::Syslog::Line::PruneRaw = 1;

=head2 PruneEmpty

This variable defaults to 0, set to 1 to delete all keys in the return hash which are undefined.

Usage:

  $Parse::Syslog::Line::PruneEmpty = 1;

=head2 PruneFields

This should be an array of fields you'd like to be removed from the hash reference.

Usage:

  @Parse::Syslog::Line::PruneFields = qw(date_raw facility_int priority_int);

=head1 FUNCTIONS

=head2 parse_syslog_line

Returns a hash reference of syslog message parsed data.

=head2 set_syslog_timezone($timezone_name)

Sets a timezone $timezone_name for parsed messages. This timezone will be used to calculate offset from UTC
if a timezone designation is not present in the message being parsed. Returns the C<DateTime::TimeZone>.
object for given timezone. If called without parameters, assumes local timezone.

NOTE: this works in conjunction with $NormalizeToUTC and automagically sets:
    $NormalizeToUTC=1
    $DateTimeCreate=1

See also $NormalizeToUTC

=head2 get_syslog_timezone

Returns the name of the timezone currently set by set_syslog_timezone.

=head2 use_utc_syslog

A convenient function which sets the syslog timezone to UTC and sets the config variables accordingly.
NOTE: by using this you promise the parser that it will get ISO8601 compliant dates. If a date is
unparsable the parser will emit a warning and set all date fields to undef.

=head2 preamble_priority

Takes the Integer portion of the syslog messsage and returns
a hash reference as such:

    $prioRef = {
        'preamble'  => 13
        'as_text'   => 'notice',
        'as_int'    => 5,
    };

=head2 preamble_facility

Takes the Integer portion of the syslog messsage and returns
a hash reference as such:

    $facRef = {
        'preamble'  => 13
        'as_text'   => 'user',
        'as_int'    => 8,
    };

=head1 DEVELOPMENT

This module is developed with Dist::Zilla.  To build from the repository, use Dist::Zilla:

    dzil authordeps |cpanm
    dzil build
    dzil test

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 CONTRIBUTORS

=for stopwords Bartłomiej Fulanty Csillag Tamas Keedi Kim Mateu X Hunter Neil Bowers Shawn Wilson Tomohiro Hosaka

=over 4

=item *

Bartłomiej Fulanty <starlight@cpan.org>

=item *

Csillag Tamas <cstamas@digitus.itk.ppke.hu>

=item *

Keedi Kim <keedi.k@gmail.com>

=item *

Mateu X Hunter <mhunter@maxmind.com>

=item *

Neil Bowers <neil@bowers.com>

=item *

Shawn Wilson <swilson@korelogic.com>

=item *

Tomohiro Hosaka <bokutin@bokut.in>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Parse-Syslog-Line>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Syslog-Line>

=back

=head2 Source Code

This module's source code is available by visiting:
L<https://github.com/reyjrar/Parse-Syslog-Line>

=cut
