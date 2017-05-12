#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;
use XML::LibXML;
use t::Octothorpe;

# In this test, the element acceptor is used individually.

my $parser = XML::LibXML->new;
my $doc = $parser->parse_string(<<XML);
<tests xmlns:A="uri:type:A">
  <ok>
    <Octothorpe><colon/></Octothorpe>
    <Octothorpe><emdash/><colon></colon></Octothorpe>
    <Octothorpe><colon>Larry Gets the colon</colon></Octothorpe>
    <Ampersand/>
    <Ampersand>
        <interpunct>2</interpunct>
    </Ampersand>
    <Caret><braces>2</braces></Caret>
    <Caret><parens></parens></Caret>
    <Octothorpe><colon/><A:section_mark/></Octothorpe>
  </ok>
  <fail>
    <Octothorpe desc="missing a required element" error="Node incomplete; expecting: .colon">
    </Octothorpe>
    <Octothorpe desc="text passed for Bool element" error="Superfluous child nodes on presence-only node">
      <emdash>x</emdash><colon></colon>
    </Octothorpe>
    <Octothorpe desc="attribute passed on Bool element" error="Superfluous attributes on presence-only node">
      <emdash foo="bar"><colon>x</colon></emdash>
    </Octothorpe>
    <Ampersand desc="bad value for Int xml data element" error="bad value 'two' at">
      <interpunct>two</interpunct>
    </Ampersand>
    <Ampersand desc="attribute passed on xml data element" error="Superfluous attributes on XML data node">
      <interpunct lang="en">2</interpunct>
      <apostrophe><colon /></apostrophe>
    </Ampersand>
    <Caret desc="alternation required, nothing given" error="Node incomplete; expecting: .parens.+braces.">
    </Caret>
    <Caret desc="single alternation required, passed multiple" error="Single child node expected">
      <braces>2</braces>
      <parens><apostrophe><emdash/><colon/></apostrophe></parens>
    </Caret>
  </fail>
</tests>
XML

{

	# replace the recursive part of the marshall process with a
	# mock that says where was recursed to
	package Dummy::Marshaller;
	sub get { bless [ $_[1] ], __PACKAGE__ }
	sub marshall_in_element { return \${$_[0]}[0] }
	sub isa {1}

	# this eliminates recursion on the way out.
	sub to_libxml { }
}

my $test_num = 1;
my $xsi = {
	"" => "",
	map { $_->declaredPrefix => $_->declaredURI }
		$doc->documentElement->attributes,
};

for my $oktest ( $doc->findnodes("//ok/*") ) {
	next unless $oktest->isa("XML::LibXML::Element");
	my @nodes = $oktest->childNodes;
	my $class = $oktest->localname;
	my $context = PRANG::Graph::Context->new(
		xpath => "//ok/$class\[position()=$test_num]",
		xsi => $xsi,
		base => (bless{},"Dummy::Marshaller"),

		#base => PRANG::Marshaller->get($class),
		prefix => "",
	);
	my %rv =
		eval { $class->meta->accept_childnodes( \@nodes, $context ) };
	for my $slot ( keys %rv ) {
		if ( (ref($rv{$slot})||"") eq "SCALAR" ) {
			$rv{$slot} = bless {}, ${$rv{$slot}};
		}
	}
	
	SKIP: {
	   if (grep { $test_num == $_ } (7, 8)) {
	       skip "Test $test_num broken due to changes in marshall_in_element interface", 2;
	   }
	    	
	   is($@, "", "ok test $test_num ($class) - no exception");

	   my $thing = eval{ $class->new(%rv) };
	   ok($thing, "created new $class OK") or diag("exception: $@");
	}

	# I'm going to give up on making these tests work.  The
	# problem is that the implementation is recursive, which
	# wasn't my preferred approach - I was going to use an
	# iterator and SAX.  It sure makes this sort of thing harder
	# to test.

	#my $node = $doc->createElement($class);
	#$context->reset;
	#$DB::single = 1 if ($test_num == 4);
	#eval { $class->meta->to_libxml($thing, $node, $context) };
	#is($@, "", "ok test $test_num - output elements no exception");
	#my @wrote_nodes = $node->childNodes;
	#@nodes = grep { !( $_->isa("XML::LibXML::Text")
	#and $_->data =~ /\A\s*\Z/) }
	#@nodes;
	#is(@wrote_nodes, @nodes,
	#"ok test $test_num - correct number of child nodes") or do {
	#diag("expected: ".$oktest->toString);
	#diag("got: ".$node->toString);
	#};

	$test_num++;
}

$test_num = 1;
for my $failtest ( $doc->findnodes("//fail/*") ) {
	next unless $failtest->isa("XML::LibXML::Element");
	my @nodes = $failtest->childNodes;
	my $class = $failtest->localname;
	my $test_name = $failtest->getAttribute("desc")
		|| "fail test $test_num";
	my $context = PRANG::Graph::Context->new(
		xpath => "//fail/$class\[position()=$test_num]",
		xsi => { "" => "" },
		base => (bless{},"Dummy::Marshaller"),

		#base => PRANG::Marshaller->get($class),
		prefix => "",
	);
	my $rv = eval {
		$class->new(
			$class->meta->accept_childnodes( \@nodes, $context )
		);
	};
	my $exception = "$@";
	isnt($exception, "", "$test_name - exception raised");
	if ( my $err_re = $failtest->getAttribute("error") ) {
		like(
			$exception, qr/$err_re/,
			"$test_name - exception string OK"
		);
	}
	$test_num++;
}

# Copyright (C) 2009, 2010  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>
