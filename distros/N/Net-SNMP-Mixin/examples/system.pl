#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

system.pl

=head1 ABSTRACT

A script to get the SNMP mib-II system-group values from agents.

=head1 SYNOPSIS

 system.pl OPTIONS agent agent ...

 system.pl OPTIONS -i <agents.txt

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

  $session->mixer(qw/Net::SNMP::Mixin::System/);
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
  print_system($session);
}
exit 0;

###################### end of main ######################

sub print_system {
  my $session = shift;

  my $system_group = $session->get_system_group;
  print "\n";
  printf "Hostname:    %s\n", $session->hostname;
  printf "sysName:     %s\n", $system_group->{sysName};
  printf "sysLocation: %s\n", $system_group->{sysLocation};
  printf "sysContact:  %s\n", $system_group->{sysContact};
  printf "sysObjectID: %s\n", $system_group->{sysObjectID};
  printf "sysUpTime:   %s\n", $system_group->{sysUpTime};
  printf "sysServices: %s\n", $system_group->{sysServices};
  printf "sysDescr:    %s\n", $system_group->{sysDescr};
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

Copyright (C) 2008-2015 by Karl Gaissmaier

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: sw=2
