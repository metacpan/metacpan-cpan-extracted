#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

dot1dbase.pl

=head1 ABSTRACT

A script to get the dot1dBase info from switches supporting the MIBs.

=head1 SYNOPSIS

 dot1dbase.pl OPTIONS agent agent ...

 dot1dbase.pl OPTIONS -i <agents.txt

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
    -debug       => $debug ? DEBUG_ALL: 0,
  );

  if ($error) {
    warn $error;
    next;
  }

  $session->mixer(qw/Net::SNMP::Mixin::Dot1dBase/);
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

print_dot1dbase();
exit 0;

###################### end of main ######################

sub print_dot1dbase {

  foreach my $session ( sort { $a->hostname cmp $b->hostname } @sessions ) {

    my $base_group = $session->get_dot1d_base_group;
    print "\n";
    printf "Hostname: %s BridgeAddr: %s NumPorts: %d Type: %d\n",
      $session->hostname, $base_group->{dot1dBaseBridgeAddress},
      $base_group->{dot1dBaseNumPorts}, $base_group->{dot1dBaseType};

    print '-' x 78, "\n";

    my $map = $session->map_bridge_ports2if_indexes;

    foreach my $bridge_port ( sort {$a <=> $b} keys %$map ) {
      my $if_index = $map->{$bridge_port};
      printf "bridgePort: %4d -> ifIndex: %4d\n", $bridge_port, $if_index;
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
EOT
}

=head1 AUTHOR

Karl Gaissmaier, karl.gaissmaier (at) uni-ulm.de

=head1 COPYRIGHT

Copyright (C) 2008-2016 by Karl Gaissmaier

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: sw=2
