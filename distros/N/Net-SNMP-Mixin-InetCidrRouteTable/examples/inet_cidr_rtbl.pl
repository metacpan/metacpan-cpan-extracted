#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

iprtbl.pl

=head1 ABSTRACT

A script to get the inetCidrRouteTable information from devices supporting the MIBs.

=head1 SYNOPSIS

 inet_cidr_rtbl.pl OPTIONS agent agent ...

 inet_cidr_rtbl.pl OPTIONS -i <agents.txt

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
getopts( 'iBdt:r:m:c:v:', \%opts ) or usage();

my $debug       = $opts{d} || undef;
my $community   = $opts{c} || 'public';
my $version     = $opts{v} || '2';
my $nonblocking = $opts{B} || 0;
my $timeout     = $opts{t} || 5;
my $retries     = $opts{t} || 0;
my $maxmsgsize  = $opts{m} || 2500;

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
    -maxmsgsize  => $maxmsgsize,
    -debug       => $debug ? DEBUG_ALL : 0,
  );

  if ($error) {
    warn $error;
    next;
  }

  $session->mixer(qw/ Net::SNMP::Mixin::IfInfo Net::SNMP::Mixin::InetCidrRouteTable /);

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

# remove sessions with errors from the sessions list
@sessions = grep { not $_->errors(1) } @sessions;

foreach my $session ( sort { $a->hostname cmp $b->hostname } @sessions ) {
  print_inet_cidr_rtbl($session);
}

exit 0;

###################### end of main ######################

sub print_inet_cidr_rtbl {
  my $session = shift;

  print "\n";
  printf "Hostname: %-15.15s\n", $session->hostname;

  print '-' x 150, "\n";
  printf "%-50s => %-40s %-8s %-10s %s\n", 'Route', 'NextHop', 'Proto', 'Type', 'ifName(Description)';
  print '-' x 150, "\n";

  my $if_entries = $session->get_if_entries();
  my @routes     = $session->get_inet_cidr_route_table();

  foreach my $route (@routes) {
    my $prefix    = $route->{inetCidrRoutePrefix};
    my $nhop      = $route->{inetCidrRouteNextHop};
    my $proto_str = $route->{inetCidrRouteProtoString};
    my $type_str  = $route->{inetCidrRouteTypeString};
    my $if_index  = $route->{inetCidrRouteIfIndex};
    my $age       = $route->{inetCidrRouteAge};
    # ...

    my $if_name  = $if_entries->{$if_index}->{ifName}  || "idx: $if_index";
    my $if_alias = $if_entries->{$if_index}->{ifAlias} || "idx: $if_index";

    printf "%-50s => %-40s %-8s %-10s %s(%s)\n", $prefix, $nhop, $proto_str, $type_str, $if_name, $if_alias;
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
  	-m maxmsgsize
  	-d		Net::SNMP debug on
	-i		read agents from stdin
  	-B		nonblocking
EOT
}

=head1 AUTHOR

Karl Gaissmaier, karl.gaissmaier (at) uni-ulm.de

=head1 COPYRIGHT

Copyright (C) 2019 by Karl Gaissmaier

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: sw=2
