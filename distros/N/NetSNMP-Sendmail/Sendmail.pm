# THIS FILE IS GENERATED AUTOMATICALLY.  PLEASE DO NOT EDIT.
# SNMP Sendmail Statistics Module
# Copyright (C) 2015, 2016 Sergey Poznyakoff <gray@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

NetSNMP::Sendmail - NetSNMP plugin for Sendmail statistics

=head1 SYNOPSIS

B<perl use NetSNMP::Sendmail qw (:config bindir /usr/bin/sm.bin);>    
    
=head1 DESCRIPTION

A perl plugin for B<net-snmp> that provides access to Sendmail
statistics information obtained by B<mailq> and B<mailstats>.

In most cases adding

    perl use NetSNMP::Sendmail;

to B<snmpd.conf>(5) is enough to get the plugin working.  You may
however need to tune it.  For example, Debian-based distributions
override default Sendmail binaries with homemade scripts that have
somewhat different output format, which can confuse this module.  The
binaries are then located in the F</usr/lib/sm.bin> directory.  To have
the plugin use the right binaries, load it as follows:

    perl use NetSNMP::Sendmail qw(:config bindir /usr/lib/sm.bin);

Another way to do so would be to export the B<Configure> method and
call it right after requiring the module:

    perl use NetSNMP::Sendmail qw(Configure);
    perl NetSNMP::Sendmail::Configure(bindir => '/usr/lib/sm.bin');

In general, configuration options and corresponding values are either
passed as a hash to the B<Configure> function, or passed with the
B<use> statement following the B<:config> marker.  The following
options are defined:

=over 4    

=item B<bindir>

Directory where to look for B<mailq> and B<mailstats>.  It is unset by
default, which means that both binaries will be looked up using the
B<PATH> environment variable, unless they are set to absolute pathname
using B<mailq> and B<mailstats> keywords.

=item B<cf>

Absolute name of the Sendmail configuaration file.  Defaults to
F</etc/mail/sendmail.cf>.    
    
=item B<mailstats>

Name of the B<mailstats> binary.  Default is B<mailstats>.    
    
=item B<mailq>

Name of the B<mailq> binary.  Default is B<mailq>.    
    
=item B<mailstats_ttl>

Time in seconds during which the result of the recent invocation of
B<mailstats>(8) is cached.  Default is 10.
    
=item B<mailq_ttl>

Time in seconds during which the result of the recent invocation of
B<mailq>(1) is cached.  Default is 10.

=back    

=head2 OIDS
    
The MIB is defined in file SENDMAIL-STATS.txt, which is distributed along
with this module.  The following OIDs are defined:

=over 4

=item B<queueTotal.0>

Total number of messages in the queue.

=item B<queueTable>

This OID provides a conceptual table of Sendmail queue groups.  Each row has
the following elements (I<N> stands for the row index):

=over 4

=item B<queueName.>I<N>

Name of the queue group.
    
=item B<queueDirectory.>I<N>

Queue directory.
    
=item B<queueMessages.>I<N>    

Number of messages in that queue group. 
    
=back    
    
=item B<mailerTable>

This OID provides a conceptual table of mailers with the corresponding
statistics.  Each row has the following elements (I<N> stands for the
row index):

=over 4    
    
=item B<mailerName.>I<N>

Name of the mailer, as set in its definition in F<sendmail.cf>.
    
=item B<mailerMessagesFrom.>I<N>

Number of outgoing messages sent using this mailer.    
    
=item B<mailerKBytesFrom.>I<N>

Number of kilobytes in outgoing messages sent using this mailer.
    
=item B<mailerMessagesTo.>I<N>

Number of messages received using this mailer.
    
=item B<mailerKBytesTo.>I<N>

Number of kilobytes in messages received using this mailer.
    
=item B<mailerMessagesRejected.>I<N>

Number of messages rejected by this mailer.    
    
=item B<mailerMessagesDiscarded.>I<N>

Number of messages discarded by this mailer.    
    
=item B<mailerMessagesQuarantined.>I<N>

Number of messages put in quarantine by this mailer.
    
=back

    
=item B<totalMessagesFrom.0>

