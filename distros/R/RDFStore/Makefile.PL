# *
# *	Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *	                   Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# *
# *	$Id: Makefile.PL,v 1.61 2006/06/19 10:10:21 areggiori Exp $

use strict;
use ExtUtils::MakeMaker 5.16 qw(WriteMakefile prompt);
use Config;

die "RDFStore needs Perl 5.004_05 or better. This is $]\n" 
    if $] <= 5.00404;

$| = 1;

# check required modules
my %missing_modules=();
print "Checking for URI..............";
eval {
        require URI;
        URI->VERSION(1.09);
	};
if ($@) {
    print " missing - The URI module is required\n";
    $missing_modules{'URI'}=1;
} else {
    print " ok\n";
	};

print "Checking for DBI..............";
eval {
        require DBI;
	};
if ($@) {
    print " missing - You need the DBI module to run RDQL/Squish queries; without it only API based triple-match will be possible\n";
    $missing_modules{'DBI'}=1;
} else {
    print " ok\n";
	};

# Some of this configurations are coming from the DB_File Makefile.PL extension written by Paul Marquess <Paul.Marquess@btinternet.com>
print "Checking for XML::Parser......";
eval {
	require XML::Parser;
	require XML::Parser::Expat;
	XML::Parser->VERSION(2.00);
	};
if ($@) {
    print " missing - XML::Parser module version 2 or higher is required\n";
    $missing_modules{'XML::Parser'}=1;
} else {
    	print " ok\n\n";
	warn qq|WARNING:

	You have installed a recent version of the XML::Parser (>2.29) with built in expat XML parser support. 
	If you are going to use RDFStore inside the Apache Web server using mod_perl, bear in mind that there 
	is a symbol conflict between XML::Parser and apache when built with expat. To properly use the RDFStore 
	parsing modules you need to rebuilt apache disabling expat (use --disable-rule=EXPAT while building your
	apache-1.3.xx + mod_perl)

|
		if($XML::Parser::VERSION gt '2.29');
	};

if(     (exists $missing_modules{'XML::Parser'}) ||
        (exists $missing_modules{'DBI'}) ||
        (exists $missing_modules{'URI'}) ) {
        print "\nSorry, can not build RDFStore :(\nPlease installed the missing modules above and try again.\n\n";
        exit;
	};

my $PLATFORM = " -DRDFSTORE_PLATFORM_" . uc($^O);
my ($LIB_DIR,$INC_DIR,$DB_NAME,$LIBS,$COMPAT185,$DB,$DBMS_INSTDIR);

# check BerkeleyDB library locals: read arch_conf.in, pick up any from %ENV if possible otheriwse prompt the user
# parse configuration file
my %options = map { $_, 1 } qw( INCLUDE LIB DBNAME DBMS_INSTDIR RDFSTORE_WORD_STEMMING RDFSTORE_MAXRECORDS );
my $conf_file = 'arch_conf.in';
open(CONF, $conf_file) 
	or die "Cannot open file $conf_file: $!\n" ;
while (<CONF>) {
	s/^\s*|\s*$//g;
	next
		if /^\s*$/ or /^\s*#/;
	s/\s*#\s*$//;
	my ($k, $v) = split(/\s+=\s+/, $_, 2);
       	$k = uc $k;
       	$options{$k} = $v
		if ($options{$k});
	};
close(CONF);

# complete the compilation parameters (precedence to %ENV settings)
$INC_DIR = $ENV{'RDFSTORE_BDB_INCLUDE'}
	if(defined $ENV{'RDFSTORE_BDB_INCLUDE'} and -e $ENV{'RDFSTORE_BDB_INCLUDE'} and -d _ );
$INC_DIR = $options{'INCLUDE'}
	if(exists $options{'INCLUDE'} and -e $options{'INCLUDE'} and -d _ );
$LIB_DIR = $ENV{'RDFSTORE_BDB_LIB'}
	if(defined $ENV{'RDFSTORE_BDB_LIB'} and -e $ENV{'RDFSTORE_BDB_LIB'} and -d _ );
