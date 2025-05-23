# ABSTRACT: Simple syslog line parser

package Parse::Syslog::Line;

use v5.16;
use warnings;

use Carp;
use Const::Fast;
use English qw(-no_match_vars);
use Exporter;
use Hash::Merge::Simple qw( dclone_merge );
use JSON::MaybeXS       qw( decode_json );
use Module::Load        qw( load );
use Module::Loaded      qw( is_loaded );
use POSIX               qw( strftime tzset );
use Ref::Util           qw( is_arrayref );
use Time::Moment;
# RECOMMEND PREREQ: Cpanel::JSON::XS

our $VERSION = '6.2';

# Default for Handling Parsing
our $DateParsing     = 1;
our $EpochCreate     = 1;

our $ExtractProgram      = 1;
our $AutoDetectJSON      = 0;
our $AutoDetectKeyValues = 0;
our $PruneRaw            = 0;
our $PruneEmpty          = 0;
our @PruneFields         = ();
our $FmtDate;
our $TimeMomentFormatString = "%FT%T%f%z";

# RFC-5424 Parsing
our $RFC5424StructuredData       = 1;
our $RFC5424StructuredDataStrict = 0;

# DEPRECATED Settings
our $DateTimeCreate;
our $HiResFmt;
our $OutputTimeZone;
our $NormalizeToUTC;


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
our @EXPORT = qw(parse_syslog_line psl_enable_sdata);
our @EXPORT_OK = qw(
    parse_syslog_line
    parse_syslog_lines
    psl_enable_sdata
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
    IPv4            => qr/(?>(?:[0-9]{1,3}\.){3}[0-9]{1,3})/,
    preamble        => qr/^\<(\d+)\>(\d{0,2}(?=\s))?\s*/,
    date_named_capture => qr/
            (?:(?<year>\d{4})\s)?             # Option Year: YYYY
            (?<date>                          # Whole String
                (?<month>[A-Za-z]{3})         # Month: Mmm
                \s+
                (?<day>[0-9]+)                # Day: DD
                \s+
                (?<hour>[0-9]{1,2})
                    :(?<minute>[0-9]{2})
                    :(?<second>[0-9]{2})
                (?:\.                         # Time: .DDD millisecond or .DDDDDD microsecond resolution
                    (?<highprecision>(?:[0-9]{3}){1,2})
                )?
            )
    /x,
    date => qr/
            (?:(\d{4})\s)?          # Option Year: YYYY --> 1
            (                       # Whole String -------> 2
                ([A-Za-z]{3})       # Month: Mmm   -------> 3
                \s+
                ([0-9]+)            # Day: DD ------------> 4
                \s+
                ([0-9]{1,2})        # Hour: HH -----------> 5
                    :([0-9]{2})     # Minute: MM ---------> 6
                    :([0-9]{2})     # Second: SS ---------> 7
                (?:\.               # Time: .DDD millisecond or .DDDDDD microsecond resolution
                    ((?:[0-9]{3}){1,2}) # Highprecision --> 8
                )?
            )
    /x,
    date_long => qr/
            (?:[0-9]{4}\s+)?           # Year: Because, Cisco
            ([.*])?                         # Cisco adds a * for no ntp, and a . for configured but out of sync
            [a-zA-Z]{3}\s+[0-9]+            # Date: Jan  1
            (?:\s+[0-9]{4})?                # Year: Because, Cisco
            \s+                             # Date Separator: spaces
            [0-9]{1,2}(?:\:[0-9]{2}){1,2}   # Time: HH:MM or HH:MM:SS
            (?:\.[0-9]{3,6})?               # Time: .DDD(DDD) ms resolution
            (?:\s+[A-Z]{3,4})?              # Timezone, ZZZ or ZZZZ
            (?:\:?)                         # Cisco adds a : after the second timestamp
    /x,
    date_iso8601 => qr/(
            [0-9]{4}-[0-9]{2}-[0-9]{2}      # Date: YYYY-MM-DD
            (?:\s|T)                        # Separato: T or ' '
            [0-9]{2}:[0-9]{2}:[0-9]{2}      # Time: HH:MM:SS
            \S*                             # Grab the rest since this looks like a date
    )/x,
    date_iso8601_capture => qr/(?<date>
            (?<year>[0-9]{4})                # Date: YYYY-MM-DD
               -(?<month>[0-9]{2})
               -(?<day>[0-9]{2})
            (?:\s|T)                         # Separato: T or ' '
            (?<hour>[0-9]{2})                # Time: HH:MM:SS
               :(?<minute>[0-9]{2})
               :(?<second>[0-9]{2})
            (?:\.                            # Time: .DDD millisecond or .DDDDDD microsecond resolution
                (?<highprecision>(?:[0-9]{3}){1,2})
            )?
            (?<offset>[Zz]|                  # UTC Offset +DD:MM or 'Z' indicating UTC-0
                (?<offset_sign>[+\-])
                (?<offset_hours>[0-9]{2})
                \:
                (?<offset_minutes>[0-9]{2})
            )
    )/x,
    host            => qr/\s*([^:\s]+)\s+/,
    cisco_detection => qr/\s*[0-9]*:\s+/,
    program_raw     => qr/\s*([^\[][^:]+)(:|\s-)\s+/,
    program_name    => qr/(.[^\[\(\ ]*)(.*)/,
    program_sub     => qr/(?>\(([^\)]+)\))/,
    program_pid     => qr/(?>\[([^\]]+)\])/,
    program_netapp  => qr/(?>\[([^\]]+)\]:\s*)/,
    kvdata          => qr/
            (?:^|\b)                            # Start from beginning or a word boundary
            \K                                  # Keep everything to the left, don't include in $&
            (?>                                 # Start atomic match, ie, disable back tracking
                ([a-zA-Z\.0-9\-_@]+)            # An "SDID", ie "\w" plus '.' and '-'
            )                                   # RETURN: Key
            =                                   # Literal '='
            (
                \S+                             # Any non-space string
                (?:\s+\S+)                      # Clustering, non-grouping, space followed by one or more strings
                    *?                          # Not greedy
            )                                   # RETURN: Value, could be one word, or several
            (?=                                 # Zero width positive look-ahead
                (?:                             # Clustering, non-grouping group one of:
                    \s*[,;(\[]                  #   Space, comma, semicolon, open bracket or paren
                    |$                          #   End of string
                    |\s+[a-zA-Z\.0-9\-_]+=      #   A word, followed by an equal sign
                )
            )
    /x,
    rfc_sdata_extract => qr/
            (?>                             # Disable backtracking since it won't help us
                (?:^|\s)
                \[
                        (?!                 # Zero width negative look ahead
                            [^=]+           # A string that doesn't contain '='
                            \]              # followed by a ]
                        )
                        ([^\]]+)            # RETURN: all non] characters
                \]
            )
    /x,
    rfc_sdata_strict => qr/
        ^
        (?>
            \[
                (
                    (?:
                        (?:timeQuality|origin|meta)
                            |(?:[a-zA-Z0-9\.\-]+@[0-9]+)
                    )
                    (?:
                        \s
                        [a-zA-Z0-9\.\-]+="(?:[^"\\]++|\\.)*+"
                    )+
                )
            \]
        )
    /x,
    sysword      => qr/[a-zA-Z0-9\.\-]+/,
    quotedstring => qr/"(?:[^"\\]++|\\.)*+"/,
);

