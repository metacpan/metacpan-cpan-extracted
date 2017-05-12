#  $Id: Context.pm,v 1.18 2000/12/21 22:04:18 aigan Exp $  -*-perl-*-

package RDF::Service::Context;

#=====================================================================
#
# DESCRIPTION
#   All resources exists in a context. This is the context.
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
use vars qw( $AUTOLOAD );
use RDF::Service::Dispatcher qw( go );
use RDF::Service::Constants qw( :all );
use RDF::Service::Cache qw( interfaces uri2id list_prefixes
			    get_unique_id id2uri debug
			    debug_start debug_end
			    $DEBUG expire time_string $Level
			    validate_context );
use Data::Dumper;
use Carp qw( confess cluck croak);

sub new
{
    my( $proto, $node, $context, $wmodel ) = @_;

    # This constructor shouls only be called from get_node, which
    # could be called from find_node or create_node.

    my $class = ref($proto) || $proto;
    my $self = bless [], $class;

    my $history = [];

    if( ref($proto) )
    {
	$context ||= $proto->[CONTEXT];
	$node    ||= $proto->[NODE]; # The same node in another context?
	$wmodel  ||= $proto->[WMODEL];

	$history = $proto->[HISTORY];
    }

    unless( ref($history) eq 'ARRAY' )
    {
	confess "HOLY SHIT!!!";
    }

    # TODO: Maby perform a deep copy of the context.  At least copy
    # each key-value pair.

    $self->[NODE]    = $node or die;
    $self->[CONTEXT] = $context or die "No context supplied";
    $self->[WMODEL]  = $wmodel 
      or confess "No WMODEL supplied by $proto\n" if $node->[RUNLEVEL];
    $self->[MEMORY]  = {};
    $self->[HISTORY] = $history;
    return $self;
}


sub AUTOLOAD
{
    # The substr depends on the package length
    #
    $AUTOLOAD = substr($AUTOLOAD, 23);
    return if $AUTOLOAD eq 'DESTROY';
    debug "AUTOLOAD $AUTOLOAD\n", 2;

    &RDF::Service::Dispatcher::go(shift, $AUTOLOAD, @_);
}


sub name
{
    my( $self ) = @_;
    return $self->[NODE][NAME]; # not guaranteed to be defined
}

sub uri
{
    # This is always defined
    $_[0]->[NODE][URISTR];
}

sub model
{
    my( $self ) = @_;
    die "not implemented" if $_[0]->[NODE][MULTI];

    my $model_res = $_[0]->new( $_[0]->[NODE][MODEL] );

    if( $DEBUG )
    {
	unless( $model_res->is_a( NS_LS.'#Model' ) )
	{
	    die "The model is not a model";
	}
    }

    return $model_res;

    # TODO: Should return a selection of models
}


sub get
{
    $_[1] ||= NS_LD."#".&get_unique_id;
    return get_context_by_id( $_[0], uri2id($_[1]), $_[2] );
}

sub get_context_by_id
{
    my( $self, $id , $ids) = @_;

    # TODO: First look for the object in the cache

    my $node = $self->[NODE];
    $ids ||= $node->[IDS];
    if( $DEBUG )
    {
	confess "IDS undefined" unless defined $ids;
	unless( ref $RDF::Service::Cache::node->{$ids} )
	{
	    $node->[RUNLEVEL] and
	      confess "IDS $ids not initialized\n";
	}

	confess "id not defined" unless $id;
    }

    my $obj = $RDF::Service::Cache::node->{$ids}{ $id };

    unless( $obj )
    {
	# Create an uninitialized object. Any request for the objects
	# properties will initialize the object with the interfaces.

	$obj = $node->new_by_id($id);

	$RDF::Service::Cache::node->{$ids}{ $id } = $obj;
    }


    if( $DEBUG )
    {
	unless( $self->[WMODEL] or
		  $obj->[URISTR] eq NS_LD.'#The_Base_Model' )
	{
	    confess "No WMODEL found for $node->[URISTR] ";
	}

	unless( ref $obj eq "RDF::Service::Resource" )
	{
	    my $uri = id2uri( $id );
	    confess "Cached $uri ($id) corrupt";
	}
    }

    return $self->new( $obj );
}


sub get_node
{
    $_[1] ||= NS_LD."#".&get_unique_id;
    return get_node_by_id( $_[0], uri2id($_[1]), $_[2] );
}

sub get_node_by_id
{
    my( $self, $id, $ids ) = @_;

    $ids ||= $self->[NODE][IDS];
    my $obj = $RDF::Service::Cache::node->{$ids}{ $id };

    unless( $obj )
    {
	# Create an uninitialized object. Any request for the objects
	# properties will initialize the object with the interfaces.

	$obj = $self->[NODE]->new(undef, $id, $ids);

	$RDF::Service::Cache::node->{$ids}{ $id } = $obj;
    }

    if( $DEBUG )
    {
	unless( $self->[WMODEL] or
		  $obj->[URISTR] eq NS_LD.'#The_Base_Model' )
	{
	    confess "No WMODEL found for $self->[NODE][URISTR] ";
	}

	unless( ref $obj eq "RDF::Service::Resource" )
	{
	    my $uri = id2uri( $id );
	    confess "Cached $uri ($id) corrupt";
	}
    }

    return $obj;
}


sub get_model
{
    my( $self, $uri ) = @_;

    debug_start("get_model", ' ', $self);

    die "No uri specified" unless $uri;
    debug "  ( $uri )\n", 2;

    my $obj = $self->find_node( $uri );
    if( $obj )
    {
	debug "Model existing: $uri\n", 1;
	# Is this a model?
	unless( $obj->is_a(NS_LS.'#Model') )
	{
	    die "$obj->[NODE][URISTR] is not a model\n".
	      $obj->types_as_string;
	}
	# setting WMODEL
	$obj->[WMODEL] = $obj;
    }
    else
    {
	debug "Model not existing. Creating it: $uri\n", 1;
	# create_model sets WMODEL
	$obj = $self->create_model( $uri );
    }

    debug_end("get_model", ' ', $self);
    return $obj;
}

