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

use Carp;
use RDFStore::NodeFactory;
use RDFStore::Model;
use DBI;

my $Usage =<<EOU;
Usage is:
    $0 [-h] [-v] -storename <IDENTIFIER> [-syntax <RDF/XML | NTriples> ]

Query an existing RDFStore database.

-h	Print this message

-storename <IDENTIFIER>
		RDFStore database name IDENTIFIER is like rdfstore://[HOSTNAME[:PORT]]/PATH/DBDIRNAME

                        E.g. URLs
                                        rdfstore://mysite.foo.com:1234/this/is/my/rd/store/database
                                        rdfstore:///root/this/is/my/rd/store/database

[-syntax <RDF/XML | NTriples> ]
		By default is (normalized) RDF/XML - otherwise you can specify N-Triples

[-v]	Be verbose

EOU

# Process options
print $Usage and exit if ($#ARGV<0);

my ($verbose,$syntax,$storename,$input_dir,$dbms_host,$dbms_port);
$verbose=0;
my @query;
while (defined($ARGV[0]) and $ARGV[0] =~ /^[-+]/) {
    my $opt = shift;

    if ($opt eq '-storename') {
        $storename = shift;
    } elsif ($opt eq '-syntax') {
	$syntax=shift;
    } elsif ($opt eq '-h') {
        print $Usage;
        exit;
    } elsif ($opt eq '-v') {
	$verbose=1;
    } elsif ($opt eq '-input_dir') {
	$opt=shift;
	$input_dir = $opt
                if(-e $opt);
        $input_dir .= '/'
                unless( (not(defined $input_dir)) ||
                        ($input_dir eq '') ||
                        ($input_dir =~ /\s+/) ||
                        ($input_dir =~ /\/$/) );
    } elsif ($opt eq '-dbms_host') {
        $dbms_host = shift;
    } elsif ($opt eq '-dbms_port') {
	$opt=shift;
        $dbms_port = (int($opt)) ? $opt : undef;
    } else {
        die "Unknown option: $opt\n$Usage";
    };
};

my $factory = new RDFStore::NodeFactory();
my $model = new RDFStore::Model( Name => $storename, Host => $dbms_host, Port => $dbms_port, Mode => 'r' );

$syntax = 'RDF/XML' unless($syntax);

print "Total statements: ".$model->size."\n"
	if($verbose);

$model->serialize( *STDOUT, $syntax );