Total number of outgoing messages.
    
=item B<totalKBytesFrom.0>

Total number of outgoing kilobytes.
    
=item B<totalMessagesTo.0>

Total number of incoming messages.
    
=item B<totalKBytesTo.0>

Total number of incoming kilobytes.
    
=item B<totalMessagesRejected.0>

Total number of rejected messages.
    
=item B<totalMessagesDiscarded.0>

Total number of discarded messages.
    
=item B<totalMessagesQuarantined.0>

Total number of messages put in quarantine.
    
=item B<connectionMessagesFrom.0>

Number of messages sent over TCP connections.
    
=item B<connectionMessagesTo.0>

Number of messages received over TCP connections.
    
=item B<connectionMessagesRejected.0>

Number of messages that arrived over TCP connections and were rejected.

=back    

=head1 SEE ALSO

B<snmpd.conf>(5), B<snmpd>(8), B<mailq>(1), B<mailstats>(8).

=head1 LICENSE

GPLv3+: GNU GPL version 3 or later, see
<http://gnu.org/licenses/gpl.html>

This  is  free  software:  you  are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
    
=head1 AUTHOR

Sergey Poznyakoff <gray@gnu.org>.    
    
=cut

package NetSNMP::Sendmail;
require 5.10.0;
use strict;
use warnings;
use feature 'state';
use NetSNMP::agent::Support;
use NetSNMP::agent (':all'); 
use NetSNMP::ASN (':all');
use Carp;

use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION = "0.95";

our @EXPORT_OK = qw(&Configure);

my $sendmail_cf = '/etc/mail/sendmail.cf';
my $mailq_bin = 'mailq';
my $mailstats_bin = 'mailstats';

my %ttl = (
    mailq => 10,
    mailstats => 10
);

my %config = (
    mailq_ttl => \$ttl{mailq},
    mailstats_ttl => \$ttl{mailstats},
    mailq => \$mailq_bin,
    mailstats => \$mailstats_bin,
    cf => \$sendmail_cf,	      
    bindir => sub {
	$mailq_bin = "$_[1]/$mailq_bin" if $mailq_bin !~ m#^/#;
	$mailstats_bin = "$_[1]/$mailstats_bin" if $mailstats_bin !~ m#^/#;
    }
);

sub debug {
}

sub Configure {
#    print Dumper ( \@_ );
    local %_ = @_;
    while (my ($k,$v) = each %_) {
	if (exists($config{$k})) {
	    if (ref($config{$k}) eq 'CODE') {
		&{$config{$k}}($k, $v);
	    } else {
		${$config{$k}} = $v;
	    }
	} else {
	    confess "unknown keyword: $k";
	}
    }
}

sub import {
    my $pkg = shift;            # package
    my @syms = ();              # symbols to import
    my @config = ();            # configuration
    my $dest = \@syms;          # symbols first
    for (@_) {
	if ($_ eq ':config') {
	    $dest = \@config;
	    next;
	}
	push @$dest, $_;
    }
    local $Exporter::ExportLevel = 1;
    $pkg->SUPER::import(@syms);
    Configure(@config) if @config;
}

my %qgroup;
my $qdir;

my %qopt = ( F => 'queueFlags',
	     N => 'queueNice',
	     I => 'queueInterval',
	     P => 'queueDirectory',
	     R => 'queueRunners',
	     J => 'queueJobs',
	     r => 'queueMaxRecipients' );

sub readcf {
    open(my $fd, '<', $sendmail_cf)
	or do {
	    warn "can't open $sendmail_cf: $!";
	    return;
	};
    while (<$fd>) {
	chomp;
	next if /^#/;
	if (/^O\s+QueueDirectory=(.+)/) {
	    # O QueueDirectory=/var/spool/mqueue
	    $qdir = $1;
	} elsif (/^Q([^,]+),\s+(.+)/) {
	    # Qlocal, P=/var/spool/mqueue/local, F=f, R=2, I=1m
	    my $name = $1;
	    # Collect parameters.  So far only P is actially used.
	    my %h = map { if (/([a-zA-Z])[^=]*=(.+)/) {
		             if (exists($qopt{$1})) {
				 $qopt{$1} => $2;
			     } else {
				 ()
			     }
			  } else {
			      ()
			  }
	              } split /,\s*/, $2;
	    if (exists($h{queueDirectory})) {
		my $dir = $h{queueDirectory};
		delete $h{$dir};
		$h{queueName} = $name;
		$qgroup{$dir} = \%h;
	    }
	}
    }
    close($fd);
}

