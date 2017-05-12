#  $Id: V01.pm,v 1.29 2000/12/21 22:04:18 aigan Exp $  -*-cperl-*-

package RDF::Service::Interface::DBI::V01;

#=====================================================================
#
# DESCRIPTION
#   Interface to storage and retrieval of statements in a general purpouse DB
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
use DBI;
#use POSIX;
#use Time::HiRes qw( time );
use vars qw( $prefix $interface_uri @node_fields );
use RDF::Service::Constants qw( :all );
use RDF::Service::Cache qw( get_unique_id uri2id id2uri debug $DEBUG );
use RDF::Service::Resource;
use Data::Dumper;
use Carp;


$prefix = [ ];

# Todo: Decide on a standard way to name functions
# # Will not use the long names in this version...
$interface_uri = "org.cpan.RDF.Interface.DBI.V01";

@node_fields = qw( id uri iscontainer isprefix
	     label aliasfor
	     pred distr subj obj model
	     member
	     isliteral lang value );


sub register
{
    my( $i, $args ) = @_;

    my $connect = $args->{'connect'} or croak "Connection string missing";
    my $name    = $args->{'name'} || "";
    my $passwd  = $args->{'passwd'} || "";

    my $dbi_options =
    {
	RaiseError => 0,
    };

    my $dbh = ( DBI->connect_cached( $connect, $name, $passwd, $dbi_options ) );


    die "Connect to $connect failed\n" unless $dbh;

    # Maby we should store interface data in a special hash instead,
    # like interface($interface->[ID])->{'dbh'}... But that seams to
    # be just as long.  Another alternative would be to reserve a
    # range especially for interfaces.
    #
    #
    # This interface module can be used for connection to several
    # diffrent DBs.  Every such connection will have the same methods
    # but the method calls will give diffrent results.  It is diffrent
    # interface objects but the same interface module.
    #
    debug "Store DBH for $i->[URISTR] in ".
	"[PRIVATE]{$i->[ID]}{'dbh'}\n", 3;

    $i->[PRIVATE]{$i->[ID]}{'dbh'} = $dbh;

    return
    {
	'' =>
	{
	    NS_LS.'#Service' =>
	    {
	    },
	    NS_LS.'#interface' =>
	    {
	    },
	    NS_LS.'#Model' =>
	    {
#		'add_arc'        => [\&add_arc],
		'find_arcs_list' => [\&find_arcs_list],
	    },
	    NS_RDFS.'Resource'   =>
	    {
		'init_types'     => [\&init_types],
		'init_rev_subjs' => [\&init_rev_subjs],
		'init_rev_objs'  => [\&init_rev_objs],
		'name'           => [\&name],
		'find_node'      => [\&find_node],
		'store_types'    => [\&store_types],
		'store_props'    => [\&store_props],
		'store_node'     => [\&store_node],
		'remove'         => [\&remove],
		'remove_types'   => [\&remove_types],
		'remove_props'   => [\&remove_props],
	    },
	    NS_RDFS.'Class' =>
	    {
		'objects_list' => [\&objects_list],
		'init_rev_types' => [\&init_rev_types],
	    },
	},
    };
}



sub find_node
{
    my( $self, $i, $uristr ) = @_;
    #
    # Is the node contained in the model?

    my $p = {}; # Interface private data
    my $obj;

    # Look for the URI in the DB.
    #
    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};

    my $sth = $dbh->prepare_cached("
              select id, refid, refpart, hasalias from uri
              where string=?
              ");
    $sth->execute( $uristr );

    my( $r_id, $r_refid, $r_refpart, $r_hasalias );
    $sth->bind_columns(\$r_id, \$r_refid, \$r_refpart, \$r_hasalias);
    if( $sth->fetch )
    {
	$p->{'uri'} = $r_id;

	$obj = $self->get( $uristr );
	$obj->[NODE][PRIVATE]{$i->[ID]} = $p;
    }
    $sth->finish; # Release the handler

    return( $obj, 1 ) if defined $obj;
    return( undef, 0 );
}

sub find_arcs_list
{
    my( $self, $i, $pred, $subj, $obj ) = @_;
    #
    # TODO: This will primarly return explicit arcs. But should also
    # return many implicit arcs.  Fo not return type arcs.

    die "Not implemented";
}

