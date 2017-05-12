#  $Id: Constants.pm,v 1.16 2000/12/21 19:54:36 aigan Exp $  -*-perl-*-

package RDF::Service::Constants;

#=====================================================================
#
# DESCRIPTION
#   Export the constants used in Resource objects
#
# AUTHOR
#   Jonas Liljegren   <jonas@paranormal.se>
#
# COPYRIGHT
#   Copyright (C) 2000 Jonas Liljegren.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#=====================================================================

use strict;
use base 'Exporter';
use vars qw( @EXPORT_OK %EXPORT_TAGS );


# The constant list should be orderd by frequency, in order to shorten
# the average array lenght.

# Resouce
use constant IDS           =>  1; #Interface Domain Signature
use constant URISTR        =>  2;
use constant ID            =>  3;
use constant TYPE          =>  4; #hash of type_id => { model_id => 1 }
use constant TYPE_ALL      =>  5; #types solid
use constant REV_TYPE      =>  6; #hash of res_id => { model_id => 1 }
use constant REV_TYPE_ALL  =>  7; #rev type solid
use constant JUMPTABLE     =>  8; #{function=>[[coderef,interface]]}
use constant NS            =>  9; #node
use constant NAME          => 10; #string
use constant LABEL         => 11; #string
use constant PRIVATE       => 12; #hash of interface_id => {%data}
use constant MODEL         => 13; #$model_node
use constant ALIASFOR      => 14; #node
use constant REV_PRED      => 15; #array of $arc_node
use constant REV_PRED_ALL  => 16; #
use constant REV_SUBJ      => 17; #(props) hash of prop_id=>[$arc_node]
use constant REV_SUBJ_ALL  => 18; #rev subj solid
use constant REV_OBJ       => 19; #(rev_props)
use constant REV_OBJ_ALL   => 20; # rev obj solid
use constant JTK           => 21; #Jumptable key  (just for debugging)
use constant FACT          => 22; #1/0/undef  ### DEPRECATED
use constant MULTI         => 23; # Multipple models for the implicit arcs
use constant SOLID         => 24; # Is it retrievable from a interface?
use constant RUNLEVEL      => 25; # 0 = startup

# Resource li
use constant MEMBER        => 31;

# Resource Statement
use constant PRED          => 36; #node
use constant SUBJ          => 37; #node
use constant OBJ           => 38; #node

# Resource Literal
use constant VALUE         => 41; #ref to string
use constant LANG          => 42; #node

# Resource Model / container
use constant REV_MODEL     => 46;  # hash of res_id => node
use constant CONTENT       => 47;  # Container content
use constant READONLY      => 48;  # TODO: To be used?

# Resource Interface
use constant PREFIX        => 51;
use constant MODULE_NAME   => 52;
use constant MODULE_REG    => 53; #hash of prefix => {typeURI => JUMPTABLE}

# Resource Service
use constant INTERFACES    => 56;  # node


# Namespaces
use constant NS_RDF        => "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
use constant NS_RDFS       => "http://www.w3.org/2000/01/rdf-schema#";
use constant NS_LS         => "http://uxn.nu/rdf/2000/09/19/local-schema";
use constant NS_LD         => "http://uxn.nu/rdf/2000/09/19/local-data";
use constant NS_XML        => "xml:"; # TODO: Fix me!


# Context
use constant CONTEXT       => 1;
use constant NODE          => 2;
use constant WMODEL        => 3; # The working model
use constant MEMORY        => 4; # Same as PRIVATE
use constant HISTORY       => 5; # call history. Hash of "@_"=>1


my @RESOURCE = qw( IDS URISTR ID TYPE TYPE_ALL REV_TYPE REV_TYPE_ALL
		   JUMPTABLE NS NAME LABEL PRIVATE ALIASFOR FACT MODEL
		   REV_SUBJ REV_SUBJ_ALL REV_PRED REV_PRED_ALL REV_OBJ
		   REV_OBJ_ALL JTK MULTI SOLID RUNLEVEL );

my @INTERFACE = qw( PREFIX MODULE_NAME MODULE_REG );
my @LITERAL   = qw( VALUE LANG );
my @CONTAINER = qw( REV_MODEL CONTENT READONLY );
my @STATEMENT = qw( SUBJ PRED OBJ );
my @LI        = qw( MEMBER );
my @RDF       = qw( INTERFACES );
my @NAMESPACE = qw( NS_RDF NS_RDFS NS_LS NS_LD );
my @CONTEXT   = qw( CONTEXT NODE WMODEL MEMORY HISTORY );
my @DEPENDS   = qw( DPROPS DREVPROPS );