$LIB_DIR = $options{'LIB'}
	if(exists $options{'LIB'} and -e $options{'LIB'} and -d _ );
$DB_NAME = $options{'DBNAME'}
	if(exists $options{'DBNAME'} and $options{'DBNAME'} ne '1');
$COMPAT185 = "-DCOMPAT185 -DDB_LIBRARY_COMPATIBILITY_API"
       	if (	(defined $ENV{'RDFSTORE_BDB_COMPAT185'}) &&
		($ENV{'RDFSTORE_BDB_COMPAT185'} =~ /^\s*(on|true|1)\s*$/i) );
if(exists $options{'DBMS_INSTDIR'} and -e $options{'DBMS_INSTDIR'} and -d _ ) {
	$DBMS_INSTDIR = $options{'DBMS_INSTDIR'};
} else {
	$DBMS_INSTDIR = '/RDFStore';
	};

#other specific options either from enviornment or arch_conf.in
my ($RDFSTORE_WORD_STEMMING,$RDFSTORE_MAXRECORDS);
$RDFSTORE_WORD_STEMMING = $ENV{'RDFSTORE_WORD_STEMMING'}
	if(defined $ENV{'RDFSTORE_WORD_STEMMING'});
$RDFSTORE_WORD_STEMMING = $options{'RDFSTORE_WORD_STEMMING'}
	if(exists $options{'RDFSTORE_WORD_STEMMING'});

my $RDFSTORE_DEFAULT_MAXRECORDS=2097152;
my $RDFSTORE_MIN_MAXRECORDS=128;
my $RDFSTORE_MAX_MAXRECORDS=60000000; # 60M triples
$RDFSTORE_MAXRECORDS = (	$ENV{'RDFSTORE_MAXRECORDS'} >= $RDFSTORE_MIN_MAXRECORDS and 
				$ENV{'RDFSTORE_MAXRECORDS'} <= $RDFSTORE_MAX_MAXRECORDS ) ? 
				$ENV{'RDFSTORE_MAXRECORDS'} :
				$RDFSTORE_DEFAULT_MAXRECORDS
	if(defined $ENV{'RDFSTORE_MAXRECORDS'});
$RDFSTORE_MAXRECORDS = (	$options{'RDFSTORE_MAXRECORDS'} >= $RDFSTORE_MIN_MAXRECORDS and 
				$options{'RDFSTORE_MAXRECORDS'} <= $RDFSTORE_MAX_MAXRECORDS ) ? 
				$options{'RDFSTORE_MAXRECORDS'} :
				$RDFSTORE_DEFAULT_MAXRECORDS
	if(exists $options{'RDFSTORE_MAXRECORDS'});

