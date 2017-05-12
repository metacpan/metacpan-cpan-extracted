#!/usr/local/bin/perl

eval 'exec /usr/local/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

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
# by Dirk-Willem van Gulik for Web Weaving Internet Engineering m/v Arnhem,
# The Netherlands.
#
##############################################################################

use Carp;
use RDFStore::Model;
use RDFStore::NodeFactory;
use RDFStore::Parser::SiRPAC;
use RDFStore::Vocabulary::RDF;
use RDFStore::Vocabulary::RDFS;

my $Usage =<<EOU;
Usage is:
    $0 [-h] [-outdir dir] schema_file

Given an RDF Schema (RDFS) generates JavaDoc style HTML documentation for the schema itself.

-h	Print this message

[-v]	Be verbose

[-name label]
	A human readable label for the schema/project.

[-outdir dir]
	Target directory.

[-examples file]
	Example instances file.

See http://wadi.asemantics.com/pieter/ for an example output.

EOU

my ($verbose,$name,$outdir,$schema_file,$examples);
while (defined($ARGV[0])) {
    my $opt = shift;

    if ($opt eq '-outdir') {
        $outdir = shift;
    } elsif ($opt eq '-name') {
        $name = shift;
    } elsif ($opt eq '-examples') {
        $examples = shift;
    } elsif ($opt eq '-h') {
        print $Usage;
        exit;
    } elsif ($opt eq '-v') {
	$verbose=1;
    } else {
	$schema_file=$opt;
    	};
};

unless($schema_file) {
	print $Usage;
	exit;
	};

$outdir = 'rdfdoc'
	unless($outdir);

mkdir $outdir
	unless(-d $outdir);

my $factory = new RDFStore::NodeFactory();

# bear in mind that this is NOT fully RDF Schema aware ie. using RDFStore::SchemaModel yet!!
my $p=new RDFStore::Parser::SiRPAC(
                                ErrorContext =>         3, 
                                Style =>                'RDFStore::Parser::Styles::RDFStore::Model',
                                NodeFactory =>          $factory,
                                store   =>      { seevalues =>    $verbose }
                                );

my $m;
if($stuff =~ /^-/) {
        # for STDIN use no-blocking
        $m = $p->parsestream(*STDIN);
} else {
        $m = $p->parsefile($schema_file);
};

if($examples) {
	my $p1=new RDFStore::Parser::SiRPAC(
                                ErrorContext =>         3, 
                                Style =>                'RDFStore::Parser::Styles::RDFStore::Model',
                                NodeFactory =>          $factory,
                                store   =>      { seevalues =>    $verbose }
                                );

	my $m_e = $p1->parsefile($examples);
	my $exs = $m_e->elements;
	while (my $e = $exs->each ) {
		$m->add($e);
		};	
	};

my @namespaces = $m->namespaces;

$name = 'RDFDoc'
	unless($name);

my $date = `date`;
chop($date);

# toc.html
&toc();

sub toc {
	open(TOC,">$outdir/toc.html");

	print TOC <<EOFHTML;
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>$name - Class Hierarchy</title>
</head>
<body>
<center><h1> Class Hierarchy for <i>$name</i> Project </h1></center><hr>
<p>
<p>
<ul>
EOFHTML

	#take top classes
	my $top_classes=$m->find(undef,$RDFStore::Vocabulary::RDF::type,$RDFStore::Vocabulary::RDFS::Class)->elements;
	if($top_classes->size <= 0 ) {
		die "No rdfs:Class(es) found in $schema_file!\n";
		};

	while ( my $top_class = $top_classes->each_subject ) {
		my $sc = $m->find($top_class,$RDFStore::Vocabulary::RDFS::subClassOf)->elements;
		my $ns = $sc->first_object;
		$ns = $ns->getNamespace
			if($ns);
		next
			unless(	$sc->size <=0 or 
				$sc->size==1 and $sc->first_object->equals($RDFStore::Vocabulary::RDFS::Resource) or
				$sc->size==1 and (! grep /^$ns$/,@namespaces ) );

		&visit_class( $top_class, *TOC ) ;
        	};

	print TOC <<EOFHTML;
</ul>
<hr>Generated on $date</body></html>
EOFHTML

	close(TOC);
	};