sub is_a
{
    my( $self, $class ) = @_;

    $self->[NODE][TYPE_ALL] or $self->init_types;
    $self->[NODE][TYPE_ALL] ||= 1;
    return $self->is_known_as_a( $class );
}

sub could_be_a
{
    my( $self, $class ) = @_;

    return 1 unless $self->[NODE][TYPE_ALL];
    return $self->is_known_as_a( $class );
}

sub is_known_as_a
{
    my( $self, $class ) = @_;

    $class = $self->get( $class ) unless ref $class;

    if( defined $self->[NODE][TYPE]{$class->[NODE][ID]} )
    {
	return 1;
    }
    else
    {
	return 0;
    }
}

sub exist_pred
{
    my( $self, $pred ) = @_;

    my $pred_id;
    if( ref $pred )
    {
	$pred_id = $pred->[NODE][ID];
    }
    else
    {
	$pred_id = uri2id( $pred );
    }

    if( $self->[NODE][REV_SUBJ]{$pred_id} )
    {
	return 1;
    }
    else
    {
	return 0;
    }
}

sub type_orderd_list
{
    my( $self, $i, $point ) = @_;

    # TODO:  This should (as all the other methods) be cached and
    # dpendencies registred.

    die "Not implemented" if $point;
    my $node = $self->[NODE];


    # We can't call level() for the resources used to define level()
    #
    if( $node->[URISTR] =~ /^(@{[NS_RDF]}|@{[NS_RDFS]}|@{[NS_LS]})/o )
    {
	my $type_uri_ref = $Schema->{$self->[NODE][URISTR]}{NS_RDF.'type'};

	return( [$self->get( $$type_uri_ref ),
		 $self->get(NS_RDFS.'Resource')] );
    }

    debug_start("type_orderd_list", ' ', $self);


#  Do we have to have all types to list the *present* defined types?
#    $node->[TYPE_ALL] or $self->init_types;

    my @types = ();
    my %included; # Keep track of included types
    foreach my $type ( sort { $b->level <=> $a->level }
			 map $self->get_context_by_id($_),
		       keys %{$node->[TYPE]}
		      )
    {
	# Check that at least one model defines the type.  Can we
	# assume that the existence of the type (in the hash tree)
	# implies the existence of at least one model (in the hash
	# treee) and that the existence of a model implies that that
	# model has the value 1, meaning that the model states the
	# type?  Yes. Assume that.

	push @types, $type unless $included{$type->[NODE][ID]};
	$included{$type->[NODE][ID]}++;
    }

    debug_end("type_orderd_list", ' ', $self);
    return( \@types );
}



# The alternative selectors:
#
#   arc               subj arcs
#   arc_obj           subj arcs objs
#   arc_obj_list      subj arcs objs list
#   select_arc        container subj arcs
#   select_arc_obj    container subj arcs objs
#   type              subj types
#   select_type       container subj types
#   rev_arc           obj arcs
#   arc_subj          obj arcs subjs
#   select_rev_arc    container obj arcs
#   select_arc_subj   container obj arcs subjs
#   rev_type          type objs
#   select_rev_type   container types objs
#   li                container res
#   rev_li            res container
#   select            container res
#   rev_select        res container

sub type
{
    my( $self, $point ) = @_;

    die "Not implemented" if $point;

    debug_start("type", ' ', $self);

    $self->[NODE][TYPE_ALL] or $self->init_types;

    # TODO: Insert the query in the selection, rather than the query
    # result

    my $selection = $self->declare_selection( $self->type_orderd_list );

    debug_end("rev_type", ' ', $self);
    return( $selection );
}


sub rev_type
{
    my( $self, $point ) = @_;

    die "Not implemented" if $point;

    debug_start("rev_type", ' ', $self);

    $self->[NODE][REV_TYPE_ALL] or $self->init_rev_types;

    # TODO: Insert the query in the selection, rather than the query
    # result

    my %subjs = ();
    foreach my $subj_id ( keys %{$self->[NODE][REV_TYPE]} )
    {
	# This includes types from all models
	foreach my $model_id ( keys %{$self->[NODE][REV_TYPE]{$subj_id}})
	{
	    if( $self->[NODE][REV_TYPE]{$subj_id}{$model_id} )
	    {
		$subjs{$subj_id} = $self->get_context_by_id( $subj_id );
	    }
	}
    }

    my $selection = $self->declare_selection( [values %subjs] );

    debug_end("rev_type", ' ', $self);
    return( $selection );
}


sub arc
{
    my( $self, $point ) = @_;

    debug_start( "arc", ' ', $self );

    unless( ref $point )
    {
	unless( defined $point )
	{
	    # TODO: allow partially initialized props

	    $self->[NODE][REV_SUBJ_ALL] or $self->init_rev_subjs;

	    # TODO: Insert the query in the selection, rather than the
	    # query result
	    #
	    my $arcs = [];
	    foreach my $pred_id ( keys %{$self->[NODE][REV_SUBJ]} )
	    {
		foreach my $arc_node ( @{$self->[NODE][REV_SUBJ]{$pred_id}} )
		{
		    push @$arcs, $self->new($arc_node);
		}
	    }
	    my $selection = $self->declare_selection( $arcs );

	    debug_end("arc", ' ', $self);
	    return $selection;
	}
	$point = $self->get( $point );
    }

    # Take action depending on $point
    #
    if( ref $point eq 'RDF::Service::Context' ) # property
    {
	unless( $self->[NODE][REV_SUBJ]{$point->[NODE][ID]} or
		  $self->[NODE][REV_SUBJ_ALL] )
	{
	    $self->init_rev_subjs( $point );
	}


	# TODO: Insert the query in the selection, rather than the
	# query result
	#
	my $arcs = [];
	foreach my $arc_node (
	      @{$self->[NODE][REV_SUBJ]{$point->[NODE][ID]}}
	     )
	{
	    push @$arcs, $self->new( $arc_node );
	}
	my $selection = $self->declare_selection( $arcs );

	debug_end("arc", ' ', $self);
	return $selection;
    }
    else
    {
	die "not implemented";
    }
}