# eventually go in interactive mode
if($ARGV[0] =~ m/-(i|interactive)/i) {
	print <<QUESTION;
You have chosen the interactive configuration - You will be now asked a few questions about
your local BerkeleyDB installation and other RDF storage and indexing specific parameters (see arch_conf.in for more info)

QUESTION

	my ($idir,$ldir,$dbn);
	while ( $idir = prompt( 'Where is the file db.h? '.( (defined $INC_DIR) ? '['.$INC_DIR.']' : '' ) ) ) {
		$idir =~ s/^\s+//g;
		$idir =~ s/\s+$//g;
		last
			if (-e $idir and -d _ );
		print "\nInvalid directory '$idir' - try again\n\n";
		};
	$INC_DIR = $idir
		if(	(defined $idir) &&
			($idir ne '') );
	while ( $ldir = prompt( 'Where is libdb? '.( (defined $LIB_DIR) ? '['.$LIB_DIR.']' : '' ) ) ) {
		$ldir =~ s/^\s+//g;
		$ldir =~ s/\s+$//g;
		last
			if (-e $ldir and -d _ );
		print "\nInvalid directory '$ldir' - try again\n\n";
		};
	$LIB_DIR = $ldir
		if(	(defined $ldir) &&
			($ldir ne '') );
	$dbn = prompt( 'Is the library called libdb (e.g. db4 - default value is db ) ? '.( (defined $DB_NAME) ? '['.$DB_NAME.']' : '' ) );
	if(	(defined $dbn) &&
		($dbn ne '') ) {
		$dbn =~ s/^\s+//g;
		$dbn =~ s/\s+$//g;
		$dbn = '-l'.$dbn
			unless( $dbn =~ m/^-l/ );
		$DB_NAME = $dbn;
		};

	my $ws = prompt( 'How many characters your need word stemming on RDF text literals (an integer - default value is 5 ) ? '.( (defined $RDFSTORE_WORD_STEMMING) ? '['.$RDFSTORE_WORD_STEMMING.']' : '' ) );
	if(	(defined $ws) &&
		($ws ne '') &&
		(int($ws)) ) {
		$RDFSTORE_WORD_STEMMING = $ws;
		};

	my $mrs = prompt( 'How many RDF triples your database can contain (an integer in the range '.$RDFSTORE_MIN_MAXRECORDS.' <= X <= '.$RDFSTORE_MAX_MAXRECORDS.') ? '.( (defined $RDFSTORE_MAXRECORDS) ? '['.$RDFSTORE_MAXRECORDS.']' : '' ) );
	if(	(defined $mrs) &&
		($mrs ne '') &&
		(int($mrs)) &&
		( $mrs >= $RDFSTORE_MIN_MAXRECORDS ) &&
		( $mrs <= $RDFSTORE_MAX_MAXRECORDS ) ) {
		$RDFSTORE_MAXRECORDS = $mrs;
		};

	print "\n";
	};

# force some default settings
if ( $^O =~ m/linux/ and ($ARGV[0] !~ m/-(i|interactive)/i) ) {
	# Some modern versions of linux need this.
	if ( -e '/usr/include/db4/db.h' ) {
       		$DB = '-DDB4_INCLUDE';
		unless($DB_NAME) {
			# let's guess what the bloody Linux installation/distro did!
			my @dbs = </usr/lib/libdb4.>;
			if( $#dbs >= 0 ) {
				$DB_NAME = '-ldb4';
				};
			@dbs = </usr/lib/libdb-4.0.>;
			if( $#dbs >= 0 ) {
				$DB_NAME = '-ldb-4.0';
			} else {
				$DB_NAME = '-ldb';
				};
			$LIBS = $DB_NAME;
			};
		$INC_DIR = '/usr/include/db4/' unless($INC_DIR);
		};
	if ( -e '/usr/include/db3/db.h' ) {
       		$DB = '-DDB3_INCLUDE';
		unless($DB_NAME) {
			# let's guess what the bloody Linux installation/distro did!
                        my @dbs = </usr/lib/libdb3.>;
                        if( $#dbs >= 0 ) {
                                $DB_NAME = '-ldb3';
                                };
                        @dbs = </usr/lib/libdb-3.0.>;
                        if( $#dbs >= 0 ) {
                                $DB_NAME = '-ldb-3.0';
                        } else {
                                $DB_NAME = '-ldb';
                                };
			$LIBS = $DB_NAME;
			};
		$INC_DIR = '/usr/include/db3/' unless($INC_DIR);
		};
	if ( -e '/usr/include/db2/db.h' ) {
       		$DB = '-DDB2_INCLUDE';
		unless($DB_NAME) {
			# let's guess what the bloody Linux installation/distro did!
                        my @dbs = </usr/lib/libdb2.>;
                        if( $#dbs >= 0 ) {
                                $DB_NAME = '-ldb2';
                                };
                        @dbs = </usr/lib/libdb-2.0.>;
                        if( $#dbs >= 0 ) {
                                $DB_NAME = '-ldb-2.0';
                        } else {
                                $DB_NAME = '-ldb';
                                };
			$LIBS = $DB_NAME;
			};
		$INC_DIR = '/usr/include/db2/' unless($INC_DIR);
		};
	if ( -e '/usr/include/db1/db.h' ) {
       		$DB = '-DDB1_INCLUDE';
		unless($DB_NAME) {
			# let's guess what the bloody Linux installation/distro did!
                        my @dbs = </usr/lib/libdb1.>;
                        if( $#dbs >= 0 ) {
                                $DB_NAME = '-ldb1';
                                };
                        @dbs = </usr/lib/libdb-1.0.>;
                        if( $#dbs >= 0 ) {
                                $DB_NAME = '-ldb-1.0';
                        } else {
                                $DB_NAME = '-ldb';
                                };
			$LIBS = $DB_NAME;
			};
		$INC_DIR = '/usr/include/db1/' unless($INC_DIR);
		};
	};