sub name
{
    # Will give the part of the URI following the 'namespace'
    die "not implemented";
}

sub add_arc  ## DEPRECATED
{
    my( $self, $i, $uristr, $pred, $subj, $obj ) = @_;

    # Why is this needed? Use store_props!

    die "deprecated";

    # Assuems that the arc does not exist

    my $arc = $self->declare_arc($pred,
				 $subj,
				 $obj,
				 $uristr,
				);


    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};


    # TODO: Only do this the first time
    #
    my $field_str = join ", ", @node_fields;
    my $place_str = join ", ", ('?')x @node_fields;

    my $sth = $dbh->prepare_cached("  insert into node
				      ($field_str)
				      values ($place_str)
				      ");


    # TODO: Handle if arc already exist
    #    my %p = %{$self->[NODE][PRIVATE]{$i->[ID]}};

    my %p = ();
    $p{'id'}     ||= &_nextval($dbh);

    $p{'uri'}         = &_create_uri( $arc->uri, $i);
    $p{'iscontainer'} = 'false';
    $p{'isprefix'}    = 'false';
    $p{'label'}       = undef;
    $p{'aliasfor'}    = undef;
    $p{'pred'}        = &_get_id( $arc->pred, $i);
    $p{'distr'}       = 'false';
    $p{'subj'}        = &_get_id( $arc->subj, $i);
    $p{'obj'}         = &_get_id( $arc->obj, $i);
    $p{'model'}       = &_get_id( $arc->[WMODEL][NODE], $i);
    $p{'member'}      = undef;
    $p{'isliteral'}   = 'false';
    $p{'lang'}        = undef;
    $p{'value'}       = undef;


    $sth->execute( map $p{$_}, @node_fields )
	or confess( $sth->errstr );

    return( 1, 1 );
}

sub init_rev_subjs
{
    my( $self, $i, $constraint ) = @_;

    # This should initiate all props from this interface


    # TODO: Use the constraint

    $self->[NODE][TYPE_ALL] or $self->init_types;
    $self->[NODE][TYPE_ALL] ||= 1;

    # TODO: Should props be undef if type changes?

    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};

    my $p = $self->[NODE][PRIVATE]{$i->[ID]} || {};

    # TODO: Also read all the other node data

    my $sth = $dbh->prepare_cached("
              select auri.string as arc,
                     puri.string as pred,
                     suri.string as subj,
                     ouri.string as obj,
                     muri.string as model
              from node,
                   uri auri,
                   uri puri,
                   uri suri,
                   uri ouri,
                   uri muri
              where node.pred  = puri.id and
                    node.subj  = suri.id and
                    node.obj   = ouri.id and
                    node.model = muri.id and
                    node.uri   = auri.id and
                    suri.string = ?
              ");

    $sth->execute( $self->[NODE][URISTR] );
    my $tbl = $sth->fetchall_arrayref({});
    $sth->finish;

    debug "Fetching props\n", 1;
    foreach my $r ( @$tbl )
    {
	my $pred   = $self->get( $r->{'pred'} );
	my $subj   = $self;
	my $obj    = $self->get( $r->{'obj'} );
	my $model  = $self->get( $r->{'model'} )->[NODE];
	debug "..Found a $pred->[NODE][URISTR]\n", 1;

	$subj->declare_add_prop( $pred, $obj, $r->{'arc'}, $model, 1 );
    }


    return( 1, 3 );
}