sub arc_subj
{
    my( $self, $point ) = @_;

    # Default $point to be a property resource
    #
    unless( ref $point )
    {
	unless( defined $point )
	{
	    die "Not implemented";
	}
	$point = $self->get( $point );
    }

    debug_start( "arc_subj", ' ', $self );
    debug "   ( $point->[NODE][URISTR] )\n", 1;

    # Take action depending on $point
    #
    if( ref $point eq 'RDF::Service::Context' ) # property
    {
	$self->init_rev_objs( $point ) unless defined
	  $self->[NODE][REV_OBJ]{$point->[NODE][ID]};

	# TODO: Insert the query in the selection, rather than the
	# query result
	#
	my $subjs = [];
	foreach my $arc_node (
	      @{$self->[NODE][REV_OBJ]{$point->[NODE][ID]}}
	     )
	{
	    push @$subjs, $self->new( $arc_node )->subj;
	}
	my $selection = $self->declare_selection( $subjs );

	debug_end("arc_subj", ' ', $self);
	return $selection;
    }
    else
    {
	die "not implemented";
    }
    die "What???";
}

sub arc_pred
{
    my( $self, $point ) = @_;

    debug_start( "arc_pred", ' ', $self );

    if( not defined $point )
    {
	$self->[NODE][REV_SUBJ_ALL] or $self->init_rev_subjs;

	# TODO: Insert the query in the selection, rather than the
	# query result
	#
	my $preds = [];
	foreach my $pred_id ( keys %{$self->[NODE][REV_SUBJ]} )
	{
	    push @$preds, $self->get_context_by_id($pred_id);
	}
	my $selection = $self->declare_selection( $preds );

	debug_end("arc_pred", ' ', $self);
	return $selection;
    }
    else
    {
	die "not implemented";
    }
    die "What???";
}

sub arc_obj
{
    my( $self, $point ) = @_;

    # Default $point to be a property resource
    #
    unless( ref $point )
    {
	unless( defined $point )
	{
	    warn "*** Failed\n";
	    warn "*** Called $self->[NODE][URISTR] with ( $point )\n";
	    croak "arc_obj ( $self->[NODE][URISTR] ) without point not implemented";
	}
	$point = $self->get( $point );
    }

    debug_start( "arc_obj", ' ', $self );
    debug "   ( $point->[NODE][URISTR] )\n", 1;

    # Take action depending on $point
    #
    if( ref $point eq 'RDF::Service::Context' ) # property
    {
	unless( $self->[NODE][REV_SUBJ]{$point->[NODE][ID]} or
		  $self->[NODE][REV_SUBJ_ALL] )
	{
	    $self->init_rev_subjs( $point );
	}

	unless( defined $self->[NODE][REV_SUBJ]{$point->[NODE][ID]} )
	{
	    debug_end("arc_obj", ' ', $self);
	    return $self->declare_selection( [] );
	}

	# TODO: Insert the query in the selection, rather than the
	# query result
	#
	my $objs = [];
	foreach my $arc_node (
	      @{$self->[NODE][REV_SUBJ]{$point->[NODE][ID]}}
	     )
	{
	    push @$objs, $self->new( $arc_node )->obj;
	}
	my $selection = $self->declare_selection( $objs );

	debug_end("arc_obj", ' ', $self);
	return $selection;
    }
    else
    {
	die "not implemented";
    }
    die "What???";
}

sub arc_obj_list
{
    my( $self, $point ) = @_;

    # Default $point to be a property resource
    #
    unless( ref $point )
    {
	unless( defined $point )
	{
	    die "Not implemented";
	}
	$point = $self->get( $point );
    }

    debug_start( "arc_obj_list", ' ', $self );
    debug "   ( $point->[NODE][URISTR] )\n", 1;

    # Take action depending on $point
    #
    if( ref $point eq 'RDF::Service::Context' ) # property
    {
	unless( $self->[NODE][REV_SUBJ]{$point->[NODE][ID]} or
		  $self->[NODE][REV_SUBJ_ALL] )
	{
	    $self->init_rev_subjs( $point );
	}

	unless( defined $self->[NODE][REV_SUBJ]{$point->[NODE][ID]} )
	{
	    debug_end("arc_obj_list", ' ', $self);
	    return [];
	}

	# TODO: Insert the query in the selection, rather than the
	# query result
	#
	my $objs = [];
	foreach my $arc_node (
	      @{$self->[NODE][REV_SUBJ]{$point->[NODE][ID]}}
	     )
	{
	    push @$objs, $self->new( $arc_node )->obj;
	}

	debug_end("arc_obj_list", ' ', $self);
	return $objs;
    }
    else
    {
	die "not implemented";
    }
    die "What???";
}

sub selector
{
    die "not imlemented";

    my $point;
    if( not defined $point ) # Return all arcs
    {
    }
    elsif( ref $point eq 'ARRAY' ) # Return ORed elements
    {
    }
    elsif( ref $point eq 'HASH' ) # Return ANDed elements
    {
    }
    elsif( ref $point eq 'RDF::Service::Context' )
    {
    }
    else
    {
	die "Malformed entry";
    }
}


sub set
{
    my( $self, $types, $props ) = @_;

    # This is practicaly the same as declare_self.  set() updates the
    # data in the interfaces.

    debug_start("set", ' ', $self);

    # Should each type and property only be saved in the first best
    # interface and not saved in the following interfaces?  Yes!
    #
    # The types and props taken by one interface must be marked so
    # that the next interface doesn't handle them. This could be done
    # by modifying the arguments $types and $props to exclude those
    # that has been taken care of.

    $self->set_types( $types, 1);
    $self->set_props( $props, 1);

    debug_end("set", ' ', $self);
    return $self;
}

