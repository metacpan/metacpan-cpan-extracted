#  $Id: V01.pm,v 1.28 2000/12/21 22:04:18 aigan Exp $  -*-perl-*-

package RDF::Service::Interface::Base::V01;

#=====================================================================
#
# DESCRIPTION
#   Interface to the basic Resource actions
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
use RDF::Service::Constants qw( :all );
use RDF::Service::Cache qw( save_ids uri2id debug time_string
			    $DEBUG debug_start debug_end id2uri
			    validate_context );
use URI;
use Data::Dumper;
use Carp qw( confess carp cluck croak );

sub register
{
    my( $interface ) = @_;

    return
    {
	'' =>
	{
	    NS_LS.'#Service' =>
	    {
		'connect' => [\&connect],
		'find_node' => [\&find_node],
	    },
	    NS_LS.'#Model' =>
	    {
		'create_model'    => [\&create_model],
		'is_empty'  => [\&not_implemented],
		'size'      => [\&not_implemented],
		'validate'  => [\&not_implemented],

		# The NS. The base for added things...
		'source_uri'=> [\&not_implemented],

		# is the model open or closed?
		'is_mutable'=> [\&not_implemented],

	    },
	    NS_RDFS.'Literal' =>
	    {
		'desig' => [\&desig_literal],
		'value' => [\&value],
	    },
	    NS_RDF.'Statement' =>
	    {
		'pred'  => [\&pred],
		'subj'  => [\&subj],
		'obj'   => [\&obj],
	        'desig' => [\&desig_statement],
	    },
	    NS_RDFS.'Resource' =>
	    {
		'desig' => [\&desig_resource],
		'delete_node_cascade' => [\&delete_node_cascade],
		'delete_node'         => [\&delete_node],
	        'init_types'          => [\&noop],
		'init_rev_subjs'      => [\&noop],
	        'store_types'         => [\&noop],
	        'remove_types'        => [\&noop],
	        'store_node'          => [\&noop],
	        'store_props'         => [\&noop],
	    },
	    NS_RDFS.'Class' =>
	    {
		'level' => [\&level],
		'init_rev_subjs' => [\&init_rev_subjs_class],
	    },
	},
	NS_LD."/service/" =>
	{
	    NS_RDFS.'Resource' =>
	    {
		'init_types' => [\&init_types_service],
		'init_rev_subjs' => [\&init_rev_subjs],
	    },
	},
	&NS_LD."/literal/" =>
	{
	    NS_RDFS.'Resource' =>
	    {
		'init_types' => [\&init_types_literal],
		'init_rev_subjs' => [\&init_rev_subjs],
	    },
	},
	&NS_LS =>
	{
	    NS_RDFS.'Resource' =>
	    {
		'init_types' => [\&init_types],
		'init_rev_subjs' => [\&init_rev_subjs],
		'level'      => [\&base_level],
	    },
	},
	&NS_RDF =>
	{
	    NS_RDFS.'Resource' =>
	    {
		'init_types' => [\&init_types],
		'init_rev_subjs' => [\&init_rev_subjs],
		'level'      => [\&base_level],
	    },
	},
	&NS_RDFS =>
	{
	    NS_RDFS.'Resource' =>
	    {
		'init_types' => [\&init_types],
		'init_rev_subjs' => [\&init_rev_subjs],
		'level'      => [\&base_level],
	    },
	},
    };
}



# ??? Create literal URIs by apending '#val' to the statement URI

sub not_implemented { die "not implemented" }

# TODO: Remove this, but without fatal results
sub noop {0,0} # Do nothing and continue

