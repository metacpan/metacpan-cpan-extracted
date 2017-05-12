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

use RDFStore::NodeFactory;
use RDFStore::Model;
use RDFStore::Parser::SiRPAC;
use RDFStore::Parser::NTriples;
use Carp;

my $Usage =<<EOU;
Usage is:
    $0 [-h] [-ntriples] [-freetext] [-storename <IDENTIFIER>] [-serialize <syntax>] [-base <URL_or_filename>] [-Context <URI_or_bNode>] [-sync] [-owl:imports] <URL_or_filename>

Parse an input RDF file and optionally store the generated triplets into a RDFStore(3) database.

-h	Print this message

[-ntriples]
	parse input stuff as N-Triples  - default is RDF/XML

[-v]	Be verbose

[-storename <IDENTIFIER>]
		RDFStore database name IDENTIFIER is like rdfstore://[HOSTNAME[:PORT]]/PATH/DBDIRNAME

			E.g. URLs
					rdfstore://mysite.foo.com:1234/this/is/my/rd/store/database
					rdfstore:///root/this/is/my/rd/store/database

[-freetext]
		Generates free-text searchable database

[-namespace <URL_or_filename>]
		Specify a string to set a base URI to use for the generation of 
		resource URIs during parsing

[-serialize RDF/XML | NTriples ]
		generate RDF/XML or NTriples syntax

[-Context <URI_or_bNode>]
		Specify a resource to set a kind of context for the statements e.g. _:lmn20031127

[-sync]
		Sync databse after each statement insertion - this is option si off by default and it is generally very
		expensive in terms of I/O operations.

[-owl:imports]
		Process owl:imports statements specially and include into output result related ontologies.

[-GenidNumberFile]
		EXISTING valid filename containing a single integer value to seed the parser "genid" numbers with the given value (I.e. for anonymous resources). Note that an exclusive lock on the file is used to guarantee that the value is consistent across runs (and concurrent processes)

[-delete]
		Remove instead of insert statements as passed into the input RDF file/source - as special case (if confirmed
		after prompt to the user or yes option enabled) when no input source is specified the WHOLE database is cleared.
		*WARNING* this operation is can not be undone!

[-y]
		Assume a yes response to all questions asked; this should be used with great caution as this is a free license
		to confirm permanent chnages to the database like deletion of data.

[-version]	Print RDFStore $VERSION

Main paramter is URL or filename to parser; '-' denotes STDIN.

EOU