sub set_types
{
    my( $self, $types, $trim, $local_changes ) = @_;
    #
    # Remove existing types not mentioned if $trim

    debug_start("set_types", ' ', $self);

    my $node = $self->[NODE];
    my $model = $self->[WMODEL][NODE];

    if( $DEBUG )
    {
	ref $model eq "RDF::Service::Resource" or
	  confess "Bad model ($model)";

    }

    $node->[TYPE_ALL] or $self->init_types;
    my $type_all = $node->[TYPE_ALL];    # Remember the state
    $node->[TYPE_ALL] = 0;


    my @add_types;
    my %del_types;
    foreach my $type ( @{$self->type_orderd_list} )
    {
	if( $node->[TYPE]{$type->[NODE][ID]}{$model->[ID]} )
	{
	    $del_types{$type->[NODE][ID]} = $type;
	}
    }

    foreach my $type ( @$types )
    {
	$type = $self->get( $type ) unless ref $type;
	if ( $del_types{ $type->[NODE][ID] } )
	{
	    delete $del_types{ $type->[NODE][ID] };
	}
	else
	{
	    push @add_types, $type;
	}
    }

    if ( @add_types )
    {
	# Will only add each type in one interface
	$self->declare_add_types( [@add_types] );
	unless( $local_changes )
	{
	    $self->store_types;
	}
    }

    if ( $trim and %del_types )
    {
	# Will delete types from all interfaces
	$self->declare_del_types( [values %del_types] );
	$self->remove_types( [values %del_types] ) unless $local_changes;
    }

    $self->[NODE][TYPE_ALL] = $type_all;

    debug_end("set_types", ' ', $self);
    return $self;
}

sub set_props
{
    my( $self, $props, $trim, $local_changes ) = @_;
    #
    # Remove existing props not mentioned if $trim.  Add props not yet
    # existing.  Only operate within WMODEL.
    #
    # $props->{$pred_uri => [ $obj ] }

    debug_start("set_props", ' ', $self);

    my $node = $self->[NODE];
    my $model = $self->[WMODEL][NODE];


    $node->[REV_SUBJ_ALL] or $self->init_rev_subjs;

    my %add_props; # $add_props->{$pred_id}[$obj]
    my %del_props; # $del_props->{$pred_id}{$obj_id => $arc}

    # This will hold present properties in the model
    # that does not exist in the new set of
    # properties.  Start by adding all present properties and remove
    # the ones that exist in the new property list.

    foreach my $arc ( @{$self->arc->list} )
    {
	# TODO: Verify that 'eq' suffice for equality test. NOT GOOD!!
	if( $arc->[NODE][MODEL][ID] == $model->[ID] )
	{
	    $del_props{$arc->[NODE][PRED][ID]}{$arc->[NODE][OBJ][ID]} = $arc;
	}
    }

    # Foreach pred and obj
    foreach my $pred_uri ( keys %$props )
    {
	foreach my $obj ( @{ $props->{$pred_uri} } )
	{
	    if( $DEBUG )
	    {
		if( ref $obj and $obj->[NODE][VALUE] )
		{
		    unless( ref($obj->[NODE][VALUE]) eq 'SCALAR')
		    {
			confess "Bad value for $obj->[NODE][URISTR] ( ".
			  ref($obj->[NODE][VALUE])." ne 'SCALAR' )";
		    }
		}
	    }

	    # Is the object a literal?
	    if( not ref $obj )
	    {
		debug "  Creating literal '$obj'\n", 1;

		# Warning. Previouslu wrote this as \$obj.  It took me
		# over a day to find this and realize that the
		# reasigning of $obj would overwrite the created
		# literal value, creating a self-reference
		#
		$obj = $self->create_literal(undef, \ "$obj");

	    }


	    # Does this resource already have the arc?
	    my $pred_id = &uri2id($pred_uri);
	    if( $del_props{$pred_id}{$obj->[NODE][ID]} )
	    {
		delete $del_props{$pred_id}{$obj->[NODE][ID]};
	    }
	    else
	    {
		push @{$add_props{$pred_id}}, $obj;
	    }
	}
    }

    if( %del_props )
    {
	# Will delete props from all interfaces
	foreach my $pred_id ( keys %del_props )
	{
	    if( $DEBUG )
	    {
		my $pred_uri = &id2uri($pred_id);
		debug "Del checking $pred_uri\n", 1;
	    }

	    # Remove the pred objs if other pred objs was specified,
	    # or if $trim is set, in case we remove everything not
	    # specified
	    #
	    next unless $trim or $add_props{$pred_id};

	    foreach my $obj_id ( keys %{ $del_props{$pred_id} } )
	    {
		die "not implemented" if $local_changes;
		$del_props{$pred_id}{$obj_id}->delete_node();
	    }
	}
    }

    if( %add_props )
    {
	# Will only add each prop in one interface
	foreach my $pred_id ( keys %add_props )
	{
	    foreach my $obj ( @{ $add_props{$pred_id} } )
	    {
		$self->declare_add_prop( &id2uri($pred_id), $obj );
	    }
	}
	unless( $local_changes or ($self->[NODE][REV_SUBJ_ALL] and 
				     $self->[NODE][REV_SUBJ_ALL] == 2) )
	{
	    $self->store_props;
	}
    }

    debug_end("set_props", ' ', $self);
    return $self;
}

sub create_literal
{
    my( $self, $uristr, $lit_str_ref ) = @_;

    debug_start("create_literal", ' ', $self);
    debug "   Creating ($$lit_str_ref)\n", 1;

    if( $uristr )
    {
	# NOTE: Copied from create_model

	# This should validate the uri.  If this interface can't
	# create the URI, it will either return "try next interface"
	# or "failed", depending on why.

	# For now: Just allow models in the local namespace
	unless( $uristr =~ /@{[NS_LD]}/o )
	{
	    die "Invalid namespace for literal";
	}
    }

    my $literal = $self->declare_literal( $lit_str_ref, $uristr );
    $literal->store_node;

    if( $DEBUG )
    {
	if( $literal->[NODE][VALUE] )
	{
	    debug "Checking literal value\n";
	    unless( ref($literal->[NODE][VALUE]) eq 'SCALAR')
	    {
		confess "Bad value for $literal->[NODE][URISTR] ( ".
		  ref($literal->[NODE][VALUE])." ne 'SCALAR' )";
	    }
	    else
	    {
#		warn Dumper $literal->[NODE][VALUE];
	    }
	}
    }


    debug_end("create_literal", ' ', $self);

    # Return the literal object
    #
    return( $literal );
}

