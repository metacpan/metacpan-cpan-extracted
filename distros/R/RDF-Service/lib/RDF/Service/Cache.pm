#  $Id: Cache.pm,v 1.19 2000/12/21 22:04:18 aigan Exp $  -*-perl-*-

package RDF::Service::Cache;

#=====================================================================
#
# DESCRIPTION
#   Exports access functions to cached data
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
use vars qw( $uri2id $id2uri $ids @EXPORT_OK %EXPORT_TAGS $create_cnt
	     $create_time $prefixlist $node %fc );
use RDF::Service::Constants qw( :all );
use Carp;

our $DEBUG = 3;
our $Level = 0;
our @Level_stack = ();

{
    # If the hash and array gets to large, they should be tied to a
    # dbm database.

    # These id's are internal and can be used for diffrent uri's if
    # the server is restarted. They should not be used to store data
    # in interfaces, such as the standard DBI interface.

    # %fc is the function counter.  Used for debugging

    $uri2id = {};
    $id2uri = [undef]; #First slot reserved

    $prefixlist = {};

    $ids =
    {
     '' => [],
    };

    $create_time = 0;

    my @ALL = qw( uri2id id2uri save_ids interfaces get_unique_id
		  list_prefixes debug $Level $DEBUG debug_start
		  debug_end expire time_string validate_context
		  reset_level);

    @EXPORT_OK = ( @ALL );
    %EXPORT_TAGS = ( 'all'        => [@ALL],
		     );
}

sub debug
{
    my( $msg, $verbose ) = @_;
    $verbose ||= 0;

    if( $verbose <= $DEBUG )
    {
	$msg =~ s/^/'|  'x$Level/gem;
	warn( $msg );
    }
}

sub reset_level
{
    $Level = 0;
    @Level_stack = ();

    warn "\n**** Error Exception ****\n\n" if $DEBUG;
    return "";
}

sub debug_start
{
    my( $call, $no, $res ) = @_;
    die "Nesting too deep. Bailing out!\n" if $Level >= 50;
    $Level++;
    return unless $DEBUG;


    $no = ' ' unless defined $no;
    $fc{$call}++;
    my $msg = '|  'x($Level-1);
    $msg .= "/-- $no $call       $fc{$call}\n";
    warn $msg;
    push @Level_stack, $call;
    if( $res )
    {
	my $ids = $res->[NODE][IDS];
	debug( $res->[NODE][URISTR]." IDS $res->[NODE][IDS]\n", 1);
	debug( "W: $res->[WMODEL][NODE][URISTR] ".
	       "IDS $res->[WMODEL][NODE][IDS]\n", 2);
	confess "IDS mismatch" if $ids ne $res->[WMODEL][NODE][IDS];
	if( $res->[NODE][MODEL] )
	{
	    debug( "M: $res->[NODE][MODEL][URISTR] ".
		     "IDS $res->[NODE][MODEL][IDS]\n", 2);
	    confess "IDS mismatch" if $ids ne $res->[NODE][MODEL][IDS];
	}

	validate_context( $res ) if $DEBUG >= 4;
    }
}

sub validate_context
{
    my( $context ) = @_;

    unless( ref $context eq 'RDF::Service::Context' )
    {
	confess "The res ($context) should be a context";
    }

    unless( ref($context->[HISTORY]) eq 'ARRAY' )
    {
	confess "Malformed HISTORY: $context->[HISTORY]";
    }

    $context->[WMODEL] or confess "WMODEL missing";
    $context->[NODE] or confess "NODE missing";

    debug "*** Validating $context->[NODE][URISTR] ".
      "IDS $context->[NODE][IDS]\n";

    validate_node( $context->[WMODEL],
		 {
		  expect =>
		{
		 types => [NS_LS.'#Model'],
		 props => [NS_LS.'#updated'],
		}
		 }
		 );

    validate_node( $context );

    debug "*** Done\n";
}

