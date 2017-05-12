#!/usr/bin/perl
##############################################################################
# 	Copyright (c) 2000-2006 All rights reserved
# 	Alberto Reggiori <areggiori@webweaving.org>
#	Dirk-Willem van Gulik <dirkx@webweaving.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer. 
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# 3. The end-user documentation included with the redistribution,
#    if any, must include the following acknowledgment:
#       "This product includes software developed by 
#        Alberto Reggiori <areggiori@webweaving.org> and
#        Dirk-Willem van Gulik <dirkx@webweaving.org>."
#    Alternately, this acknowledgment may appear in the software itself,
#    if and wherever such third-party acknowledgments normally appear.
#
# 4. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#    This product includes software developed by the University of
#    California, Berkeley and its contributors. 
#
# 5. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# 6. Products derived from this software may not be called "RDFStore"
#    nor may "RDFStore" appear in their names without prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
#
# ====================================================================
#
# This software consists of work developed by Alberto Reggiori and 
# Dirk-Willem van Gulik. The RDF specific part is based on public 
# domain software written at the Stanford University Database Group by 
# Sergey Melnik. For more information on the RDF API Draft work, 
# please see <http://www-db.stanford.edu/~melnik/rdf/api.html>
# The DBMS TCP/IP server part is based on software originally written
# by Dirk-Willem van Gulik for Web Weaving Internet Engineering m/v Enschede,
# The Netherlands.
#
##############################################################################

use DBMS;
use strict;

my $Usage =<<EOU;

Usage is:

    $0 [-h] [-v] 	dbms://host1:port/database1     dbms://host2:port/database2

Copy a source DBMS database to another either local or remote.

[-noflush]

	Do not flush target database before copy

[-v]    Be verbose

[-h]	Print this message

Target database/dbms-host clearly needs write (or create) permissions.

EOU

my $verbose=0;
my $noflush=0;
my @dbs;
my @hosts;
my @ports;
my @datasources;
while (defined($ARGV[0])) {
	my $opt = shift;

	if ($opt eq '-h') {
        	print $Usage;
        	exit;
	} elsif ($opt eq '-v') {
		$verbose=1;
	} elsif ($opt eq '-noflush') {
		$noflush=1;
	} else {
		if( $opt =~ m|^\s*dbms://([^:]+):(\d+)/([^\s]+)| ) {
			push @hosts, $1;
                        push @ports, $2;
                        push @datasources, $3;
                } elsif( $opt =~ m|^\s*dbms://([^/]+)/([^\s]+)| ) {
			push @hosts, $1;
                        push @ports, '1234'; #or undef?
                        push @datasources, $2;
                } else {
			die "Invalid database identifier $opt\n";
                        };

		push @dbs, $opt;
		};
	};

unless (	defined $dbs[0] and
		$dbs[0] ne '' and
		defined $hosts[0] and
		defined $datasources[0] and
		defined $dbs[1] and
		$dbs[1] ne '' and
		defined $hosts[1] and
		defined $datasources[1] ) {
	print $Usage;
	exit;
	};

undef $DBMS::ERROR;

print STDERR "Connecting to input database $dbs[0] ....."
	if($verbose);
my %a;
tie %a, "DBMS", $datasources[0], &DBMS::XSMODE_RDONLY, 0, $hosts[0], $ports[0]
	or die "Cannot open input database $dbs[0]: $! $DBMS::ERROR";
print STDERR "DONE\n"
	if($verbose);

print STDERR "Connecting to output database $dbs[1] ....."
	if($verbose);
my %b;
tie %b, "DBMS", $datasources[1], &DBMS::XSMODE_CREAT, 0, $hosts[1], $ports[1]
	or die "Cannot open output database $dbs[1]: $! $DBMS::ERROR";
print STDERR "DONE\n"
	if($verbose);

unless($noflush) {
	print STDERR "Flushing $dbs[1] database ....."
		if($verbose);

	# NOTE: DROP() requires special permissions - so we do simple scan of whole DB and delete
	#tied(%b)->DROP;
	while (	my ($k, $v) = each %b ) {
		delete( $b{ $k } );
		};

	print STDERR "DONE\n"
		if($verbose);
	};

print STDERR "Copying data from $dbs[0] to $dbs[1] ....."
	if($verbose);

# simply scan the whole input DB and copy to output one
my $ii=0;
my $log_every = 10;
my ($k,$v);
while (	($k, $v) = each %a ) {

	# copy record through
	$b{ $k } = $v;

	if($ii == $log_every ) {
		print STDERR "."
			if($verbose);
		$ii = 0;
	} else {
		$ii++;
		};
	};

print STDERR ( ($noflush) ? "COPIED" : "MIRRORED" )."\n"
	if($verbose);

untie %b;
untie %a;
