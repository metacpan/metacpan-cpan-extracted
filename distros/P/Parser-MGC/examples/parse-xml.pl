#!/usr/bin/perl

use v5.14;
use warnings;

# DO NOT RELY ON THIS AS A REAL XML PARSER!

# It is not intended to be used actually as an XML parser, simply to stand as
# an example of how you might use Parser::MGC to parse an XML-like syntax

# There are a great many things it doesn't do correctly; it lacks at least the
# following features:
#   Entities
#   Processing instructions
#   Comments
#   CDATA

package XmlParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   my $rootnode = $self->parse_node;
   $rootnode->kind eq "element" or die "Expected XML root node";
   $rootnode->name eq "xml"     or die "Expected XML root node";

   return [ $rootnode->children ];
}

sub parse_node
{
   my $self = shift;

   # A "node" is either an XML element subtree or plaintext
   $self->any_of( 'parse_plaintext', 'parse_element' );
}

sub parse_plaintext
{
   my $self = shift;

   my $str = $self->substring_before( '<' );
   $self->fail( "No plaintext" ) unless length $str;

   return XmlParser::Node::Plain->new( $str );
}

sub parse_element
{
   my $self = shift;

   my $tag = $self->parse_tag;

   $self->commit;

   return XmlParser::Node::Element->new( $tag->{name}, $tag->{attrs} ) if $tag->{selfclose};

   my $childlist = $self->sequence_of( 'parse_node' );

   $self->parse_close_tag->{name} eq $tag->{name}
      or $self->fail( "Expected $tag->{name} to be closed" );

   return XmlParser::Node::Element->new( $tag->{name}, $tag->{attrs}, @$childlist );
}

sub parse_tag
{
   my $self = shift;

   $self->expect( '<' );
   my $tagname = $self->token_ident;

   my $attrs = $self->sequence_of( 'parse_tag_attr' );

   my $selfclose = $self->maybe_expect( '/' );
   $self->expect( '>' );

   return {
      name  => $tagname,
      attrs => { map { ( $_->[0], $_->[1] ) } @$attrs },
      selfclose => $selfclose,
   };
}

sub parse_close_tag
{
   my $self = shift;

   $self->expect( '</' );
   my $tagname = $self->token_ident;
   $self->expect( '>' );

   return { name => $tagname };
}

sub parse_tag_attr
{
   my $self = shift;

   my $attrname = $self->token_ident;
   $self->expect( '=' );
   return [ $attrname => $self->parse_tag_attr_value ];
}

sub parse_tag_attr_value
{
   my $self = shift;

   # TODO: This sucks
   return $self->token_string;
}


use Data::Dumper;

if( !caller ) {
   my $parser = __PACKAGE__->new;

   my $ret = $parser->from_file( \*STDIN );
   print Dumper( $ret );
}


package XmlParser::Node;
sub new { my $class = shift; bless [ @_ ], $class }

package XmlParser::Node::Plain;
use base qw( XmlParser::Node );
sub kind { "plain" }
sub text { shift->[0] }

package XmlParser::Node::Element;
use base qw( XmlParser::Node );
sub kind     { "element" }
sub name     { shift->[0] }
sub attrs    { shift->[1] }
sub children { my $self = shift; @{$self}[2..$#$self] }

1;
