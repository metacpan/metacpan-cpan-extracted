#!/usr/bin/env perl
# -*- mode: perl; coding: iso-8859-1 -*-
# Author: Peter Corlett
# Contact: abuse@cabal.org.uk
# Revision: $Revision$
# Date: $Date$
# Copyright: (c) 2005 Peter Corlett - All Rights Reserved

package SNMP::Server::Logtail;
require v5.8.1;			# need 5.8.1 for reliable threads
use strict;
use vars qw( $VERSION @ISA @EXPORT );
# $Id: Logtail.pm 35 2005-09-27 13:27:28Z abuse $
$VERSION = do { my @r=(q$Revision: 35 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
@EXPORT=qw( snmpd_init add_oidmap add_logfile snmpd_run );
@ISA=qw( Exporter );

use threads;
use threads::shared;

use CGI::Carp qw(set_progname);
use Data::Dumper;
require Exporter;

# This hash contains the counters for various events
my %counter;
share %counter;

my $stop=0;
share $stop;

my %oidmap;
my %oidnext;

my $running;
my @threads;

my $prefix;

=head1 NAME

SNMP::Server::Logtail - Tails logfiles and presents counters via SNMP

=head1 SYNOPSIS

 #!/usr/bin/perl
 use SNMP::Server::Logtail;

 sub exim_mainlog {
   my($hash, $line)=@_;
   $hash->{MSG_IN}++ if /^<= /;
   $hash->{MSG_OUT}++ if /^=> /;
   # etc
 }

 snmpd_init( -logfile => '/tmp/testlog',
	     -prefix => '.1.3.6.1.4.1.2021.255' );
 add_oidmap( MSG_IN => 1,
	     MSG_OUT => 2 );
 add_logfile('/var/log/exim/mainlog' => \&exim_mainlog);
 snmpd_run();

=head1 DESCRIPTION

This module implements the core functionality that combines with the
Net-SNMP SNMP daemon (not to be confused with the Net::SNMP Perl
module) which allows you to monitor updates to a logfile. Typically,
it's used to present a MIB of counters that increment whenever certain
events are logged. It also detects when the logfile has been rotated
and will start monitoring the new logfile when this occurs.

The example in SYNOPSIS above is a complete program that Net-SNMP can
use. Note that this module imports functions into your namespace, has
global variables, and is generally hostile to your script doing
anything other than purely being a client to it. This is intentional.

To tell Net-SNMP about your new MIB and script, insert the following
line into I<snmpd.conf>:

 pass_persist .1.3.6.1.4.1.2021.255 /path/to/script.pl

and then reload Net-SNMP. You can then perform a SNMP query:

 snmpget -v 1 -c public localhost .1.3.6.1.4.1.2021.255.1

You can obviously also read this by using Net::SNMP, MRTG, or similar.

The function set with add_logfile() is called back whenever a new
entry appears in the logfile. It is passed a hash reference and single
lines from the logfile. The function may use the hash as it sees fit,
although normally it would just increment/set values in the hash as
new log data becomes available to it.

The arguments given to add_oidmap() define which entries in the hash
are read whenever a SNMP query is made. It contains key/value pairs.
The key corresponds to keys in the hash which are read - the value is
the suffix of the OID that causes this read. (The OID's prefix is
given in snmpd_init.)

=head1 FUNCTIONS

=over 4

=item B<snmpd_init>

 snmpd_init( -logfile => '/tmp/testlog',
	     -prefix => '.1.3.6.1.4.1.2021.255' );

Initialises the global state for the log tailer. This script's own
diagnostics goes to the logfile given with B<-logfile> and the base
OID for the MIB you're creating is given with B<-prefix>.

=cut

sub snmpd_init {
  my(%opts)=@_;

  my $logfile=$opts{-logfile};
  croak "-logfile not set" unless defined $logfile;
  $prefix=$opts{-prefix};
  croak "-prefix not set" unless defined $prefix;
  my $logname=$opts{-logname} || $0;

  open STDERR, '>>', $logfile
    or croak "Can't create/append $logfile: $!";

  set_progname("${logname}[$$]");
  $running++;
  warn "Started\n";
  $|=1;
}

sub END {
  warn "Crashed!\n"
    if $running;
}

=item B<add_oidmap>

 add_oidmap( ACCEPT => 1,
	     REJECT => 2 );

This adds a mapping of keywords to OIDs.

=cut

sub add_oidmap {
  %oidmap=(%oidmap, reverse @_);

  my @oids=sort {$a<=>$b} keys %oidmap;
  $oidnext{''}=$oids[0];
  foreach(1..$#oids) {
    $oidnext{$oids[$_-1]}=$oids[$_];
  }
}

sub run_monitor {
  my($logname, $subref)=@_;
  warn "Starting monitoring $logname\n";
  my $first=1;
  until($stop) {
    open LOG, '<', $logname
      or croak "Can't open $logname: $!";
    my($curinode, $cursize)=(stat LOG)[(1, 7)];
    if($first) {
      # If this is the first run (i.e. the logfile hasn't been rotate
      # on us) we seek to the end of the file and start tailing from
      # there. This is so that all the previous entries in the logfile
      # don't appear all at once and be potentially graphed as
      # happening in the last moment.
      seek LOG, 2, 0;
      $first=0;
    }
    my $rotated=0;
    until($rotated || $stop) {
      my($newinode, $newsize)=(stat $logname)[(1, 7)];
      while(my $line=<LOG>) {
	lock %counter;
	&{$subref}(\%counter, $line);
	#print "\033[H\033[J", Dumper \%counter, scalar localtime;
	last if $stop;
      }
      sleep 1;
      # has logfile been rotated?
      if(defined $newinode && (
			       $newinode != $curinode # file has been rotated
			       || $newsize < $cursize # file has been truncated
			      )
	) {
	$rotated=1;
	warn "Log rotated, will reopen $logname\n";
      }
    }
  }
  warn "Stopped monitoring $logname\n";
}


=item B<add_logfile>

 add_logfile('/var/log/exim/mainlog' => \&exim_mainlog);

This adds another logfile to be monitored, and registers a callback
function which will be called for each new line that appears in the
logfile.

=cut

sub add_logfile {
  my($logname, $subref)=@_;
  my $thread=threads->create('run_monitor', $logname, $subref);
  push @threads, $thread;
}

=item B<snmpd_run>

 snmpd_run();

This starts the main loop. Control will return when Net-SNMP is shut
down, so you should only clean up and exit after this occurs.

=cut

sub snmpd_run {
  while (my $command=<STDIN>) {
    chomp $command;
    if ($command=~/^PING/){
      #warn "Answering snmpd PING\n" if $DEBUG;
      print "PONG\n";
      next;
    }
    my $oid=<>;
    chomp $oid;
    my($suffix)=$oid=~/^$prefix\.?(.*)$/o;
    $suffix='' unless defined $suffix;
    if ($command eq "getnext") {
      #warn "Answering getnext for suffix $suffix\n" if $DEBUG;
      if(exists $oidnext{$suffix}) {
	$suffix=$oidnext{$suffix};
      } else {
	$suffix='NONE';
      }
    }
    #warn "Answering get for suffix $suffix\n" if $DEBUG;
    if(exists $oidmap{$suffix}) {
      lock %counter;
      my $value=$counter{$oidmap{$suffix}} || 0;
      $value &= 0xffffffff;
      print "$prefix.$suffix\ncounter\n$value\n";
    } else {
      print "NONE\n";
    }
  }

  warn "Shutting down...\n";
  $stop=1;
  $_->join foreach @threads;
  warn "Stopped\n";
  $running=0;
}

=back

=head1 BUGS

This documentation is terrible. Reading the example client may be more
helpful.

=head1 SEE ALSO

Net::SNMP

=head1 AUTHOR

All code and documentation by Peter Corlett <abuse@cabal.org.uk>.

=head1 COPYRIGHT

Copyright (C) 2004 Peter Corlett <abuse@cabal.org.uk>. All rights
reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SUPPORT / WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=cut
  
1;