# example
sub example {
	my ($example,$class_name) = @_;

	my $example_name = ($example->isbNode) ? $example->toString : $example->getLocalName;

	open(EXAMPLE,">$outdir/$example_name.html");

	print EXAMPLE <<EOFHTML;
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Project: $name - Example of $class_name Class - $example_name</title>
</head>
<body>
<H2><font size="-1"> Project: $name</font><BR>
Example $example_name</H2>  
<dl>
<dt><b> Example of <A HREF="$class_name.html">$class_name</A> Class&nbsp;</b></dt>
<dt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
</dl>
<TABLE BORDER="1" CELLPADDING="3" CELLSPACING="0" WIDTH="100%"> 
<TR BGCOLOR="#CCCCFF" CLASS="TableHeadingColor">
<TD COLSPAN=3 width="100%"><font size="+2"><b>Own Slots</b></font></TD>
</TR> 
<TR BGCOLOR="white" CLASS="TableRowColor"> 
<TD ALIGN="right" VALIGN="top" WIDTH="20%"><b>Slot name</b></TD>
<TD ALIGN="left" width="10%"><b>Value&nbsp;</b></TD> 
<TD ALIGN="left" width="10%"><b>Type</b></TD>   
</TR>

EOFHTML

	my $slots = $m->find($example)->elements;

	while ( my $s = $slots->each) {
		next
			if( $s->predicate->equals( $RDFStore::Vocabulary::RDF::type ) );
		my $slot_name = $s->predicate->getLocalName;
		my $value = $s->object;
		my $type;
		my $tt;
		if($value->isa("RDFStore::Resource")) {
			$type = $m->find($value, $RDFStore::Vocabulary::RDF::type)->elements->first_object;

			if( $value->isbNode ) {
				my $ll = $m->find($value, $RDFStore::Vocabulary::RDFS::label)->elements->first_object; #pick up rdfs:label of it if there
				$ll = ($ll) ? $ll->toString : 'bNode';
				$value = "<A HREF='".$value->toString.".html'>$ll</A>";
			} else {
				my $ns = $value->getNamespace;
				if( grep /^$ns$/, @namespaces ) {
					$value = "<A HREF='".$value->getLocalName.".html'>".$value->getLocalName."</A>";
				} else {
					$tt = 'Resource<br>(controlled list)';
					$value = $value->getLocalName;
					};
				};
		} else {
			$value = $value->toString;
			};

		unless($tt) {
			if($type) {
				$type = $type->getLocalName;
				$type = " (of class <A HREF='".$type.".html'>".$type."</A>)";
				$tt = 'Instance';
			} else {
				$tt = 'String';
				};
			};

		print EXAMPLE <<EOFHTML;

<TR>
<TD ALIGN="left" VALIGN="top" WIDTH="15%"><i>$slot_name&nbsp;</i></TD>
<TD ALIGN="left" width="70%">$value$type&nbsp;</b></TD> 
<TD ALIGN="left" width="15%">$tt&nbsp;</b></TD>
</TR> 

EOFHTML
        	};

	print EXAMPLE <<EOFHTML;
</table><P>
<P><A HREF="toc.html"> Return to class hierarchy </A>
<hr>Generated on $date</body></html>
EOFHTML

	close(EXAMPLE);
	};