sub set_literal
{
    my( $self, $lit_str_ref ) = @_;

    debug_start("set_literal", ' ', $self);
    debug "   Change to ($$lit_str_ref)\n", 1;

    # TODO: make sure you have the right to update this literal!

    $self->declare_literal( $lit_str_ref, $self,  );
    $self->store_node;

    debug_end("set_literal", ' ', $self);
}


sub types_as_string
{
    my( $self ) = @_;
    #
#   die $self->uri."--::".Dumper($self->[TYPES]);
    my $result = "";
    my $type_ref = $self->[NODE][TYPE];
    foreach my $type_id ( sort keys %{$type_ref} )
    {
	my $type_uristr = id2uri( $type_id );
	$result .= "t $type_uristr\n";
	foreach my $model_id ( sort keys
				 %{$type_ref->{$type_id}} )
	{
	    my $model_uristr = id2uri( $model_id );
	    my $solid = $type_ref->{$type_id}{$model_id} - 1;
	    $result .= "  m $model_uristr  SOLID $solid\n";
	}

    }

    return $result;
}


sub to_string
{
    my( $self ) = @_;

    # Old!

    my $str = "";
    no strict 'refs';

    $str.="TYPES\t: ". $self->types_as_string ."\n";

    foreach my $attrib (qw( IDS URISTR ID NAME LABEL VALUE FACT PREFIX MODULE_NAME ))
    {
	$self->[NODE][&{$attrib}] and $str.="$attrib\t:".
	    $self->[NODE][&{$attrib}] ."\n";
    }

    foreach my $attrib (qw( NS MODEL ALIASFOR LANG PRED SUBJ OBJ ))
    {
#	my $dd = Data::Dumper->new([$self->[&{$attrib}]]);
#	$str.=Dumper($dd->Values)."\n\n\n";
#	$self->[&{$attrib}] and $str.="$attrib\t:".Dumper($self->[&{$attrib}])."\n";
	$self->[NODE][&{$attrib}] and $str.="$attrib\t:".
	    ($self->[NODE][&{$attrib}][URISTR]||"no value")."\n";
    }

    return $str;
}

sub li
{
    my( $self ) = @_;

    # TODO: Add support for criterions

    my $cnt = @{$self->[NODE][CONTENT]};

    if( $cnt == 1 )
    {
	return $self->[NODE][CONTENT][0];
    }
    else
    {
	die "Selection has $cnt resources, while expecting one\n";
    }
}

sub list
{
    my( $self ) = @_;

    # TODO: Convert the contents to individual objects.  Maby tie the
    # list to a list object for iteration through the list.

    if( $DEBUG )
    {
	my $cnt = @{$self->[NODE][CONTENT]};
	debug "Returning a list of $cnt resources\n", 1;
    }

    return $self->[NODE][CONTENT];
}


########################################################
#
# Wrapper methods for the interfaces
#
#    &RDF::Service::Dispatcher::go(shift, $AUTOLOAD, @_);

# TODO:  Should not mark that ALL data has been initialized if
# init_types was called from a function in the process of adding new
# types.  This could be done with a memory of previous calls in the
# CONTEXT.

# NB!  Expect all initiated data to be solid!

# NB!  Set ALL after a call to init, unless thare are additionall data
# to be set.

sub init_types
{
    my( $self ) = shift;
    debug "GO init_types\n", 3;
    go($self, 'init_types', @_);
    $self->[NODE][TYPE_ALL] ||= 1;
}

sub init_rev_types
{
    my( $self ) = shift;
    debug "GO init_rev_types\n", 3;
    go($self, 'init_rev_types', @_);
    $self->[NODE][REV_TYPE_ALL] ||= 1;
}

sub init_rev_subjs
{
    my( $self ) = shift;
    debug "GO init_rev_subjs\n", 3;
    go($self, 'init_rev_subjs', @_);
    $self->[NODE][REV_SUBJ_ALL] ||= 1;
}

sub init_rev_objs
{
    my( $self ) = shift;
    debug "GO init_rev_objs\n", 3;
    go($self, 'init_rev_objs', @_);
    $self->[NODE][REV_OBJ_ALL] ||= 1;
}


sub store_types
{
    my( $self, @args ) = @_;

    if( $DEBUG )
    {
	warn "HISTORY --- @{$self->[HISTORY]}\n";
    }


    my $node = $self->[NODE];
    $node->[TYPE_ALL] or $self->init_types();
    debug "GO store_types\n", 3;
    if( go($self, 'store_types', @args) and $node->[TYPE_ALL] )
    {
	$node->[TYPE_ALL] = 2;
    }
}

sub store_props
{
    my( $self, @args ) = @_;
    my $node = $self->[NODE];
    $node->[REV_SUBJ_ALL] or $self->init_rev_subjs();
    debug "GO store_props\n", 3;
    if( go($self, 'store_props', @args) and $node->[REV_SUBJ_ALL] )
    {
	$node->[REV_SUBJ_ALL] = 2;
    }
}

sub store
{
    my( $self ) = @_;

    debug_start("store", ' ', $self);

    # TODO: Reset all other IDS caches (for this Resource)


    my $node = $self->[NODE];
    unless( $node->[SOLID] )
    {
	if( $DEBUG )
	{
	    if( $node->[VALUE] )
	    {
		debug( "Node NOT solid: ${$node->[VALUE]}\n" );
	    }
	}
	$self->store_node;
    }
    else
    {
	if( $DEBUG )
	{
	    if( $node->[VALUE] )
	    {
		debug( "Node SOLID: ${$node->[VALUE]}\n" );
	    }
	}
    }

    # Save types unless they are solid
    unless( defined $node->[TYPE_ALL] and $node->[TYPE_ALL] == 2 )
    {
	$self->store_types;
    }

    # Save props unless they are solid
    unless( defined $node->[REV_SUBJ_ALL] and $node->[REV_SUBJ_ALL] == 2 )
    {
	$self->store_props;
    }


    # Also store the model
    if( $node->[MODEL] )
    {
	debug "  Is the model ($node->[URISTR]) solid?\n", 2;
	$self->get_context_by_id($node->[MODEL][ID])->store
	  unless $node->[MODEL][SOLID];
    }

    # Only saves props. Not rev props.

    debug_end("store", ' ', $self);

    return( 1 );
}



