#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

stp.pl

=head1 ABSTRACT

A script to get the STP information from Cisco NXOS switches.

=head1 SYNOPSIS

 stp.pl OPTIONS agent agent ...

 stp.pl OPTIONS -i <agents.txt

=head2 OPTIONS

  -c snmp_community
  -v snmp_version
  -t snmp_timeout
  -r snmp_retries

  -d			Net::SNMP debug on
  -i			read agents from stdin, one agent per line
  -b			blocking

=cut

use blib;
use Net::SNMP qw(:debug :snmp);
use Net::SNMP::Mixin;

use Getopt::Std;

my %opts;
getopts( 'ibdt:r:c:v:', \%opts ) or usage();

my $debug     = $opts{d} || undef;
my $community = $opts{c} || 'public';
my $version   = $opts{v} || '2';
my $blocking  = !$opts{b};
my $timeout   = $opts{t} || 5;
my $retries   = $opts{t} || 0;

my $from_stdin = $opts{i} || undef;

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
    -nonblocking => !$blocking,
    -timeout     => $timeout,
    -retries     => $retries,
    -debug       => $debug ? DEBUG_ALL : 0,
  );

  if ($error) {
    warn $error;
    next;
  }

  $session->mixer(qw/Net::SNMP::Mixin::IfInfo Net::SNMP::Mixin::NXOSDot1dStp Net::SNMP::Mixin::NXOSDot1dBase/);
  $session->init_mixins;
  push @sessions, $session;

}
snmp_dispatcher() if $Net::SNMP::NONBLOCKING;

# remove sessions with errors from the sessions list
@sessions = grep {
  if   ( $_->init_ok ) { 1 }
  else                 { warn join( "\n", $_->errors, "\n" ); undef }
} @sessions;

foreach my $session ( sort { $a->hostname cmp $b->hostname } @sessions ) {
  print_stp($session);
}

exit 0;

###################### end of main ######################

sub print_stp {
  my $session = shift;

  my $stp_group      = $session->get_dot1d_stp_group;
  my $bridge_address = $session->get_dot1d_base_group->{dot1dBaseBridgeAddress};

  print "\n";
  printf "Hostname:       %s\n", $session->hostname;
  printf "TopoChanges:    %s\n", $stp_group->{dot1dStpTopChanges};
  printf "LastChange:     %s\n", $stp_group->{dot1dStpTimeSinceTopologyChange};
  printf "ThisRootPort:   %s\n", $stp_group->{dot1dStpRootPort};
  printf "ThisRootCost:   %s\n", $stp_group->{dot1dStpRootCost};
  printf "ThisBridgeMAC:  %s\n", $bridge_address;
  printf "ThisStpPrio:    %s\n", $stp_group->{dot1dStpPriority};
  printf "RootBridgeMAC:  %s\n", $stp_group->{dot1dStpDesignatedRootAddress};
  printf "RootBridgePrio: %s\n", $stp_group->{dot1dStpDesignatedRootPriority};

  print '-' x 82, "\n";
  printf "%-36s | %s\n", 'Local Bridge Port', 'Designated Bridge Port and Bridge';
  print '-' x 82, "\n";

  printf "%-6s %10s %8s %9s | %8s %9s %12s %11s\n", qw/If State Cost Prio.Port Cost Prio.Port DB-Address DB-Prio/;
  print '-' x 82, "\n";

  my $stp_ports          = $session->get_dot1d_stp_port_table;
  my $map_br_port2if_idx = $session->map_bridge_ports2if_indexes;
  my $if_info            = $session->get_if_entries;

  foreach my $port ( sort { $a <=> $b } keys %$stp_ports ) {
    my $port_enabled = $stp_ports->{$port}{dot1dStpPortEnable};
    next unless defined $port_enabled && $port_enabled == 1;

    my $port_state             = $stp_ports->{$port}{dot1dStpPortState};
    my $port_state_string      = $stp_ports->{$port}{dot1dStpPortStateString};
    my $port_prio              = $stp_ports->{$port}{dot1dStpPortPriority};
    my $port_path_cost         = $stp_ports->{$port}{dot1dStpPortPathCost};
    my $port_desig_cost        = $stp_ports->{$port}{dot1dStpPortDesignatedCost};
    my $port_desig_bridge_prio = $stp_ports->{$port}{dot1dStpPortDesignatedBridgePriority};
    my $port_desig_bridge_mac  = $stp_ports->{$port}{dot1dStpPortDesignatedBridgeAddress};
    my $port_desig_port_prio   = $stp_ports->{$port}{dot1dStpPortDesignatedPortPriority};
    my $port_desig_port_nr     = $stp_ports->{$port}{dot1dStpPortDesignatedPortNumber};

    my $if_idx  = $map_br_port2if_idx->{$port} || -$port;
    my $if_name = $if_info->{$if_idx}{ifName}  || '???';

    printf "%-6s %10s %8d %4d.%-4d | %8d %4d.%-4d %12s %6d\n",
      #
      shorten($if_name), $port_state_string, $port_path_cost, $port_prio, $port,
      #
      $port_desig_cost, $port_desig_port_prio, $port_desig_port_nr, $port_desig_bridge_mac, $port_desig_bridge_prio,;
  }
  print "\n";
}

# shorten ifNames
sub shorten {
  my $val = shift // die 'missing interface name,';

  $val =~ s/Interface/If/g;
  $val =~ s/Ethernet/E/ig;
  $val =~ s/Gig(abit)?/G/g;
  $val =~ s/Forty/F/g;
  $val =~ s/Ten-?/T/g;
  $val =~ s/Hundred/H/g;
  $val =~ s/Bridge-Aggregation/Bri-Agg/ig;
  $val =~ s/Port-Channel/Po/ig;
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
  	-b		blocking
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
