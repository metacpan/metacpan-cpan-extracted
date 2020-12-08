#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

vlanstatic.pl

=head1 ABSTRACT

An example script to get the vlan tag/untag info from IEEE switches.

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
use Getopt::Std;
use List::Util qw(max);

my %opts;
getopts( 'iBdt:r:c:v:', \%opts ) or usage();

my $debug     = $opts{d} || undef;
my $community = $opts{c} || 'public';
my $version   = $opts{v} || '2';
my $blocking  = $opts{b};
my $timeout   = $opts{t} || 5;
my $retries   = $opts{t} || 2;

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

  $session->mixer(qw/Net::SNMP::Mixin::IfInfo Net::SNMP::Mixin::Dot1qVlanStatic/);
  $session->init_mixins;

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
  print "######################################\n";
  printf "Hostname:    %s\n", $session->hostname;
  print_vlan_info($session);
  print "\n";
}

exit 0;

###################### end of main ######################

sub print_vlan_info {
  my $session = shift;

  my $ids2names = $session->map_vlan_id2name;
  my $ids2ifs   = $session->map_vlan_id2if_idx;
  my $ifs2ids   = $session->map_if_idx2vlan_id;

  my @trunks = sort { $a <=> $b } keys %$ifs2ids;
  my @vlans  = sort { $a <=> $b } keys %$ids2names;

  # the if list may have gaps, record the row position
  my $if2idx = {};
  my $idx    = 0;
  foreach my $if (@trunks) {
    $if2idx->{$if} = $idx;
    $idx++;
  }

  print_tab_header( $session, @trunks );
  foreach my $vlan_id ( sort { $a <=> $b } keys %{$ids2names} ) {

    # preset tagslist
    my $tags = '.' x scalar @trunks;

    foreach my $if ( @{ $ids2ifs->{$vlan_id}{tagged} } ) {
      next unless exists $if2idx->{$if};
      substr( $tags, $if2idx->{$if}, 1 ) = 't';
    }

    foreach my $if ( @{ $ids2ifs->{$vlan_id}{untagged} } ) {
      next unless exists $if2idx->{$if};
      substr( $tags, $if2idx->{$if}, 1 ) = 'u';
    }

    printf "%s vid: %4d (%s)\n", $tags, $vlan_id, $ids2names->{$vlan_id};
  }
  print_tab_header( $session, @trunks ) if scalar @vlans > 20;
}

sub print_tab_header {
  my $session = shift;
  my @trunks  = @_;

  my $if_entries = $session->get_if_entries;

  my @if_names;
  foreach my $if_idx (@trunks) {
    my $if_name = $if_entries->{$if_idx}->{ifName};

    unless ( defined $if_name ) {
      warn "ERROR: if_name missing for if_index '$if_idx'\n";
      next;
    }

    push @if_names, shorten($if_name);
  }

  # print the delimiter line
  #print '#' x scalar @trunks, "\n";
  print "\n";

  my $max_name_length = max( map( length, @if_names ) );
  foreach my $char_pos ( 0 .. $max_name_length - 1 ) {
    foreach my $if_name (@if_names) {
      no warnings 'substr';
      my $char = substr( $if_name, $char_pos, 1 );
      $char = ' ' if not defined $char;
      $char = ' ' if $char eq '';
      print $char;
    }
    print "\n";
  }
}

# strip leading and trailing whitespace
# shorten string
sub shorten {
  my $val = shift;
  return unless defined $val;

  $val =~ s/^\s*|\s*$//g;
  $val =~ s/  / /g;
  $val =~ s/Interface/If/g;
  $val =~ s/Ethernet/E/ig;
  $val =~ s/Gig(abit)?/G/g;
  $val =~ s/Forty/F/g;
  $val =~ s/Ten-?/T/g;
  $val =~ s/Hundred/H/g;
  $val =~ s/Bridge-Aggregation/Bri-Agg/ig;
  $val =~ s/Port-Channel/PO/ig;
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

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

=cut

# vim: sw=2
