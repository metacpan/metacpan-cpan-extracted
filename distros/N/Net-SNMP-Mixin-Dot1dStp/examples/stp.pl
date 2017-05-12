#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

stp.pl

=head1 ABSTRACT

A script to get the STP information from switches supporting the MIBs.

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
  -B			nonblocking

=cut

use blib;
use Net::SNMP qw(:debug :snmp);
use Net::SNMP::Mixin;

use Getopt::Std;

my %opts;
getopts( 'iBdt:r:c:v:', \%opts ) or usage();

my $debug       = $opts{d} || undef;
my $community   = $opts{c} || 'public';
my $version     = $opts{v} || '2';
my $nonblocking = $opts{B} || 0;
my $timeout     = $opts{t} || 5;
my $retries     = $opts{t} || 0;

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
    -nonblocking => $nonblocking,
    -timeout     => $timeout,
    -retries     => $retries,
    -debug       => $debug ? DEBUG_ALL : 0,
  );

  if ($error) {
    warn $error;
    next;
  }

  $session->mixer(
    qw/Net::SNMP::Mixin::Dot1dStp Net::SNMP::Mixin::Dot1dBase/);
  $session->init_mixins;
  push @sessions, $session;

}
snmp_dispatcher() if $Net::SNMP::NONBLOCKING;

# warn on errors during initialization
foreach my $session (@sessions) {
  if ( $session->errors ) {
    foreach my $error ( $session->errors ) {
      warn $session->hostname . ": $error\n";
    }
  }
}

# remove sessions with errors from the sessions list
@sessions = grep {not $_->errors(1)} @sessions;

foreach my $session ( sort { $a->hostname cmp $b->hostname } @sessions ) {
  print_stp($session);
}

exit 0;

###################### end of main ######################

sub print_stp {
  my $session = shift;

    my $stp_group = $session->get_dot1d_stp_group;
    my $bridge_address =
      $session->get_dot1d_base_group->{dot1dBaseBridgeAddress};

    print "\n";
    printf "Hostname:       %s\n", $session->hostname;
    printf "TopoChanges:    %s\n", $stp_group->{dot1dStpTopChanges};
    printf "ThisRootPort:   %s\n", $stp_group->{dot1dStpRootPort};
    printf "ThisRootCost:   %s\n", $stp_group->{dot1dStpRootCost};
    printf "ThisBridgeMAC:  %s\n", $bridge_address;
    printf "ThisStpPrio:    %s\n", $stp_group->{dot1dStpPriority};
    printf "RootBridgeMAC:  %s\n",
      $stp_group->{dot1dStpDesignatedRootAddress};
    printf "RootBridgePrio: %s\n",
      $stp_group->{dot1dStpDesignatedRootPriority};

    print '-' x 75, "\n";
    printf "%-29s | %s\n", 'Local Port', 'Designated Port and Bridge';
    print '-' x 75, "\n";

    printf "%4s %4s %8s %10s | %4s %4s %8s %12s %11s\n",
      qw/Port Prio Cost State Port Prio Cost DB-Address DB-Prio/;
    print '-' x 75, "\n";

    my $stp_ports = $session->get_dot1d_stp_port_table;
    foreach my $port ( sort { $a <=> $b } keys %$stp_ports ) {
      my $port_enabled = $stp_ports->{$port}{dot1dStpPortEnable};
      next unless defined $port_enabled;
      next unless $port_enabled == 1;

      my $port_state        = $stp_ports->{$port}{dot1dStpPortState};
      my $port_state_string = $stp_ports->{$port}{dot1dStpPortStateString};
      my $port_prio         = $stp_ports->{$port}{dot1dStpPortPriority};
      my $port_path_cost    = $stp_ports->{$port}{dot1dStpPortPathCost};
      my $port_desig_cost = $stp_ports->{$port}{dot1dStpPortDesignatedCost};

      my $port_desig_bridge_prio =
        $stp_ports->{$port}{dot1dStpPortDesignatedBridgePriority};

      my $port_desig_bridge_mac =
        $stp_ports->{$port}{dot1dStpPortDesignatedBridgeAddress};

      my $port_desig_port_prio =
        $stp_ports->{$port}{dot1dStpPortDesignatedPortPriority};

      my $port_desig_port_nr =
        $stp_ports->{$port}{dot1dStpPortDesignatedPortNumber};

      printf "%4s %4s %8s %10s | %4s %4s %8s %s %6s\n", $port, $port_prio,
        $port_path_cost,       $port_state_string, $port_desig_port_nr,
        $port_desig_port_prio, $port_desig_cost,   $port_desig_bridge_mac,
        $port_desig_bridge_prio,;
    }
    print "\n";
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

Copyright (C) 2008 by Karl Gaissmaier

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: sw=2