sub init_rev_objs
{
    my( $self, $i, $constraint ) = @_;

    # This should get all rev_props from this interface


    # TODO: Use the constraint


    $self->[NODE][TYPE_ALL] or $self->init_types;
    $self->[NODE][TYPE_ALL] ||= 1;

    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};

    my $p = $self->[NODE][PRIVATE]{$i->[ID]} || {};

    # TODO: Also read all the other node data

    my $sth = $dbh->prepare_cached("
              select auri.string as arc,
                     puri.string as pred,
                     suri.string as subj,
                     ouri.string as obj,
                     muri.string as model
              from node,
                   uri auri,
                   uri puri,
                   uri suri,
                   uri ouri,
                   uri muri
              where node.pred  = puri.id and
                    node.subj  = suri.id and
                    node.obj   = ouri.id and
                    node.model = muri.id and
                    node.uri   = auri.id and
                    ouri.string = ?
              ");

#    warn "*** $self->[NODE][URISTR]\n";

    $sth->execute( $self->[NODE][URISTR] );
    my $tbl = $sth->fetchall_arrayref({});
    $sth->finish;

    debug "Fetching rev_props\n", 1;
    foreach my $r ( @$tbl )
    {
	my $pred   = $self->get( $r->{'pred'} );
	my $subj   = $self->get( $r->{'subj'} );
	my $obj    = $self;
	my $model  = $self->get( $r->{'model'} );
	debug "..Found a $pred->[NODE][URISTR]\n", 1;

	$subj->declare_add_prop( $pred, $obj, $r->{'arc'}, $model, 1 );
    }

    return( 1, 3 );
}