######################################################################
#
# Declaration methods should only be called from interfaces.
#

sub declare_del_types
{
    my( $self, $types ) = @_;

    debug_start("declare_del_types", ' ', $self);

    my $node_type = $self->[NODE][TYPE];
    my $model_id = $self->[WMODEL][NODE][ID];
    my $id = $self->[NODE][ID];

    my @ids = ();
    if( defined $types )
    {
	@ids = map $_->[NODE][ID], @$types;
    }
    else
    {
	@ids = keys %$node_type;
    }

    foreach my $class_id ( @ids )
    {
	my $class_node = $self->get_node_by_id($class_id);
	debug "  Checking $class_node->[URISTR]\n", 2;
	unless( delete $node_type->{$class_id}{$model_id} )
	{
	    debug "    Type defined in another model:\n", 2;
	    foreach my $other_model_id ( keys %{$node_type->{$class_id}} )
	    {
		my $other_model_node =
		  $self->get_node_by_id($other_model_id);
		debug "      $other_model_node->[URISTR]\n", 2;
	    }
	    next;
	}

	my $class_rev_type = $class_node->[REV_TYPE];

	debug "    Removing rev_type node\n", 2;
	if( $DEBUG )
	{
	    unless( $class_rev_type->{$id} )
	    {
		unless( $class_node->[URISTR] eq NS_RDFS.'Resource' )
		{
		    die "    There was no rev_type to remove!!\n";
		}
	    }
	}

	delete $class_rev_type->{$id}{$model_id};

	delete $node_type->{$class_id} 
	  unless keys %{$node_type->{$class_id}};

	delete $class_rev_type->{$id}
	  unless keys %{$class_rev_type->{$id}};
    }

    debug_end("declare_del_types", ' ', $self);
}

sub declare_del_rev_types
{
    my( $self, $res ) = @_;

    debug_start("declare_del_rev_types", ' ', $self);

    my $class_rev_type = $self->[NODE][REV_TYPE];
    my $model_id = $self->[WMODEL][NODE][ID];
    my $id = $self->[NODE][ID];

    my @ids = ();
    if( defined $res )
    {
	@ids = map $_->[NODE][ID], @$res;
    }
    else
    {
	@ids = keys %$class_rev_type;
    }

    foreach my $res_id ( @ids )
    {
	my $class_node = $self->get_node_by_id($res_id);
	debug "  Checking $class_node->[URISTR]\n", 2;
	unless( delete $class_rev_type->{$res_id}{$model_id} )
	{
	    next;
	}

	my $class_type = $class_node->[TYPE];

	debug "  Removing type node\n", 2;
	if( $DEBUG )
	{
	    unless( $class_type->{$id} )
	    {
		die "    There was no type to remove!!\n";
	    }
	}
	delete $class_type->{$id}{$model_id};

	delete $class_rev_type->{$res_id} 
	  unless keys %{$class_rev_type->{$res_id}};

	delete $class_type->{$id}
	  unless keys %{$class_type->{$id}};
    }

    debug_end("declare_del_rev_types", ' ', $self);
}

sub declare_literal
{
    my( $self, $lit_str_ref, $lit, $types, $props, $model ) = @_;
    #
    # - $model is a resource object
    # - $lit (uri or node or undef)
    # - $lref will be a scalar ref
    # - $types is ref to array of type objects or undef
    # - $props is hash ref with remaining properties or undef

    # $types and $props is not done yet

    # $lit can be node or uristr
    #
    unless( ref $lit )
    {
	unless( defined $lit )
	{
	    $lit = NS_LD."/literal/". &get_unique_id;
	}
	$lit = $self->get( $lit );
    }

    if( $DEBUG )
    {
	debug_start("declare_literal", ' ', $self );
	debug "   ( $$lit_str_ref )\n", 1;

	ref $lit_str_ref eq 'SCALAR'
	  or die "Value must be a scalar reference";

	if( $$lit_str_ref =~ /^RDF/ )
	{
	    warn "*****";
	    confess "Value is $$lit_str_ref";
	}

    }


    # TODO: Set value as property if value differ among models

    $model ||= $self->[WMODEL][NODE];
    $lit->[NODE][VALUE] = $lit_str_ref;
    $lit->[NODE][MODEL] = $model;
    $lit->[NODE][NAME] = 'Literal';
    $model->[REV_MODEL]{$lit->[NODE][ID]} = $lit->[NODE];

    $lit->declare_add_types([NS_RDFS.'Literal'], $model, 1 );

    debug_end("declare_literal", ' ', $self);
    return $lit;
}

sub declare_selection
{
    my( $self, $content, $selection ) = @_;


    debug_start("declare_selection", ' ', $self);
    if( $DEBUG )
    {
	confess unless ref $content;
	my @con_uristr = ();
	foreach my $res ( @$content )
	{
	    confess "$res no Resource" unless ref $res and ref $res->[NODE];
	    push @con_uristr, $res->[NODE][URISTR];
	}
	debug "   ( @con_uristr )\n";
    }

    $content ||= [];
    my $model = $self->[WMODEL][NODE] or
      die "$self->[NODE][URISTR] doesn't have a defined model";

    unless( ref $selection )
    {
	unless( defined $selection )
	{
	    $selection = NS_LD.'/selection/'.&get_unique_id;
	}
	$selection = $self->get( $selection );
    }
#    warn "*** Selection is $selection->[NODE][URISTR]\n";

    my $selection_node = $selection->[NODE];

    $selection_node->[MODEL] = $model;
    $selection_node->[CONTENT] = $content;
    $selection_node->[NAME] = 'Selection';

    # TODO: Only add if this is an addition
    $model->[REV_MODEL]{$selection_node->[ID]} = $selection_node;

    $selection->declare_add_types( [NS_LS.'#Selection'] );

    debug_end("declare_selection", ' ', $self);
    return $selection;
}