$DB_NAME = '-ldb'
	if (	(! defined $DB_NAME) &&
		 $LIB_DIR );

if(	($ARGV[0] =~ m/-(v|verbose)/i) ||
	($ARGV[1] =~ m/-(v|verbose)/i) ||
	($ARGV[0] =~ m/-(i|interactive)/i) ) {
	print "Your configuration is the following:\n\n";
	print "BerkeleyDB configuration:\n\n";
	print "\tinclude directory          [".( (defined $INC_DIR) ? $INC_DIR : 'undefined/default to built in' )."]\n";
	print "\tlibrary directory          [".( (defined $LIB_DIR) ? $LIB_DIR : 'undefined/default to built in' )."]\n";
	print "\tlibrary name               [".( (defined $DB_NAME) ? $DB_NAME : 'undefined/default to built in' )."]\n\n";
	print "RDF storage and indexing configuration:\n\n";
	print "\tRDF literal word stemming up to       [$RDFSTORE_WORD_STEMMING]\n";
	print "\tMax number of RDF statements/triples  [$RDFSTORE_MAXRECORDS]\n\n";
	};

my $debug = ($ENV{RDFSTORE_DEBUG} =~ m/1|yes|on|enable/) ? '-DRDFSTORE_DEBUG' : '';
my $debug_malloc = ($ENV{RDFSTORE_DEBUG_MALLOC} =~ m/1|yes|on|enable/) ? '-DRDFSTORE_DEBUG_MALLOC' : '';
my $dbms_debug = ($ENV{RDFSTORE_DBMS_DEBUG} =~ m/1|yes|on|enable/) ? '-DRDFSTORE_DBMS_DEBUG' : '';
my $dbms_debug_malloc = ($ENV{RDFSTORE_DBMS_DEBUG_MALLOC} =~ m/1|yes|on|enable/) ? '-DRDFSTORE_DBMS_DEBUG_MALLOC' : '';
my $flat_store_debug = ($ENV{RDFSTORE_FLAT_STORE_DEBUG} =~ m/1|yes|on|enable/) ? '-DRDFSTORE_FLAT_STORE_DEBUG' : '';
my $profile = ($ENV{RDFSTORE_PROFILE} =~ m/1|yes|on|enable/) ? 1 : 0;

my $RDFSTORE_OPTIONS = ' -DRDFSTORE_WORD_STEMMING='.$RDFSTORE_WORD_STEMMING
	if(defined $RDFSTORE_WORD_STEMMING);
$RDFSTORE_OPTIONS .= ' -DRDFSTORE_MAXRECORDS='.$RDFSTORE_MAXRECORDS
	if(defined $RDFSTORE_MAXRECORDS);

# generate dbms/arch.conf
open(ARCH_CONF,">dbms/arch.conf"); #overwrite existing one
print ARCH_CONF <<EOT;
# *
# *     Copyright (c) 2000-2006 Alberto Reggiori  <areggiori\@webweaving.org>
# *     		        Dirk-Willem van Gulik <dirkx\@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
#
INSTDIR=$DBMS_INSTDIR

TESTDIR=/usr/tmp/test.dbstore
PIDFILE=/usr/tmp/test.dbstore.pid

#CC = gcc
RANLIB = ranlib
LINT = lint
LINTFLAGS = -chapbx

INCLUDES= -I../include -I../../include