# Read Sendmail configuration
readcf();

my %timestamp;

sub queue_stats {
    state %tmp;

    if ($ttl{mailq}) {
	my $now = time();
	return %tmp if $now - $timestamp{mailq} < $ttl{mailq};
	$timestamp{mailq} = $now;
	%tmp = ();
    }
    open(my $fd, '-|', $mailq_bin)
	or die "can't run $mailq_bin: $!";
    while (<$fd>) {
	chomp;
	if (/^(^\S+) is empty/) {
	    push @{$tmp{q}}, { queueName => $qgroup{$1}{queueName} || "",
			       queueDirectory => $1,
			       queueMessages => 0 };
	} elsif (/^\s*(\S+) \((\d+) requests\)/) {
	    push @{$tmp{q}}, { queueName => $qgroup{$1}{queueName} || "",
			       queueDirectory => $1,
			       queueMessages => $2 };
	} elsif (/Total requests:\s+(\d+)\s*$/) {
	    $tmp{total} = $1 
	}
    }
    close($fd);
    return %tmp;
}

sub mailer_stats {
    state $timestamp;
    state %mstats;

    my $now = time();
    return %mstats if $now - $timestamp{mailstats} < $ttl{mailstats};
    $timestamp{mailstats} = $now;
    %mstats = ();

    debug("calling $mailstats_bin");    
    open(my $fd, '-|', "$mailstats_bin -P")
	or die "can't run $mailstats_bin: $!";
    my $line = 0;

    while (<$fd>) {
	++$line;

	next if $line == 1;
	
	s/^\s+//;
#  msgsfr  bytes_from   msgsto    bytes_to  msgsrej msgsdis msgsqur  Mailer
	my @a = split /\s+/;
	if ($a[0] eq 'T') {
	    @{$mstats{totals}}{('totalMessagesFrom',
				'totalKBytesFrom',	      
				'totalMessagesTo',
				'totalKBytesTo',
				'totalMessagesRejected',
				'totalMessagesDiscarded', 
				'totalMessagesQuarantined')} = @a[1..7];
	} elsif ($a[0] eq 'C') {
	    @{$mstats{conn}}{('connectionMessagesFrom',
			      'connectionMessagesTo',
			      'connectionMessagesRejected')} = @a[1..3];
	} else {
	    my %h;
	    @h{('mailerMessagesFrom',
		'mailerKBytesFrom',	      
		'mailerMessagesTo',
		'mailerKBytesTo',
		'mailerMessagesRejected',
		'mailerMessagesDiscarded', 
		'mailerMessagesQuarantined',
		'mailerName')} = @a[1..8];
	    push @{$mstats{mailer}}, \%h;
	}
    }
    close($fd);
    return %mstats;
}

# #############

sub get_queueTotal {
    my %qstats = queue_stats();
    return $qstats{total};
}

sub get_queueTable {
    my ($name, $off, $oid) = @_;
    my $idx = getOidElement($oid, $off);
    my %qstats = queue_stats();
    return $qstats{q}->[$idx-1]{$name};
}

sub check_queueTable {
    my ($off, $oid) = @_;
    my $idx = getOidElement($oid, $off);
    my %qstats = queue_stats();
    return $idx-1 <= $#{$qstats{q}};
}

sub next_queueTable {
    my ($len, $oid) = @_;
    
    my $idx = getOidElement($oid, $len);
    my %qstats = queue_stats();
    ++$idx;
    if ($idx-1 <= $#{$qstats{q}}) {
	return setOidElement($oid, $len, $idx);
    }
    return 0;
}

sub get_mailerTable {
    my ($name, $off, $oid) = @_;
    my $idx = getOidElement($oid, $off);
    my %mstats = mailer_stats();
    return $mstats{mailer}->[$idx-1]{$name};
}

