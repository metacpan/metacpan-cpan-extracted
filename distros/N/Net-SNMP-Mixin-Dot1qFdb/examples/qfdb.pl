#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

qfdb.pl

=head1 ABSTRACT

A script to get the forwarding database table (FDB) from switches supporting the Q-BRIDGE-MIB:

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

Normal output prints the MAC address related to the switch/vlan/port combination with the minimum number of MAC addresses learned. This is a simple but powerful algorithm to find the enduser port or the network insertion port for a given MAC address.

It's also possible to print the whole FDB unprocessed (-R) or summary statistics for any switch/vlan/port (-S).

=head1 REQUIREMENTS

The switches must support the standard Q-BRIDGE-MIB. The script was developed with HP Procurve switches, but any Switch with standard conformity is a good candidate.

Sorry to disappoint you, Cisco isn't standard conform :-(

But you knew this already, for sure!

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
my $print_raw   = $opts{R} || undef;
my $print_stats = $opts{S} || undef;

usage('-R and -S incompatible options') if $opts{R} && $opts{S};

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

  $session->mixer(qw/Net::SNMP::Mixin::Dot1qFdb/);
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

# build FDB datastructure over all agents and all macs
# in the first run. We need a second run to decide the
# enduser/insertion port for the MACs
my $fdb    = {};
my $sums   = {};
my $result = {};

build_fdb();

if ($print_raw) {
  print_raw();
  exit 0;
}

if ($print_stats) {
  print_stats();
  exit 0;
}

find_switchport();
print_match();

exit 0;

###################### end of main ######################

sub build_fdb {
  foreach my $session (@sessions) {
    my $agent = $session->hostname;

    foreach my $fdb_entry ( $session->get_dot1q_fdb_entries() ) {
      my $mac        = $fdb_entry->{MacAddress};
      my $vlan_id    = $fdb_entry->{vlanId};
      my $status_str = $fdb_entry->{fdbStatusString};
      my $port       = $fdb_entry->{dot1dBasePort};

      # store the whole knowledge for any fdb_entry in one big hash

      $fdb->{$vlan_id}{$mac}{$agent}{status_str} = $status_str;
      $fdb->{$vlan_id}{$mac}{$agent}{port}       = $port;

      # count the macs per agent/vlan/port in order to decide
      # if this is an enduser port or a trunk

      $sums->{macs}{$agent}++;
      $sums->{vlan}{$agent}{$vlan_id}++;
      $sums->{port}{$agent}{$vlan_id}{$port}++;

    }
  }
}

# find the agent and port with the less connected MACs
# stuff it into result hash
sub find_switchport {

  foreach my $vlan_id ( keys %$fdb ) {
    my @macs = keys %{ $fdb->{$vlan_id} };
    foreach my $mac (@macs) {

      my @agents = keys %{ $fdb->{$vlan_id}{$mac} };
      foreach my $agent (@agents) {

        # get port and status for current mac in this vlan on this agent
        my $port = $fdb->{$vlan_id}{$mac}{$agent}{port};
        next unless defined $port;

        my $status_str = $fdb->{$vlan_id}{$mac}{$agent}{status_str};
        next unless defined $status_str;

        # check if we find a port with less connected systems,
        # this is a candidate for this MAC as enduser port

        my $this_port_sum = $sums->{port}{$agent}{$vlan_id}{$port};
        next unless $this_port_sum > 0;

        my $min_port_sum = $result->{$vlan_id}{$mac}{min_port_sum};

        # when do we replace the current best entry?
        if (
          not defined $min_port_sum or    # first match
          $port == 0                or    # the switch own VLAN MAC address
          $this_port_sum < $min_port_sum  # better match
          )
        {

          # this is a candidate for this MAC as enduser port
          $result->{$vlan_id}{$mac}{min_port_sum} = $this_port_sum;
          $result->{$vlan_id}{$mac}{agent}        = $agent;
          $result->{$vlan_id}{$mac}{port}         = $port;
          $result->{$vlan_id}{$mac}{status_str}   = $status_str;

        }
      }
    }
  }
}

# print the best match switchport for a MAC
sub print_match {

  # sort by vlan_id
  foreach my $vlan_id ( sort { $a <=> $b } keys %$result ) {

    # sort by port
    foreach my $mac (
      sort {
        $result->{$vlan_id}{$a}{port} <=> $result->{$vlan_id}{$b}{port}
      }
      keys %{ $result->{$vlan_id} }
      )
    {
      my $port         = $result->{$vlan_id}{$mac}{port};
      my $status_str   = $result->{$vlan_id}{$mac}{status_str};
      my $agent        = $result->{$vlan_id}{$mac}{agent};
      my $min_port_sum = $result->{$vlan_id}{$mac}{min_port_sum};

      printf
        "%-5d bridge_port(%3d) vlan(%4d) mac(%s) status(%7s) agent(%s)\n",
        $min_port_sum, $port, $vlan_id, $mac, $status_str, $agent;
    }
    print "\n";
  }
}

sub print_raw {

  # resort for print order vlan_id, port, agent
  my $resort = {};

  foreach my $vlan_id ( keys %$fdb ) {

    my @macs = keys %{ $fdb->{$vlan_id} };
    foreach my $mac (@macs) {

      my @agents = keys %{ $fdb->{$vlan_id}{$mac} };
      foreach my $agent ( sort @agents ) {

        # get port and status for current mac in this vlan on this agent
        my $port = $fdb->{$vlan_id}{$mac}{$agent}{port};
        next unless defined $port;

        my $status_str = $fdb->{$vlan_id}{$mac}{$agent}{status_str};
        next unless defined $status_str;

        my $this_port_sum = $sums->{port}{$agent}{$vlan_id}{$port};
        next unless $this_port_sum > 0;

        # store FDB in other sort order for raw printing
        $resort->{$agent}{$vlan_id}{$port}{$mac}{status_str} = $status_str;
      }
    }
  }

  # now print in resort order
  foreach my $agent ( sort keys %$resort ) {

    my @vlans = sort { $a <=> $b } keys %{ $resort->{$agent} };
    foreach my $vlan_id (@vlans) {

      my @ports = sort { $a <=> $b } keys %{ $resort->{$agent}{$vlan_id} };
      foreach my $port (@ports) {

        my @macs = sort keys %{ $resort->{$agent}{$vlan_id}{$port} };
        foreach my $mac (@macs) {

          my $status_str =
            $resort->{$agent}{$vlan_id}{$port}{$mac}{status_str};
          my $port_sum = $sums->{port}{$agent}{$vlan_id}{$port};

          printf
"%-5d bridge_port(%3d) vlan(%4d) mac(%s) status(%7s) agent(%s)\n",
            $port_sum, $port, $vlan_id, $mac, $status_str, $agent;
        }
      }
      print "\n";
    }
    print "\n";
  }
}

sub print_stats {

  foreach my $agent ( sort keys %{ $sums->{vlan} } ) {

    my @vlans = sort { $a <=> $b } keys %{ $sums->{vlan}{$agent} };
    foreach my $vlan_id (@vlans) {

      my $vlan_sum = $sums->{vlan}{$agent}{$vlan_id};

      printf "agent(%s) vlan(%4d) addresses(%4d)\n", $agent, $vlan_id,
        $vlan_sum;

    }
    print "\n";
  }
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
  	-R		print raw FDB table
  	-S		print statistics for agents
EOT
}

=head1 AUTHOR

Karl Gaissmaier, karl.gaissmaier (at) uni-ulm.de

=head1 COPYRIGHT

Copyright (C) 2008-2015 by Karl Gaissmaier

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: sw=2
