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
use RDFStore::Model;
use RDFStore::NodeFactory;
use DBI;

my $Usage =<<EOU;
Usage is:

    $0 <querystring_or_filename> [-storename <IDENTIFIER>] [-serialize <syntax>] [-h]

Query an existing RDFStore database.

<querystring_or_filename>

		A SPARQL query string (see syntax at http://www.w3.org/TR/rdf-sparql-query/) or a file containing the actual query

		Example RSS-1.0 query

		PREFIX   rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
		PREFIX   rss:   <http://purl.org/rss/1.0/>
		SELECT
			?title ?link
		FROM
			<http://xmlhack.com/rss10.php>
		WHERE
			( ?item rdf:type rss:item )
			( ?item rss::title ?title )
			( ?item rss::link ?link )

[-storename <IDENTIFIER>]
	If not specified into the FROM clause part of the query, this option allows to specify a 
	database IDENTIFIER like rdfstore://[HOSTNAME[:PORT]]/PATH/DBDIRNAME to query

        E.g. URLs
        		rdfstore://mysite.foo.com:1234/this/is/my/rd/store/database
                        rdfstore:///root/this/is/my/rd/store/database

[-serialize rdf-for-xml | dawg-xml ]
	Result Forms - by default SELECT generates RDF/XML tabular format (http://www.w3.org/2001/sw/DataAccess/tests/result-set#) while 
	DESCRIBE or CONSTRUCT queries generate canonical RDF/XML output.
	
	Alternatively this option allows you to get two simple XML output formats
		* dawg-xml (http://www.w3.org/2001/sw/DataAccess/rf1/) syntax
		* rdf-for-xml (http://jena.hpl.hp.com/~afs/RDF-XML.html)

[-smart]
	Use simple rdfs:subClassOf rdfs:subPropertyOf and owl:sameAs inferencing

[-comment <STRING>]
	Comment to add to the XML output

[-metadata <filename_or_URI>]
	Additional metadata link for <head/> elemenet into DAWG-XML format

[-h]
	Print this message

EOU

# Process options
print $Usage and exit if ($#ARGV<0);

my ($verbose,$metadata, $comment,$query,$storename,$input_dir,$dbms_host,$dbms_port,$serialize,$smart);
$smart=0;
while (defined($ARGV[0])) {
    my $opt = shift;

    if ($opt eq '-storename') {
        $storename = shift;
    } elsif ($opt eq '-h') {
        print $Usage;
        exit;
    } elsif ($opt eq '-smart') {
	$smart=1;
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
    } elsif ($opt eq '-serialize') {
        $serialize = shift;
	$serialize = 'RDF/XML'
		unless($serialize);
    } elsif ($opt eq '-comment') {
        $comment = shift;
    } elsif ($opt eq '-metadata') {
        $metadata = shift;
    } else {
	$query=$opt;
    	};
};

my $factory = new RDFStore::NodeFactory();
my %results_options = (
	'syntax' => $serialize
	);
$results_options{'metadata'} = $metadata
	if($metadata); #check if file or URI perhaps?

$results_options{'comment'} = $comment
	if($comment);

my $dbh = DBI->connect("DBI:RDFStore:database=$input_dir$storename;host=$dbms_host;port=$dbms_port", "pincopallino", 0,
						{	nodeFactory => $factory,
							results => \%results_options,
							smarter => $smart } )
	or die "Oh dear, can not connect to rdfstore: $!";

if( -e $query && -r _ ) {
	open(QUERY, $query);
	$query='';
	while(<QUERY>) {
		$query.=$_;
		};
	close(QUERY);
	};

my $sth;
my $rdfresults;
eval {
        $sth=$dbh->prepare($query);
	$sth->execute();
	};
my $err = $@;
croak $err
	if $err;

if( $sth->func('getQueryStatement')->getQueryType eq 'SELECT' and $serialize !~ /n-triples/i ) {
	while (my $xml = $sth->func( $serialize ? $serialize : 'dawg-results', 'fetchrow_XML' )) {
		print $xml;
       		};
} else {
	while (my $rdf = $sth->func( $serialize ? $serialize : 'RDF/XML', 'fetchsubgraph_serialize' )) {
		print $rdf;
       		};
	};

$sth->finish();
