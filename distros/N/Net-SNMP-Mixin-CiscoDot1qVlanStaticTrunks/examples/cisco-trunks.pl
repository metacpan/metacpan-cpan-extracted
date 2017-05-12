#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

mgetciscotrunk.pl

=head1 ABSTRACT

A script to get the vlan tag info from switches supporting the CISCO-VTP-MIB.

=head1 SYNOPSIS

 cisco-trunks.pl OPTIONS agent agent ...

 cisco-trunks.pl OPTIONS -i <agents.txt

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

my $debug     = $opts{d} || undef;
my $community = $opts{c} || 'public';
my $version   = $opts{v} || '2';
my $blocking  = $opts{b};
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
    -debug       => $debug ? DEBUG_ALL: 0,
  );

  if ($error) {
    warn $error;
    next;
  }

  $session->mixer( qw/Net::SNMP::Mixin::IfInfo Net::SNMP::Mixin::CiscoDot1qVlanStaticTrunks/);

  $session->init_mixins;;
  push @sessions, $session;

}

snmp_dispatcher();

# check for init errors
$_->init_ok foreach @sessions;

# remove sessions with error from the sessions list
@sessions = grep {
  if ( $_->errors ) { warn scalar $_->errors, "\n"; undef }
  else              { 1 }
} @sessions;


foreach my $session ( sort { $a->hostname cmp $b->hostname } @sessions ) {
  print_header($session);
  print_cisco_trunk_info($session);
}

exit 0;

###################### end of main ######################

sub print_header {
  my $session  = shift;
  print "\n";
  printf "Hostname: %-15.15s\n", $session->hostname;
  printf "---------------------------------------------------\n";
}

sub print_cisco_trunk_info {
  my $session = shift;

  printf "%-5s %-8s %-20.20s %s\n", 'INDEX', 'NAME', 'ALIAS', 'VLANS';
  
  my $trunk_ports2vlan_ids = $session->cisco_trunk_ports2vlan_ids;
  foreach my $if_idx (
    sort { $a <=> $b }
    keys %{ $trunk_ports2vlan_ids }
    )
  {
    # get the vlan ids for this trunk port
    my $trunk_vlan_ids = $trunk_ports2vlan_ids->{$if_idx};
    my @trunk_vlan_ids = sort{ $a <=> $b } @$trunk_vlan_ids;

    # get the interface name for this trunk port
    my $if_name = $session->get_if_entries->{$if_idx}->{ifName} || "${if_idx}_noname";
    my $if_alias = $session->get_if_entries->{$if_idx}->{ifAlias} || "${if_idx}_noalias";

    printf "%-5d %-8s %-20.20s %s\n", $if_idx, $if_name, $if_alias, join( ':', @trunk_vlan_ids );
  }

  print "\n\n";

  printf "%-4s %-20.20s  %s\n", 'ID', 'NAME', 'TRUNKS';

  my $vlan_ids2names = $session->cisco_vlan_ids2names;
  my $vlan_ids2trunk_ports = $session->cisco_vlan_ids2trunk_ports;
  foreach my $vlan_id (sort {$a <=> $b} keys %{ $vlan_ids2names } ) {
    # get the trunk ports for this vlan id
    my $trunk_ports = $vlan_ids2trunk_ports->{$vlan_id};
    my @trunk_ports = sort{ $a <=> $b } @$trunk_ports;

    # get the vlan name for this vlan_id
    my $vlan_name = $vlan_ids2names->{$vlan_id} || "${vlan_id}_noname";

    printf "%-4d %-20.20s  %s\n", $vlan_id, $vlan_name, join( ':', @trunk_ports );
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
EOT
}

=head1 AUTHOR

Karl Gaissmaier, karl.gaissmaier (at) uni-ulm.de

=head1 COPYRIGHT

Copyright (C) 2011-2016 by Karl Gaissmaier

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

=cut

# vim: sw=2
