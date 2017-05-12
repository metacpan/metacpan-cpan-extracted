#!/usr/bin/perl

use II::Develop;
package SyslogScanD;

use strict;
use warnings;
use SyslogScan::Daemon;
use File::Basename;

our @ISA = qw(SyslogScan::Daemon);

my $progname = basename($0);

newdaemon(
	progname	=> $progname,
	pidfile		=> "/var/run/$progname.pid",
	configfile	=> "/etc/$progname.conf",
);



=head1 NAME

 syslogscand - daemon to watch log files

=head1 SYNOPSIS

 syslogscand [ -c file ] [ -f ] { start | stop | reload | restart | help | version | check }

=head1 DESCRIPTION

Syslogscand is a wapper for L<SyslogScan::Daemon>.    It watches log files.
Which log files it watches and what it does is defined by the plugins that
are configured in its configuration file.

=head1 FILES

=over 25

=item /etc/syslogscand.conf

The configuration file

=item /var/run/syslogscand.pid 

The process ID file -- also use to make sure there is only one syslogscand running.

=back

=head1 SEE ALSO

L<SyslogScan::Daemon>