sub visit_class {
	my ($top_class, $fh, $parent_slots ) = @_;

	my $class_name = $top_class->getLocalName;
	print $fh <<EOFHTML;
<li>
<A HREF="$class_name.html">$class_name</A>
</li>
EOFHTML
	my $examples = $m->find(undef,$RDFStore::Vocabulary::RDF::type, $top_class);

	if($examples->size > 0 ) {

		$examples = $examples->elements;

		print $fh <<EOFHTML;
<ul>
<i>Examples :
EOFHTML
		my $max_examples=3; #avoid a complete messy HTML page...
		my $ex_i=0;
		while ( my $ex = $examples->each_subject ) {
			last
				if($ex_i == $max_examples);

			my $ll = $m->find($ex, $RDFStore::Vocabulary::RDFS::label)->elements->first_object; #pick up rdfs:label of it if there

			my $example_name;
			if($ex->isbNode) {
				$example_name = $ex->toString;
				$ll = ($ll) ? $ll->toString : 'bNode';
			} else {
				$example_name = $ex->getLocalName;
				$ll = ($ll) ? $ll->toString : $example_name;
				};
			print $fh "<A HREF='$example_name.html'>$ll</A>&nbsp;";

			&example( $ex, $class_name );

			$ex_i++;
			};

		print $fh <<EOFHTML;
</i></ul>
EOFHTML
		};

	my $slots = $m->find(undef,$RDFStore::Vocabulary::RDFS::domain, $top_class)->elements;
	$slots = $slots->unite( $parent_slots )
		if($parent_slots);

	my $sc = $m->find(undef, $RDFStore::Vocabulary::RDFS::subClassOf, $top_class)->elements;

	print $fh '<ul>'
		if($sc->size>0);

	while( my $es = $sc->each_subject) {
		&visit_class( $es, $fh, $slots );
		};

	print $fh '</ul>'
		if($sc->size>0);

	&class($top_class, $slots);
	};