DEFINES += $PLATFORM

###### BEGIN specific confs
EOT

print ARCH_CONF "\n# add the include directory of your BDB installation is if not found to the bottom line\n";
print ARCH_CONF ($INC_DIR) ? 'INCLUDES += -I'.$INC_DIR : '#INCLUDES += -I/usr/local/BerkeleyDB-4.0.14/include';
print ARCH_CONF "\n\n# add the library directory of your BDB installation is if not found to the bottom line\n";
print ARCH_CONF 'LIBS_DIR  = -L../libdbms ' . ( ($LIB_DIR) ? ' -L'.$LIB_DIR : ' # -L/usr/local/BerkeleyDB-4.0.14/lib' ) . "\n";
print ARCH_CONF ( ($LIB_DIR) ? 'BDB_LD_LIBS_DIR  = '.$LIB_DIR : '#BDB_LD_LIBS_DIR = /usr/local/BerkeleyDB-4.0.14/lib' ) . "\n";
print ARCH_CONF <<EOT;


# uncomment one the following lines if your BDB library is not found. 
#
# NOTE: most BSD systems have BDB built in in the 'libc' standard C 
#       library and do not need the bottom definition
#
EOT
print ARCH_CONF "\n# anything not built in and linux platforms in general\n";
print ARCH_CONF ($DB_NAME) ? 'LIBS  = '.$DB_NAME : '#LIBS = -ldb';
print ARCH_CONF "\n";
if($^O eq 'linux') {
	print ARCH_CONF "\n# Some linux platforms have diffferent DB versions installed.\n";
	if ( $DB ) {
		print ARCH_CONF 'DEFINES  += "'.$DB.'"'."\n";
	} else {
		print ARCH_CONF <<EOT;
# choose db1
#DEFINES += "-DDB1_INCLUDE"
#INCLUDES += -I/usr/include/db1/include
#LIBS = -ldb1
# ...or db2       
#DEFINES += "-DDB2_INCLUDE"
#INCLUDES += -I/usr/include/db2/include
#LIBS = -ldb2
# ...or db3       
#DEFINES += "-DDB3_INCLUDE"
#INCLUDES += -I/usr/include/db3/include
#LIBS = -ldb3
# ...or db4       
#DEFINES += "-DDB4_INCLUDE"
#INCLUDES += -I/usr/include/db4/include
#LIBS = -ldb4

EOT
		};
	};

if($^O eq 'darwin') {
	print ARCH_CONF "UID=root\n";
	print ARCH_CONF "GID=wheel\n";
} else {
	print ARCH_CONF "UID=bin\n";
	print ARCH_CONF "GID=bin\n";
}

print ARCH_CONF "\n\n# uncomment the following line to use BDB 1.85 compatibility code\n";
print ARCH_CONF ($COMPAT185) ? 'DEFINES  += "'.$COMPAT185.'"' : '#DEFINES += " -DCOMPAT185 -DDB_LIBRARY_COMPATIBILITY_API "';
print ARCH_CONF "\n";

if($^O eq 'solaris') {
	print ARCH_CONF <<EOT;

# for SOLARIS
LIBS += -lsocket -lnsl

EOT
	};

print ARCH_CONF <<EOT;

###### END specific confs

LFLAGS = -g3 
CFLAGS = -g3

EOT
print "# For profiling..\nCFLAGS += -pg\n" if($profile);
print ARCH_CONF <<EOT;

