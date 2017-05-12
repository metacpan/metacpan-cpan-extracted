#  $Id: Service.pm,v 1.22 2000/12/21 22:04:18 aigan Exp $  -*-perl-*-

package RDF::Service;

#=====================================================================
#
# DESCRIPTION
#   Creates the Service resource
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
use 5.006;
use RDF::Service::Constants qw( :rdf :namespace :context );
use RDF::Service::Cache qw( get_unique_id uri2id debug debug_start
			    debug_end time_string $DEBUG);
use RDF::Service::Resource;
use RDF::Service::Context;
use Data::Dumper;

our $VERSION = 0.04;

sub new
{
    my( $class, $uristr ) = @_;

    # This will (then implemented) create a session context resource.
    # This resource will hold a orderd list of connected interfaces.
    # A signature will be generated from this order.  Every created
    # object will be marked with this signature.  The object will be
    # cached and can be used again if a object with the same signature
    # is creating the same object.

    # This means that all the objects functions and information is
    # only dependent on the order of the connected interfaces. This
    # also means that for each resource there could be one object for
    # each signature. They are the same resource, but viewed from
    # diffrent contexts, they appear diffrent in regard to the result
    # of queries, etc.

    # Many queries will probably give the same answer for diffrent
    # signatures, but that could not be guaranteed.  This construction
    # is based on the asumption that there will be many agents using
    # the same signature. That is: the same object will be reused more
    # times than not.  For futher optimization, some data could be
    # shared between diffrent objects for the same resource. Data
    # could be marked as static or dynamic and new objects could point
    # to the data for the previous object, if its marked as static.

    # Interfaces connected after the creation of an object will not
    # change the objects signature. The objects signature is a read
    # only value.  The first interface connection parameter is taken
    # to be the URI of the source accessed by the interface. This URI
    # is a part of the signature. (That is, the connection string to a
    # database, or similar.)

    # All context/client-dependent functions should use the session
    # object methods or send it in as a parameter. This construction
    # is a compromise to shorten the method calls in most cases, so
    # that we doesn't have to tag along the context varaible evrywhere
    # and so that we still can reuse the cached resource objects
    # between more than one session.


    # Initialize the level indicator
    $RDF::Service::Cache::Level = 0;

    debug_start("new RDF::Service");

    if( $uristr )
    {
	# Must have a Service URI as recognized by the Base find_node

	my $pattern = "^".NS_LD."/service/[^/#]+\$";
	unless( $uristr =~  m/$pattern/o )
	{
	    die "Invalid namespace for Service: $uristr";
	}
    }
    else
    {
	# Every service object is unique
	#
	$uristr = NS_LD."/service/".&get_unique_id;
    }


    # The service object is not stored in any interface.  The base
    # interface init_types function states that all resources matching
    # a specific pattern are Service objects.  That is needed since
    # the resources acts as models for other models stored in other
    # interfaces.  But here we state the types for the newly created
    # Service object.

    # Declare the types for the service.  Do it the low-level way.  We
    # can not call declare_add_typews() since that calles init_props()
    # for the classes.


    my $so = RDF::Service::Resource->new($uristr);
    $so->[RUNLEVEL] = 0; # Startup runlevel
    my $s = RDF::Service::Context->new( $so, {} );

    &_bootstrap( $s );

    debug_end("new RDF::Service");

    return $s;
}

sub _bootstrap
{
    my( $s ) = @_;
    #
    # Connect the base interface.

    debug "Bootstrap\n", 1;

    my $node = $s->[NODE];

    my $base_model = $s->get_node(NS_LD.'#The_Base_Model');
#    $base_model->[REV_MODEL]{$node->[ID]} = $node;  # Try without...
    $base_model->[TYPE_ALL] = 1;
    debug "Changing SOLID to 1 for $base_model->[URISTR] ".
      "IDS $base_model->[IDS]\n", 3;
    $base_model->[SOLID] = 1; # nonchanging

    $s->[WMODEL] = $s;
    $node->[MODEL] = $base_model;
    $node->[TYPE] = {};
    $node->[INTERFACES] = [];
    debug "Changing SOLID to 0 for $node->[URISTR] ".
      "IDS $node->[IDS]\n", 3;
    $node->[SOLID] = 0;

    my $module = "RDF::Service::Interface::Base::V01";

    my $file = $module;
    $file =~ s!::!/!g;
    $file .= ".pm";
    require "$file";

    {
	no strict 'refs';
#	my $base_interface_uri = &{$module."::_construct_interface_uri"}( $module );
#	my $base_interface = $s->get( $base_interface_uri );

	# NB! The session node is used as the interface.  It will be
	# replaced during the connection.
	#
	debug_start( "connect", 0, $s );
	&{$module."::connect"}( $s, $s->[NODE], $module );
	debug_end( "connect", 0, $s );
    }

    # Node has now been updated
    #
    $node = $s->[NODE];

    # The IDS of $s is now defined; update $s->[WMODEL].  We do not
    # have to do the same thing for $node, since it doesn't is used as
    # an object above.
    #
    $base_model->[IDS] = $node->[IDS];
    $base_model->[JUMPTABLE] = undef;

    # Save node in cache!
    #
#    $RDF::Service::Cache::node->{$node->[IDS]}{ $node->[ID] } = $node;
#    warn "*** Setting cache($s->[IDS], $s->[ID] ) to $s\n";

    # Add the type
    #
    $s->declare_add_types( [NS_LS.'#Service'] );

    $node->[RUNLEVEL] = 1; # Normal runlevel
}


1;

