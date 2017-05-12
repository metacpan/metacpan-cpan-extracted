#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

ifinfo.pl

=head1 ABSTRACT

A script to get the ifTable and ifXTable info from switches supporting the MIBs.

=head1 SYNOPSIS

 ifinfo.pl OPTIONS agent agent ...

 ifinfo.pl OPTIONS -i <agents.txt

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
my $timeout     = $opts{t} || 3;
my $retries     = $opts{t} || 1;

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

  $session->mixer(qw/Net::SNMP::Mixin::IfInfo/);
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
  print_if($session);
}

exit 0;

###################### end of main ######################

sub print_if {
  my $session = shift;

  print "\n";
  printf "Hostname: %-15.15s\n", $session->hostname;

  print '-' x 78, "\n";
  printf "%5s %5s %6s %10s %26s %21s\n",
    'ifIdx', 'ad/op', 'ifName', 'ifDesc', 'ifAlias', 'ifType';
  print '-' x 78, "\n";

  my $if_entries = $session->get_if_entries;
  foreach my $if_index ( sort { $a <=> $b } keys %$if_entries ) {
    my $ifAdminStatus = $if_entries->{$if_index}->{ifAdminStatus} || 0;
    my $ifOperStatus  = $if_entries->{$if_index}->{ifOperStatus}  || 0;
    my $ifName        = $if_entries->{$if_index}->{ifName}        || '';
    my $ifDescr       = $if_entries->{$if_index}->{ifDescr}       || '';
    my $ifType        = $if_entries->{$if_index}->{ifType}        || '';
    my $ifAlias       = $if_entries->{$if_index}->{ifAlias}       || '';

    printf "%5d  %1d/%1d  %-10.10s %-25.25s %-22.22s %2d\n", $if_index,
      $ifAdminStatus, $ifOperStatus, $ifName, $ifDescr, $ifAlias, $ifType;
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

Copyright (C) 2008-2015 by Karl Gaissmaier

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: sw=2