#
# Whether to fork(on BSD) or multitread(on Irix)
# or not at all. You propably want to leave this
# in as the non-tread/non-fork versions have not
# been used in a long time...
#
DEFINES += -DFORKING
#
# General debugging; also, some asserts present
# so should use -NDEBUG :-)
#
EOT
print ARCH_CONF ( ($ENV{RDFSTORE_DBMS_DEBUG} =~ m/1|yes|on|enable/) ? '' : '# ')."DEFINES += -DRDFSTORE_DBMS_DEBUG\n";
print ARCH_CONF <<EOT;
# 
# Bit of malloc tracing, basically a
# free check on termination
#
EOT
print ARCH_CONF ( ($ENV{RDFSTORE_DBMS_DEBUG_MALLOC} =~ m/1|yes|on|enable/) ? '' : '# ')."DEFINES += -DRDFSTORE_DBMS_DEBUG_MALLOC\n";
print ARCH_CONF <<EOT;
# 
# Wether to malloc once; and keep it on
# a linked list; or contineously malloc/free
# for dbase/child/connect structs, i.e. the
# 'long' lived things (i.e. >= session time)
#
DEFINES += -DSTATIC_BUFF
#
# Same for short (per transact) buffers
#
DEFINES +=  -DSTATIC_CS_BUFF
DEFINES +=  -DSTATIC_SC_BUFF
#
# If your kernel allows it.. *implies a 
# kernel recompile normally*
#
# DEFINES += -DFD_SETSIZE=4048
#

EOT
close(ARCH_CONF);

# generate dbms/utils/dbmsd.sh
open(DBMSDSH,">dbms/utils/dbmsd.sh"); #overwrite existing one
print DBMSDSH <<EOT;
#!/bin/sh
##############################################################################
#       Copyright (c) 2000-2006 All rights reserved
#       Alberto Reggiori <areggiori\@webweaving.org>
#       Dirk-Willem van Gulik <dirkx\@webweaving.org>
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
#        Alberto Reggiori <areggiori\@webweaving.org> and
#        Dirk-Willem van Gulik <dirkx\@webweaving.org>."
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
DIR=$DBMS_INSTDIR

#
# WARNING: the following "ulimit" commands are generally *BIG* server machines
#          enable them to your own risk! :-)
#
#ulimit -d 65000
#ulimit -n 2048
#ulimit -u 256
#ulimit -m 64000

RUNDIR=\$DIR/run
LOGDIR=\$DIR/logs

test -d \$RUNDIR || exit 1
test -d \$LOGDIR || exit 1

PIDFILE=\$RUNDIR/dbmsd.pid
LOGFILE=\$DIR/logs/dbmsd_errorlog

# Make sure cores are collected in the right place.
#
cd \$RUNDIR || exit 1

