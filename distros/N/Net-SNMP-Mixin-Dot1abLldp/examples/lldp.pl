#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

lldp.pl

=head1 ABSTRACT

A script to get the LLDP information from switches supporting the MIBs.

=head1 SYNOPSIS

 lldp.pl OPTIONS agent agent ...

 lldp.pl OPTIONS -i <agents.txt

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
my $blocking  = $opts{b};
my $timeout   = $opts{t} || 5;
my $retries   = $opts{r} || 1;

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

  $session->mixer( qw/ Net::SNMP::Mixin::Dot1abLldp /);

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
  print_lldp($session);
}

exit 0;

###################### end of main ######################

sub print_lldp {
  my $session = shift;

  my $lldp_loc_port_tbl = $session->get_lldp_loc_port_table;
  my $lldp_rem_tbl      = $session->get_lldp_rem_table;

  print "\n";
  printf "Hostname: %-15.15s ChassisID: %-17.17s\n",
    $session->hostname,
    $session->get_lldp_local_system_data->{lldpLocChassisId};

  print '-' x 115, "\n";

  printf "%5s %5s %25.25s %25.25s %25.25s %25s\n", 'LPort', 'LDesc',
    'RemSysName',
    'RemPortId', 'RemPortDesc', 'RemChassisId';

  print '-' x 115, "\n";

  foreach my $lport ( sort { $a <=> $b } keys %$lldp_rem_tbl ) {
    foreach my $idx ( sort { $a <=> $b } keys %{ $lldp_rem_tbl->{$lport} } ) {
      my $ldesc            = $lldp_loc_port_tbl->{$lport}{lldpLocPortDesc};
      my $lldpRemPortId    = $lldp_rem_tbl->{$lport}{$idx}{lldpRemPortId};
      my $lldpRemPortDesc  = $lldp_rem_tbl->{$lport}{$idx}{lldpRemPortDesc};
      my $lldpRemSysName   = $lldp_rem_tbl->{$lport}{$idx}{lldpRemSysName};
      my $lldpRemChassisId = $lldp_rem_tbl->{$lport}{$idx}{lldpRemChassisId};

      printf "%5s %5s %25.25s %25.25s %25.25s %25s\n", $lport, $ldesc,
        $lldpRemSysName, $lldpRemPortId, $lldpRemPortDesc, $lldpRemChassisId;
    }
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
  	-B		nonblocking, default
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
