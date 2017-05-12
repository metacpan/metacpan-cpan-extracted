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

# ok here is the a basic Unix like shell to manage RDF (RDFStore) databases
#
# Useful for inspiration are the following links:
#
#	XML Editing Shell: http://xsh.sourceforge.net/ and http://www.xml.com/lpt/a/2002/07/10/kip.html
#	Guha rdfdb tcp/ip commands: http://www.guha.com/rdfdb/query.html
#	Tucana RDF store Interactive Query Language: http://tks.pisoftware.com/user/itql.html
#	Intellidimension RDF Gateway RDFQL: http://www.intellidimension.com/default.rsp?topic=/pages/rdfgateway/reference/db/default.rsp
#

use RDFStore::Parser::SiRPAC;
use RDFStore::Parser::NTriples;
use RDFStore::NodeFactory;
use Carp;

my $Usage =<<EOU;
Usage is:
    $0 [-h] [-f <command_file>] [-i]

RDF shell

-h	Print this message

[-f <command_file>]
	Command file containing the RDF shell commands

EOU

my ($command_file);
$interactive=0;
while (defined($ARGV[0]) and $ARGV[0] =~ /^[-+]/) {
    my $opt = shift;

    if ($opt eq '-f') {
        $command_file = shift;
	undef $command_file
		unless(-e $command_file);
    } elsif ($opt eq '-h') {
        print $Usage;
        exit;
    } elsif ($opt eq '-v') {
	$verbose=1;
    } else {
        die "Unknown option: $opt\n$Usage";
    };
};

my $fh;
if($command_file) {
	open(FILE,$command_file);
	$fh = *FILE;
} else {
	$fh = *STDIN;
	};

my %aliases = (
	'http://www.w3.org/1999/02/22-rdf-syntax-ns#' => rdf,
	'http://www.w3.org/2000/01/rdf-schema#' => rdfs,
	'http://purl.org/rss/1.0/' => rss,
	'http://www.daml.org/2001/03/daml+oil#' => 'daml+oil',
	'http://purl.org/dc/elements/1.1/' => 'dc',
	'http://purl.org/dc/terms/' => 'dcq',
	'http://xmlns.com/foaf/0.1/' => 'foaf'
	);

print "\nWelcome to RDFStore shell!\n\nType help for a list of available commands\n\n" unless($command_file);

for(;;) {
	prompt();

	$line = <$fh>;

	last unless($line);

	#print "OOOKKK!!!\n" if($line =~ m/^[[A/);

	next
		if( $line =~ m/^(\s|\n|#[^\n]*)*$/gm);

	if($line =~ m/^(help)/i) {
		print "help <command>\n";
	} elsif($line =~ m/^(quit|exit)/i) {
		exit;
		};
	};

close(FILE)
	if($command_file);

sub prompt { print 'rdfsh> '; };
