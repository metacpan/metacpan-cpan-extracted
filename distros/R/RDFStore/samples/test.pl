#!/usr/local/bin/perl -I ../lib
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
use File::Path qw(rmtree);

unless($#ARGV>=2) {
	print STDERR "\nUsage: <subject> <predicate> (<object> | 'object')\n\n";
	exit;
};

my $factory= new RDFStore::NodeFactory();
my $statement = $factory->createStatement(
			$factory->createResource($ARGV[0]),
			$factory->createResource($ARGV[1]),
			($#ARGV>2) ? $factory->createLiteral($ARGV[2]) : $factory->createResource($ARGV[2])
					);
my $statement0 = $factory->createStatement(
			$factory->createResource($ARGV[0]),
			$factory->createResource($ARGV[0]),
			($#ARGV>2) ? $factory->createLiteral($ARGV[2]) : $factory->createResource($ARGV[2])
					);
my $statement1 = $factory->createStatement($factory->createResource("http://www.altavista.com"),$factory->createResource("http://pen.jrc.it/schema/1.0/#author"),$factory->createLiteral("Alberto Reggiori"));

my $statement2 = $factory->createStatement($factory->createUniqueResource(),$factory->createUniqueResource(),$factory->createLiteral(""));

my $model = new RDFStore::Model(Name => 'test', Style => "BerkeleyDB", Split => 3);

$model->add($statement);
$model->add($statement0);
$model->add($statement1);
$model->add($statement2);

my $found = $model->find($statement->subject,undef,$statement->object);
my($found_elements) = $found->elements;
for ( my $st = $found_elements->first; $found_elements->hasnext; $st= $found_elements->next ) {
	print $st->getLabel(),"\n";
};

my $model1 = $model->duplicate();
#print $model1->getDigest->equals($model1->getDigest),"\n";
#print $model1->getDigest->hashCode,"\n";

print "The following should give the same results due that is a duplicate model :-)\n";

$found = $model1->find($statement->subject,undef,$statement->object);
($found_elements) = $found->elements;
for ( my $st = $found_elements->first; $found_elements->hasnext; $st= $found_elements->next ) {
	print $st->getLabel(),"\n";
};
eval{
rmtree('test');
};