# Process options
print $Usage and exit if ($#ARGV<0);

my ($sync,$delete,$yes,$delete,$owl_imports,$Context,$ntriples,$freetext,$GenidNumberFile, $verbose,$namespace,$storename,$strawman,$stuff,$output_dir,$dbms_host,$dbms_port,$serialize);
$sync = 0;
$delete = 0;
$yes = 0;
while (defined($ARGV[0])) {
    my $opt = shift;

    if ($opt eq '-stuff') {
	print STDERR "WARNING! -stuff option is deprecated - input source is defined to be last passed argument now\n";
        $stuff = shift;
    } elsif ($opt eq '-Context') {
        $Context = shift;
    } elsif ($opt eq '-namespace') {
        $namespace = shift;
    } elsif ($opt eq '-GenidNumberFile') {
        $GenidNumberFile = shift;
    } elsif ($opt eq '-freetext') {
        $freetext = 1;
    } elsif ($opt eq '-strawman') {
        $strawman = 1;
    } elsif ($opt eq '-sync') {
        $sync = 1;
    } elsif ($opt eq '-ntriples') {
        $ntriples = 1;
    } elsif ($opt eq '-storename') {
        $storename = shift;
    } elsif ($opt eq '-version') {
	print $RDFStore::VERSION;
	exit;
    } elsif ($opt eq '-h') {
        print $Usage;
        exit;
    } elsif ($opt eq '-delete') {
	$delete=1;
    } elsif ($opt eq '-y') {
	$yes=1;
    } elsif ($opt eq '-v') {
	$verbose=1;
    } elsif ($opt eq '-owl:imports') {
        $owl_imports = 1;
    } elsif ($opt eq '-output_dir') {
	$opt=shift;
        $output_dir = $opt
		if(-e $opt);
	$output_dir .= '/'
		unless(	(not(defined $output_dir)) || 
			($output_dir eq '') || 
			($output_dir =~ /\s+/) || 
			($output_dir =~ /\/$/) );
    } elsif ($opt eq '-serialize') {
        $serialize = shift;
    } elsif ($opt eq '-dbms_host') {
        $dbms_host = shift;
    } elsif ($opt eq '-dbms_port') {
	$opt=shift;
        $dbms_port = (int($opt)) ? $opt : undef;
    } else {
	$stuff = $opt; #last is file/URL is not specificed with -stuff (which is deprecated)
    	};
};

my $factory=new RDFStore::NodeFactory();

#special case - no source and delete and confirmed
if(	(!$stuff) &&
	($storename) &&
	($delete) ) {
	my $in_context = ($Context) ? " in context '$Context'" : '';
	confirm("\n*WARNINIG* This operation can not be undone!!\n\nAre you sure you want to clear the whole '$storename' database$in_context? (^C to kill, any key to continue)\n\n")
		unless($yes);

	# zap the whole model
	my $model = new RDFStore::Model( Name => $output_dir.$storename,
					 Host => $dbms_host, 
					 Port => $dbms_port, 
					 NodeFactory => $factory,
					 FreeText     =>      $freetext,
					 Context => ( (defined $Context) ? $Context : undef ) );
	my $all = $model->elements;
	if($all->size<=0) {
		warn "Database '$storename' is empty.\n";
		exit;
		};
	while ( my $st = $all->each ) {
		$model->remove($st);

		print "Removed statement ".$st->toString."\n"
			if($verbose);
		};
	};

my $cnt;
if(	(defined $GenidNumberFile) &&
	(-e $GenidNumberFile) ) {
	# lock the genid counter
	open(FH,'+<'.$GenidNumberFile)
        	or die "Failed to get genid counter $!";
	# go non buffered.
	select(FH);
	$|=1;
	select(STDOUT);
	flock FH,2
        	or die "Failed to get exclusive lock $!";
	seek FH,0,0
        	or die "Failed to seek $!";
	while(<FH>) {
        	chomp;
        	$cnt = int $_;
        };
	die "No genid counter"
        	unless defined $cnt;
};

my $pt;
if($ntriples) {
        $pt = 'NTriples';
} else {
        $pt = 'SiRPAC';
};
$pt = 'RDFStore::Parser::'.$pt;

if($Context) {
	if($Context =~ m/^_:(.*)/) {
		$Context = $factory->createAnonymousResource($1);
	} else {
		$Context = $factory->createResource($Context);
		};
	};

my $style = ($storename or $serialize =~ /RDF\/XML/i ) ? 'RDFStore::Parser::Styles::RDFStore::Model' :
				'RDFStore::Parser::Styles::RDFStore::Statement';
my $p=new ${pt}(
				ErrorContext => 	3, 
				Style => 		$style,
				NodeFactory => 		$factory,
				Source	=> 		(defined $namespace) ?
								$namespace :
								($stuff =~ /^-/) ? undef : $stuff,
				bCreateBags =>		(defined $bagIDs) ? $bagIDs : undef,
				GenidNumber => $cnt,
				style_options	=>	{
							'seevalues' => 	$verbose,
							'owl:imports' => $owl_imports,
							'delete' => ($delete) ? 1 : undef,
							'confirm' => ($yes) ? 1 : undef,
							'store_options'		=> 	{	
										Name	=> 	$output_dir.$storename,
										Host =>	$dbms_host,
										Port =>	$dbms_port,
										FreeText     =>      $freetext,
										Sync    => $sync,
										Context	=> ( (defined $Context) ? $Context : undef ) }
						}
				);

my $m;
if($stuff =~ /^-/) {
	# for STDIN use no-blocking
	$m = $p->parsestream(*STDIN,$namespace);
} else {
	$m = $p->parsefile($stuff);
};
if(defined $GenidNumberFile) {
	unless(-e $GenidNumberFile) {
		open(FH,">".$GenidNumberFile)
			or die "Failed to create genid counter file $!";
		};
	$cnt = $p->getReificationCounter();
	seek FH,0,0
        	or die "Failed to seek $!";
	print FH $cnt."\n";
 
	select(FH);
	$|=1;
	flock FH,8
        	or die "Failed to unlock genid counter $!";
	close(FH);
	die "Issue with lock file $!"
        	if ($?);
};

$m->serialize(*STDOUT,$serialize)
	if( !$storename and $serialize );

sub confirm {
	my ($msg) = @_;

	print $msg;

	return <STDIN>;
	};