sub declare_node
{
    my( $self, $uri, $types, $props );

    die "Not done";
}

sub declare_self
{
    my( $self, $types, $props ) = @_;

    # This is practicaly the same as set.  declare_self does not store
    # the changes in the interfaces

    debug_start("declare_self", ' ', $self );

    # Should each type and property only be saved in the first best
    # interface and not saved in the following interfaces?  Yes!
    #
    # The types and props taken by one interface must be marked so
    # that the next interface doesn't handle them. This could be done
    # by modifying the arguments $types and $props to exclude those
    # that has been taken care of.

    $self->set_types( $types, 0, 1 );
    $self->set_props( $props, 0, 1 );

    debug_end("declare_self", ' ', $self);
    return $self;
}


sub declare_add_types
{
    my( $self, $types, $model, $solid ) = @_;

    debug_start("declare_add_types", ' ', $self );

    # TODO: Should it be model instead of types?

    # TODO: type(Resource) should be added by base init_types

    # The types will be listed in order from the most specific to the
    # most general. rdfs:Resource will allways be last.  Insert
    # implicit items according to subClassOf.

    my $node = $self->[NODE];
    $model ||= $self->[WMODEL][NODE];
    $model = $self->get_node($model) unless ref $model;
    $solid ||= 0;

    if( $DEBUG )
    {
	croak "Invalid solid value: $solid" if $solid > 1;
	croak "types must be a list ref" unless ref $types;
	croak "Bad model: $model" unless
	  ref $model eq "RDF::Service::Resource";
	confess "Bad node: $node" unless
	  ref $node eq "RDF::Service::Resource";
	debug "  in model $model->[URISTR] IDS $model->[IDS]\n";
    }

    my $model_id = $model->[ID];
    foreach my $type ( @$types )
    {
	# This should update the $types listref
	#
	$type = $self->get( $type ) unless ref $type;

	# Duplicate types in the same model will merge
	#
	# SOLID = 2, NONSOLID = 1
	#
	$node->[TYPE]{$type->[NODE][ID]}{$model_id} = 1 + $solid;
	$type->[NODE][REV_TYPE]{$node->[ID]}{$model_id} = 1 + $solid;

	if( $DEBUG )
	{
	    debug("    T $type->[NODE][URISTR] ".
		    "(IDS $type->[NODE][IDS] )\n", 2);
	    if( $type->[NODE][MODEL] )
	    {
		debug("      Model of type is ".
			$type->[NODE][MODEL][URISTR] .
			  " IDS $type->[NODE][MODEL][IDS]\n", 2);
	    }
	}
    }

    # TODO: Only set this if one type was added
    #
    # NB! The model include this node in REV_MODEL if it self or any
    # of its types belongs to the model.  But the node includes the
    # model only if int's internal data belongs to that model.
    #
    $model->[REV_MODEL]{$node->[ID]} = $node;

    unless( $solid )
    {
	# Node type no longer solid. (Unsaved types)
	#
	$node->[TYPE_ALL] = 1 if $node->[TYPE_ALL];
    }

    # TODO: Separate the dynamic types to a separate init_types



    # TODO: Maby place in separate method

    # Add the implicit types for $node.  This is done in a second loop
    # in order to resolv cyclic dependencies.
    # TODO: Check that this generates the right result.
    #
    my $subClassOf = $self->get(NS_RDFS.'subClassOf');
    foreach my $type ( @$types )
    {
	# $types has previously (in this function) been converted from
	# URISTR to res

 	# NB!!! Special handling of some basic classes  in order to
 	# avoid cyclic dependencies
 	#
	my $type_node = $type->[NODE];
 	next if $type_node->[URISTR] eq NS_RDFS.'Literal';
 	next if $type_node->[URISTR] eq NS_RDFS.'Class';
 	next if $type_node->[URISTR] eq NS_RDFS.'Resource';
 	next if $type_node->[URISTR] eq NS_RDF.'Statement';
 	next if $type_node->[URISTR] eq NS_LS.'#Selection';



 	# The class init_rev_subjs creates implicit subClassOf for
 	# second and nth stage super classes.  We only have to iterate
 	# through the subClassOf properties of the type.
 	#
 	foreach my $sc ( @{$type->arc_obj_list($subClassOf)} )
 	{
	    # Special handling of Resource. Added below
	    next if $sc->[NODE][URISTR] eq NS_RDFS.'Resource';

	    # These are SOLID, since they are dynamic
	    # TODO: What should the model be?
	    #
 	    $node->[TYPE]{$sc->[NODE][ID]}{$model_id} = 2;
	    $sc->[NODE][REV_TYPE]{$node->[ID]}{$model_id} = 2;
 	    # These types are dependent on the subClasOf statements
 	}
    }

    # Add RDFS:Resource, in case not done yet
    #
    $node->[TYPE]{&uri2id(NS_RDFS.'Resource')}{uri2id(NS_RDFS)} = 2;

    # The jumptable must be redone now!
    if( $node->[JUMPTABLE] )
    {
	debug "Resetting the jumptable for ".
	  "$node->[URISTR]: $node->[JTK]\n", 1;
	$node->[JTK] = '--resetted--';
	undef $node->[JUMPTABLE];
    }

    debug_end("declare_add_types", ' ', $self);
    return 1;
}

sub declare_add_static_literal
{
    my( $subj, $pred, $lit_str, $arc_uristr ) = @_;
    #
    # $lit_str is a scalar ref
    #
    # The URI of a static literal represents what the value
    # represents.  That is; the abstract property.  It will never
    # change.  (The literal static/dynamic type info is not stored)

    # TODO: find the literal...

    die "Not implemented";

#    $arc_uristr ||= $model.'#'.get_unique_id();
#    my $arc_id = uri2id( $arc_uristr );
#    push @{ $subj->[PROPS]{$pred->[ID]} }, [$obj->[ID],
#					    $arc_id,
#					    $model->[ID],
#					    ];
#    return $arc_uristr;
}