sub connect
{
    my( $self, $i, $module, $args ) = @_;

    # Create the interface object. The IDS will be the same for the
    # RDF object and the new interface object.  Old interfaces doesn't
    # get their IDS changed.

    # A Interface is a source of statements. The interface also has
    # special metadata, as the type of interface, its range, etc.  The
    # main property of the interface is its model that represents all
    # the statements.  The interface can also have a collection of
    # literals, namespaces, resource names and other things.


    # Create the new interface resource object
    #
    my $uri = _construct_interface_uri( $module, $args );
    my $node = $self->[NODE];



    if( $DEBUG >= 5 )
    {
	debug "Nodes in this IDS:\n";
	foreach my $id ( keys %{$self->[WMODEL][NODE][REV_MODEL]} )
	{
	    my $obj = $self->get_context_by_id($id);
	    debug "  $id: ".$obj->desig."\n";
	}
    }

    # Generate new IDS
    #
    my $new_ids = join('-', map(uri2id($_->[URISTR]),
				@{$node->[INTERFACES]}),
		       uri2id($uri));

    # Initialize the cache for this IDS.  Each IDS has it's own cache
    # of node objects
    #
    $RDF::Service::Cache::node->{$new_ids} ||= {};

    # Update IDS and export model resources to new IDS
    #
    _export_to_ids( $self, $i, $node, $new_ids );



    # A new Service node should now have been created.  Make $self
    # point to the new node.  Change the IDS in order to get it from
    # the right IDS cache.  Kill the old node!
    #
    my $new_node = $self->get_node_by_id( $node->[ID], $new_ids );
    $self->[NODE] = $new_node;
    my $new_wmodel =
      $self->get_context_by_id( $self->[WMODEL][NODE][ID], $new_ids );
    $self->[WMODEL] = $new_wmodel;
#    debug "*!* New NODE has now IDS $self->[NODE][IDS]\n";
#    debug "*!* Setting new WMODEL to IDS $new_wmodel->[NODE][IDS]\n";
    $new_node->[INTERFACES] = $node->[INTERFACES];
    $node = undef;



    # Create a new base model
    #
    my $base_model = $self->get_node(NS_LD.'#The_Base_Model', $new_ids);
    $base_model->[TYPE_ALL] = 2;
    debug "Changing SOLID to 1 for $base_model->[URISTR] ".
      "IDS $base_model->[IDS]\n", 3;
    $base_model->[SOLID] = 1; # nonchanging
    $new_node->[MODEL] = $base_model;

    # This should get the new *interface* node prepared by _export_to_ids
    #
    my $new_interface = $self->get( $uri, $new_ids );
    my $new_interface_node = $new_interface->[NODE];

    push @{$new_node->[INTERFACES]}, $new_interface_node;
    save_ids( $new_ids, $new_node->[INTERFACES] );

    # Set up the new object, based on the IDS
    #
    $new_interface_node->[MODEL] = $self->[WMODEL][NODE]; # What is the model of this?
    $new_interface_node->[MODULE_NAME] = $module; # This is not used


    # OBS: The TYPE creation must wait. The type object depends on the
    # RDFS interface object in the creation. So it can't be set until
    # the RDFS interface has been created. The TYPE value will be set
    # then needed.

    # This is the functions offered by the interface. Pass on the
    # interface initialization arguments.
    #
    my $file = $module;
    $file =~ s!::!/!g;
    $file .= ".pm";
    require "$file" or die $!;


    debug "Registring $file\n", 1;

  {   no strict 'refs';
      $new_interface_node->[MODULE_REG] =
	&{$module."::register"}( $new_interface_node, $args );
  }

    return( $new_interface, 1 );
}



sub create_model
{
    my( $self, $i, $obj, $content ) = @_;


    ### NOTES from old create_model in DBI
    #
    # We are asked to create a new resource and a new object
    # representing that resource and a context for the resource
    # object.  The new resource must have an URI.  The creator must
    # own the $uri namespace, as statements will be placed in it..

    # If no URI is supplied, one will be generated by the method
    # create_resource().  In case the URI is supplied, it will
    # be validated by the appropriate interface.



    # TODO: Validate the URI

    $content ||= [];

    unless( ref $obj )
    {
	unless( defined $obj )
	{
	    $obj = NS_LD."/model/".&get_unique_id;
	}
	$obj = $self->get( $obj );
    }

    my $obj_node = $obj->[NODE];

    debug "  ( $obj_node->[URISTR] )\n", 2;

    # The model consists of triples. The [content] holds the access
    # points for the parts of the model. Each element can be either a
    # triple, model, ns, prefix or interface. Each of ns, prefix and
    # interface represents all the triples contained theirin.

    # the second parameter is the interface of the created object
    # That parameter will be removed and the interface list will be
    # created from the availible interfaces as pointed to by the
    # context signature.


    $obj_node->[MODEL] = $self->[WMODEL][NODE];
    $self->[WMODEL][NODE][REV_MODEL]{$obj_node->[ID]} = $obj_node;
    $obj_node->[FACT]     = 1; # DEPRECATED
    $obj_node->[NS]       = $obj_node->[URISTR];
    $obj_node->[CONTENT]  = $content;
    $obj_node->[READONLY] = 0;


    # The working model of the model will be the model itself.  But
    # the model of the model will be the working model of it's parent.

    # What is the model of the model?  Is it the parent model
    # ($self->[MODEL]) or itself ($model) or some default
    # (NS_LD."/model/system") or maby the interface?  Answer: Its the
    # parent model.  Commonly the Service object.
    #
    $obj->[WMODEL] = $obj;

    my $types = [ NS_LS.'#Model' ];
    my $props =
    {
	NS_LS.'#updated' => [time_string()],
    };

    # Should the WMODEL not be $obj while we are setting the type of
    # obj?
    #
    $obj->set( $types, $props );

    return $obj, 1;
}



