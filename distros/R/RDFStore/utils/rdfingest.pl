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

my $Usage =<<EOU;
Usage is:
    $0 [-h] -storename <IDENTIFIER> [-freetext] [-serialise] [-v] [-Context <URL_or_filename>] <URL_or_filename>

Query an existing RDFStore database.

-h	Print this message

[-v]	Be verbose

-storename <IDENTIFIER>
		RDFStore database name IDENTIFIER is like rdfstore://[HOSTNAME[:PORT]]/PATH/DBDIRNAME

                        E.g. URLs
                                        rdfstore://mysite.foo.com:1234/this/is/my/rd/store/database
                                        rdfstore:///root/this/is/my/rd/store/database

[-freetext]
                Generates free-text searchable database

[-serialise]
                Generate strawman RDF output

[-Context <URL_or_filename>]
                Specify a resource to set a kind of context for the statements

Main paramter is URL or filename to parser; '-' denotes STDIN.

EOU

# Process options
print $Usage and exit if ($#ARGV<0);

my $factory = new RDFStore::NodeFactory();

my ($verbose,$Context,$freetext,$serialise,$stuff,$storename,$output_dir,$dbms_host,$dbms_port);
my @query;
while (defined($ARGV[0])) {
    my $opt = shift;

    if ($opt eq '-storename') {
        $storename = shift;
    } elsif ($opt eq '-Context') {
	$Context=shift;
    } elsif ($opt eq '-stuff') {
	print STDERR "WARNING! -stuff option is deprecated - input source is defined to be last passed argument now\n";
        $stuff = shift;
    } elsif ($opt eq '-freetext') {
        $freetext = 1;
    } elsif ($opt eq '-serialise') {
        $serialise = 1;
    } elsif ($opt eq '-h') {
        print $Usage;
        exit;
    } elsif ($opt eq '-v') {
	$verbose=1;
    } elsif ($opt eq '-output_dir') {
	$opt=shift;
	$output_dir = $opt
                if(-e $opt);
        $output_dir .= '/'
                unless( (not(defined $output_dir)) ||
                        ($output_dir eq '') ||
                        ($output_dir =~ /\s+/) ||
                        ($output_dir =~ /\/$/) );
    } elsif ($opt eq '-dbms_host') {
        $dbms_host = shift;
    } elsif ($opt eq '-dbms_port') {
	$opt=shift;
        $dbms_port = (int($opt)) ? $opt : undef;
    } else {
        $stuff = $opt;
    	};
};

my $model = new RDFStore::Model(
					Name	=>	$output_dir.$storename,
					Host =>    $dbms_host,
                                        Port =>    $dbms_port,
					FreeText	=>	$freetext,
					Sync	=> 1,
					Context => ( (defined $Context) ? $factory->createResource($Context): undef ) )
	or croak "Oh dear, can not build my model :( $!";

if($stuff eq '-') {
	*STUFF=*STDIN;
} else {
	open(STUFF,$stuff);
};

my $stats=0;
# input must look like ("S","P","O") or ("S","P",literal("O"))
while(<STUFF>) {
        if(     (m/\("([^,]*)", "([^,]+)", "(.*)"\)$/) ||
                (m/\("([^,]*)", "([^,]+)", (literal\(".*"\))\)$/) ) {
                my $s = trim($1);
                my $p = trim($2);
                my $o = trim($3);
                $s =~ s/^(stdin|file:[^#]+)#?(\w+:)/$2/;
                $p =~ s/^(stdin|file:[^#]+)#?(\w+:)/$2/;
                $s = $factory->createResource($s);
                $p = $factory->createResource($p);
                if($o =~ m/literal\(\s*"([^"]+)"\s*\)/) {
                        $o = $factory->createLiteral($1);
                } else {
                        $o =~ s/^(stdin|file:[^#]+)#?(\w+:)/$2/;
                        $o = $factory->createResource($o);
                };
                my $stat = $factory->createStatement($s,$p,$o);
                print STDERR "Ingesting: ",$stat->toString,"\n"
                        if($verbose);
                $model->add($stat);
                $stats++;
        };
};
print STDERR "Ingested '$stats' RDF statements in '$output_dir$storename' using '$style' style and split factor '$split'\n"
	if($verbose);
unless($stuff eq '-') {
	close(STUFF);
};

if($serialise) {
        print $model->toStrawmanRDF(),"\n";
};

sub trim {
	my $t = shift;
	$t =~ s/^\s+//g;
	$t =~ s/\s+$//g;
	return $t;
};