sub init_types
{
    my( $self, $i ) = @_;
    #
    # Read the types from the DBI.  Get all info from the node
    # record

    # TODO: Get the implicite types from subClassOf (Handled by
    # Base/V01)

    if( $DEBUG )
    {
	debug "Init types for $self->[NODE][URISTR]\n", 2;

	unless( ref $self eq "RDF::Service::Context" )
	{
	    die "Wrong type for self: $self";
	}

	unless( ref $i eq "RDF::Service::Resource" )
	{
	    die "Wrong type for i: $i";
	}

	die "No node for self" unless $self->[NODE];

	die "No private for self_node" unless $self->[NODE][PRIVATE];
    }

    # Look for the URI in the DB.
    #
    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};
    my $p = $self->[NODE][PRIVATE]{$i->[ID]} || {};
    $p->{'uri'} ||= &_get_id($self->[NODE], $i);

    my $node = $self->[NODE];

  Node:
    {
	# TODO: Reuse cols variable and sth
	my @cols = qw( id iscontainer isprefix label aliasfor
		       model pred distr subj obj member isliteral
		       lang value blob );

	my $fields = join ", ", @cols;

	my $sth_node = $dbh->prepare_cached("
              select $fields
              from node
              where uri=?
              ");

	my $true = '1';
	my  $false = '0';

	$sth_node->execute( $p->{'uri'} );
	my $tbl = $sth_node->fetchall_arrayref({});
	$sth_node->finish; # The fetchall should finish the sth implicitly

	# TODO: Handle the case with more than one hit!

	foreach my $r ( @$tbl )
	{
	    debug "Changing SOLID to 1 for $node->[URISTR] ".
	      "IDS $node->[IDS]\n", 3;
	    $node->[SOLID] = 1; # Resource found in db
	    my $types = [];

	    # TODO: Go through all the varables

	    # iscontainer

	    # isprefix

	    # label  (there can be only one!)
	    if( $r->{'label'} )
	    {
		if( $node->[LABEL] )
		{
		    $node->[LABEL] .= " /  $r->{'label'}";
		}
		else
		{
		    $node->[LABEL] = $r->{'label'};
		}
	    }

	    # aliasfor

	    # model
	    my $model_res = &_get_node($r->{'model'}, $self, $i);
	    my $model = $model_res->[NODE];
	    $self->[NODE][MODEL] = $model;
	    if( $DEBUG )
	    {
		unless( $model_res->is_a( NS_LS.'#Model' ) )
		{
		    die "The model is not a model";
		}
	    }

	    # pred distr subj obj
	    if( my $r_pred = $r->{'pred'} )
	    {
		push @$types, NS_RDF.'Statement';
	    }

	    # member

	    # isliteral, lang, value, blob
	    if( $r->{'isliteral'} eq $true )
	    {
		debug "..Literal: $self->[NODE][URISTR]\n", 2;
		if( $r->{'value'} )
		{
		    # Rewrite from $r->{'value'}
		    $self->[NODE][VALUE] = \${$r}{'value'};
		    push @$types, NS_RDFS.'Literal';

		    if( $DEBUG )
		    {
			unless( ref $self->[NODE][VALUE] eq 'SCALAR' )
			{
			    die "Value not a string ( $self->[NODE][VALUE] ) ";
			}
		    }
		}
		else
		{
		    die "not implemented";
		}
	    }
	    $self->declare_add_types( $types, $model, 1 );
	}
    }


  Types:
    {
	my $sth_types = $dbh->prepare_cached("
              select type.id, string, type, model
              from type, uri
              where node=? and uri.id=type
              ");

	$sth_types->execute( $p->{'uri'} );
	my $tbl = $sth_types->fetchall_arrayref({});
	$sth_types->finish;
	foreach my $r ( @$tbl )
	{
	    my $type = $self->get($r->{'string'});
	    my $model = &_get_node( $r->{'model'}, $self, $i )->[NODE];

	    # Remember the record ID
	    $type->[NODE][PRIVATE]{$i->[ID]}{'uri'} = $r->{'type'};

	    # TODO: Maby group the types before creating them
	    $self->declare_add_types( [$type], $model, 1 );
	}
    }

    debug "Types for $self->[NODE][URISTR]\n", 1;
    debug $self->types_as_string, 1;

    return( 1, 3 );
}

sub init_rev_types
{
    my( $self, $i ) = @_;
    #
    # Read the types from the DBI.

    # TODO: Get the implicite types from subClassOf. ( Should be
    # handled by declare_add_rev_types )

    # I may the assumption that this initiation does not affect
    # knowledge of the resource SOLID state.


    # Look for the URI in the DB.
    #
    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};
    my $p = $self->[NODE][PRIVATE]{$i->[ID]} || {};
    $p->{'uri'} ||= &_get_id($self->[NODE], $i);

    my $rev_types = [];

    my $sth_rev_types = $dbh->prepare_cached("
              select type.id, string, node, model
              from type, uri
              where type=? and uri.id=node
              ");

    $sth_rev_types->execute( $p->{'uri'} );
    my $tbl = $sth_rev_types->fetchall_arrayref({});
    $sth_rev_types->finish;
    foreach my $r ( @$tbl )
    {
	my $rev_type = $self->get($r->{'string'});
	my $model = &_get_node( $r->{'model'}, $self, $i )->[NODE];

	# Remember the record ID
	$rev_type->[NODE][PRIVATE]{$i->[ID]}{'uri'} = $r->{'node'};

	# TODO: Group the rev_types (by model) before creating them
	$rev_type->declare_add_types( [$self], $model, 1 );
    }

    return( 1, 3 );
}


sub remove
{
    my( $self, $i ) = @_;

    # Remove node from interface. But not from the cahce.  This is
    # called from Base delete before it removes the node from cache.

    # TODO: Check that the node (with the model) actually exist in
    # this interface


    # Remove types and node

    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};

    my $sth_type = $dbh->prepare_cached("
                    delete from type
                    where node = ? and model = ?");
    my $sth_node = $dbh->prepare_cached("
                    delete from node
                    where uri = ? and model = ?");

    my $r_model = &_get_id( $self->[WMODEL][NODE], $i );
    my $r_node  = &_get_id( $self->[NODE],  $i );
    my $node_p = $self->[NODE][PRIVATE]{$i->[ID]} || {};

    $sth_type->execute( $r_node, $r_model)
      or confess( $sth_type->errstr );
    $sth_node->execute( $r_node, $r_model)
      or confess( $sth_type->errstr );

    debug "Deleted $self->[NODE][URISTR] for model ".
      $self->[WMODEL][NODE][URISTR]."\n", 1;

    # Remove the private information.  This removes info for all
    # models.  Not just the deleted one.

    # TODO: Check that there is no mixup between diffrent models
    # interface private data in the same node.

    delete $self->[NODE][PRIVATE]{$i->[ID]};

    # TODO: What happens if the resource is stored in several
    # interfaces?  When should we set SOLID to false?

    return( 1, 3 );
}

sub store_types
{
    my( $self, $i ) = @_;
    #
    # TODO: Could store duplicate type statements. But only from
    # diffrent models.

    my $node = $self->[NODE];

    debug $self->types_as_string, 2;


    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};
    my $p = $node->[PRIVATE]{$i->[ID]} || {};

    my $sth = $dbh->prepare_cached("
                   insert into type
                   (node, type, model)
                   values (?, ?, ?)
    ");

    my $r_node  = &_get_id($node, $i);

    foreach my $type_id ( keys %{$node->[TYPE]} )
    {
	my $type = $self->get_context_by_id( $type_id );
	my $r_type = &_get_id($type->[NODE], $i);

	debug "..Checking $type->[NODE][URISTR]\n", 2;

	$type->store; # Store the type if necessary

	foreach my $model_id ( keys %{$node->[TYPE]{$type_id}} )
	{
	    # TODO: Use _get_id_by_node_id
	    my $model = $self->get_context_by_id( $model_id )->[NODE];
	    debug "....Model $model->[URISTR]\n", 2;

	    # Don't store type if it's already solid
	    if( $node->[TYPE]{$type_id}{$model_id} == 2 )
	    {
		my $uri = &id2uri( $type_id );
		debug "      Already solid: $uri\n", 1;
		next;
	    }

	    debug "      Saving type in DB\n", 2;

	    my $r_model = &_get_id($model, $i);
	    $sth->execute( $r_node, $r_type, $r_model )
	      or confess( $sth->errstr );

	    # Type is now solid!
	    $node->[TYPE]{$type_id}{$model_id} = 2;
	}
    }

    # This interface store all the types. Do not continue
    return( 1, 1 );
}

sub remove_types
{
    my( $self, $i, $types ) = @_;

    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};

    my $sth = $dbh->prepare_cached("
                   delete from type
                   where node=? and type=? and model=?
    ");

    my $r_node  = &_get_id($self->[NODE], $i);
    my $r_model = &_get_id($self->[WMODEL][NODE], $i);

    foreach my $type ( @$types )
    {
	debug "  t $type->[NODE][URISTR]\n", 2;

	my $r_type = &_get_id($type->[NODE], $i);
	$sth->execute( $r_node, $r_type, $r_model )
	    or confess( $sth->errstr );
    }

    return( 1, 3 );
}

sub store_props
{
    my( $self, $i ) = @_;
    #
    # The supplied preds are a list of pred_uri.  They specify the
    # preds to store.  The arcs are already declared.  Store the arcs
    # matching the WMODEL.  Implicit preds should not be included in
    # the $preds list.  Preds already stored should not be included.

    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};
    my $p = $self->[NODE][PRIVATE]{$i->[ID]} || {};
    my $node = $self->[NODE];

    my $sth = $dbh->prepare_cached("
                   insert into node
                   (id, uri, iscontainer, isprefix, model,
                   pred, subj, obj, isliteral)
                   values (?, ?, false, false, ?, ?, ?, ?, false)
    ");

    my $r_subj = $p->{'uri'} ||= &_get_id($node, $i);

    # TODO: Store the subj (like update_node)

    if( $DEBUG )
    {
	my $pred_cnt = keys %{$node->[REV_SUBJ]};
#	debug "  *****************************\n", 1;
	debug "  Resource has $pred_cnt predicates\n", 1;

#	foreach my $obj ( @{$self->arc_obj_list( NS_LS.'#updated' )} )
#	{
#	    debug "  u $obj->[NODE][URISTR]\n";
#	}
    }

    foreach my $pred_id ( keys %{$node->[REV_SUBJ]} )
    {
	my $pred = $self->get_context_by_id($pred_id);
	my $r_pred = &_get_id($pred->[NODE], $i);

	$pred->store; # Store the pred if necessary

	if( $DEBUG )
	{
	    debug "..Storing $pred->[NODE][URISTR] ($pred_id)\n", 1;
	    debug "....".@{$node->[REV_SUBJ]{$pred_id}}." entries\n", 1;
	}

	foreach my $arc_node ( @{$node->[REV_SUBJ]{$pred_id}} )
	{
	    debug "....Checking arc $arc_node->[URISTR]\n", 3;
	    # Don't store prop is it's already solid
	    next if $arc_node->[SOLID];

	    if( $DEBUG )
	    {
		if( $arc_node->[OBJ][VALUE] )
		{
		    unless( ref($arc_node->[OBJ][VALUE]) eq 'SCALAR')
		    {
			confess "Bad value for $arc_node->[OBJ][URISTR] ( ".
			  ref($arc_node->[OBJ][VALUE])." ne 'SCALAR' )";
		    }
		}
	    }

	    my $pa = $arc_node->[PRIVATE]{$i->[ID]} || {};

	    $pa->{'id'} ||= &_nextval($dbh);
	    $pa->{'pred'} = $r_pred;
	    $pa->{'subj'} = $r_subj;
	    $pa->{'obj'} ||= &_get_id( $arc_node->[OBJ], $i );
	    $pa->{'uri'} ||= &_get_id( $arc_node, $i );
	    $pa->{'model'} ||= &_get_id( $arc_node->[MODEL], $i );

	    $sth->execute( $pa->{'id'}, $pa->{'uri'}, $pa->{'model'},
			   $r_pred, $r_subj, $pa->{'obj'} )
	      or confess( $sth->errstr );

	    # The arc has been saved.
	    debug "Changing SOLID to 1 for $arc_node->[URISTR] ".
	      "IDS $arc_node->[IDS]\n", 3;
	    $arc_node->[SOLID] = 1;

	    # Instead of $arc->obj
	    #
	    my $obj = $self->new($arc_node->[OBJ]);
	    debug "....Checking obj $obj->[NODE][URISTR]\n", 2;
	    $obj->store; # Store the obj if necessary

	    debug "....Stored arc $arc_node->[URISTR]\n", 1;
	}
    }

    # This interface store all the props. Do not continue
    return( 1, 1 );
}


sub store_node
{
    my( $self, $i ) = @_;
    #
    # Store the object in the database

    my $node = $self->[NODE];

    die "Not implemented" if $node->[MULTI];

    # Should we update, create or ignore the node?
    #
    # TODO: Handle other special data
    #
    if( $node->[PRED] or $node->[VALUE] or
	  $node->[LABEL] or $node->[MEMBER] )
    {
	my $p = $node->[PRIVATE]{$i->[ID]} || {};
	my $node_exist = $p->{'id'};
	unless( $node_exist )
	{
	    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};
	    my $sth = $dbh->prepare_cached("
              select id
              from node
              where uri=?
              ");
	    $p->{'uri'} ||= &_get_id($self->[NODE], $i);
	    $sth->execute( $p->{'uri'} );
	    $node_exist = 1 if $sth->rows;
	    $sth->finish;
	}

	if( $node_exist )
	{
	    &_update_node($self, $i);
	}
	else
	{
	    &_create_node($self, $i);
	}
    }
    else
    {
	debug "..The node is neither Literal nor arc!\n", 4;
    }

    # The resource is now stored and SOLID
    #
    debug "Changing SOLID to 1 for $node->[URISTR] ".
      "IDS $node->[IDS]\n", 3;
    $node->[SOLID] = 1;

    return( 1, 1);
}

sub _update_node
{
    my( $self, $i ) = @_;
    # This only updates the node; not the types or properties.  Mainly
    # used to update literals

    # TODO: What shall we do about multipple models?


    my $p = $self->[NODE][PRIVATE]{$i->[ID]} || {};
    my %p = %$p;
    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};


    # TODO: Only do this the first time
    #
    my $field_str = join ", ", map "$_=?",
      @node_fields[1..$#node_fields];

    my $sth = $dbh->prepare_cached(" update node
                                    set $field_str
                                    where uri = ?
                                    and model = ?
                                   ");

    $p{'uri'}         ||= &_get_id( $self->[NODE], $i) or die;
    $p{'iscontainer'} = 'false';
    $p{'isprefix'}    = 'false';
    $p{'label'}       = $self->[NODE][LABEL];
    $p{'aliasfor'}    ||= &_get_id( $self->[NODE][ALIASFOR], $i);
    $p{'pred'}        ||= &_get_id( $self->[NODE][PRED], $i);
    $p{'distr'}       = 'false';
    $p{'subj'}        ||= &_get_id( $self->[NODE][SUBJ], $i);
    $p{'obj'}         ||= &_get_id( $self->[NODE][OBJ], $i);

    # TODO: What should the new model be?
    $p{'model'}       ||= &_get_id( $self->[WMODEL][NODE], $i) or die;

    $p{'member'}      ||= &_get_id( $self->[NODE][MEMBER], $i);

    # TODO: Use isa(literal)
    if( $self->[NODE][VALUE] )
    {
	if( $DEBUG )
	{
	    ref $self->[NODE][VALUE] eq 'SCALAR' or
	      die "Value not a string";
	}

	$p{'isliteral'}   = 'true';
	$p{'lang'}        = undef;
	if( length(${$self->[NODE][VALUE]}) <= 250 )
	{
	    $p{'value'}       = ${$self->[NODE][VALUE]};
	}
	else
	{
	    die "not implemented";
	}
    }
    else
    {
	$p{'isliteral'}   = 'false';
    }


    debug "Updating value to ($p{'value'})\n", 2;
    debug ".. where uri=$p{'uri'} and model=$p{'model'}\n", 2;


    $sth->execute( map $p{$_}, @node_fields[1..$#node_fields],
		   'uri', 'model' )
	or confess( $sth->errstr );

    $self->[NODE][PRIVATE]{$i->[ID]} = \%p;

    return( 1, 3 );
}

sub _create_node
{
    my( $self, $i ) = @_;
    #
    # Stores the object in the database.  The object does not exist
    # before this. All data gets stored in the supplied $model.

    debug "_create_node $self->[NODE][URISTR]\n", 2;

    my $model = $self->[WMODEL][NODE];
    my $node = $self->[NODE];

    # Interface PRIVATE data. These has to be updated then the
    # corresponding official data change. The dependencies could be
    # handled as they are (will be) in RDF::Cache
    #
    my $p = $node->[PRIVATE]{$i->[ID]} || {};
    my %p = %$p;

    debug "Getting DBH for $i->[URISTR] from ".
	"[PRIVATE]{$i->[ID]}{'dbh'}\n", 3;
    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};


    # TODO: Only do this the first time
    #
    my $field_str = join ", ", @node_fields;
    my $place_str = join ", ", ('?')x @node_fields;

    my $sth = $dbh->prepare_cached("  insert into node
				      ($field_str)
				      values ($place_str)
				      ");

    # This is a new node. We know that it doesn't exist yet. Create a
    # new record in the db
    #
    $p{'id'}     ||= &_nextval($dbh) or die;

    # TODO: method calls should be used, i case the attribute hasn't
    # been initialized. $self->pred->private($i, 'id')?  It's possible
    # that the attribute object is stored in several interfaces. We
    # are only intrested in the private id for this interface. We
    # can't make a special method for getting that id, because we
    # can't guarantee that another interface doesn't have the same
    # method.  The private() method could be constructed to access a
    # specific attribute, but that doesn't seem to be much better than
    # just using the _get_id() function.
    #
    # I don't like this repetivity there we get the
    # sth and execute it once for each resource.  How much can we save
    # by group the lookups together?
    #
    # The list below could be shortend if we knew the type of node to
    # create.
    #
    $p{'uri'}         ||= &_create_uri( $node->[URISTR], $i) or die;
    $p{'iscontainer'} = 'false';
    $p{'isprefix'}    = 'false';
    $p{'label'}       = $node->[LABEL];
    $p{'aliasfor'}    ||= &_get_id( $node->[ALIASFOR], $i);
    $p{'pred'}        ||= &_get_id( $node->[PRED], $i);
    $p{'distr'}       = 'false';
    $p{'subj'}        ||= &_get_id( $node->[SUBJ], $i);
    $p{'obj'}         ||= &_get_id( $node->[OBJ], $i);
    $p{'model'}       ||= &_get_id( $model, $i) or die;
    $p{'member'}      ||= &_get_id( $node->[MEMBER], $i);
    if( $node->[VALUE] )
    {
	if( $DEBUG )
	{
	    ref $node->[VALUE] eq 'SCALAR' or
	      die "Value not a string: ( $node->[VALUE] )";
	}

	$p{'isliteral'}   = 'true';
	$p{'lang'}        = undef;
	if( length(${$node->[VALUE]}) <= 250 )
	{
	    $p{'value'}       = ${$node->[VALUE]};
	}
	else
	{
	    die "not implemented";
	}
    }
    else
    {
	$p{'isliteral'}   = 'false';
    }

    debug ".. id: $p{'id'}\n", 1;
    debug "..uri: $p{'uri'}\n", 1;

#    confess "SQL insert node $node->[URISTR]\n" if $DEBUG;

    $node->[PRIVATE]{$i->[ID]} = \%p;

    $sth->execute( map $p{$_}, @node_fields )
	or confess( $sth->errstr );
}

sub _get_node
{
    my( $r_id, $caller, $i ) = @_;
    #
    # find_node_by_interface_node_id


    # TODO: Optimize with a interface id cache

    # Look for the URI in the DB.
    #
    my $dbh = $i->[PRIVATE]{$i->[ID]}{'dbh'};
    my $p = {}; # Interface private data
    my $obj;
    $p->{'id'} = $r_id;

    my $sth = $dbh->prepare_cached("
              select string, refid, refpart, hasalias from uri
              where id=?
              ");
    $sth->execute( $r_id );

    my( $r_uristr, $r_refid, $r_refpart, $r_hasalias );
    $sth->bind_columns(\$r_uristr, \$r_refid, \$r_refpart, \$r_hasalias);
    if( $sth->fetch )
    {
	$obj = $caller->get( $r_uristr );
	$obj->[NODE][PRIVATE]{$i->[ID]} = $p;
    }
    $sth->finish; # Release the handler

    die "couldn't find the resource with record id $r_id" unless $obj;

    return $obj;
}

sub _get_id
{
    return undef unless defined $_[0]; # Common case
    my( $obj_node, $interface ) = @_;
    #
    # The object already exist.  Here we just want to know what id it
    # has in the DB. NB!!! field URI in NODE table.

    if( $DEBUG )
    {
	debug "_get_id( $obj_node->[URISTR] )\n", 2;
	unless( ref $obj_node eq "RDF::Service::Resource" )
	{
	    confess "obj_node $obj_node malformed ";
	}
    }

    # Has the object a known connection to the DB?
    #
    my $p = $obj_node->[PRIVATE]{$interface->[ID]} || {};
    if( defined( my $id = $p->{'uri'}) )
    {
	return $id;
    }


    $obj_node->[URISTR] or die "No URI supplied";

    # Look for the URI in the DB.
    #
    my $dbh = $interface->[PRIVATE]{$interface->[ID]}{'dbh'};

    my $sth = $dbh->prepare_cached("
              select id, refid, refpart, hasalias from uri
              where string=?
              ");
    $sth->execute( $obj_node->[URISTR] );

    my( $r_id, $r_refid, $r_refpart, $r_hasalias );
    $sth->bind_columns(\$r_id, \$r_refid, \$r_refpart, \$r_hasalias);
    if( $sth->fetch )
    {
	$p->{'uri'} = $r_id;
	$sth->finish; # Release the handler

	# TODO: Maby update other data with the result?
	return $r_id;
    }
    else
    {
	$sth->finish; # Release the handler

	# If URI not found in DB:
	#
	# Insert the uri in the DB. The object itself doesn't have to be
	# inserted since it would already be in the DB if this interface
	# handles its storage.

	$p->{'uri'} = &_create_uri( $obj_node->[URISTR], $interface );
	$obj_node->[PRIVATE]{$interface->[ID]} = $p;
	return $p->{'uri'};
    }
}

sub _create_uri
{
    my( $uri, $interface ) = @_;
    #
    # Insert a new URI in the DB.

    debug "_create_uri( $uri )\n", 2;

    # Same as _get_id(), except that we know that the uri doesn't
    # exist in the db. No error checking.

    my $dbh = $interface->[PRIVATE]{$interface->[ID]}{'dbh'};

    my $sth = $dbh->prepare_cached("
                  insert into uri
                  (string, id, hasalias)
                  values (?,?,false)
                  ");
    my $id = &_nextval($dbh, 'uri_id_seq');
    $sth->execute($uri, $id);
    die unless defined $id;

    return $id;
}

sub _nextval
{
    my( $dbh, $seq ) = @_;

    # Values could be collected before they are needed, as to save the
    # lookup time.

    $seq ||= 'node_id_seq';
    my $sth = $dbh->prepare_cached( "select nextval(?)" );
    $sth->execute( $seq );
    my( $id ) = $sth->fetchrow_array;
    $sth->finish;

    $id or die "Failed to get nextval";
}

1;