# For Date Translations
my @MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my %MoY;
@MoY{@MoY} = 0..11;



my $SYSLOG_TIMEZONE = '';

sub parse_syslog_line {
    my ($raw_string) = @_;

    # State Variables
    state $DateTimeTried = 0;
    state $CpanelJSONXSWarning = 0;
    state $DisableWarnings = $ENV{PARSE_SYSLOG_LINE_QUIET} || $ENV{TEST_ACTIVE} || $ENV{TEST2_ACTIVE};

    # Initialize everything to undef
    my %msg =  ();
    $msg{message_raw} = $raw_string unless $PruneRaw;

    # Lines that begin with a space aren't syslog messages, skip
    return \%msg if $raw_string =~ /^\s/;

    # grab the preamble:
    if( $raw_string =~ s/^$RE{preamble}//o ) {
        # Cast to integer
        $msg{preamble} = int $1;
        $msg{version}  = int $2 if $2;

        # Extract Integers
        $msg{priority_int} = $msg{preamble} & $CONV_MASK{priority};
        $msg{facility_int} = $msg{preamble} & $CONV_MASK{facility};

        # Lookups
        $msg{priority} = $LOG_PRIORITY{ $msg{priority_int} };
        $msg{facility} = $LOG_FACILITY{ $msg{facility_int} };
    }

    #
    # Handle Date/Time
    my %date = ();
    if( $raw_string =~ s/^$RE{date}//o) {
        # Positional
        $msg{datetime_raw} = $2;
        $msg{datetime_raw} .= " $1" if $1;
        # Copy into the date hash
        %date = (
            year          => $1,
            date          => $2,
            month         => $3,
            day           => $4,
            hour          => $5,
            minute        => $6,
            second        => $7,
            highprecision => $8,
        );
        $date{month_abbr} = 1;
    }
    elsif( $raw_string =~ s/^$RE{date_iso8601}//o) {
        $msg{datetime_raw} = $1;
    }

    # Handle Date Parsing
    if( exists $msg{datetime_raw} && length $msg{datetime_raw} ) {
        if ( $DateParsing ) {
            # if User wants to fight with dates themselves, let them :)
            if( $FmtDate && ref $FmtDate eq 'CODE' ) {
                @msg{qw(date time epoch datetime_str)} = $FmtDate->($msg{datetime_raw});
            }
            elsif ( $msg{datetime_raw} ) {
                my $tm;
                if ( %date ) {
                    delete $date{date};
                    if ( delete $date{month_abbr} ) {
                        $date{month} = $MoY{$date{month}} + 1;
                    }
                    if ( my $offset = delete $date{offset} ) {
                        if ( $offset eq 'Z' ) {
                            $date{offset} = 0;
                        }
                        else {
                            my $sign = delete $date{offset_sign};
                            my $hours = delete $date{offset_hours};
                            my $minutes = delete $date{offset_minutes};
                            $date{offset} = ($sign eq '-' ? -1 : 1)
                                            * (( $hours * 60 ) + $minutes);
                        }
                    }
                    else {
                        $date{offset} = Time::Moment->now()->offset;
                    }
                    if( my $hp = delete $date{highprecision} ) {
                        my $len = length($hp);
                        my $v   = $len <= 3 ? $hp * 1_000_000
                                : $len <= 6 ? $hp * 1_000
                                : $len <= 9 ? $hp
                                : 0;
                        $date{nanosecond} = $v if $v
                    }
                    my $has_year = length $date{year};
                    if ( !$has_year ) {
                        $date{year} = 1900 + (localtime)[5];
                    }
                    $tm = eval { Time::Moment->new(%date) };
                    if ( defined $tm ) {
                        # Check that the timestamp isn't more than 1 day in the future
                        $tm = Time::Moment->new(%date, year => $date{year} - 1)
                            if !$has_year && $tm->epoch > (time + 86400);
                    }
                }
                else {
                    $tm = eval { Time::Moment->from_string($msg{datetime_raw}, lenient => 1) };
                }
                my $ltm = Time::Moment->now();
                $tm ||= $ltm;

                # HiRes Epoch
                $msg{epoch} = $tm->strftime("%s%f");
                # ISO8601 Timestamps
                $msg{datetime_utc}   = $tm->with_offset_same_instant(0)->strftime($TimeMomentFormatString) =~ s/\+00:?00$/Z/r;
                $msg{datetime_local} = $tm->with_offset_same_instant($ltm->offset)->strftime($TimeMomentFormatString) =~ s/\+00:?00$/Z/r;
                $msg{datetime_str}   = $tm->strftime($TimeMomentFormatString) =~ s/\+00:?00$/Z/r;
                $msg{tz}             = $tm->strftime('%z') =~ s/\+00:?00/Z/r;
            }

            if ( $msg{datetime_str} ) {
                # Split this up into parts
                my @parts    = split /[ T]/, $msg{datetime_str};
                $msg{date}   = $parts[0];
                $msg{time}   = (split /[+\-Z]/, $parts[1])[0];

                # Debugging for my sanity
                printf("TZ=%s Parsed: %s to [%s] %s D:%s T:%s O:%s\n",
                    $SYSLOG_TIMEZONE,
                    @msg{qw(datetime_raw epoch datetime_str date time tz)},
                ) if $ENV{PARSE_SYSLOG_LINE_DEBUG};
            }
        }
    }

    #
    # Host Information:
    if( $raw_string =~ s/^$RE{host}//o ) {
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
    # Check for relayed logs, grab the origin
    while( $raw_string =~ /^(?:\s*[0-9]+\s+)?$RE{date_iso8601}\s+$RE{host}/go ) {
        $msg{origin} = $2;
        $msg{origin_date} = $1;
        $raw_string = substr($raw_string,pos($raw_string));
    }

    # Find weird cisco dates
    if( $raw_string =~ s/^$RE{cisco_detection}//o ) {
        # Yes, Cisco adds a second timestamp to it's messages, because ...
        if( $raw_string =~ s/^$RE{date_long}//o ) {
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
    my $progsep = ':';
    if( $ExtractProgram ) {
        if( $raw_string =~ s/^$RE{program_raw}//o ) {
            $msg{program_raw} = $1;
            $progsep = $2 || '';
            my $progStr = join ' ', grep {!exists $INT_PRIORITY{$_}} split /\s+/, $msg{program_raw};
            if( $progStr =~ /^$RE{program_name}/o ) {
                $msg{program_name} = $1;
                my $remainder      = $2;
                if ( $remainder ) {
                    ($msg{program_pid}) = ($remainder =~ /$RE{program_pid}/o);
                    ($msg{program_sub}) = ($remainder =~ /$RE{program_sub}/o);
                    if( !$msg{program_sub}  ) {
                        ($msg{program_sub}) = ($remainder =~ /^(?:[\/\s])?([^\[(]+)/o);
                    }
                }
                if( $msg{program_name} !~ m{^/} && $msg{program_name} =~ tr{/}{} ) {
                    @msg{qw(program_name program_sub)} = split m{/}, $msg{program_name}, 2;
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
    $msg{message} = defined $msg{program_raw} ? "$msg{program_raw}$progsep $msg{content}" : $msg{content};

    # Extract RFC Structured Data
    if( $RFC5424StructuredDataStrict ) {
        while ( $msg{content} =~ s/$RE{rfc_sdata_strict}//o ) {
            my $rfc_sdata = $1;
            my ($sdid,$sdata) = split /\s+/, $rfc_sdata, 2;
            foreach my $token ( $sdata =~ /($RE{sysword}=$RE{quotedstring})/og ) {
                my ($k,$v) = split /=/, $token, 2;
                next unless length $v;
                # Trim off the quotes
                $v = substr($v, 1, length($v) - 2);
                $msg{SDATA}{$sdid}{$k} = $v;
            }
        }
        $msg{content} =~ s/^\s+//;
    }
    elsif ( $RFC5424StructuredData ) {
        while ( $msg{content} =~ s/$RE{rfc_sdata_extract}//o ) {
            my $rfc_sdata = $1;
            my ($group) = $rfc_sdata =~ s/^([^\s=]+)\s// ? $1 : undef;
            foreach my $token ( $rfc_sdata =~ /($RE{sysword}=(?:$RE{quotedstring}|\S+))/og ) {
                my ($k,$v) = split /=/, $token, 2;
                next unless length $v;
                # Trim off the quotes
                $v =~ s/(?:^")|(?:"$)//g;
                if( $group ) {
                    $msg{SDATA}{$group}{$k} = $v;
                } else {
                    $msg{SDATA}{$k} = $v;
                }
            }
            # When we parse without ExtractProgram, shit gets weird.
            #   We need to restore the first space between the first semi-colon
            #   and the rest of the string
            $msg{content} =~ s/:\s*/: / if $msg{SDATA};
        }
        $msg{content} =~ s/^\s+// if $msg{SDATA};
    }

    if( $AutoDetectJSON && (my $pos = index($msg{content},'{')) >= 0 ) {
        if( !$CpanelJSONXSWarning && !is_loaded('Cpanel::JSON::XS') ) {
            warn "When using AutoDetectJSON, we recommend Cpanel::JSON::XS for performance and compatibility"
                unless $DisableWarnings;
            $CpanelJSONXSWarning = 1;
        }
        eval {
            my $json = decode_json(substr($msg{content},$pos));
            $msg{SDATA} = $msg{SDATA} ? dclone_merge($json,$msg{SDATA}) : $json;
            1;
        } or do {
            my $err = $@;
            $msg{_json_error} = sprintf "Failed to decode json: %s", $err;
        };
    }
    if( $AutoDetectKeyValues && $msg{content} =~ /(?:^|\s)[a-zA-Z\.0-9\-_]+=\S+/ ) {
        my %sdata = ();
        while( $msg{content} =~ /$RE{kvdata}/og ) {
            my ($k,$v) = ($1,$2);
            # Remove Trailing Characters
            $v =~ s/[)\]>,;'"]+$//;
            # Remove Leading Characters
            $v =~ s/^[(\[<'"]+//;
            if( exists $sdata{$k} ) {
                if( is_arrayref($sdata{$k}) ) {
                    push @{ $sdata{$k} }, $v;
                }
                else {
                    # Auto Promote to an Array Ref
                    $sdata{$k} = [ $sdata{$k}, $v ];
                }
            }
            else {
                $sdata{$k} = $v;
            }
        }
        if ( %sdata ) {
            $msg{SDATA} = $msg{SDATA} ? dclone_merge(\%sdata,$msg{SDATA}) : \%sdata;
        }
    }

    if( $PruneRaw ) {
        delete $msg{$_} for grep { $_ =~ /_raw$/ } keys %msg;
    }
    if( $PruneEmpty ) {
        delete $msg{$_} for grep { !length $msg{$_} } keys %msg;
    }
    if( @PruneFields ) {
        no warnings;
        delete $msg{$_} for @PruneFields;
    }
    delete $msg{epoch} if exists $msg{epoch} and !$EpochCreate;

    #
    # Return our hash reference!
    return \%msg;
}


{
    my $buffer = '';
    sub parse_syslog_lines {
        my @lines = map { split /\r?\n/, $_ } grep { defined } @_;
        my @structured = ();
        if( @lines ) {
            while( my $line = shift @lines ) {
                if( $line =~ /^\s/ ) {
                    $buffer .= "\n" . $line;
                    next;
                }
                else {
                    push @structured, parse_syslog_line($buffer);
                    $buffer = $line;
                }
            }
        }
        else {
            # grab the remaining buffer
            push @structured, parse_syslog_line($buffer)
                if length $buffer;
            $buffer = '';
        }
        return @structured;
    }

}


sub psl_enable_sdata {
    $AutoDetectJSON        = 1;
    $AutoDetectKeyValues   = 1;
    $RFC5424StructuredData = 1;
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

sub set_syslog_timezone {
    my ( $tz_name ) = @_;

    if( defined $tz_name && length $tz_name ) {
        $ENV{TZ} = $SYSLOG_TIMEZONE = $tz_name;
        tzset();
    }

    return $SYSLOG_TIMEZONE;
}

sub get_syslog_timezone {
    return $SYSLOG_TIMEZONE;
}

# If you have a syslog which logs dates in UTC, then processing will be much, much faster
sub use_utc_syslog {
    set_syslog_timezone('UTC');
    return;
}

1; # End of Parse::Syslog::Line

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Syslog::Line - Simple syslog line parser

=head1 VERSION

version 6.2

=head1 SYNOPSIS

I wanted a very simple log parser for network based syslog input.
Nothing existed that simply took a line and returned a hash ref all
parsed out.

    use Parse::Syslog::Line qw(parse_syslog_line);

    $Parse::Syslog::Line::AutoDetectJSON = 1;
    $Parse::Syslog::Line::AutoDetectKeyValues = 1;

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
    #       datetime_local  => ISO 8601 datetime, in local timezone (potentially buggy)
    #       datetime_str    => ISO 8601 datetime, in message timezone
    #       datetime_utc    => ISO 8601 datetime, in UTC
    #       datetime_raw    => 'Feb 17 11:12:13'
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
    #       ntp             => 'ok',        # Only set for Cisco messages
    #       version         => 1,
    #       SDATA           => { ... },     # RFC Structured data, decoded JSON, or K/V Pairs in the message
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

If this variable is set to 0 raw date will not be parsed further into
components (datetime_str date time epoch).  Default is 1 (parsing enabled).

Usage:

  $Parse::Syslog::Line::DateParsing = 0;

=head2 TimeMomentFormatString

This defaults to C<"%FT%T%f%z">. See L<Time::Moment/"EXAMPLE FORMAT STRINGS"> for syntax and usage.

=head2 EpochCreate

If this variable is set to 1, the default, the number of seconds from UNIX
epoch will be returned in the $m->{epoch} field.  Setting this to false will
only delete the epoch before returning the hash reference.

=head2 FmtDate

You can pass your own formatter/parser here. Given a raw datetime string it
should output a list containing date, time, epoch, datetime_str,
in your wanted format.

    use Parse::Syslog::Line;

    local $Parse::Syslog::Line::FmtDate = sub {
        my ($raw_datestr) = @_;
        my @elements = (
            #date
            #time
            #epoch
            #datetime_str
        );
        return @elements;
    };

B<NOTE>: No further date processing will be done, you're on your own here.

=head2 AutoDetectJSON

Default is false.  If true, we'll autodetect the presence of JSON in the syslog
message and use L<JSON::MaybeXS> to decode it.  The detection/decoding is
simple.  If a '{' is detected, everything until the end of the message is
assumed to be JSON.  The decoded JSON will be added to the C<SDATA> field.

    $Parse::Syslog::Line::AutoDetectJSON = 1;

=head2 AutoDetectKeyValues

Default is false.  If true, we'll autodetect the presence of Splunk style
key/value pairds in the message stream.  That format is C<k1=v1, k2=v2>.
Resulting K/V pairs will be added to the C<SDATA> field.

    $Parse::Syslog::Line::AutoDetectKeyValues = 1;

=head2 RFC5424StructuredData

Default is true.  When enabled, this will extract the RFC standard structured data
from the message content.  That content will be stripped from the message
C<content> field.

Some examples:

    # Input
    [foo x=1] some words [bar x=2]

    # To (YAML for brevity)
    ---
    SDATA:
      bar:
        x: 2
      foo:
        x: 1
    content: some words

    # Input
    [x=1] some words

    # To (YAML for brevity)
    ---
    SDATA:
      x: 1
    content: some words

To disable:

    $Parse::Syslog::Line::RFC5424StructuredData = 0;

=head2 RFC5424StructuredDataStrict

Require the format:

    [namespace@id property="value"][namespace@id property="value"]

Defaults to 0, set to 1 to only parse the RFC5424 formatted structured data.

=head2 PruneRaw

This variable defaults to 0, set to 1 to delete all keys in the return hash
ending in "_raw"

Usage:

  $Parse::Syslog::Line::PruneRaw = 1;

=head2 PruneEmpty

This variable defaults to 0, set to 1 to delete all keys in the return hash
which are undefined.

Usage:

  $Parse::Syslog::Line::PruneEmpty = 1;

=head2 PruneFields

This should be an array of fields you'd like to be removed from the hash reference.

Usage:

  @Parse::Syslog::Line::PruneFields = qw(facility_int priority_int);

=head1 FUNCTIONS

=head2 parse_syslog_line

Returns a hash reference of syslog message parsed data.

B<NOTE>: Date/time parsing is hard.  This module has been optimized to balance
common sense and processing speed. Care is taken to ensure that any data input
into the system isn't lost, but with the varieties of vendor and admin crafted
date formats, we don't always get it right.  Feel free to override date
processing using by setting the C<$FmtDate> variable or completely disable it with
C<$DateParsing> set to 0.

=head3 Dates and Version 6+

As of version C<6.0> and later, the date parsing is handled by L<Time::Moment>.
Ideally, I would use L<Date> for performance reasons, but it requires some
heavy XS toolkits to build which don't work on my MacBookPro out of the box.
This made the decision to use C<Time::Moment> kinda automatic. If you are
B<seriously> concerned with performance, enough to figure out how to package
and run L<Date> successfully, you can use the C<$FmtDate> parameter to inject
your own date processing logic.

C<Time::Moment>'s API and known limitations informed updates to the API and output of dates
in this module. It is drastic enough a shift to warrant a major version bump.

L<Time::Moment/"The Effect of Daylight Saving Time"> explains that to properly
convert times during DST transitions, things get messy. This caused issues in testing
and warrants words of caution here, B<ALWAYS> use C<datetime_utc> or C<epoch>
fields for datetime portability.

The changes to the API and fields returned are as follows:

=over 2

=item B<API Changes>

=over 2

=item C<DateTimeCreate> is B<deprecated>

L<DateTime> is slow and memory heavy. I never should've added support for it in
this module.  This release removes it. If you need L<DateTime> objects, you'll
need to build it yourself.

=item C<HiResFmt> is B<deprecated>, use C<TimeMomentFormatString>

=item C<NormalizeToUTC> is B<deprecated>, every log now returns C<datetime_utc>

=item C<OutputTimeZone> is B<deprecated>, use C<TimeMomentFormatString>

=back

=item B<Field Changes>

=over 2

=item C<datetime_utc>

Present in every document, use this for portability.

=item C<datetime_str>

Now represents the parsed datetime as from the log without modifying the timezone.

=item C<datetime_local>

Attempts to represent the datetime in the timezone local to the program. This
is prone to errors around DST, I don't advise using this, but it's
provided as footgun for future generations.

=item C<offset> renamed to C<tz>

=back

=back

=head3 Fields Returned

=over 2

=item B<preamble>

Syslog preamble without the brackets, i.e., C<13>.

=item B<priority>

String representation of the priority, i.e., C<"warn">

=item B<priority_int>

Integer representation of the priority, i.e., C<1>

=item B<facility>

String representation of the facility, i.e., C<"daemon">

=item B<priority_int>

Integer representation of the facility, i.e., C<1>

=item B<datetime_raw>

The datetime string from the log as it was discovered

=item B<epoch>

Numeric representation of the UNIX time as parsed by the C<datetime_str>. This
is the most portable format for computers and I recommend using it, and only it
for passing onto to computer systems.

=item B<datetime_utc>

UTC representation of the C<datetime_raw> in ISO8601 format (via
C<TimeMomentFormatString>). If you must use a string format, this is the one
you should pass to other computers.

=item B<datetime_str>

ISO8601 representation of the C<datetime_raw> (via C<TimeMomentFormatString>),
without manipulating timezones.

=item B<datetime_local>

ISO8601 representation of the C<datetime_raw> (via C<TimeMomentFormatString>)
attempting to manipulate into the timezone of the local computer or the
timezone set by C<set_syslog_timezone()>.

B<NOTE:> This does not handle DST well as the logic for that requires
L<DateTime::TimeZone> when using L<Time::Moment>. Adding C<DateTime> back into
this module will kill performance, so I accept the inaccuracy here as you
should never use this.

It is provided for those living in Arizona to mock the rest of us for our
stupid DST sins.

=item B<date>

The date portion of C<datetime_str>

=item B<time>

The time portion of C<datetime_str>

=item B<tz>

The timezone offset of C<datetime_str>

=item B<host_raw>

The source host of the log as parsed, i.e., C<"host.example.com">

=item B<host>

Host portion of the C<host_raw>, i.e., C<"host">

=item B<domain>

Domain portion of the C<host_raw>, i.e., C<"example.com">

=item B<origin>

If relayed, contains the origin of the message, i.e., "host.example.com"

=item B<origin_date>

If relayed, contains the origin timestamp, this is unparsed.

=item B<program_raw>

The program, appname, or syslogtag in full, save the final colon, i.e.,
C<sshd(pam_unix)[35454]>.

=item B<program_name>

Program name parsed from C<program_raw>, i.e., C<sshd>.

=item B<program_pid>

The PID as parsed from the C<program_raw>, i.e., C<35454>.

=item B<program_sub>

The program context as parsed from C<program_raw>, i.e., C<pam_unix>.

=item B<content>

Everything after the syslog tag, except when using C<AutoDetectJSON> or
C<AutoDetectKeyValues>. When detecting structured data, successfully parsed chunks
of the message are removed from the string.

As an example, if the message is:

    2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: updating data {"lunchTime":1443612366.442}

By default, C<content> will be:

    updating data {"lunchTime":1443612366.442}

However, if C<AutoDetectJSON> is set, then C<content> will be:

    updating data

And the JSON will be decoded into the C<SDATA> field.

=item B<SDATA>

The structured data from the log message. This include RFC5424 Structured Data as well
as anything extracted by C<AutoDetectJSON> and/or C<AutoDetectKeyValues>.

=item B<message>

Everything from the syslogtag onward, i.e., C<"program_raw content">

=item B<message_raw>

The entire message passed into the function.

=back

=head2 C<set_syslog_timezone($timezone_name)>

Sets a timezone C<$timezone_name> for parsed messages. This timezone will be
used to calculate offset from UTC if a timezone designation is not present in
the message being parsed.  This timezone will also serve as the source timezone
for the C<datetime_local> field.

=head2 C<get_syslog_timezone()>

Returns the name of the timezone currently set by set_syslog_timezone.

=head2 C<use_utc_syslog()>

A convenient function which sets the syslog timezone to UTC.

=head2 parse_syslog_lines

Returns a list of hashes of the lines interpretted.

When passed one or more line of text, attempts to parse that text as syslog data.  This function
varies from C<parse_syslog_line> in that it handles multi-line messages.  The caveat to this, is
after the last iteration of the loop, you to call the function by itself to get the last message.

    use strict;
    use warnings;
    use DDP;
    use Parse::Syslog::Line qw(parse_syslog_lines);

    while(<>) {
        foreach my $log ( parse_syslog_lines($_) ) {
            p($log);
        }
    }
    p($_) for parse_syslog_lines();

This function holds a parsing buffer which it flushes any time it encounters a
line in the stream that starts with non-whitespace.  Any lines beginning with
whitespace will be assumed to be a continuation of the previous line.

It is not exported by default.

=head2 psl_enable_sdata

Call this to turn on all the Structured Data Parsing Options

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

=head1 ENVIRONMENT VARIABLES

There are environment variables that affect how we operate. They are not
options as they are not intended to be used by our users. Use at your own risk.

=head2 PARSE_SYSLOG_LINE_DEBUG

Outputs debugging information about the parser, not really intended for end-users.

=head2 PARSE_SYSLOG_LINE_QUIET

Disables warnings in the parse_syslog_line() function

=head2 TEST_ACTIVE / TEST2_ACTIVE

Disables warnings in the parse_syslog_line() function

=head1 DEVELOPMENT

This module is developed with Dist::Zilla.  To build from the repository, use Dist::Zilla:

    dzil authordeps --missing |cpanm
    dzil listdeps --missing |cpanm
    dzil build
    dzil test

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Brad Lhotsky.

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

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Parse-Syslog-Line>

=back

=head2 Bugs / Feature Requests

This module uses the GitHub Issue Tracker: L<https://github.com/reyjrar/Parse-Syslog-Line/issues>

=head2 Source Code

This module's source code is available by visiting:
L<https://github.com/reyjrar/Parse-Syslog-Line>

=cut