EOT
print DBMSDSH ( ($LIB_DIR) ? 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'.$LIB_DIR : '#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/BerkeleyDB-4.0.14/lib' )."\n\n";
print DBMSDSH '[ -f $DIR/bin/dbmsd ] && $DIR/bin/dbmsd -e $LOGFILE -U -P $PIDFILE -d $DIR/dbms && echo -n dbmsd'."\n\n";
close(DBMSDSH);

# generate dbms/utils/start_dbserver
open(DBMSDSTART,">dbms/utils/start_dbserver");
print DBMSDSTART <<EOT;
#!/bin/sh
##############################################################################
#       Copyright (c) 2000-2006 All rights reserved
#       Alberto Reggiori <areggiori\@webweaving.org>
#       Dirk-Willem van Gulik <dirkx\@webweaving.org>
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
#        Alberto Reggiori <areggiori\@webweaving.org> and
#        Dirk-Willem van Gulik <dirkx\@webweaving.org>."
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

$DBMS_INSTDIR/rc/dbmsd.sh

EOT
close(DBMSDSTART);

# generate dbms/utils/stop_dbserver
open(DBMSDSTOP,">dbms/utils/stop_dbserver");
print DBMSDSTOP <<EOT;
#!/bin/sh
##############################################################################
#       Copyright (c) 2000-2006 All rights reserved
#       Alberto Reggiori <areggiori\@webweaving.org>
#       Dirk-Willem van Gulik <dirkx\@webweaving.org>
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
#        Alberto Reggiori <areggiori\@webweaving.org> and
#        Dirk-Willem van Gulik <dirkx\@webweaving.org>."
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

DIR=$DBMS_INSTDIR

RUNDIR=\$DIR/run

test -d \$RUNDIR || exit 1

if [ \$# = 0 ]; then
	PIDFILE=\$RUNDIR/dbmsd.pid
else
        PIDFILE=\$1
fi
 
echo 'Stoppping DBMS server....'
echo 'First kills....'

if [ -f \$PIDFILE ] ; then
        PID=`cat \$PIDFILE`
        if [ "x\$PID" != "x" ] && kill -0 \$PID 2>/dev/null ; then
                kill -15 \$PID;
        else
                echo not a valid PID=\$PID in \$PIDFILE
                rm -f \$PID;
                exit 1
        fi
else
        echo no \$PIDFILE found
        exit 1
fi
 
echo DONE
exit 0

EOT
close(DBMSDSTOP);

# generate utils/Makefile
open(UTILSMAKE,">utils/Makefile"); #overwrite existing one
print UTILSMAKE <<EOT;
# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori\@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx\@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * 
TFILE=`date +%Y-%m-%d`

include ../dbms/arch.conf

OBJS = ../dbms/libdbms/libdbms.o ../rdfstore_flat_store.o ../rdfstore_kernel.o ../rdfstore_bits.o ../rdfstore_utf8.o ../rdfstore_xsd.o ../rdfstore_digest.o ../rdfstore_ap_sha1.o ../rdfstore_compress.o ../rdfstore_log.o ../rdfstore_serializer.o ../rdfstore_iterator.o ../sflcomp.o ../my_compress.o ../fraenkel_compress.o ../backend_bdb_store.o ../backend_dbms_store.o ../backend_caching_store.o

all:	db_stats

clean:
	rm -f db_stats

EOT

print UTILSMAKE "db_stats: db_stats.c Makefile\n\t".'$(CC) $(CFLAGS) $(INCLUDES) -I ../dbms/include -I ../dbms/client $(DEFINES) $(LIBS_DIR) $(OBJS) '.( ($DB_NAME) ? $DB_NAME : '' ).' -o db_stats db_stats.c';
close(UTILSMAKE);

# generate test/Makefile
open(TESTSMAKE,">test/Makefile"); #overwrite existing one
print TESTSMAKE <<EOT;
# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori\@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx\@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * 
TFILE=`date +%Y-%m-%d`

include ../dbms/arch.conf

OBJS = ../dbms/libdbms/libdbms.o ../rdfstore_flat_store.o ../rdfstore_kernel.o ../rdfstore_bits.o ../rdfstore_utf8.o ../rdfstore_xsd.o ../rdfstore_digest.o ../rdfstore_ap_sha1.o ../rdfstore_compress.o ../rdfstore_log.o ../rdfstore_iterator.o  ../rdfstore_serializer.o ../sflcomp.o ../my_compress.o ../fraenkel_compress.o ../backend_bdb_store.o ../backend_dbms_store.o ../backend_caching_store.o


all:	mytest mytest1 myingest

test:	all
	./mytest || exit 1
	./mytest1 || exit 1
	./myingest test.triples || exit 1

clean:
	rm -f mytest mytest1 myingest myingest.core mytest.core mytest1.core mytest.gmon mytest1.gmon

EOT

print TESTSMAKE "mytest: Makefile mytest.c\n\t".
	'$(CC) $(CFLAGS) $(INCLUDES) -I ../dbms/include -I ../dbms/client $(DEFINES) $(LIBS_DIR) $(OBJS) '.( ($DB_NAME) ? $DB_NAME : '' ).' -o mytest mytest.c'.
	"\n\n";
print TESTSMAKE "mytest1: Makefile mytest1.c\n\t".
	'$(CC) $(CFLAGS) $(INCLUDES) -I ../dbms/include -I ../dbms/client $(DEFINES) $(LIBS_DIR) $(OBJS) '.( ($DB_NAME) ? $DB_NAME : '' ).' -o mytest1 mytest1.c'.
	"\n\n";
print TESTSMAKE "myingest: Makefile myingest.c\n\t".
	'$(CC) $(CFLAGS) $(INCLUDES) -I ../dbms/include -I ../dbms/client $(DEFINES) $(LIBS_DIR) $(OBJS) '.( ($DB_NAME) ? $DB_NAME : '' ).' -o myingest myingest.c'.
	"\n\n";
close(TESTSMAKE);

if (defined $DB_NAME) {
	$LIBS = $DB_NAME;
} else {
	if ($^O eq 'MSWin32') {
		$LIBS = '-llibdb';
	} else {
		$LIBS = '-ldb';
		};
	};

# build client libdbms library first
`(cd dbms/libdbms; make clean; make)`;


WriteMakefile(
	#DIR	=> [ 'RDFNode' ],
    	NAME      => 'RDFStore',
	VERSION_FROM => 'RDFStore.pm',
	INC             => ( (defined $INC_DIR) ? '-I'.$INC_DIR : '' )." -I dbms/include -I dbms/client -I ./include -I.",
	LIBS            => [ ( (defined $LIB_DIR) ? '-L'.$LIB_DIR : '' ) . " $LIBS -Ldbms/libdbms -ldbms "],
	XSPROTOARG      => '-noprototypes',
	OPTIMIZE        => '-g',
	DEFINE          => ( ($profile) ? '-pg ' : '' )." $PLATFORM $debug $debug_malloc $dbms_debug $dbms_debug_malloc $flat_store_debug -D_NOT_CORE $DB $COMPAT185 -DSTATIC_BUFF -DSTATIC_CS_BUFF -DSTATIC_SC_BUFF $RDFSTORE_OPTIONS",
        LDFROM    => q[RDFStore$(OBJ_EXT) rdfstore_log$(OBJ_EXT) rdfstore_compress$(OBJ_EXT) rdfstore_flat_store$(OBJ_EXT) rdfstore_iterator$(OBJ_EXT) rdfstore_serializer$(OBJ_EXT) rdfstore_kernel$(OBJ_EXT) rdfstore_ap_sha1$(OBJ_EXT) rdfstore_digest$(OBJ_EXT) rdfstore_bits$(OBJ_EXT) rdfstore_utf8$(OBJ_EXT) rdfstore_xsd$(OBJ_EXT) sflcomp$(OBJ_EXT) my_compress$(OBJ_EXT) fraenkel_compress$(OBJ_EXT) backend_bdb_store$(OBJ_EXT) backend_dbms_store$(OBJ_EXT) backend_caching_store$(OBJ_EXT)],
        OBJECT    => q[RDFStore$(OBJ_EXT) rdfstore_log$(OBJ_EXT) rdfstore_compress$(OBJ_EXT) rdfstore_flat_store$(OBJ_EXT) rdfstore_iterator$(OBJ_EXT) rdfstore_serializer$(OBJ_EXT) rdfstore_kernel$(OBJ_EXT) rdfstore_ap_sha1$(OBJ_EXT) rdfstore_digest$(OBJ_EXT) rdfstore_bits$(OBJ_EXT) rdfstore_utf8$(OBJ_EXT) rdfstore_xsd$(OBJ_EXT) my_compress$(OBJ_EXT) sflcomp$(OBJ_EXT) fraenkel_compress$(OBJ_EXT) backend_bdb_store$(OBJ_EXT) backend_dbms_store$(OBJ_EXT) backend_caching_store$(OBJ_EXT) ],
    	'clean'     => { FILES => "y.tab.o lex.yy.o *.db" },
	EXE_FILES    => [ "utils/rdf.pl", "utils/rdfquery.pl", "utils/rdfdump.pl" ],
	($] ge '5.005') ? (
                               'AUTHOR' => 'Alberto Reggiori <areggiori@webweaving.org>, Dirk-Willem van Gulik <dirkx@webweaving.org>',
                               'ABSTRACT' => 'Perl/C RDF storage and API',
                           ) : ()
);

sub MY::post_initialize {
	print <<EOT;

In addition, you can install the (optional) DBMS module for TCP/IP remote storage by:

cd dbms
make
make test
make install (by default into $DBMS_INSTDIR directory)

EOT
	'';
	};
