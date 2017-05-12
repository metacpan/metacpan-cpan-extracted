#!/usr/local/bin/perl
# =============================================================================
# realifmon.pl - Realtime monitor of host interfaces
# -----------------------------------------------------------------------------
$main::VERSION = '1.04';
# -----------------------------------------------------------------------------

=head1 NAME

realifmon.pl - Realtime monitor of host interfaces

=head1 SYNOPSIS

    $ realifmon.pl [-c COMMUNITY_NAME] [-w WAIT] [-x REGEXP] HOST

    COMMUNITY_NAME ... SNMP Community Name. Omitting uses 'public'.
    WAIT           ... Interval seconds. Default is 5.
    REGEXP         ... Specify regular expression for pickup IFs by name.
    HOST           ... Target hosts to check.

    This program is for devices which can deal SNMP version 2c.

=head1 DESCRIPTION

This program shows realtime traffic throughput of interfaces of a host on your
console with using C<snmpwalk()> and callbacking.

=head1 NOTE

This script is a sample of C<Net::SNMP::Util>.
This program is for devices which can deal SNMP version 2c.

=cut


use strict;
use warnings;
use Getopt::Std;
use Term::ANSIScreen qw/:color :screen :constants/;
use Net::SNMP::Util;

my %opt;
getopts('hv:c:w:x:', \%opt);
my $host = shift @ARGV;

sub HELP_MESSAGE {
    print "Usage: $0 [-c COMMUNITY_NAME] [-w WAIT] [-x REGEXP] HOST\n";
    exit 1;
}
HELP_MESSAGE() if ( !$host || $opt{h} );

my ($wait,$regexp) = ($opt{w}||5, $opt{x}? qr/$opt{x}/: '');
my $console = Term::ANSIScreen->new();
local $| = 1;

# make session
my ($ses, $err) = Net::SNMP->session(
    -hostname  => $host,
    -version   => "2",
    -community => ($opt{c} || "public")
);
die "[ERROR] $err\n" unless defined $ses;

# main loop
my (%pdata, %cdata);  # flag, previous and current octets data
my $first = 1;
while ( 1 ){
    %cdata = ();
    (my $ret, $err) = snmpwalk(
        snmp => $ses,
        oids => {
            sysUpTime => '1.3.6.1.2.1.1.3',
            ifTable => [
                '1.3.6.1.2.1.31.1.1.1.1',  # [0] ifName
                '1.3.6.1.2.1.2.2.1.7',     # [1] ifAdminStatus
                '1.3.6.1.2.1.2.2.1.8',     # [2] ifOperStatus
                '1.3.6.1.2.1.31.1.1.1.6',  # [3] ifHCInOctets
                '1.3.6.1.2.1.31.1.1.1.10', # [4] ifHCOutOctets
                '1.3.6.1.2.1.31.1.1.1.15', # [5] ifHighSpeed
            ] },
        -mycallback => sub {
            my ($s, $host, $key, $val) = @_;
            return 1 if $key ne 'ifTable';
            my $name = $val->[0][1];
            return 0 if ( $regexp && $name !~ /$regexp/ );
            # storing current octets data
            $cdata{$name}{t} = time;
            $cdata{$name}{i} = $val->[3][1];
            $cdata{$name}{o} = $val->[4][1];
            return 1;
        }
    );
    die "[ERROR] $err\n" unless $ret;

    # header
    $console->Cls();
    $console->Cursor(0, 0);

    printf "%s, up %s - %s\n\n",
        BOLD.$host.CLEAR, $ret->{sysUpTime}{0}, scalar(localtime(time));

    # matrix
    printf "%s%-30s (%-10s) %2s %2s %10s %10s %10s%s\n",
        UNDERSCORE, qw/ifName ifIndex Ad Op BW(Mbps) InBps(M) OutBps(M)/, CLEAR;

    my $iftable = $ret->{ifTable};
    foreach my $i ( sort { $a <=> $b } keys %{$iftable->[1]} )
    {
        my ($name, $astat, $ostat, $bw)
            = map { $iftable->[$_]{$i} } qw( 0 1 2 5 );
        if ( $first ){
            printf "%-30s (%-10d) %2d %2d %10.1f %10s %10s\n",
                $name, $i, $astat, $ostat, $bw/1000, '-', '-';
            next;   # skip first
        }

        # calculate (k)bps
        my $td = $cdata{$name}{t} - $pdata{$name}{t};
        my ($inbps, $outbps) = map {
            my $delta = $cdata{$name}{$_} - $pdata{$name}{$_};
            $delta<0? 0: $delta / $td / 1000; # Kbps
        } qw( i o );

        printf "%-30s (%-10d) %2d %2d %10.1f %10.1f %10.1f\n",
            $name, $i, $astat, $ostat, map { $_/1000 } ($bw, $inbps, $outbps);
    }

    %pdata = %cdata;
    $first = 0;
    sleep $wait;
}

__END__


=head1 EXAMPLES

Simply way to check host with specifying community name is;

    example% realifmon.pl -c max-heart luminous.precures.local

Checking traffics throughtput for every 10 seconds;

    example% realifmon.pl -c max-heart -w 10 black.precures.local

If you want check only ports of slot #2 when the device has IFs which ifNames
are set like "X/Y";

    example% realifmon.pl -c max-heart -r '2/\d+$' white.precures.local


=head1 REQUIREMENTS

C<Net::SNMP>, C<Net::SNMP::Util>


=head1 AUTHOR

t.onodera, C<< <cpan :: garakuta.net> >>


=head1 SEE ALSO

L<Net::SNMP> - Core module of C<Net::SNMP::Util> which brings us good SNMP
implementations.
L<Net::SNMP::Util::OID> - Sub module of C<Net::SNMP::Util> which provides
easy and simple functions to treat OID.
L<Net::SNMP::Util::TC> - Sub module of C<Net::SNMP::Util> which provides
easy and simple functions to treat textual conversion.


=head1 LICENSE AND COPYRIGHT

Copyright(C) 2011- Takahiro Ondoera.

This program is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