sub validate_node
{
    my( $self, $arg ) = @_;

    my $node = $self->[NODE];

    ref $node eq 'RDF::Service::Resource'
      or confess "The node ($node) is not a Resource";

    my $uri = $node->[URISTR] or confess "URISTR missing";

    defined $node->[RUNLEVEL] or confess "RUNLEVEL undefined";
    $node->[IDS] or confess "IDS missing" if $node->[RUNLEVEL];
    $node->[ID] or confess "ID missing";
    uri2id( $uri ) eq $node->[ID] or confess "Wrong ID";
    id2uri( $node->[ID] ) eq $uri or confess "Wrong URI";

    validate_type($self,
		{ target => TYPE,
		  expect => $arg->{'expect'}{'types'},
		}) if $node->[TYPE];
    validate_type($self, {target => REV_TYPE} ) if $node->[REV_TYPE];

    if( $node->[MODEL] )
    {
	ref $node->[MODEL] eq 'RDF::Service::Resource'
	  or confess "Bad model ($node->[MODEL])";
	my $model_res = $self->get_context_by_id( $node->[MODEL][ID] );
	my $model = $model_res->[NODE];
	if( $model->[URISTR] ne NS_LD.'#The_Base_Model' )
	{
	    $model_res->could_be_a(NS_LS.'#Model')
	      or confess "The model ($model->[URISTR]) ".
		"is not a Model";
	$node->[MODEL][REV_MODEL]{$node->[ID]}
	  or confess "Res ($uri IDS $node->[IDS]) is missing from ".
	    "model $node->[MODEL][URISTR] IDS $node->[MODEL][IDS]";
	}
    }

    validate_pred( $self ) if @{$node->[REV_PRED]};
    validate_prop( $self, {target => REV_SUBJ} ) if $node->[REV_SUBJ];
    validate_prop( $self, {target => REV_OBJ } ) if $node->[REV_OBJ];
    validate_arc(  $self ) if $node->[PRED];
    validate_model($self ) if $self->is_known_as_a( NS_LS.'#Model' );
}

sub validate_type
{
    my( $self, $arg ) = @_;

    my( $rel, $rev, $rel_all, $rel_name, $rev_name );
    if( not defined $arg->{'target'} or $arg->{'target'} == TYPE )
    {
	$rel = $self->[NODE][TYPE];
	$rel_name = 'TYPE';
	$rev_name = 'REV_TYPE';
	$rev = REV_TYPE;
	$rel_all = TYPE_ALL;
    }
    elsif( $arg->{'target'} == REV_TYPE )
    {
	$rel = $self->[NODE][REV_TYPE];
	$rel_name = 'REV_TYPE';
	$rev_name = 'TYPE';
	$rev = TYPE;
	$rel_all = REV_TYPE_ALL;
    }
    else
    {
	confess "Wrong argument 'target': $arg->{'target'}";
    }

    return if $self->[NODE][URISTR] eq NS_RDFS.'Resource';

    ref $rel eq 'HASH' or confess "Type ($rel) should be a hashref";

    my( %expect ) = map { uri2id($_), 0  } @{$arg->{'expect'}};
    my $node_id = $self->[NODE][ID];

    debug "Validating $rel_name $self->[NODE][URISTR]\n", 6;
    my $found_resource = 0;
    foreach my $res_id ( keys %$rel )
    {
	$res_id =~ /^\d+$/
	  or confess "Res key ($res_id) should be a number";

	my $res = $self->get_context_by_id( $res_id );
	my $uri = $res->[NODE][URISTR] or confess "Shit";

	if( $rev == REV_TYPE )
	{
	    $res->could_be_a(NS_RDFS.'Class')
	      or confess "The type ($uri) is not a class";
	}

	debug "  Checking type $uri\n", 6;
	if( $uri eq NS_RDFS.'Resource' )
	{
	    debug "    Setting found_resource to 1\n", 6;
	    $found_resource ++;
	}

	ref $rel->{$res_id} eq "HASH"
	  or confess "Value for $uri should be a hashref";
	keys( %{$rel->{$res_id}} )
	  or confess "$rel_name for $self->[NODE][URISTR] is $uri, ".
	    "but that's false. No model has that. --";

	foreach my $model_id ( keys %{$rel->{$res_id}} )
	{
	    $model_id =~ /^\d+$/
	      or confess "The model key ($model_id)".
		" for $uri should be a number";

	    my $model_res = $self->get_context_by_id( $model_id );
	    my $model = $model_res->[NODE];

	    if( $model->[URISTR] ne NS_LD.'#The_Base_Model' )
	    {
		$model_res->could_be_a(NS_LS.'#Model')
		  or confess "The model ($model->[URISTR]) ".
		    "is not a Model";
	    }

	    if( my $state =  $rel->{$res_id}{$model_id} )
	    {
		$state =~ /^[12]$/
		  or confess "The value of type ($uri) ".
		    "can only be 1 or 2";
	    }

	    unless( $res->[NODE][$rev]{$node_id}{$model_id} )
	    {
		unless( $uri eq NS_RDFS.'Resource' )
		{
		    my $rel_uri = $self->[NODE][URISTR];
		    my $rev_uri = $uri;
		    my $model_uri = $model->[URISTR];
		    my $explain = "\nIn the model $model_uri ".
		      "(IDS : $model->[IDS])\n";
		    $explain .= "$rel_uri is $self->[NODE] ".
		      "with IDS $self->[NODE][IDS]\n";
		    $explain .= "$rev_uri is $res->[NODE] ".
		      "with IDS $res->[NODE][IDS]\n";
		    $explain .= "$rel_uri --$rel_name--> $rev_uri exists\n";
		    $explain .= "$rev_uri --$rev_name--> $rel_uri missing\n";
		    confess $explain ."--";
		}
	    }
	}

	$expect{$res_id}++;

    }

    if( $self->[NODE][$rel_all] )
    {
	if( $rev == REV_TYPE )
	{
	    $found_resource or confess "A defined TYPE should ".
	      "at least include Resource:\n".
		$self->types_as_string . "--";
	}
	foreach my $type_id ( keys %expect )
	{
	    unless( $expect{$type_id} )
	    {
		my $uri = id2uri( $type_id );
		confess "Type $uri expected but not found ".
		  "for $self->[NODE][URISTR]:\n".
		    $self->types_as_string . "--";
	    }
	}
    }
}

sub validate_pred
{
    my( $self, $arg ) = @_;

    my $node = $self->[NODE];

    ref $node->[REV_PRED] eq "ARRAY"
      or confess "REV_SUBJ should be an array ref";

    foreach my $arc_node ( @{$node->[REV_PRED]} )
    {
	my $arc = $self->get_context_by_id( $arc_node->[ID] );

#	warn "*** REV_PRED $arc_node->[URISTR]\n";

	$arc->could_be_a( NS_RDF.'Statement' )
	  or confess "The arc ($arc_node->[URISTR]) ".
	    "should be a Statement";

	$arc_node->[PRED][ID] == $node->[ID]
	  or confess "The REV_PRED was not met by ".
	    "the arc ($arc_node->[URISTR])";
    }

    $self->could_be_a( NS_RDF.'Property' )
      or confess "The node ($node->[URISTR]) should ".
	"be a Property";

}

sub validate_prop
{
    my( $self, $arg ) = @_;

    my( $rel, $rel_name, $rev );
    if( not defined $arg->{'target'} or $arg->{'target'} == REV_SUBJ )
    {
	$rel = REV_SUBJ;
	$rel_name = 'REV_SUBJ';
	$rev = SUBJ;
    }
    elsif( $arg->{'target'} == REV_OBJ )
    {
	$rel = REV_OBJ;
	$rel_name = 'REV_OBJ';
	$rev = OBJ;
    }
    else
    {
	confess "Wrong argument 'target': $arg->{'target'}";
    }

    my $node = $self->[NODE];
    ref $node->[$rel] eq 'HASH'
      or confess "Var ($node->[$rel]) should be a hashref";

    my( %expect ) = map { uri2id($_), 0  } @{$arg->{'expect'}};

    foreach my $pred_id ( keys %{$node->[$rel]} )
    {
	$pred_id =~ /^\d+$/
	  or confess "The Pred key ($pred_id) should be a number";

	my $pred = $self->get_context_by_id( $pred_id );
	my $uri = $pred->[NODE][URISTR] or confess "Shit";

	$pred->could_be_a(NS_RDF.'Property')
	  or confess "The Res ($uri) should be a Property";

	ref $node->[$rel]{$pred_id} eq "ARRAY"
	  or confess "Value for $uri should be an array ref";
	@{$node->[$rel]{$pred_id}}
	  or confess "$rel_name $uri should not be empty";

	foreach my $arc_node ( @{$node->[$rel]{$pred_id}} )
	{
	    my $arc = $self->get_context_by_id( $arc_node->[ID] );

	    $arc->could_be_a( NS_RDF.'Statement' )
	      or confess "The res ($arc_node->[URISTR] ".
		"IDS $arc_node->[IDS]) ".
		  "should be a Statement";

	    $arc_node->[$rev][ID] == $node->[ID]
	      or confess "The pred $pred->[NODE][URISTR] was ".
		"not met by the arc ($arc_node->[URISTR])";
	}

	$expect{$pred_id}++;
    }

    foreach my $pred_id ( keys %expect )
    {
	unless( $expect{$pred_id} )
	{
	    my $uri = id2uri( $pred_id );
	    confess "Pred $uri expected but not found";
	}
    }
}

sub validate_arc
{
    my( $self, $arg ) = @_;

    my $node = $self->[NODE];

    $self->could_be_a( NS_RDF.'Statement' )
      or confess "The arc ($node->[URISTR] IDS $node->[IDS]) ".
	"should be a Statement";

    my $explain = "   P $node->[PRED][URISTR] IDS $node->[PRED][IDS]\n";
    $explain .= "   S $node->[SUBJ][URISTR] IDS $node->[SUBJ][IDS]\n";
    $explain .= "   O $node->[OBJ][URISTR] IDS $node->[OBJ][IDS]\n";
    $explain .= "   M $node->[MODEL][URISTR] IDS $node->[MODEL][IDS]\n";
    $explain .= "   A $node->[URISTR] IDS $node->[IDS]\n";
    $explain .= "   SOLID $node->[SOLID]\n";

    my $found = 0;
    foreach my $arc_node ( @{$node->[PRED][REV_PRED]} )
    {
	$found ++ if $arc_node->[ID] == $node->[ID]
    }
    $found or confess "$explain  The pred $node->[PRED][URISTR] ".
      "did not meet up with REV_PRED";

    my $model_id = $node->[MODEL][ID];
    my $pred_id = $node->[PRED][ID];

    # This only checks if there is any subj pointing with the same
    # pred
    #
    $node->[SUBJ][REV_SUBJ]{$pred_id}
      or confess "$explain  SUBJ was not met by a REV_SUBJ";

    $node->[OBJ][REV_OBJ]{$pred_id}
      or confess "$explain  OBJ was not met by a REV_OBJ";
}

sub validate_model
{
    my( $self, $arg ) = @_;
    #
    # NB! The model include this node in REV_MODEL if it self or any
    # of its types belongs to the model.  But the node includes the
    # model only if int's internal data belongs to that model.

    return;

    my $node = $self->[NODE];
    foreach my $res_id ( keys %{$node->[REV_MODEL]} )
    {
	my $res = $self->get_context_by_id($res_id);
	my $res_node = $res->[NODE];

	unless( $res_node->[MODEL] )
	{
	    confess "Res ($res_node->[URISTR]) model ".
	      "should be defined ".
		"and point to the model ($node->[URISTR])\n";
	}

	unless( $res_node->[MODEL][ID] == $node->[ID] )
	{
	    my $explain = "The res ($res_node->[URISTR]) should belong ".
	      "to this model\n";
	    $explain .= "$res_node->[URISTR] is $res_node ".
	      "with IDS $res_node->[IDS]\n";
	    $explain .= "Types for $node->[URISTR]:\n";
	    $explain .= $self->types_as_string;
	    confess $explain ."--";
	}
    }
}

sub debug_end
{
    my( $call, $no, $res ) = @_;
    if( $DEBUG >= 4 and $res )
    {
	validate_context( $res );
    }
    $Level--;
    return unless $DEBUG;

    $no = ' ' unless defined $no;

    my $in_call = pop @Level_stack;

    my $msg = '|  'x$Level;
    $msg .= "\\__ $no $call\n";
    warn $msg;

    if( $in_call ne $call )
    {
	warn "*** call mismatch ***\n";
	confess "Call mismatch. End call should be '$in_call' ";
    }
}

sub uri2id
{# TODO: Define constnats for the most common nodes


    # $_[0] is the uri. (How much faster is this?)

    confess unless defined $_[0];

    # Todo: Normalize the uri and consider aliases
    #
    my $id = $uri2id->{$_[0]};
    return $id if defined $id;

    $id = $#$id2uri+1; #No threads here!

    $id2uri->[$id] = $_[0];
    $uri2id->{$_[0]} = $id;

    return $id;
}

sub id2uri
{
    if( $DEBUG )
    {
	confess "Not a number ( $_[0] )" unless $_[0] =~ /^\d+$/;
    }
    return $id2uri->[$_[0]];
}

sub time_string
{
    # NB! Don't call this as &time_string, since that reuses the old
    # @_

    use Time::Object;
    return localtime( $_[0] || time )->strftime('%Y-%m-%d %H:%M:%S');
}


sub save_ids
{
    # $_[0] is the new IDS
    # $_[1] is a ref to array of interface objects
    $ids->{$_[0]} = $_[1];
}

sub interfaces
{
    # Return ref to array of inteface object

#    carp "*** interfaces @{$ids->{$_[0]}} ***\n";
    return $ids->{$_[0]} or die "IDS $_[0] does not exist\n";
}

sub get_unique_id
{
    # Return a unique id.  This depends on
    # usage in a ns owned by the server process. I.e: only one process
    # allowed, unless combined with the PID.

    # Remember the number of objects created this second
    #
    my $time = time;
    if( $time != $create_time )
    {
	$create_time = $time;
	$create_cnt = 1;
    }
    else
    {
	$create_cnt++;
    }

    # Normally not more than 1000 objects created per second
    #
    use POSIX qw( strftime );
    return strftime( "%Y%m%dT%H%M%S", localtime($time)).
	sprintf('-%.3d', $create_cnt);
}

sub list_prefixes
{
    my( $ids ) = @_;

    debug "Creating a prefixlist for IDS $ids\n", 2;

    return @{ $prefixlist->{$ids} ||= [sort {length($b) <=> length($a)}
				       map( keys %{$_->[MODULE_REG]},
					    @{interfaces($ids)}),'' ] };
}

1;
