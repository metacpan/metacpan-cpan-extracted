#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Net::Syslogd;

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  '4!'          => \$opt{4},
  '6!'          => \$opt{6},
  'directory=s' => \$opt{dir},
  'interface:i' => \$opt{interface},
  'list!'       => \$opt{list},
  'time!'       => \$opt{time},
  'write+'      => \$opt{write},
  'help!'       => \$opt_help,
  'man!'        => \$opt_man
) or pod2usage(-verbose => 0);

pod2usage(-verbose => 1) if defined $opt_help;
pod2usage(-verbose => 2) if defined $opt_man;

# Default to IPv4
my $family = 4;
if ($opt{6}) {
    $family = 6
}

$opt{time} = $opt{time} || 0;

# -d is a directory, if it exists, assign it
if (defined $opt{dir}) {

    # replace \ with / for compatibility with UNIX/Windows
    $opt{dir} =~ s/\\/\//g;

    # remove trailing / so we're sure it does NOT exist and we CAN put it in later
    $opt{dir} =~ s/\/$//;

    if (!(-e $opt{dir})) {
        print "$0: directory does not exist - $opt{dir}";
        exit 1
    }
    $opt{write} = 1 if (!$opt{write})
}

if (defined $opt{interface}) {
    if (!(($opt{interface} > 0) && ($opt{interface} < 65536))) {
        print "$0: port not valid - $opt{interface}"
    }
} else {
    $opt{interface} = '514'
}

my $syslogd = Net::Syslogd->new(
    LocalPort => $opt{interface},
    Family    => $family
);

if (!$syslogd) {
    printf "$0: Error creating Syslogd listener: %s", Net::Syslogd->error;
    exit 1
}

printf "Listening on %s:%i\n", $syslogd->server->sockhost, $syslogd->server->sockport;

while (1) {
    my $message = $syslogd->get_message();

    if (!defined $message) {
        printf "$0: %s\n", Net::Syslogd->error;
        exit 1
    } elsif ($message == 0) {
        next
    }

    if (!defined $message->process_message()) {
        printf "$0: %s\n", Net::Syslogd->error
    } else {
        my $p;
        if ($opt{list}) {
            $p = sprintf 
                "Time       = %s\n" . 
                "RemoteAddr = %s\n" . 
                "RemotePort = %s\n" . 
                "Severity   = %s\n" . 
                "Facility   = %s\n" . 
                "Time       = %s\n" . 
                "Hostname   = %s\n" . 
                "Message    = %s\n",
                ($opt{time} ? yyyymmddhhmmss() : time),
                $message->remoteaddr,
                $message->remoteport,
                $message->severity,
                $message->facility,
                $message->time,
                $message->hostname,
                $message->message
        } else {
            $p = sprintf "%s\t%s\t%i\t%s\t%s\t%s\t%s\t%s\n", 
                ($opt{time} ? yyyymmddhhmmss() : time),
                $message->remoteaddr,
                $message->remoteport,
                $message->severity,
                $message->facility,
                $message->time,
                $message->hostname,
                $message->message
        }
        print $p;

        if ($opt{write}) {
            my $outfile;
            if (defined $opt{dir}) { $outfile = $opt{dir} . "/" }

            if    ($opt{write} == 1) { $outfile .= "syslogd.log"               }
            elsif ($opt{write} == 2) { $outfile .= $message->facility . ".log" }
            else                     { $outfile .= $message->remoteaddr . ".log" }

            if (open(my $OUT, '>>', $outfile)) {
                print $OUT $p;
                close $OUT
            } else {
                print STDERR "$0: cannot open outfile - $outfile\n"
            }
        }
    }
}

sub yyyymmddhhmmss {
    my @time = localtime();
    return (($time[5] + 1900) . ((($time[4] + 1) < 10)?("0" . ($time[4] + 1)):($time[4] + 1)) . (($time[3] < 10)?("0" . $time[3]):$time[3]) . (($time[2] < 10)?("0" . $time[2]):$time[2]) . (($time[1] < 10)?("0" . $time[1]):$time[1]) . (($time[0] < 10)?("0" . $time[0]):$time[0]))
}

__END__

=head1 NAME

SYSLOGD-SIMPLE - Simple Syslog Server

=head1 SYNOPSIS

 syslod-simple [options]

=head1 DESCRIPTION

Listens for Syslog messages and logs to console and 
optional file.  Tries to decode according to RFC 3164 
message format.  Syslog columns are:

  Source IP Address
  Source UDP port
  Facility
  Severity
  Timestamp (or 0 if not matched)
  Hostname  (or 0 if not matched)
  Message

=head1 OPTIONS

 -4               Force IPv4.
 -6               Force IPv6 (overrides -4).

 -d <dir>         Output file directory.
 --directory      DEFAULT:  (or not specified) [Current].

 -i #             UDP Port to listen on.
 --interface      DEFAULT:  (or not specified) 514.

 -l               Output list format.
 --list           DEFAULT:  (or not specified) Line.

 -t               Print time in human-readable yyyymmddhhmmss format.
 --time           DEFAULT:  (or not specified) Unix epoch.

 -w               Log to "syslogd.log".
 -w -w            Log by facility in "<facility>.log".
 -w -w -w         Log by hostname in "<host>.log".

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
