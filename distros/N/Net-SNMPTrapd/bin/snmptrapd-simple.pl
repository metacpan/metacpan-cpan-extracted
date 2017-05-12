#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Net::SNMPTrapd;

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  '4!'          => \$opt{4},
  '6!'          => \$opt{6},
  'directory=s' => \$opt{dir},
  'Dump!'       => \$opt{dump},
  'Hexdump!'    => \$opt{hex},
  'interface:i' => \$opt{interface},
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

$opt{hex}  = $opt{hex}  || 0;
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
    $opt{interface} = '162'
}

my $snmptrapd = Net::SNMPTrapd->new(
    LocalPort => $opt{interface},
    Family    => $family
);

if (!$snmptrapd) {
    printf "$0: Error creating SNMPTrapd listener: %s", Net::SNMPTrapd->error;
    exit 1
}

printf "Listening on %s:%i\n", $snmptrapd->server->sockhost, $snmptrapd->server->sockport;

while (1) {
    my $trap = $snmptrapd->get_trap();

    if (!defined $trap) {
        printf "$0: %s\n", Net::SNMPTrapd->error;
        exit 1
    } elsif ($trap == 0) {
        next
    }

    if (!defined $trap->process_trap()) {
        printf "$0: %s\n", Net::SNMPTrapd->error
    } else {
        my $p;
        if ($opt{hex}) {
            $p = $trap->datagram(1)
        } elsif ($opt{dump}) {
            $trap->dump
        } else {
            $p = sprintf "%s\t%s\t%i\t%i\t%s\t%s\t", 
                ($opt{time} ? yyyymmddhhmmss() : time),
                $trap->remoteaddr, 
                $trap->remoteport, 
                $trap->version, 
                $trap->community,
                $trap->pdu_type;
            if ($trap->version == 1) {
                $p .= sprintf "%s\t%s\t%s\t%s\t%s\t", 
                    $trap->ent_OID, 
                    $trap->agentaddr, 
                    $trap->generic_trap, 
                    $trap->specific_trap, 
                    $trap->timeticks
            } else {
                $p .= sprintf "%s\t%s\t%s\t", 
                    $trap->request_ID, 
                    $trap->error_status, 
                    $trap->error_index
            }
            for my $varbind (@{$trap->varbinds}) {
                for (keys(%{$varbind})) {
                    # Here, one could use a MIB translation table or 
                    # Perl module to map OID's ($_) to text and values 
                    # ($varbind->{$_}) to applicable meanings or metrics.
                    # This example just prints -> OID: val; OID: val; ...
                    if ($varbind->{$_} =~ /[\x00-\x1f\x7f-\xff]/s) {
                        $p .= sprintf "%s: 0x%s; ", $_, unpack ("H*", $varbind->{$_})
                    } else {
                        $p .= sprintf "%s: %s; ", $_, $varbind->{$_}
                    }
                }
            }
        }
        $p .= "\n";
        print $p;

        if ($opt{write}) {
            my $outfile;
            if (defined $opt{dir}) { $outfile = $opt{dir} . "/" }

            $outfile .= "snmptrapd.log";
            
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

SNMPTRAPD-SIMPLE - Simple SNMP Trap Server

=head1 SYNOPSIS

 snmptrapd-simple [options]

=head1 DESCRIPTION

Listens for SNMP traps and logs to console and optional 
file.  Can decode SNMP v1 and v2c traps and v2c InformRequest 
(will send Response PDU).  Output columns are:

        Source IP Address
        Source UDP port
        SNMP version
        SNMP community
        PDU Type
  (Version 1)          (Version 2c)
  Enterprise OID       Request ID
  Agent IP Address     Error Status
  Trap Type            Error Index
  Specific Trap
  Timeticks
        Varbinds (OID: val; [...])

=head1 OPTIONS

 -4               Force IPv4.
 -6               Force IPv6 (overrides -4).

 -d <dir>         Output file directory.
 --directory      DEFAULT:  (or not specified) [Current].

 -D               Use Net::SNMPTrapd->dump() method.
 --Dump           DEFAULT:  (or not specified) [Decode trap].

 -H               Print hex dump of trap PDU - do not decode.
 --Hexdump        DEFAULT:  (or not specified) [Decode trap].

 -i #             UDP Port to listen on.
 --interface      DEFAULT:  (or not specified) 162.

 -t               Print time in human-readable yyyymmddhhmmss format.
 --time           DEFAULT:  (or not specified) Unix epoch.

 -w               Log to "snmptrapd.log".

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
