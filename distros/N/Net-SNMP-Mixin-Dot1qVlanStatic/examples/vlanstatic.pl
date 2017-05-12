#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

vlanstatic.pl

=head1 ABSTRACT

A script to get the vlan tag info from switches supporting the Q-BRIDGE-MIB.

=head1 SYNOPSIS

 vlanstatic.pl OPTIONS agent agent ...

 vlanstatic.pl OPTIONS -i <agents.txt

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
use List::Util;
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

  $session->mixer(qw/ Net::SNMP::Mixin::Dot1qVlanStatic /);

  $session->init_mixins;
  push @sessions, $session;

}
snmp_dispatcher();

# check for init errors
$_->init_ok foreach @sessions;

# remove sessions with error from the sessions list
@sessions = grep { warn $_->error if $_->error; not $_->error } @sessions;

foreach my $session ( sort { $a->hostname cmp $b->hostname } @sessions ) {
  print_header($session);
  print_vlan_tag_info($session);
}

exit 0;

###################### end of main ######################

sub print_header {
  my $session = shift;
  print "\n";
  printf "Hostname: %-15.15s\n", $session->hostname;

  my $ports2ids = $session->map_vlan_static_ports2ids;
  my $max_port = List::Util::max( keys %{ $ports2ids } );

  print '=' x $max_port, "\n";

  # mark the decades
  my @tens;
  foreach my $ten ( 1 .. $max_port / 10 ) {
    push @tens, ( ' ' x 9, $ten );
  }
  print @tens, "\n";

  # print the digits
  my @ports = ( 1 .. 9, 0 ) x ( $max_port / 10 + 1 );
  print @ports[ 0 .. $max_port - 1 ], " total $max_port bridge ports\n";

  # print the delimiter line
  print '=' x $max_port, "\n";
}

sub print_vlan_tag_info {
  my $session = shift;

  my $ids2names = $session->map_vlan_static_ids2names;
  my $ids2ports   = $session->map_vlan_static_ids2ports;
  my $ports2ids   = $session->map_vlan_static_ports2ids;

  my $max_port = List::Util::max( keys %{ $ports2ids} );

  foreach my $vlan_id ( sort { $a <=> $b } keys %{$ids2names} ) {

    # preset tagslist
    my $tags = '.' x $max_port;

    foreach my $tagged_port ( @{ $ids2ports->{$vlan_id}{tagged} } ) {
      substr( $tags, $tagged_port - 1, 1 ) = 't';
    }

    foreach my $untagged_port ( @{ $ids2ports->{$vlan_id}{untagged} } ) {
      substr( $tags, $untagged_port - 1, 1 ) = 'u';
    }

    printf "%s vid: %4d (%s)\n", $tags, $vlan_id, $ids2names->{$vlan_id};
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

Copyright (C) 2008-2016 by Karl Gaissmaier

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

=cut

# vim: sw=2
