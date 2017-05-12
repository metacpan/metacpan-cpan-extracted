#  $Id: Resource.pm,v 1.22 2000/12/21 20:07:48 aigan Exp $  -*-perl-*-

package RDF::Service::Resource;

#=====================================================================
#
# DESCRIPTION
#   The main Resource class. Implement actions accessable by all
#   resources
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
use RDF::Service::Dispatcher;
use RDF::Service::Constants qw( :all );
use RDF::Service::Cache qw( interfaces uri2id list_prefixes
			    get_unique_id id2uri debug $DEBUG ); #);
use Data::Dumper;
use Carp qw( cluck confess croak carp );


sub new_by_id
{
    return new($_[0], undef, $_[1]);
}

sub new_with_ids
{
    return new($_[0], undef, undef, $_[1]);
}

sub new
{
    my( $proto, $uri, $id, $ids ) = @_;

    # This constructor shouls only be called from get_node, which
    # could be called from find_node or create_node.  get_node will
    # first look in the cache for this resource.

    my $class = ref($proto) || $proto;
    my $self = bless [], $class;



    $self->[IDS] = ''; # This should only be used in the bootstrap
    # TODO: Use bootstrap mode for allow this

    if( ref($proto) )
    {
	if( $DEBUG )
	{
	    if( ref $proto ne 'RDF::Service::Resource')
	    {
		confess "The proto $proto is of wrong type";
	    }
	}

	$self->[IDS] = $proto->[IDS];
    }

    if( $ids )
    {
	$self->[IDS] = $ids;
    }

    if( $uri )
    {
	$self->[URISTR] = $uri or die "No URI for $self";
	$self->[ID] = uri2id( $self->[URISTR] );
    }
    elsif( $id )
    {
	$self->[URISTR] = id2uri($id);
	$self->[ID] = $id;
    }
    else
    {
	$self->[ID] = $proto->[ID];
	$self->[URISTR] = $proto->[URISTR];
    }

    $self->[TYPE] = {};
    $self->[TYPE_ALL] = undef;
    $self->[REV_TYPE] = {};
    $self->[REV_TYPE_ALL] = undef;
    $self->[REV_PRED] = [];
    $self->[REV_PRED_ALL] = undef;
    $self->[REV_SUBJ] = {};
    $self->[REV_SUBJ_ALL] = undef;
    $self->[REV_OBJ] = {};
    $self->[REV_OBJ_ALL] = undef;

    debug "Changing SOLID to 0 for $self->[URISTR] ".
      "IDS $self->[IDS]\n", 3;
    $self->[SOLID] = 0;

    $self->[JUMPTABLE] = undef;

    $self->[NS] = undef;
    $self->[NAME] = undef;
    $self->[LABEL] = undef;

    $self->[PRIVATE] = {};
    $self->[MODEL] = undef;

    $self->[ALIASFOR] = undef;

    $self->[JTK] = "--no value--";

    $self->[RUNLEVEL] = 1;

    return $self;
}



sub find_prefix_id
{
    my( $self ) = @_;
    #
    # Return the longest prefix in the interface jumptables matching
    # the URI.

#    cluck " *** find_prefix_id *** \n";

    debug "Finding prefix_id for $self->[URISTR]\n", 2;
    foreach my $prefix ( &list_prefixes($self->[IDS]) )
    {
	debug "..Checking $prefix\n", 2;
	if( $self->[URISTR] =~ /^\Q$prefix/ )
	{
	    debug "....Done!\n", 2;
	    return uri2id($prefix);
	}
    }

    die "Prefixlist failed to return at least ''\n";
}


1;


__END__
