#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib ".";
require "examples/parse-xml.pl";

my $parser = XmlParser->new;

sub plain { bless [ @_ ], "XmlParser::Node::Plain" }
sub elem  { bless [ @_ ], "XmlParser::Node::Element" }

sub test
{
   my ( $str, $expect, $name ) = @_;

   is( $parser->from_string( $str ), $expect, $name );
}

test q[<xml>Hello world</xml>],
     [ plain("Hello world") ],
     "Plaintext";

test q[<xml><message>Hello world</message></xml>],
     [ elem(message => {}, plain("Hello world")) ],
     "Single node";

test q[<xml><first>Hello</first><second>world</second></xml>],
     [ elem(first => {}, plain("Hello")), elem(second => {}, plain("world")) ],
     "Two nodes";

test q[<xml><first>Hello</first> <second>world</second></xml>],
     [ elem(first => {}, plain("Hello")), plain(" "), elem(second => {}, plain("world")) ],
     "Two nodes with whitespace";

test q[<xml><node a1="v1" a2="v2" /></xml>],
     [ elem(node => { a1 => "v1", a2 => "v2" }) ],
     "Node with attrs";

done_testing;