# class
sub class {
	my ($class,$slots) = @_;

	my $class_name = ($class->isbNode) ? $class->toString : $class->getLocalName;

	my $base_class = $m->find($class,$RDFStore::Vocabulary::RDFS::subClassOf)->elements;
	if($base_class->size > 0 and ! $base_class->first_object->equals($RDFStore::Vocabulary::RDFS::Resource) ) {
		$base_class = $base_class->first_object;
		my $ns = $base_class->getNamespace;
		if( ! grep /^$ns$/, @namespaces ) {
			$base_class = $base_class->toString;
		} else {
			$base_class = ($base_class->isbNode) ? $base_class->toString : $base_class->getLocalName;
			$base_class =  "<A HREF='$base_class.html'>$base_class</A>";
			};
	} else {
		$base_class = ':THING';	
		};	

	open(CLASS,">$outdir/$class_name.html");

	print CLASS <<EOFHTML;
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Project: $name - Example of $class_name Class - $class_name</title>
</head>
<body>
<H2><font size="-1"> Project: $name</font><BR>
Class $class_name</H2>  
<dl>
<dt><b>Concrete Class Extends&nbsp;</b></dt>
<dt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
$base_class</dt><dd>&nbsp;</dd>
<dt><b>Direct Examples:</b> <dd>
EOFHTML

	my $examples = $m->find(undef,$RDFStore::Vocabulary::RDF::type, $class);

	if($examples->size > 0 ) {

		$examples = $examples->elements;

		while ( my $ex = $examples->each_subject ) {
			if($ex->isbNode) {
				my $example_name = $ex->toString;
				my $ll = $m->find($ex, $RDFStore::Vocabulary::RDFS::label)->elements->first_object; #pick up rdfs:label of it if there
				$ll = ($ll) ? $ll->toString : 'bNode';
				print CLASS "<A HREF='$example_name.html'>$ll</A>&nbsp;";
			} else {
				my $example_name = $ex->getLocalName;
				print CLASS "<A HREF='$example_name.html'>$example_name</A>&nbsp;";
				};
			};
	} else {
		print CLASS "None";
		};

	print CLASS <<EOFHTML;
</dt><dd>&nbsp;</dd>
<DT><B>Direct Subclasses:</B> <DD>
EOFHTML
	my $sub_classes = $m->find(undef,$RDFStore::Vocabulary::RDFS::subClassOf, $class)->elements;
	if($sub_classes->size > 0) {
		print CLASS "<OL>";
		while ( my $sc = $sub_classes->each_subject ) {
			if($sc->isbNode) {
				my $sc_name = $sc->toString;
				my $ll = $m->find($sc, $RDFStore::Vocabulary::RDFS::label)->elements->first_object; #pick up rdfs:label of it if there
				$ll = ($ll) ? $ll->toString : 'bNode';
				print CLASS "<LI><A HREF='$sc_name.html'>$ll</A></LI>";
			} else {
				my $sc_name = $sc->getLocalName;
				print CLASS "<LI><A HREF='$sc_name.html'>$sc_name</A></LI>";
				};
			};
		print CLASS "</OL>";
	} else {
		print CLASS "None";
		};
	print CLASS <<EOFHTML;
</dt><dd>&nbsp;</dd> </dl>
<HR>
<P>
<TABLE BORDER="1" CELLPADDING="3" CELLSPACING="0" WIDTH="100%"> 
<TR BGCOLOR="#CCCCFF" CLASS="TableHeadingColor">
<TD COLSPAN=6 width="100%"><font size="+2"><b>Template Slots</b></font></TD>
</TR> 
<TR BGCOLOR="white" CLASS="TableRowColor"> 
<TD ALIGN="right" WIDTH="10%"><b>Slot name</b></TD>
<TD width="60%"><b>Documentation</b></TD>
<TD width="10%"><b>Type</b></TD>   
<TD width="10%"><b>Allowed Values/Classes</b></TD> 
<TD width="5%"><b>Cardinality</b></TD> 
<TD width="5%"><b>Default</b></TD>  
</TR>  

EOFHTML

	while ( my $s = $slots->each_subject) {
		my $slot_name = $s->getLocalName;
		my $comment = $m->find($s,$RDFStore::Vocabulary::RDFS::comment)->elements;
		if($comment->size>0) {
			$comment=$comment->first_object->toString;
		} else {
			$comment='';
			};
		my $tt=$m->find($s,$RDFStore::Vocabulary::RDFS::range)->elements;
		my $ranges;
		if($tt->size > 0 and ! $tt->first_object->equals($RDFStore::Vocabulary::RDFS::Literal) ) {
			while(my $rr=$tt->each_object) {
				if($rr->isbNode) {
					my $rr_name = $rr->toString;
					my $ll = $m->find($rr, $RDFStore::Vocabulary::RDFS::label)->elements->first_object; #pick up rdfs:label of it if there
					$ll = ($ll) ? $ll->toString : 'bNode';
					$ranges .= "<A HREF='$rr_name.html'>$ll</A>&nbsp;";
				} else {
					my $rr_name = $rr->getLocalName;
					if(	($rr->getNamespace eq 'http://www.w3.org/2000/10/XMLSchema#') ||
						($rr->getNamespace eq 'http://www.w3.org/2001/XMLSchema#') ) {
						$ranges .= "$rr_name&nbsp;";
					} else {
						$ranges .= "<A HREF='$rr_name.html'>$rr_name</A>&nbsp;";
						};
					};
				};
			$tt = 'Instance';
		} else {
			$tt = 'String';
			};
		my $max = $m->find($s,$factory->createResource('http://www.w3.org/2002/07/owl#maxCardinality'))->elements;
		if($max->size > 0) {
			$max = $max->first_object->toString;
		} else {
			$max = 'n';
			};
		my $min = $m->find($s,$factory->createResource('http://www.w3.org/2002/07/owl#minCardinality'))->elements;
		if($min->size > 0) {
			$min = $min->first_object->toString;
		} else {
			$min = '0';
			};

		print CLASS <<EOFHTML;

<TR>
<TD ALIGN="right"  WIDTH="10%"><i>$slot_name</i></TD>
<TD ALIGN="left" width="60%">$comment&nbsp;</TD>
<TD ALIGN="left" width="15%">$tt&nbsp;</TD>   
<TD ALIGN="left" width="10%">$ranges&nbsp;</TD> 
<TD width="5%">$min:$max&nbsp;</b></TD> 
<TD ALIGN="left" width="5%">&nbsp;</TD>
</TR>  

EOFHTML
        	};

	print CLASS <<EOFHTML;
</table><P>
<P><A HREF="toc.html"> Return to class hierarchy </A>
<hr>Generated on $date</body></html>
EOFHTML

	close(CLASS);
	};