sub init_types
{
    my( $self, $i ) = @_;

#    warn "***The model of $i is $i->[MODEL]\n";
    croak "Bad interface( $i )" unless ref $i eq "RDF::Service::Resource";

    my $success = 0;

    if( my $entry = $Schema->{$self->[NODE][URISTR]}{NS_RDF.'type'} )
    {
	$self->declare_add_types( &_obj_list($self, $i, $entry),
				  NS_LD.'#The_Base_Model', 1 );
	$success = 1;
    }
    if( my $entry = $Schema->{$self->[NODE][URISTR]}{NS_LS.'#name'} )
    {
	$self->[NODE][NAME] = $entry;
    }

    return( $success, 3);
}

sub init_rev_subjs
{
    my( $self, $i) = @_;

    my $subj_uri = $self->[NODE][URISTR];
    my $subj = $self;
    foreach my $pred_uri (keys %{$Schema->{$subj_uri}})
    {
	# Make an exception for type
	#
	next if $pred_uri eq NS_RDF.'type';
	next if $pred_uri eq NS_LS.'#name';

	my $lref = $Schema->{$subj_uri}{$pred_uri};
	defined $lref or die "\$Schema->{$subj_uri}{$pred_uri} not defined\n";
	my $pred = $self->get($pred_uri);

	# Just define the arcs.
	#
	_arcs_branch($self, $i, $subj, $pred, $lref);
    }

    return(1, 3);
}


sub init_rev_subjs_class
{
    my( $self, $i ) = @_;
    #
    # A class inherits it's super-class subClassOf properties

    debug "RDFS init_rev_subjs_class $self->[URISTR]\n", 1;


    # Since init_rev_subjs_class() depends on that all the other
    # init_rev_subjs has been called, it will call init_rev_subjs()
    # from here.  That would cause an infinite recurse unless the
    # dispatcher would remember which interface subroutines it has
    # called, by storing that in a hash in the context.  The
    # dispatcher will not call the same interface subroutine twice (in
    # deapth) with the same arguments.
    #
    # TODO: But how do we know if the cyclic dependency was a mistake
    # or not?  In some cases, we should report it as an error.  ... I
    # will waite with this until we have the function/property
    # equality.
    #
    # $self->init_rev_subjs;


    my $subClassOf = $self->get(NS_RDFS.'subClassOf');

    # Could be optimized?
    my $subj_uristr = $self->[NODE][URISTR];
    foreach my $pred_uristr ( keys %{$Schema->{$subj_uristr}} )
    {
	my $lref = $Schema->{$subj_uristr}{$pred_uristr};
	defined $lref or
	  die "\$Schema->{$subj_uristr}{$pred_uristr} not defined\n";
	my $pred = $self->get($pred_uristr);

	# This should recursively add all arcs
	_arcs_branch($self, $i, $self, $pred, $lref);

	if( $pred_uristr eq NS_RDFS.'subClassOf' )
	{
	    foreach my $superclass (
		  @{ $self->arc_obj($subClassOf)->list }
		 )
	    {
		foreach my $multisuperclass (
		      @{ $superclass->arc_obj($subClassOf)->list }
		     )
		{

		    # TODO: Place this dynamic statement in a special
		    # namespace

		    $self->declare_add_prop( $subClassOf,
					     $multisuperclass, undef,
					     undef, 1 );
		}
	    }
	}

	# TODO: Set create dependency on the subject and remove
	# dependency on each added statement and change dependency on
	# object literlas.
    }

    return( 1, 3 );
}