my @ALL = (@INTERFACE, @RESOURCE, @LITERAL, @CONTAINER, @STATEMENT, @LI,
	   @RDF, @NAMESPACE, @CONTEXT, '$Schema' );

@EXPORT_OK = ( @ALL );
%EXPORT_TAGS = (
    'all'        => [@ALL],
    'resource'   => [@RESOURCE],
    'interface'  => [@RESOURCE,@INTERFACE],
    'literal'    => [@RESOURCE,@LITERAL],
    'container'  => [@RESOURCE,@CONTAINER],
    'statement'  => [@RESOURCE,@STATEMENT],
    'li'         => [@RESOURCE,@LI],
    'rdf'        => [@RESOURCE, @RDF, @CONTAINER],
    'namespace'  => [@NAMESPACE],
    'context'    => [@CONTEXT],
    );





##### DATA

our $Schema =
{
    NS_LS.'#name' =>
    {
        NS_LS.'#name' => 'name',
	NS_RDF.'type' =>  \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDFS.'Resource'),
	NS_RDFS.'range' => \(NS_RDFS.'Literal'),
    },
    NS_LS.'#level' =>
    {
        NS_LS.'#name' => 'level',
	NS_RDF.'type' =>  \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDFS.'Class'),
	NS_RDFS.'range' => \(NS_RDFS.'Literal'),
    },
    NS_LS.'#updated' =>
    {
        NS_LS.'#name' => 'updated',
	NS_RDF.'type' =>  \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDFS.'Model'),
	NS_RDFS.'range' => \(NS_RDFS.'Literal'),
    },
    NS_LS.'#agent' =>
    {
        NS_LS.'#name' => 'agent',
	NS_RDF.'type' =>  \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDFS.'Model'),
	NS_RDFS.'range' => \(NS_RDFS.'Literal'),
    },
    NS_LS.'#Interface' =>
    {
	NS_LS.'#ns' => \(NS_LS),
	NS_LS.'#name' => 'Interface',
        NS_LS.'#level' => '1',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
    },
    NS_LS.'#interface' =>
    {
	NS_LS.'#name' => 'interface',
	NS_RDF.'type' =>  \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDFS.'Resource'),
	NS_RDFS.'range' => \(NS_LS.'#Interface'),
    },
    NS_LS.'#Selection' =>
    {
	NS_LS.'#name' => 'Selection',
        NS_LS.'#level' => '1',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
	NS_RDFS.'subClassOf' => \(NS_RDFS.'Container'),
    },
    NS_LS.'#Model' =>
    {
	NS_LS.'#name' => 'Model',
        NS_LS.'#level' => '1',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
	NS_RDFS.'subClassOf' => \(NS_RDFS.'Container'),
    },
    NS_LS.'#model' =>
    {
	NS_LS.'#name' => 'model',
	NS_RDF.'type' =>  \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDFS.'Resource'),
	NS_RDFS.'range' => \(NS_LS.'#Model'),
    },
    NS_LS.'#Service' =>
    {
	NS_LS.'#name' => 'Service',
        NS_LS.'#level' => '1',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
	NS_RDFS.'subClassOf' => \(NS_LS.'#Model'),
    },

    NS_RDFS.'Resource' =>
    {
	NS_LS.'#name' => 'Resource',
        NS_LS.'#level' => '0',
	NS_RDF.'type' => \ (NS_RDFS.'Class'),
	NS_RDFS.'label' => 'Resource',
	NS_RDFS.'comment' => 'The most general class',
    },

    NS_RDF.'type' =>
    {
	NS_LS.'#name' => 'type',
	NS_RDF.'type' => \(NS_RDF.'Property'),
	NS_RDFS.'range' => \(NS_RDFS.'Class'),
    },
    NS_RDFS.'comment' =>
    {
	NS_LS.'#name' => 'comment',
	NS_RDF.'type' => \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDFS.'Resource'),
	NS_RDFS.'range' => \(NS_RDFS.'Literal'),
    },
    NS_RDFS.'label' =>
    {
	NS_LS.'#name' => 'label',
	NS_RDF.'type' => \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDFS.'Resource'),
	NS_RDFS.'range' => \(NS_RDFS.'Literal'),
    },
    NS_RDFS.'Class' =>
    {
	NS_LS.'#name' => 'Class',
        NS_LS.'#level' => '1',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
	NS_RDFS.'subClassOf' => \(NS_RDFS.'Resource'),
    },
    NS_RDFS.'subClassOf' =>
    {
	NS_LS.'#name' => 'subClassOf',
	NS_RDF.'type' => \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDFS.'Class'),
	NS_RDFS.'range' => \(NS_RDFS.'Class'),
    },
    NS_RDFS.'subPropertyOf' =>
    {
	NS_LS.'#name' => 'subPropertyOf',
	NS_RDF.'type' => \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDF.'Property'),
	NS_RDFS.'range' => \(NS_RDF.'Property'),
    },
    NS_RDFS.'seeAlso' =>
    {
	NS_LS.'#name' => 'seeAlso',
	NS_RDF.'type' => \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDFS.'Resource'),
	NS_RDFS.'range' => \(NS_RDFS.'Resource'),
    },
    NS_RDFS.'isDefinedBy' =>
    {
	NS_LS.'#name' => 'isDefinedBy',
	NS_RDF.'type' => \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDFS.'Resource'),
	NS_RDFS.'range' => \(NS_RDFS.'Resource'),
    },
    NS_RDFS.'ConstraintResource' =>
    {
	NS_LS.'#name' => 'ConstraintResource',
        NS_LS.'#level' => '1',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
    },
    NS_RDFS.'ConstraintProperty' =>
    {
	NS_LS.'#name' => 'ConstraintProperty',
        NS_LS.'#level' => '1',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
	NS_RDFS.'subClassOf' => [ \(NS_RDF.'Property'),
				\(NS_RDFS.'ConstraintResource'),
				],
    },
    NS_RDFS.'domain' =>
    {
	NS_LS.'#name' => 'domain',
	NS_RDF.'type' => \(NS_RDFS.'ConstraintProperty'),
	NS_RDFS.'domain' => \(NS_RDF.'Property'),
	NS_RDFS.'range' => \(NS_RDFS.'Class'),
    },
    NS_RDFS.'range' =>
    {
	NS_LS.'#name' => 'range',
	NS_RDF.'type' => \(NS_RDFS.'ConstraintProperty'),
	NS_RDFS.'domain' => \(NS_RDF.'Property'),
	NS_RDFS.'range' => \(NS_RDFS.'Class'),
    },
    NS_RDF.'Property' =>
    {
	NS_LS.'#name' => 'Property',
        NS_LS.'#level' => '1',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
    },
    NS_RDFS.'Literal' =>
    {
	NS_LS.'#name' => 'Literal',
        NS_LS.'#level' => '1',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
    },
    NS_RDF.'Statement' =>
    {
	NS_LS.'#name' => 'Statement',
        NS_LS.'#level' => '1',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
    },
    NS_RDF.'subject' =>
    {
	NS_LS.'#name' => 'subject',
	NS_RDF.'type' => \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDF.'Statement'),
	NS_RDFS.'range' => \(NS_RDFS.'Resource'),
    },
    NS_RDF.'predicate' =>
    {
	NS_LS.'#name' => 'predicate',
	NS_RDF.'type' => \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDF.'Statement'),
	NS_RDFS.'range' => \(NS_RDF.'Property'),
    },
    NS_RDF.'object' =>
    {
	NS_LS.'#name' => 'object',
	NS_RDF.'type' => \(NS_RDF.'Property'),
	NS_RDFS.'domain' => \(NS_RDF.'Statement'),
    },
    NS_RDFS.'Container' =>
    {
	NS_LS.'#name' => 'Container',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
        NS_LS.'#level' => '1',
    },
    NS_RDF.'Bag' =>
    {
	NS_LS.'#name' => 'Bag',
        NS_LS.'#level' => '2',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
	NS_RDFS.'subClassOf' => \(NS_RDFS.'Container'),
    },
    NS_RDF.'Seq' =>
    {
	NS_LS.'#name' => 'Seq',
        NS_LS.'#level' => '2',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
	NS_RDFS.'subClassOf' => \(NS_RDFS.'Container'),
    },
    NS_RDF.'Alt' =>
    {
	NS_LS.'#name' => 'Alt',
        NS_LS.'#level' => '2',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
	NS_RDFS.'subClassOf' => \(NS_RDFS.'Container'),
    },
    NS_RDFS.'ContainerMembershipProperty' =>
    {
	NS_LS.'#name' => 'ContainerMembershipProperty',
        NS_LS.'#level' => '1',
	NS_RDF.'type' => \(NS_RDFS.'Class'),
	NS_RDFS.'subClassOf' => \(NS_RDF.'Property'),
    },
    NS_RDF.'value' =>
    {
	NS_LS.'#name' => 'value',
	NS_RDF.'type' => \(NS_RDF.'Property'),
    },
};


1;
