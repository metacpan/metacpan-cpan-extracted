#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Net::TFTPd qw( :all );

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  '4!'          => \$opt{4},
  '6!'          => \$opt{6},
  'directory=s' => \$opt{dir},
  'interface:i' => \$opt{interface},
  'time!'       => \$opt{time},
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
} else {
    $opt{dir} = '.'
}

if (defined $opt{interface}) {
    if (!(($opt{interface} > 0) && ($opt{interface} < 65536))) {
        print "$0: port not valid - $opt{interface}"
    }
} else {
    $opt{interface} = '69'
}

my $tftpd = Net::TFTPd->new(
    RootDir   => $opt{dir},
    Writable  => 1,
    LocalPort => $opt{interface},
    Family    => $family
);

if (!$tftpd) {
    printf "$0: Error creating TFTPd listener: %s", Net::TFTPd->error;
    exit 1
}

printf "Listening on %s:%i\n" . 
       "TFTP Root Dir = %s\n\n", 
       $tftpd->{_UDPSERVER_}->sockhost, 
       $opt{interface}, 
       $opt{dir};

my $tftpdRQ;
while (1) {
    if (!($tftpdRQ = $tftpd->waitRQ())) { next }

    my $p = sprintf "%s\t%s\t%i\t%s\t%s\t%s", ($opt{time} ? yyyymmddhhmmss() : time), $tftpdRQ->getPeerAddr, $tftpdRQ->getPeerPort, $OPCODES{$tftpdRQ->{_REQUEST_}->{OPCODE}}, $tftpdRQ->getMode, $tftpdRQ->getFileName;
    print "$p\tSTARTED\n";

    my $pid = fork();

    if (!defined $pid) {
        print "fork() Error!\n";
        exit
    } elsif ($pid == 0) {
        printf $p;
        if (defined $tftpdRQ->processRQ()) {
            printf "\tSUCCESS [%i bytes]\n", $tftpdRQ->getTotalBytes
        } else {
            print "\t" . Net::TFTPd->error . "\n"
        }
        exit
    } else {
        # parent
    }
}

sub yyyymmddhhmmss {
    my @time = localtime();
    return (($time[5] + 1900) . ((($time[4] + 1) < 10)?("0" . ($time[4] + 1)):($time[4] + 1)) . (($time[3] < 10)?("0" . $time[3]):$time[3]) . (($time[2] < 10)?("0" . $time[2]):$time[2]) . (($time[1] < 10)?("0" . $time[1]):$time[1]) . (($time[0] < 10)?("0" . $time[0]):$time[0]))
}

__END__

=head1 NAME

TFTPD-SIMPLE - Simple TFTP Server

=head1 SYNOPSIS

 tftpd-simple [options]

=head1 DESCRIPTION

Listens for TFTP requests and proccess them.

=head1 OPTIONS

 -4               Force IPv4.
 -6               Force IPv6 (overrides -4).

 -d <dir>         TFTP root directory.
 --directory      DEFAULT:  (or not specified) [Current].

 -i #             UDP Port to listen on.
 --interface      DEFAULT:  (or not specified) 69.

 -t               Print time in human-readable yyyymmddhhmmss format.
 --time           DEFAULT:  (or not specified) Unix epoch.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2015

L<http://www.VinsWorld.com>

All rights reserved

=cut