sub declare_add_dynamic_literal
{
    my( $subj, $pred, $lit_str_ref, $lit_uristr, $arc_uristr, $model ) = @_;
    #
    # $lit_str is a scalar ref
    #
    # The URI of a dynamic literal represents the property for the
    # specific subject.  The literal changes content as the subjects
    # property changes.  (The literal static/dynamic type info is not
    # stored)

    debug_start("declare_add_dynamic_literal", ' ', $subj );

    croak "Invalid subj" unless ref $subj;
    croak "No subj model" unless ref $subj->[NODE][MODEL];

    $pred = $subj->get( $pred ) unless ref $pred;
    $model ||= $subj->[WMODEL][NODE];

    $arc_uristr ||= NS_LD."/literal/".get_unique_id();

    # TODO: This is a implicit object. It's URI should be based on the
    # subject URI
    #
    my $lit = $subj->declare_literal( $lit_str_ref,
				      $lit_uristr,
				      undef,
				      undef,
				      $model,
				     );

    my $arc = $subj->declare_add_prop( $pred, $lit, $arc_uristr, $model );

    debug_end("declare_add_dynamic_literal", ' ', $subj);
    return $arc;
}

sub declare_add_prop
{
    my( $subj, $pred, $obj, $arc_uristr, $model, $solid ) = @_;

    $model ||= $subj->[WMODEL][NODE];
    $solid ||= 0;

    my $arc = $subj->declare_arc( $pred,
				  $subj,
				  $obj,
				  $arc_uristr,
				  $model,
				  $solid
				 );

    return $arc;
}

sub declare_arc
{
    my( $self, $pred, $subj, $obj, $uristr, $model, $solid ) = @_;

    # It *could* be that we have two diffrent arcs with the same URI,
    # if they comes from diffrent models.  The common case is that the
    # arcs with the same URI are identical.  The PRED, SUBJ, OBJ slots
    # are used for the common case.
    #
    # TODO: Use explicit properties if the models differs.
    #
    # All models says the same thing unless the properties are
    # explicit.

    # A defined [REV_SUBJ] only means that some props has been
    # defined. It doesn't mean that ALL props has been defined.

    # A existing prop key with an undef value means that we know that
    # the prop doesn't exist.  But a look for a nonexisting prop sould
    # (for now) trigger a complete initialization and set the complete
    # key.

    # The concept of "complete list" depends on other selection.
    # Diffrent selections will have diffrent lists.  Every such
    # selection will be saved separately from the [REV_SUBJ] list.
    # It's existence guarantee that the list is complete.

    debug_start("declare_arc", ' ', $self);

    if( $DEBUG )
    {
	if( $obj->[NODE][VALUE] )
	{
	    unless( ref($obj->[NODE][VALUE]) eq 'SCALAR')
	    {
		confess "Bad value for $obj->[NODE][URISTR] ( ".
		  ref($obj->[NODE][VALUE])." ne 'SCALAR' )";
	    }
	}
    }


    if( $uristr )  # arc could be changed
    {
	# TODO: Check that tha agent owns the namespace
	# For now: Just allow models in the local namespace
	my $ns_l = NS_LD;
	unless( $uristr =~ /$ns_l/ )
	{
	    confess "Invalid namespace for literal: $uristr";
	}
    }
    else  # The arc is created
    {
	# Who will know anything about this arc?  There could be
	# statements about it later, but not now.

	$uristr = NS_LD."/arc/". &get_unique_id;

	# TODO: Call a miniversion of add_types that knows that no other
	# types has been added.  We should not require the setting of
	# types and props to initialize itself. The initialization
	# should be done here.
    }

    # Prioritize submitted $model
    #
    $model ||= $self->[WMODEL][NODE];
    $solid ||= 0;


    my $arc = $self->get( $uristr );
    my $arc_node = $arc->[NODE];

    $model or die "*** No WMODEL for arc $arc_node->[URISTR]\n";
    $arc_node->[IDS] or die "*** No IDS for arc $arc_node->[URISTR]\n";



    $pred = $self->get($pred) unless ref $pred;
    $subj = $self->get($subj) unless ref $subj;
    $obj = $obj->get($obj) unless ref $obj;

    if( $DEBUG )
    {
	unless( ref( $model ) eq "RDF::Service::Resource" )
	{
	    confess "Bad model";
	}

	debug "   P $pred->[NODE][URISTR]\n", 1;
	debug "   S $subj->[NODE][URISTR]\n", 1;
	debug "   O $obj->[NODE][URISTR]\n", 1;
	debug "   M $model->[URISTR]\n", 1;
	debug "   A $arc->[NODE][URISTR]\n", 1;
    }

    $arc_node->[PRED] = $pred->[NODE];
    $arc_node->[SUBJ] = $subj->[NODE];
    $arc_node->[OBJ]  = $obj->[NODE];
    $arc_node->[MODEL] = $model;

    push @{ $subj->[NODE][REV_SUBJ]{$pred->[NODE][ID]} }, $arc_node;
    push @{ $obj->[NODE][REV_OBJ]{$pred->[NODE][ID]} }, $arc_node;
    push @{ $pred->[NODE][REV_PRED] }, $arc_node;
    $model->[REV_MODEL]{$arc_node->[ID]} = $arc_node;

    if( $solid )
    {
	debug "Changing SOLID to 1 for $arc_node->[URISTR] ".
	  "IDS $arc_node->[IDS]\n", 3;
	$arc_node->[SOLID] = 1;
    }
    else
    {
	debug "Changing SOLID to 0 for $arc_node->[URISTR] ".
	  "IDS $arc_node->[IDS]\n", 3;
	$arc_node->[SOLID] = 0;
	$subj->[NODE][REV_SUBJ_ALL] = 1 if $subj->[NODE][REV_SUBJ_ALL];
	$obj->[NODE][REV_OBJ_ALL] = 1 if $subj->[NODE][REV_OBJ_ALL];
    }

    # TODO: declare_self should only be used if a existing arc is
    # changed. New arc should not call declare_self since that forces
    # an deep initialization of itself.

    $arc->declare_add_types( [NS_RDF.'Statement'], NS_RDF, 1 );


    debug_end("declare_arc", ' ', $self);
    return $arc;
}





1;


__END__
