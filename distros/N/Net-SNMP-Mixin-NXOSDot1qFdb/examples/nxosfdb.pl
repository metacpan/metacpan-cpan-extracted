#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

qfdb.pl

=head1 ABSTRACT

A script to get the forwarding database table (FDB) from switches supporting the NX-OS limited Q-BRIDGE-MIB:

=head1 SYNOPSIS

 qfdb.pl OPTIONS agent agent ...

 qfdb.pl OPTIONS -i <agents.txt

=head2 OPTIONS

  -c snmp_community
  -v snmp_version
  -t snmp_timeout
  -r snmp_retries

  -d			Net::SNMP debug on
  -i			read agents from stdin, one agent per line
  -B			nonblocking
  -R			print raw FDB table
  -S			print statistics for agents

=head1 DESCRIPTION

Prints the MAC-address table.

=cut

use blib;
use Net::SNMP qw(:debug :snmp);
use Net::SNMP::Mixin;
use Getopt::Std;

my %opts;
getopts( 'iRSBdt:r:c:v:', \%opts ) or usage();

my $debug       = $opts{d} || undef;
my $community   = $opts{c} || 'public';
my $version     = $opts{v} || '2';
my $nonblocking = $opts{B} || 0;
my $timeout     = $opts{t} || 3;
my $retries     = $opts{t} || 1;
my $from_stdin  = $opts{i} || undef;

my @agents = @ARGV;
push @agents, <STDIN> if $from_stdin;
chomp @agents;
usage('missing agents') unless @agents;

my @sessions;
foreach my $agent ( sort @agents ) {
  my ( $session, $error ) = Net::SNMP->session(
    -community   => $community,
    -hostname    => $agent,
    -version     => $version,
    -nonblocking => $nonblocking,
    -timeout     => $timeout,
    -retries     => $retries,
    -debug       => $debug ? DEBUG_ALL : 0,
  );

  if ($error) {
    warn $error;
    next;
  }

  $session->mixer(qw/Net::SNMP::Mixin::IfInfo Net::SNMP::Mixin::NXOSDot1dBase Net::SNMP::Mixin::NXOSDot1qFdb/);
  $session->init_mixins;
  push @sessions, $session;

}
snmp_dispatcher() if $Net::SNMP::NONBLOCKING;

# check for init errors
$_->init_ok foreach @sessions;

# remove sessions with error from the sessions list
@sessions = grep {
  if ( $_->errors ) { warn scalar $_->errors, "\n"; undef }
  else              { 1 }
} @sessions;

foreach my $session (@sessions) {
  print_fdb($session);
}

exit 0;

###################### end of main ######################

sub print_fdb {
  my $session = shift;
  my $agent   = $session->hostname;

  print "\n";
  printf "Hostname:  %s\n", $agent;

  print '-' x 60, "\n";
  printf "%12s %4s %-17s %s\n", 'ifName', 'VID', 'MAC', 'Status',;
  print '-' x 60, "\n";

  my $if_entries        = $session->get_if_entries;
  my $bride_port2id_idx = $session->map_bridge_ports2if_indexes;

  foreach my $fdb_entry ( sort { $a->{dot1dBasePort} <=> $b->{dot1dBasePort} || $a->{vlanId} <=> $b->{vlanId} }
    $session->get_dot1q_fdb_entries() )
  {
    my $mac         = $fdb_entry->{MacAddress};
    my $vlan_id     = $fdb_entry->{vlanId};
    my $status_str  = $fdb_entry->{fdbStatusString};
    my $bridge_port = $fdb_entry->{dot1dBasePort};
    my $id_idx      = $bride_port2id_idx->{$bridge_port} || -$bridge_port;
    my $if_name     = $if_entries->{$id_idx}{ifName} || $id_idx;

    printf "%12s %4d %17s %s\n", shorten($if_name), $vlan_id, $mac, $status_str;

  }
  print '-' x 60, "\n";
}

# strip leading and trailing whitespace
# shorten interface strings
sub shorten {
  my $val = shift;
  return unless defined $val;

  $val =~ s/^\s*|\s*$//g;
  $val =~ s/  / /g;
  $val =~ s/Interface/If/g;
  $val =~ s/Ethernet/Eth/ig;
  $val =~ s/Gigabit/Gig/g;
  $val =~ s/port-channel/Po/ig;
  return $val;
}

sub usage {
  my @msg = @_;
  die <<EOT;
>>>>>> @msg
    Usage: $0 [options] hostname
   
    	-c community
  	-v version
  	-t timeout
  	-r retries
  	-d		Net::SNMP debug on
	-i		read agents from stdin
  	-B		nonblocking
EOT
}

=head1 AUTHOR

Karl Gaissmaier, karl.gaissmaier (at) uni-ulm.de

=head1 COPYRIGHT

Copyright (C) 2020 by Karl Gaissmaier

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: sw=2