sub check_mailerTable {
    my ($off, $oid) = @_;
    my $idx = getOidElement($oid, $off);
    my %mstats = mailer_stats();
    return $idx-1 <= $#{$mstats{mailer}};
}

sub next_mailerTable {
    my ($len, $oid) = @_;
    
    my $idx = getOidElement($oid, $len);
    my %mstats = mailer_stats();

    ++$idx;
    if ($idx-1 <= $#{$mstats{mailer}}) {
	return setOidElement($oid, $len, $idx);
    }
    return 0;
}

sub total_table_get {
    my $name = shift;
    my %mstats = mailer_stats();
    return $mstats{totals}->{$name};
}

sub connection_table_get {
    my $name = shift;
    my %mstats = mailer_stats();
    return $mstats{conn}->{$name};
}

# Hash for all OIDs
my  $oidtable={
    ".1.3.6.1.4.1.9163.100.1.2.1.2.0" => {
	func     => sub { get_queueTable('queueName', 12, @_) },
	type     => ASN_OCTET_STR,
	check    => sub { check_queueTable(12, @_) },
        nextoid  => sub { next_queueTable(12, @_) },
	istable  => '1',
	next     => "",
	numindex => 1
     },
    ".1.3.6.1.4.1.9163.100.1.2.1.3.0" => {
	func     => sub { get_queueTable('queueDirectory', 12, @_) },
	type     => ASN_OCTET_STR,
	check    => sub { check_queueTable(12, @_) },
        nextoid  => sub { next_queueTable(12, @_) },
	istable  => '1',
	next     => "",
	numindex => 1
     },
    ".1.3.6.1.4.1.9163.100.1.2.1.4.0" => {
	func     => sub { get_queueTable('queueMessages', 12, @_) },
	type     => ASN_GAUGE,
	check    => sub { check_queueTable(12, @_) },
        nextoid  => sub { next_queueTable(12, @_) },
	istable  => '1',
	next     => "",
	numindex => 1
     },
    ".1.3.6.1.4.1.9163.100.2.1.2.0" => {
	func     => sub { get_mailerTable('mailerName', 11, @_) },
	type     => ASN_OCTET_STR,
	check    => sub { check_mailerTable(11, @_) },
        nextoid  => sub { next_mailerTable(11, @_) },
	istable  => '1',
	next     => "",
	numindex => 1
     },
    ".1.3.6.1.4.1.9163.100.2.1.3.0" => {
	func     => sub { get_mailerTable('mailerMessagesFrom', 11, @_) },
	type     => ASN_COUNTER64,
	check    => sub { check_mailerTable(11, @_) },
        nextoid  => sub { next_mailerTable(11, @_) },
	istable  => '1',
	next     => "",
	numindex => 1
     },
    ".1.3.6.1.4.1.9163.100.2.1.4.0" => {
	func     => sub { get_mailerTable('mailerKBytesFrom', 11, @_) },
	type     => ASN_COUNTER64,
	check    => sub { check_mailerTable(11, @_) },
        nextoid  => sub { next_mailerTable(11, @_) },
	istable  => '1',
	next     => "",
	numindex => 1
     },
    ".1.3.6.1.4.1.9163.100.2.1.5.0" => {
	func     => sub { get_mailerTable('mailerMessagesTo', 11, @_) },
	type     => ASN_COUNTER64,
	check    => sub { check_mailerTable(11, @_) },
        nextoid  => sub { next_mailerTable(11, @_) },
	istable  => '1',
	next     => "",
	numindex => 1
     },
    ".1.3.6.1.4.1.9163.100.2.1.6.0" => {
	func     => sub { get_mailerTable('mailerKBytesTo', 11, @_) },
	type     => ASN_COUNTER64,
	check    => sub { check_mailerTable(11, @_) },
        nextoid  => sub { next_mailerTable(11, @_) },
	istable  => '1',
	next     => "",
	numindex => 1
     },
    ".1.3.6.1.4.1.9163.100.2.1.7.0" => {
	func     => sub { get_mailerTable('mailerMessagesRejected', 11, @_) },
	type     => ASN_COUNTER64,
	check    => sub { check_mailerTable(11, @_) },
        nextoid  => sub { next_mailerTable(11, @_) },
	istable  => '1',
	next     => "",
	numindex => 1
     },
    ".1.3.6.1.4.1.9163.100.2.1.8.0" => {
	func     => sub { get_mailerTable('mailerMessagesDiscarded', 11, @_) },
	type     => ASN_COUNTER64,
	check    => sub { check_mailerTable(11, @_) },
        nextoid  => sub { next_mailerTable(11, @_) },
	istable  => '1',
	next     => "",
	numindex => 1
     },
    ".1.3.6.1.4.1.9163.100.2.1.9.0" => {
	func     => sub { get_mailerTable('mailerMessagesQuarantined', 11, @_) },
	type     => ASN_COUNTER64,
	check    => sub { check_mailerTable(11, @_) },
        nextoid  => sub { next_mailerTable(11, @_) },
	istable  => '1',
	next     => "",
	numindex => 1
     },
# Scalars
    '.1.3.6.1.4.1.9163.100.1.1.0' => {
	func     => \&get_queueTotal,
	istable  => 0,
        type     => ASN_GAUGE,
	next     =>"",
	numindex => 1
    },	
    '.1.3.6.1.4.1.9163.100.3.1.0' => {
        func     => sub { total_table_get('totalMessagesFrom', @_) },
	istable  => 0,
        type     => ASN_COUNTER64,
	next     =>"",
	numindex => 1
    },	
    '.1.3.6.1.4.1.9163.100.3.2.0' => {
        func     => sub { total_table_get('totalKBytesFrom', @_) },
	istable  => 0,
        type     => ASN_COUNTER64,
	next     =>"",
	numindex => 1
    },	
    '.1.3.6.1.4.1.9163.100.3.3.0' => {
        func     => sub { total_table_get('totalMessagesTo', @_) },
	istable  => 0,
        type     => ASN_COUNTER64,
	next     =>"",
	numindex => 1
    },	
    '.1.3.6.1.4.1.9163.100.3.4.0' => {
        func     => sub { total_table_get('totalKBytesTo', @_) },
	istable  => 0,
        type     => ASN_COUNTER64,
	next     =>"",
	numindex => 1
    },	
    '.1.3.6.1.4.1.9163.100.3.5.0' => {
        func     => sub { total_table_get('totalMessagesRejected', @_) },
	istable  => 0,
        type     => ASN_COUNTER64,
	next     =>"",
	numindex => 1
    },	
    '.1.3.6.1.4.1.9163.100.3.6.0' => {
        func     => sub { total_table_get('totalMessagesDiscarded', @_) },
	istable  => 0,
        type     => ASN_COUNTER64,
	next     =>"",
	numindex => 1
    },	
    '.1.3.6.1.4.1.9163.100.3.7.0' => {
        func     => sub { total_table_get('totalMessagesQuarantined', @_) },
	istable  => 0,
        type     => ASN_COUNTER64,
	next     =>"",
	numindex => 1
    },	
    '.1.3.6.1.4.1.9163.100.4.1.0' => {
        func     => sub { connection_table_get('connectionMessagesFrom', @_) },
	istable  => 0,
        type     => ASN_COUNTER64,
	next     =>"",
	numindex => 1
    },	
    '.1.3.6.1.4.1.9163.100.4.2.0' => {
        func     => sub { connection_table_get('connectionMessagesTo', @_) },
	istable  => 0,
        type     => ASN_COUNTER64,
	next     =>"",
	numindex => 1
    },	
    '.1.3.6.1.4.1.9163.100.4.3.0' => {
        func     => sub { connection_table_get('connectionMessagesRejected', @_) },
	istable  => 0,
        type     => ASN_COUNTER64,
	next     =>"",
	numindex => 1
    },	
};

# Register the top oid with the agent
my $agent = new NetSNMP::agent('Name' => 'Sendmail');
registerAgent($agent, '.1.3.6.1.4.1.9163.100', $oidtable);

# Local variables:
# buffer-read-only: t
# End:
# vi: set ro:
