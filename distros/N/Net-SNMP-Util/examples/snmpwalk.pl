#!/usr/local/bin/perl
# =============================================================================
# snmpwalk.pl - Command to get MIB with SNMP GetNextRequest via Net::SNMP::Util
# -----------------------------------------------------------------------------
$main::VERSION = '1.04';
# -----------------------------------------------------------------------------

=head1 NAME

snmpwalk.pl - Command to get MIB values with SNMP GetNextRequest

=head1 SYNOPSIS

    $ snmpwalk.pl [OPTIONS] HOST[,HOST[,...]] OID [OID [...]]

See command help, type;

    $ snmpwalk.pl -h

=head1 DESCRIPTION

This program gets MIB values with C<snmpwalk()> or C<snmpparawalk()> of
C<Net::SNMP::Util>.

=cut

use strict;
use warnings;
use Getopt::Std;

use Net::SNMP::Util qw(:para);
use Net::SNMP::Util::OID qw(*);


# ---------- Data::Dumper setting ----------
# put output into hands of Data::Dumper :-)
use Data::Dumper;
use Storable qw(lock_nstore);

local($a,$b);
$Data::Dumper::Indent   = 1;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Sortkeys = sub { [ sort {
    # if keys are numbers, then do numerical sort
    return ($a =~ /^\d+$/)? ($a <=> $b): ($a cmp $b);
} keys %{$_[0]} ] };


# ---------- Parsing options ----------
my %opt;
getopts('hPa:A:c:dD:E:m:n:p:r:t:u:v:x:X:f:', \%opt);

my ($hosts, @oids) = @ARGV;
HELP_MESSAGE()                    if defined $opt{h};
HELP_MESSAGE("No Host Specified") unless $hosts;
HELP_MESSAGE("No OID Specified")  unless @oids;

my @hosts = split(/,/, $hosts);
my %oids  = map {
    /,/? ($_ => [ map oid($_),split(/,/) ]): oidp($_)
} @oids;


# ---------- set session options ----------
my %snmp = ();
my %omap = qw(
    authprotocol a  authpassword A  community    c  domain       D
    maxmsgsize   m  port         p  retries      r  timeout      t
    username     u  version      v  privprotocol x  privpassword X
);
while( my ($o,$sw) = each %omap ){
    $snmp{"-$o"} = $opt{$sw} if exists $opt{$sw};
}
my $debug = exists($opt{d})? 0xff: 0;
$snmp{-debug} = $debug if $debug;


# ---------- kick function ----------
my $func = $opt{P}? 'snmpparawalk': 'snmpwalk';
print "[DEBUG] Calling $func()\n" if $debug;

my ( $result, $error );
{
    no strict;
    ( $result, $error ) = &$func(
        hosts => \@hosts,
        oids  => \%oids,
        snmp  => \%snmp
    );
    die "[ERROR] $error\n" unless defined $result;
}


# ---------- output result ----------
print Dumper($result);
warn "[ERROR] $error\n" if $error;
if ( $opt{f} ){
    eval { lock_nstore $result, $opt{f}; };
    warn "[ERROR] Storable error; $@\n" if $@;
    print "[INFO] Stored to $opt{f}\n";
}


# ---------- supporting stuffs ----------
sub HELP_MESSAGE {
    my $mess = shift;
    warn "[ERROR] $mess\n" if $mess;

    print <<__USAGE__;
Usage: $0 [OPTIONS] HOST[,HOST[,...]] OID [OID [...]]

* snmpwalk.pl - Command to get MIB with SNMP GetNextRequest via Net::SNMP::Util
  Version: $main::VERSION
  Web:     http://search.cpan.org/perldoc?Net::SNMP::Util

OPTIONS:
    -h                  Display this help message
    -P                  Use Non-Blocking Net::SNMP sessions
    -d                  Enable Debugging
    -v VERSION          Specify version (same way of Net::SNMP)
  <SNMPv1/2c>
    -c COMMUNITY        Specify community name
  <SNMPv3>
    -u USERNAME         Username (required)
    -E ENGINEID         Context Engine ID
    -n NAME             Context Name
    -a AUTHPROTO        Authentication protocol <md5|sha>
    -A PASSWORD         Authentication password
    -x PRIVPROTO        Privacy protocol <des|3des|aes>
    -X PASSWORD         Privacy password
  <General>
    -t TIMEOUT          Timeout seconds (defalut 5)
    -r RETRIES          Retry count (defalut 1)
  <Tool>
    -f FILENAME         Also store the result to FILENAME with Storeble

HOST                    Specify checking host
OID                     MIB name or OID to check
    "Oid"               Specify one OID
    "Oid,Oid,..."       Specify and set OIDs to a VarBindings
__USAGE__
    exit 1;
}


__END__

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
