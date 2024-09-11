#!/usr/bin/env perl

use strict;
use warnings;

use blib;
use Net::SNMP qw(:debug :snmp);
use Net::SNMP::Mixin;
use Getopt::Std;

=head1 NAME

poe.pl

=head1 ABSTRACT

A script to get the PoE information from switches supporting the MIBs.

=head1 SYNOPSIS

 poe.pl OPTIONS agent agent ...

 poe.pl OPTIONS -i <agents.txt

=head2 OPTIONS

  -c snmp_community
  -v snmp_version
  -t snmp_timeout
  -r snmp_retries

  -d			Net::SNMP debug on
  -i			read agents from stdin, one agent per line
  -b			blocking

=cut

my %opts;
getopts('ibdt:r:c:v:', \%opts) or usage();

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
foreach my $agent (sort @agents) {
  my ($session, $error) = Net::SNMP->session(
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

  $session->mixer(qw/Net::SNMP::Mixin::PoE/);
  $session->init_mixins;
  push @sessions, $session;
}

snmp_dispatcher();

# check for init errors
$_->init_ok foreach @sessions;

# remove sessions with error from the sessions list
@sessions = grep {
  if ($_->errors) { warn scalar $_->errors, "\n"; undef }
  else            {1}
} @sessions;

foreach my $session (sort { $a->hostname cmp $b->hostname } @sessions) {
  print_poe($session);
}

exit 0;

###################### end of main ######################

sub print_poe {
  my $session = shift;

  my $poe_main_tbl = $session->get_poe_main_table;

  print "\n";
  printf "Hostname: %-25.25s\n", $session->hostname;

  foreach my $group (sort { $a <=> $b } keys %$poe_main_tbl) {
    printf "\n";
    printf "PoE Group:   %d\n", $group;
    print '-' x 100, "\n";
    printf "OperStatus:  %d\n",          $poe_main_tbl->{$group}{operStatus};
    printf "Power:       %-4d [Watt]\n", $poe_main_tbl->{$group}{power};
    printf "Consumption: %-4d [Watt]\n", $poe_main_tbl->{$group}{consumption};
    printf "Threshold:   %-4d [%%]\n",   $poe_main_tbl->{$group}{threshold};
  }

  my $poe_port_tbl = $session->get_poe_port_table;

  print '-' x 130, "\n";
  printf "group port adminEnable pwrPairsCtrl pwrPairs detectionStatus prio mpsAbsent type   pwrClass invSignature pwrDenied overload short\n";
  print '-' x 130, "\n";

  foreach my $group (sort { $a <=> $b } keys %$poe_port_tbl) {
    foreach my $port (sort { $a <=> $b } keys %{$poe_port_tbl->{$group}}) {
      my $adminEnable      = $poe_port_tbl->{$group}{$port}{adminEnable};
      my $powerPairsCtrl   = $poe_port_tbl->{$group}{$port}{powerPairsCtrl};
      my $powerPairs       = $poe_port_tbl->{$group}{$port}{powerPairs};
      my $detectionStatus  = $poe_port_tbl->{$group}{$port}{detectionStatus};
      my $priority         = $poe_port_tbl->{$group}{$port}{priority};
      my $mpsAbsent        = $poe_port_tbl->{$group}{$port}{mpsAbsent};
      my $type             = $poe_port_tbl->{$group}{$port}{type};
      my $powerClass       = $poe_port_tbl->{$group}{$port}{powerClass};
      my $invalidSignature = $poe_port_tbl->{$group}{$port}{invalidSignature};
      my $powerDenied      = $poe_port_tbl->{$group}{$port}{powerDenied};
      my $overload         = $poe_port_tbl->{$group}{$port}{overload};
      my $short            = $poe_port_tbl->{$group}{$port}{short};

      printf "%5d %4d %11d %12d %8d %15d %4d %8d %7s %8d %12d %9d %8d %5d\n",                                  #
        $group, $port, $adminEnable, $powerPairsCtrl, $powerPairs, $detectionStatus, $priority, $mpsAbsent,    #
        $type, $powerClass, $invalidSignature, $powerDenied, $overload, $short;
    }
    print '-' x 130, "\n";
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
  	-B		nonblocking, default
EOT
}

=head1 AUTHOR

Karl Gaissmaier, karl.gaissmaier (at) uni-ulm.de

=head1 COPYRIGHT

Copyright (C) 2021-2024 by Karl Gaissmaier

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: sw=2