sub base_level
{
    my( $self, $point ) = @_;

    my $level = $Schema->{$self->[NODE][URISTR]}{NS_LS.'#level'};
    defined $level or die "No level for $self->[NODE][URISTR]\n";
    return( $level, 1);
}

sub level
{
    my( $self, $point ) = @_;

    # The level of a node is a measure of it's place in the class
    # heiarchy.  The Resouce class is level 0.  The level of a class
    # is the level of the heighest superclass plus one.  Used for
    # sorting in type_orderd_list().

    # TODO: Store the level as a property

    my $level = 0;
    foreach my $sc ( @{$self->arc_obj(NS_RDFS.'subClassOf')->list} )
    {
	my $sc_level = $sc->level;
	$level = $sc_level if $sc_level > $level;
    }
    $level++;

    return( $level, 1);
}

sub delete_node
{
    my( $self ) = @_;

    # Only deletes the part of the node associated with the WMODEL

    if( $DEBUG )
    {
	unless( ref $self eq 'RDF::Service::Context' )
	{
	    confess "Self $self not Context";
	}
    }

    my $node = $self->[NODE];
    my $wmodel = $self->[WMODEL];
    my $wmodel_id = $wmodel->[NODE][ID];


    die "Not implemented" if $node->[MULTI];

    $self->declare_del_types;
    $self->declare_del_rev_types;

    for(my $j=0; $j<= $#{$node->[REV_PRED]}; $j++)
    {
	# This model does not longer define the arc.  Remove the
	# property unless another model also defines the arc. (In
	# which case delete_node returns false.)

	my $arc_node = $node->[REV_PRED][$j];
	splice @{$node->[REV_PRED]}, $j--, 1
	  if $self->new($arc_node)->delete_node;
    }

    foreach my $subj_id ( keys %{$node->[REV_SUBJ]} )
    {
	for(my $j=0; $j<= $#{$node->[REV_SUBJ]{$subj_id}}; $j++ )
	{
	    # This model does not longer define the arc.  Remove the
	    # property unless another model also defines the arc.

	    my $arc_node = $node->[REV_SUBJ]{$subj_id}[$j];
	    splice @{$node->[REV_SUBJ]{$subj_id}}, $j--, 1
	      if $self->new($arc_node)->delete_node;
	}
	delete $node->[REV_SUBJ]{$subj_id}
	  unless @{$node->[REV_SUBJ]{$subj_id}};
    }

    foreach my $obj_id ( keys %{$node->[REV_OBJ]} )
    {
	for(my $j=0; $j<= $#{$node->[REV_OBJ]{$obj_id}}; $j++ )
	{
	    # This model does not longer define the arc.  Remove the
	    # property unless another model also defines the arc.

	    my $arc_node = $node->[REV_OBJ]{$obj_id}[$j];
	    splice @{$node->[REV_OBJ]{$obj_id}}, $j--, 1
	      if $self->new($arc_node)->delete_node;
	}
	delete $node->[REV_OBJ]{$obj_id}
	  unless @{$node->[REV_OBJ]{$obj_id}};
    }

    # Should we delete the whole node?
    #
    if( $node->[MULTI] ) # Has another model defined this node?
    {
	# TODO: Something to do here?
	debug "*** Did NOT remove $node->[URISTR]\n";
	debug "***   because of existing model\n";
	die "Not implemented";
    }
    else
    {
	$self->remove;

	# Is this a statement?
	if( $node->[PRED] )
	{
	    # Expire all dependent lists
	    $node->[PRED][REV_PRED] = undef;
	    $node->[PRED][REV_PRED_ALL] = undef;
	    $node->[SUBJ][REV_SUBJ] = undef;
	    $node->[SUBJ][REV_SUBJ_ALL] = undef;
	    $node->[OBJ][REV_OBJ] = undef;
	    $node->[OBJ][REV_OBJ_ALL] = undef;
	}

	$node->[MODEL] = undef;
	$self = undef;
    }
    return( 1, 1 );
}

sub delete_node_cascade
{
    my( $self, $i ) = @_;
    #
    # TODO:
    #  1. The agent must be authenticated
    #  2. Is the target model open?
    #  3. Does the agent owns the target model?
    #
    #  Special handling of implicit nodes
    #
    # Delete the node and all statements refering to the node.  How
    # will we handle dangling nodes, like the properties of the node
    # mainly in the form of literals?  We will not delete them if they
    # belong to another model or if they are referenced in another
    # statement (that itself is not among the statements to be
    # deleted).  But there could be references to the node from other
    # interfaces that arn't even connected in this session.
    #
    # We could collect the dangling nodes and return them to the
    # caller for decision.  This could be made to an option.

    # This version will delete from left to right.  A deleted subject
    # will delete all prperty statements and all objects. This will
    # obviously have to change!

    # Procedure:
    #  Foreach statement
    #    - call obj->delete
    #  Remove self

    foreach my $arc ( @{ $self->arc->list} )
    {
	my $obj = $arc->obj;
	$obj->delete_node_cascade();
    }

    return( $self->delete_node, 1 );
}


sub find_node
{
    my( $self, $i, $uri ) = @_;

    my $obj = $RDF::Service::Cache::node->{$self->[NODE][IDS]}{ uri2id($uri) };
    return( RDF::Service::Context->new($obj,
				       $self->[CONTEXT],
				       $self->[WMODEL]),
	    1) if $obj;
    return( undef, 0 );
}

sub init_types_service
{
    my( $self, $i ) = @_;
    #
    # We currently doesn't store the service objects in any
    # interface. The Base interface states that all URIs matching a
    # specific pattern are Service objects.

    debug "Initiating types for $self->[NODE][URISTR]\n", 1;

    my $pattern = "^".NS_LD."/service/[^/#]+\$";
    if( $self->[NODE][URISTR] =~ m/$pattern/o )
    {
	# Declare the types for the service
	#
	$self->declare_add_types([NS_LS.'#Service'], NS_LD.'#The_Base_Model', 1);

	return( 0, 3 );
    }

    return 0;
}

sub init_types_literal
{
    my( $self, $i ) = @_;

    debug "Initiating types for $self->[NODE][URISTR]\n", 1;

    my $pattern = "^".NS_LD."/literal/[^/#]+\$";
    if( $self->[NODE][URISTR] =~ m/$pattern/o )
    {
	# Declare the types for the literal
	#
	$self->declare_add_types([
	      NS_RDFS.'Literal',
	      ], $self->get_node(NS_LD.'#The_Base_Model'), 1);
	return( 0, 3 );
    }
    return 0;
}

sub desig_literal
{
    if( $_[0]->[NODE][VALUE] )
    {
	return( "'${$_[0]->[NODE][VALUE]}'", 1);
    }
    else
    {
	return( "''", 1);
#	return( desig($_[0]) );
    }
}

sub desig_statement
{
    my( $self ) = @_;

    my( $str ) = desig_resource($self);

    my $pred = $self->pred->desig;
    my $subj = $self->subj->desig;
    my $obj  = $self->obj->desig;

    $str .= ": $pred of $subj is $obj\n";
    return( $str, 1);
}

sub desig_resource
{
#    debug $_[0]->types_as_string, 1;

    # Change to make method calls
    #
    my $str = ( $_[0]->[NODE][LABEL] ||
		$_[0]->[NODE][NAME] ||
		$_[0]->[NODE][URISTR] ||
		'(anonymous resource)'
		);
#    debug "Desig of $_[0]->[NODE][URISTR] is $str\n", 1;

    return( $str, 1 );
}




# All methods with the prefix 'list_' will return a list of objects
# rather than a collection. (Model or collection of resources or
# literals.)  But teh method will still return a ref to the list to
# the Dispatcher.

sub value
{
    my( $self ) = @_;
    $self->[NODE][REV_SUBJ_ALL] or $self->init_rev_subjs;
    $self->[NODE][REV_SUBJ_ALL] ||= 1;

#    warn "**** ".($self->types_as_string)."****\n";
    if( not defined $_[0]->[NODE][VALUE] )
    {
	die "$self->[NODE][URISTR] has no defined value\n";
    }

    # TODO: Should return 2
    return( ${$_[0]->[NODE][VALUE]}, 1);
}


sub pred
{
    # TODO. Should return 2;
    return( $_[0]->new($_[0]->[NODE][PRED]), 1);
}

sub subj
{
    # TODO. Should return 2;
    return( $_[0]->new($_[0]->[NODE][SUBJ]), 1);
}

sub obj
{
    # TODO. Should return 2;
    return( $_[0]->new($_[0]->[NODE][OBJ]), 1);
}

sub _export_to_ids
{
    my( $self, $i, $node, $new_ids ) = @_;

    debug_start( "_export_to_ids", ' ', $self );

#    warn "BBB1 Start by exporting $node->[URISTR]\n";

    _export_to_ids_node( $self, $i, $node, $new_ids );
#    warn "BBB2\n";

    foreach my $id ( keys %{$node->[REV_MODEL]} )
    {
#    warn "BBB3\n";
	my $sub = $self->get_context_by_id($id);
	if( $sub->is_known_as_a( NS_LS.'#Model' ) )
	{
#    warn "BBB4\n";
	    next if $sub->[NODE][ID] == $node->[ID];
	    debug "Is a model ($sub->[NODE][URISTR]), ".
	      "checking it's content\n", 2;
	    _export_to_ids( $self, $i, $sub->[NODE], $new_ids );
	}
	else
	{
#    warn "BBB5\n";
	    next if $sub->[NODE][SOLID];
	    _export_to_ids_node( $self, $i, $sub->[NODE], $new_ids );
	}
    }
 #   warn "BBB6\n";

    # Transferens done. Empty list:
    #
    my $m = $self->[MEMORY]{$i->[ID]} ||= {};
    $m->{'transfered'} = undef;

    debug_end( "_export_to_ids", ' ', $self );
}

sub _export_to_ids_node
{
    my( $self, $i, $subnode, $new_ids ) = @_;

    unless( $i->[ID] )
    {
	confess "Invalid interface ( $i )";
    }

    # Remember which nodes we have transfered
    #
    my $m = $self->[MEMORY]{$i->[ID]} ||= {};
    return if $m->{'transfered'}{$subnode->[ID]};
    $m->{'transfered'}{$subnode->[ID]} ++;



    debug_start("_export_to_ids_node", ' ', $self );
    debug "  Exporting $subnode->[URISTR] $subnode->[ID] ".
      "(IDS $subnode->[IDS])\n", 3;

    if( $DEBUG )
    {
	my $donelist = [sort keys %{$m->{'transfered'}}];
	debug "MEMORY @$donelist\n";
    }


    my $cache = $RDF::Service::Cache::node->{$new_ids};

    my $new_node = $self->get_node_by_id($subnode->[ID], $new_ids);

    # The $new_node has responsability now
    #
    debug "Changing SOLID to 1 for $subnode->[URISTR] ".
      "IDS $subnode->[IDS]\n", 3;
    $subnode->[SOLID] = 1;

    my $model_id = $self->[WMODEL][NODE][ID];
#    warn "AAA1\n";

    $new_node->[IDS] = $new_ids;
    $new_node->[NAME] = $subnode->[NAME];
    $new_node->[LABEL] = $subnode->[LABEL];
    $new_node->[MEMBER] = $subnode->[MEMBER];
    $new_node->[MULTI] = $subnode->[MULTI];
    $new_node->[VALUE] = $subnode->[VALUE];
    $new_node->[LANG] = $subnode->[LANG];

    # TODO: Transfer CONTENT (och READONLY)
    # TODO: Transfer PREFIX, MODULE_NAME, MODULE_REG and INTERFACES



    # Get the model from the new IDS
    if( $subnode->[MODEL] )
    {
	_export_to_ids_node( $self, $i, $subnode->[MODEL], $new_ids );
	my $subnode_model =
	  $self->get_node_by_id( $subnode->[MODEL][ID], $new_ids );
	debug "subnode_model  $subnode_model->[URISTR] ".
	  "IDS  $subnode_model->[IDS]\n", 3;
	$new_node->[MODEL] = $subnode_model;
	$new_node->[MODEL][REV_MODEL]{$new_node->[ID]} = $new_node;
    }

#	$new_node->[ALIASFOR] = $subnode->[ALIASFOR];

	my $new = RDF::Service::Context->new($new_node,
					     $self->[CONTEXT],
					     $self->[WMODEL]);


#    warn "AAA2\n";

	foreach my $type_id ( keys %{$subnode->[TYPE]} )
	{
	    my $old_type_node = $self->get_node_by_id( $type_id );
	    debug "  TYPE $old_type_node->[URISTR] IDS $new_ids\n", 4;
	    debug "    Checking...\n", 4;

	    next unless $subnode->[TYPE]{$type_id};
	    if( $DEBUG >= 4 )
	    {
		next unless $subnode->[TYPE]{$type_id}{$model_id};
		debug "    Solidity is ".
		  $subnode->[TYPE]{$type_id}{$model_id} ."\n", 2;
	    }

	    # Only transfer types belonging to the working model, that
	    # are marked as NONSOLID (==1)
	    #
	    unless( $subnode->[TYPE]{$type_id}{$model_id} and
		      $subnode->[TYPE]{$type_id}{$model_id} == 1 )
	    {
		next;
	    }

	    _export_to_ids_node( $self, $i, $old_type_node, $new_ids );
	    my $type_node = $new->get_node_by_id( $type_id, $new_ids );

	    debug "    Transfering!\n", 4;

	    $subnode->[TYPE]{$type_id}{$model_id} = 2;
	    $new_node->[TYPE]{$type_id}{$model_id} = 1;

	    $type_node->[REV_TYPE]{$new_node->[ID]}{$model_id} = 1;

	    if( $DEBUG )
	    {
		my $model_uri = id2uri( $model_id );
		debug "Setting $type_node->[URISTR] ".
		  "(IDS $type_node->[IDS]) ".
		    "REV_TYPE $new_node->[URISTR] ".
		      "(IDS $new_node->[IDS]) ".
			"in model $model_uri\n";
	    }
	}

	# NB: REV_TYPE is ignored

#    warn "AAA3\n";

	foreach my $arc_node ( @{$subnode->[REV_PRED]} )
	{
	    next unless $arc_node->[MODEL];
	    next unless $arc_node->[MODEL][ID] == $model_id;
	    next if $arc_node->[SOLID];
	    debug "  REV_PRED $arc_node->[URISTR]\n", 2;
	    _export_to_ids_node( $self, $i, $arc_node, $new_ids );
	    my $new_arc_node =
	      $self->get_node_by_id( $arc_node->[ID], $new_ids );
	    push @{$new_node->[REV_PRED]}, $new_arc_node;
	}

#    warn "AAA4\n";

	foreach my $pred_id ( keys %{$subnode->[REV_SUBJ]} )
	{
	    $new_node->[REV_SUBJ]{$pred_id} = [];
	    foreach my $arc_node ( @{$subnode->[REV_SUBJ]{$pred_id}} )
	    {
		next unless $arc_node->[MODEL];
		next unless $arc_node->[MODEL][ID] == $model_id;
		next if $arc_node->[SOLID];
		debug "  REV_SUBJ $arc_node->[URISTR]\n", 2;
		_export_to_ids_node( $self, $i, $arc_node, $new_ids );
		my $new_arc_node =
		  $self->get_node_by_id( $arc_node->[ID], $new_ids );
 		push @{$new_node->[REV_SUBJ]{$pred_id}}, $new_arc_node;
	    }
	    delete $new_node->[REV_SUBJ]{$pred_id} unless
	      @{$new_node->[REV_SUBJ]{$pred_id}};
	}

#    warn "AAA5\n";

	foreach my $pred_id ( keys %{$subnode->[REV_OBJ]} )
	{
	    $new_node->[REV_OBJ]{$pred_id} = [];
	    foreach my $arc_node ( @{$subnode->[REV_OBJ]{$pred_id}} )
	    {
		next unless $arc_node->[MODEL];
		next unless $arc_node->[MODEL][ID] == $model_id;
		next if $arc_node->[SOLID];
		debug "  REV_OBJ $arc_node->[URISTR]\n", 2;
		_export_to_ids_node( $self, $i, $arc_node, $new_ids );
		my $new_arc_node =
		  $self->get_node_by_id( $arc_node->[ID], $new_ids );
		push @{$new_node->[REV_OBJ]{$pred_id}}, $new_arc_node;
	    }
	    delete $new_node->[REV_OBJ]{$pred_id} unless
	      @{$new_node->[REV_OBJ]{$pred_id}};
	}

#    warn "AAA6\n";

	if( $subnode->[PRED] )
	{
	    debug "  PRED/SUBJ/OBJ\n", 2;


	    _export_to_ids_node( $self, $i, $subnode->[PRED], $new_ids );
	    my $new_pred_node =
	      $self->get_node_by_id($subnode->[PRED][ID], $new_ids);
	    push @{$new_pred_node->[REV_PRED]}, $new_node;
	    $new_node->[PRED] = $new_pred_node;

	    my $pred_id =  $new_node->[PRED][ID];

	    _export_to_ids_node( $self, $i, $subnode->[SUBJ], $new_ids );
	    my $new_subj_node =
	      $self->get_node_by_id($subnode->[SUBJ][ID], $new_ids);
	    push @{$new_subj_node->[REV_SUBJ]{$pred_id}}, $new_node;
	    $new_node->[SUBJ] = $new_subj_node;

	    _export_to_ids_node( $self, $i, $subnode->[OBJ], $new_ids );
	    my $new_obj_node =
	      $self->get_node_by_id($subnode->[OBJ][ID], $new_ids);
	    push @{$new_obj_node->[REV_OBJ]{$pred_id}}, $new_node;
	    $new_node->[OBJ] = $new_obj_node;
	}


#    warn "AAA7\n";

	$cache->{$new_node->[ID]} = $new_node;

    debug_end( "_export_to_ids_node", ' ', $self );
}

sub _construct_interface_uri
{
    my( $module, $args ) = @_;

    # Generate the URI of interface object. This will have to
    # change. The URI should be known or availible by request. Not
    # guessed.  Make a clear distinction between the interface module
    # resource and the interface resource returned from a connection.
    #
    my $uri = URI->new("http://cpan.org/rdf/module/"
		       . join('/',split /::/, $module));

    if( ref $args eq 'HASH' )
    {
	my @query = ();
	foreach my $key ( sort keys %$args )
	{
	    next if $key eq 'passwd';
	    push @query, $key, $args->{$key};
	}
	$uri->query_form(@query);
    }
    return $uri->as_string;
}


sub _obj_list
{
    my( $self, $i, $ref ) = @_;
    my @objs = ();

    if( ref $ref eq 'SCALAR' )
    {
	push @objs, $self->get($$ref);
    }
    elsif( ref $ref eq 'ARRAY' )
    {
	foreach my $obj ( @$ref )
	{
	    push @objs, _obj_list( $self, $i, $obj );
	}
    }
    else
    {
	push @objs, $self->declare_literal($i, undef, $ref);
    }

    return \@objs;
}

sub _arcs_branch
{
    my( $self, $i, $subj, $pred, $lref ) = @_;

    my $arcs = [];
    my $obj;
    if( ref $lref and ref $lref eq 'SCALAR' )
    {
	my $obj_uri = $$lref;
	$obj = $self->get($obj_uri);
    }
    elsif( ref $lref and ref $lref eq 'HASH' )
    {
	# Anonymous resource
	# (Sublevels is not returned)

	die "Anonymous resources not supported";
#	$obj = RDF::Service::Resource->new($ids, undef);
    }
    elsif(  ref $lref and ref $lref eq 'ARRAY' )
    {
	foreach my $item ( @$lref )
	{
	    _arcs_branch($self, $i, $subj, $pred, $item);
	}
	return 1;
    }
    else
    {
	confess("_arcs_branch called with undef obj: ".Dumper(\@_))
	    unless defined $lref;

	# TODO: The model of the statement should be NS_RDFS or NS_RDF
	# or NS_LS, rather than $i
	#
	debug "_arcs_branch adds literal $lref\n", 1;
	$obj = $self->declare_literal( \$lref );
    }

    # TODO: Handle LABEL (and name)

    unless( $pred->[NODE][URISTR] eq NS_RDF.'type' or
	  $pred->[NODE][URISTR] eq NS_LS.'#name' )
    {
	debug "_arcs_branch adds arc $pred->[NODE][URISTR]( ".
	  "$subj->[NODE][URISTR], # $obj->[NODE][URISTR])\n", 3;
	$self->declare_arc( $pred, $subj, $obj, undef,
			    undef, 1 );
    }
    return 1;
}


1;
