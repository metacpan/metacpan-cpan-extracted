#!/usr/bin/env perl
use strict;

=head1 NAME

lsf-synchroFilesUntilFinished.pl

=head1 DESCRIPTION

synchronize file from a node back to the master until a job is finished.

Directory structures must be the same ton the node as on the local machine

=head1 SYNOPSIS

lsf-synchroFilesUntilFinished.pl --jobid=lsfjobid --remotehost=hostname [--delay=int] /my/path1/file1 /my/path2/file2 /my/path3/file3

=head1 ARGUMENTS

=head3 --jobid=LSFJOBID

The lsf job id

If no files are specified (thus the format must be) I/O are stdin/out.

=head3 remotehost=hostname

A host from wich the file(s) is the to be gathered. A non-interactive rsync command chould be achievable towards this node.

argument can be user@host (or whatever considered by the rsync command)

=head3 remotenode=int

wait 4 the lsf job to start, then get back the file from given node in the attributed list

=head3 --delay=int

number of seconds to sleep between 2 synchro. [default is 5]

=head3 --rsyncopt=str

rsync options (--verbose --recursive "--rsh=ssh"...)

=head3 --lsfhost=[user@]hostname

Set a remote host for lsf master (thus a remote check for a job to be finished)

=head3 --help

=head3 --man

=head3 --verbose


=head1 EXAMPLE

=head1 SEE ALSO

Phenyx::Utils::LSF::JobInfo rsync

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

=cut


use Phenyx::Utils::LSF::JobInfo;

use Getopt::Long;
use Pod::Usage;
my $delay=5;

my($lsfid, $remoteHost, $lsfHost, $remoteNode, $rsyncOptions, $help, $man, $verbose);

if (!GetOptions(
		"lsfid=s"=>\$lsfid,		
		"remotehost=s"=>\$remoteHost,		
		"remotenode=i"=>\$remoteNode,
		"lsfhost=s"=>\$lsfHost,
		"delay=i"=>\$delay,

		"rsyncopt=s"=>\$rsyncOptions,		

                "help" => \$help,
                "man" => \$man,
                "verbose" => \$verbose,
               )
    || $help || $man){
  pod2usage(-verbose=>2, -exitval=>2) if(defined $man);
  pod2usage(-verbose=>1, -exitval=>2);
}

my $rsyncCmd="rsync";
$rsyncCmd.=" $rsyncOptions" if $rsyncOptions;

$Phenyx::Utils::LSF::JobInfo::SHELLCOMMANDPREFIX="ssh $lsfHost" if $lsfHost;

unless(defined $lsfid){
  print STDERR  "you must provide an lsf job id --lsfid=XXX\n";
  pod2usage(-verbose=>1, -exitval=>2);
}
unless(defined $remoteHost or defined $remoteNode){
  print STDERR  "you must provide a remote host or node where to gather the file(s) from --remotehost=hostname or $remoteNode=int\n";
  pod2usage(-verbose=>1, -exitval=>2);
}

if(defined $remoteNode){
  while(!Phenyx::Utils::LSF::JobInfo::isJobStarted($lsfid)){
    print STDERR "waiting for $lsfid to start\n" if $verbose;
    sleep 1;
  }
  $remoteHost=Phenyx::Utils::LSF::JobInfo::jobInfo($lsfid, 'EXEC_HOST')->[$remoteNode];
  print STDERR "node [$remoteNode] is [$remoteHost]\n";
}

die "you must provide file to be gathered" unless @ARGV;
my @files=@ARGV;

while(($lsfid==-1)||!Phenyx::Utils::LSF::JobInfo::isJobFinished($lsfid)){
  foreach (@files){
#     my $cmd="if ssh $remoteHost '[ ! -f $_ ]' ; then $rsyncCmd $remoteHost:$_ $_; fi";
#     print STDERR "$cmd\n";
#     system ($cmd) && die "could not execute [$cmd]: $!";
    my $cmd="$rsyncCmd $remoteHost:$_ $_";
    print STDERR "$cmd\n";
    system ($cmd);
  }
  sleep $delay;
}
