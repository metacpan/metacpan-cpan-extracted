package Net::Rexster::Client;

use warnings;
use strict;
use Carp;

use Moose;
use Net::Rexster::Request;

use version; 
our $VERSION = qv('0.0.5');

has 'server' => (is => 'rw', isa => 'Str', default => 'http://localhost:8182');
has 'graph'  => (is => 'rw', isa => 'Str', required => 1);
has 'request' => (is => 'ro', isa => 'Net::Rexster::Request', default => sub { new Net::Rexster::Request } );

__PACKAGE__->meta->make_immutable;
no Moose;

# /graphs
sub get_graphs {
    my ($self) = @_;
    my $uri = $self->server . "/graphs";
    return $self->request->get($uri)->get_graphs;
}

# /graphs/<graph>
sub get_graph {
    my ($self) = @_;
    my $uri = $self->server . "/graphs/" . $self->graph;
    return $self->request->get($uri);
}

# /graphs/<graph>/vertices 
sub get_all_vertices {
    my ($self) = @_;
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices";
    return $self->request->get($uri)->get_results();
}

#/graphs/<graph>/vertices?key=<key>&value=<value>
sub lookup_vertex {
    my ($self, $key, $value) = @_;
    die "key and value are needed\n" if (! defined $key || ! defined $value);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices?key=$key&value=$value";
    return $self->request->get($uri)->get_results();
}

#/graphs/<graph>/vertices/<id>
sub get_vertex {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id;
    return $self->request->get($uri)->get_results();
}

#/graphs/<graph>/vertices/<id>/out
sub outV {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/out";
    return $self->request->get($uri)->get_results();
}

#/graphs/<graph>/vertices/<id>/in
sub inV {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/in";
    return $self->request->get($uri)->get_results();
}

#/graphs/<graph>/vertices/<id>/both
sub bothV {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/both";
    return $self->request->get($uri)->get_results();
}

# /graphs/<graph>/vertices/<id>/outCount
sub outVcount {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/outCount";
    return $self->request->get($uri)->get_totalSize();
}

# /graphs/<graph>/vertices/<id>/inCount
sub inVcount {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/inCount";
    return $self->request->get($uri)->get_totalSize();
}

# /graphs/<graph>/vertices/<id>/bothCount
sub bothVcount {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/bothCount";
    return $self->request->get($uri)->get_totalSize();
}

#/graphs/<graph>/vertices/<id>/outIds
sub outIds{
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/outIds";
    return $self->request->get($uri)->get_results();
}

#/graphs/<graph>/vertices/<id>/inIds
sub inIds{
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/inIds";
    return $self->request->get($uri)->get_results();
}
#/graphs/<graph>/vertices/<id>/bothIds
sub bothIds{
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/bothIds";
    return $self->request->get($uri)->get_results();
}

#/graphs/<graph>/edges
sub get_all_edges {
    my ($self) = @_;
    my $uri = $self->server . "/graphs/" . $self->graph . "/edges";
    return $self->request->get($uri)->get_results();
}

#/graphs/<graph>/edges?key=<key>&value=<value>
sub lookup_edges {
    my ($self, $key, $value) = @_;
    die "key and value are needed\n" if (! defined $key || ! defined $value);
    my $uri = $self->server . "/graphs/" . $self->graph . "/edges?key=$key&value=$value";
    return $self->request->get($uri)->get_results();
}
#/graphs/<graph>/edges/<id>
sub get_edge {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/edges/". $id;
    return $self->request->get($uri)->get_results();
}
#/graphs/<graph>/vertices/<id>/outE
sub outE {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/outE";
    return $self->request->get($uri)->get_results();
}
#/graphs/<graph>/vertices/<id>/inE
sub inE {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/inE";
    return $self->request->get($uri)->get_results();
}
#/graphs/<graph>/vertices/<id>/bothE
sub bothE {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/". $id . "/bothE";
    return $self->request->get($uri)->get_results();
}

#/graphs/<graph>/indices
sub get_indices {
    my ($self) = @_;
    my $uri = $self->server . "/graphs/" . $self->graph . "/indices";
    return $self->request->get($uri)->get_results();
}
#/graphs/<graph>/indices/index?key=<key>&value=<value>
sub lookup_index {
    my ($self, $index, $key, $value) = @_;
    die "index, key and value are needed\n" if (! defined $key || ! defined $value || ! defined $index);
    my $uri = $self->server . "/graphs/" . $self->graph . "/indices/$index?key=$key&value=$value";
    return $self->request->get($uri)->get_results();
}

#/graphs/<graph>/indices/index/count?key=<key>&value=<value>
sub index_count {
    my ($self, $key, $value) = @_;
    die "key and value are needed\n" if (! defined $key || ! defined $value);
    my $uri = $self->server . "/graphs/" . $self->graph . "/indices/index/count?key=$key&value=$value";
    return $self->request->get($uri)->get_totalSize();
}

# Comment out until I figure out how kyeindices is used. 
##/graphs/<graph>/keyindices/
#sub index_keys {
#    my ($self) = @_;
#    my $uri = $self->server . "/graphs/" . $self->graph . "/keyindices";
#    #return $self->request->get($uri)->get_results();
#    return $self->request->get($uri)->get_keys();
#}
#
##/graphs/<graph>/keyindices/vertex
#sub get_vertex_indices {
#    my ($self) = @_;
#    my $uri = $self->server . "/graphs/" . $self->graph . "/keyindices/vertex";
#    return $self->request->get($uri)->get_results();
#}
#
##/graphs/<graph>/keyindices/edge
#sub get_edge_indices {
#    my ($self) = @_;
#    my $uri = $self->server . "/graphs/" . $self->graph . "/keyindices/edge";
#    print $uri;
#    return $self->request->get($uri)->get_results();
#}
#
#/graphs/<graph>/prefixes - only SailGraph. No need to support
#/graphs/<graph>/prefixes/prefix - only SailGraph. No need to support

#======================================================================================
# POST 
#======================================================================================
#/graphs/<graph>/vertices
#/graphs/<graph>/vertices/<id> # <id> may not work. 
sub create_vertex {
    my ($self, $id) = @_;
    $id = "" unless ( defined $id );
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/$id";
    return $self->request->post($uri)->get_results();
}

#/graphs/<graph>/vertices/<id>?<key>=<value>&<key'>=<value'>
sub create_vertex_property {
    my ($self, $id, $params) = @_;

    die "id and parameters are needed\n" if (! defined $id || ! defined $params);
    # $params = { 'age' => 30, 'sex' => 'male'} 
    my $uri_param = $self->_params_to_string($params);
    
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/$id?$uri_param";
    return $self->request->post($uri)->get_results();
}

#/graphs/<graph>/edges?_outV=<id>&_label=friend&_inV=2&<key>=<key'>
#/graphs/<graph>/edges/3?_outV=<id>&_label=friend&_inV=2&<key>=<key'>
sub create_edge {
    my ( $self, $outId, $label, $inId, $params) = @_;
    #param = { name => key, name2 => key2 } 
    die "out-id, label and in-id are needed\n" if (! defined $outId || ! defined $label || ! defined $inId );
    my $uri_param = $self->_params_to_string($params);
    my $uri = $self->server . "/graphs/" . $self->graph . "/edges?_outV=$outId&_label=$label&_inV=$inId&$uri_param";
    return $self->request->post($uri)->get_results();
}

#/graphs/<graph>/edges/3?<key>=<key'>
sub create_edge_property {
    my ($self, $id, $params) = @_;
    die "id and parameters are needed\n" if (! defined $id || ! defined $params);
    # $params = { 'age' => 30, 'sex' => 'male'} 
    my $uri_param = $self->_params_to_string($params);
    my $uri = $self->server . "/graphs/" . $self->graph . "/edges/$id?$uri_param";
    return $self->request->post($uri)->get_results();
}

#/graphs/<graph>/indices/index?class=vertex
sub create_index {
    my ($self, $index) = @_;
    die "index is needed" if ( ! defined $index );
    my $uri = $self->server . "/graphs/" . $self->graph . "/indices/$index?class=vertex";
    return $self->request->post($uri)->get_results();
}

#
# TODO Comment out keyindeces as it's not clear about how it's used 
##/graphs/<graph>/keyindices/vertex/<key>
#sub create_vertex_index {
#    my ($self, $key) = @_;
#    my $uri = $self->server . "/graphs/" . $self->graph . "/keyindices/vertex/$key";
#    return $self->request->post($uri)->get_contents;
#}
##/graphs/<graph>/keyindices/edge/<key>
#sub create_edge_index {
#    my ($self, $key) = @_;
#    my $uri = $self->server . "/graphs/" . $self->graph . "/keyindices/edge/$key";
#    return $self->request->post($uri)->get_contents;
#}

#======================================================================================
# PUT  
#======================================================================================

#/graphs/<graph>/vertices/<id>?<key>=<value>&<key'>=<value'>
sub replace_vertex_property {
    my ($self, $id, $params) = @_;
    die "id and parameters are needed\n" if (! defined $id || ! defined $params);
    my $uri_param = $self->_params_to_string($params);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/$id?$uri_param";
    return $self->request->put($uri)->get_results();
}
#/graphs/<graph>/edges/<id>?<key>=<value>&<key'>=<value'>
sub replace_edge_property {
    my ($self, $id, $params) = @_;
    die "id and parameters are needed\n" if (! defined $id || ! defined $params);
    my $uri_param = $self->_params_to_string($params);
    my $uri = $self->server . "/graphs/" . $self->graph . "/edges/$id?$uri_param";
    return $self->request->put($uri)->get_results();
}
#/graphs/<graph>/indices/index?key=<key>&value=<value>&id=<id>
sub put_vertex_to_index {
    my ($self, $id, $index, $key, $value) = @_;
    die "id, index, key and value are needed\n" if (! defined $id || ! defined $key || ! defined $value || ! defined $index);
    my $uri = $self->server . "/graphs/" 
	. $self->graph . "/indices/$index?key=$key&value=$value&id=$id";
    return $self->request->put($uri);
}

#======================================================================================
# DELETE  : return of each funtion is void
#======================================================================================
#/graphs/<graph>/vertices/<id>
sub delete_vertex {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/$id";
    return $self->request->delete($uri);
}
#/graphs/<graph>/vertices/<id>?<key>&<key'>
sub delete_vertex_property {
    my ($self, $id, $params) = @_;
    die "id and parameters are needed\n" if (! defined $id || ! defined $params);
    my $uri_param = $self->_array_params_to_string($params);
    my $uri = $self->server . "/graphs/" . $self->graph . "/vertices/$id?$uri_param";
    return $self->request->delete($uri);
}
#/graphs/<graph>/edges/<id>
sub delete_edge {
    my ($self, $id) = @_;
    die "id is needed\n" if (! defined $id);
    my $uri = $self->server . "/graphs/" . $self->graph . "/edges/$id";
    return $self->request->delete($uri);
}
#/graphs/<graph>/edges/3?<key>&<key'>
sub delete_edge_property{
    my ($self, $id, $params) = @_;
    die "id and parameters are needed\n" if (! defined $id || ! defined $params);
    my $uri_param = $self->_array_params_to_string($params);
    my $uri = $self->server . "/graphs/" . $self->graph . "/edges/$id?$uri_param";
    return $self->request->delete($uri);
}
#/graphs/<graph>/indices/index
sub delete_index {
    my ($self, $index) = @_;
    die "index is needed\n" if (! defined $index);
    my $uri = $self->server . "/graphs/" . $self->graph . "/indices/$index";
    return $self->request->delete($uri);
}
#/graphs/<graph>/indices/index?key=<key>&value=<value>&class=vertex&id=<id>
sub delete_vertex_from_index {
    my ($self, $id, $index, $key, $value) = @_;
    die "id, index, key and value are needed\n" if (! defined $id || ! defined $key || ! defined $value || ! defined $index);
    my $uri = $self->server . "/graphs/" . $self->graph . "/indices/$index?key=$key&value=$value&class=vertex&id=$id";
    return $self->request->delete($uri);
}

#======================================================================================

# Create a string from hash parameter
sub _params_to_string {
    my ( $self, $params ) = @_;
    my @uri_params;
    for my $param (keys %$params) {
        push @uri_params, $param . "=" . $params->{ $param };  
    }
    return join '&', sort @uri_params;
}

# [ 1 2 3 ] to '1&2&3'
sub _array_params_to_string {
    my ( $self, $array_ref ) = @_;
    return join '&', @$array_ref;
}

# The below yet to be installed 
#/graphs/<graph>/indices/index?key=<key>&value=<value>
#/graphs/<graph>/indices/index/count?key=<key>&value=<value>
#/graphs/<graph>/keyindices/
#/graphs/<graph>/keyindices/vertex
#/graphs/<graph>/keyindices/edge
#/graphs/<graph>/prefixes
#/graphs/<graph>/prefixes/prefix


1; # Magic true value required at end of module

__END__

=head1 NAME

Net::Rexster::Client - Handle Rexster REST request and response 

=head1 VERSION

This document describes Net::Rexster version 0.0.5

=head1 SYNOPSIS

    use Net::Rexster::Client;
    use Data::Dumper;
    
    my $c = new Net::Rexster::Client(graph => "testdb", server => 'http://localhost:8182');
    
    # Create vertices and get the id
    $id1 = $c->create_vertex->{_id};
    $id2 = $c->create_vertex->{_id};
    
    # Add property. 
    $c->create_vertex_property($id1, { 'dateOfBirth' => 'Dec 26' });
    
    # Create edge with label, friend
    $c->create_edge($id1, "friend", $id2);
    
    # See edge and vertices
    print Dumper $c->get_all_edges;
    print Dumper $c->get_all_vertices;
    
    # Delete the vertices
    $c->delete_vertex($id1);
    $c->delete_vertex($id2);


=head1 DESCRIPTION

Rexster(https://github.com/tinkerpop/rexster/wiki) provides REST API for Blueprint graph(e.g. Neo4j, OrientDB..)
This module covers the most of REST in hhttps://github.com/tinkerpop/rexster/wiki/Basic-REST-API
so that REST can be called from Perl. GraphDB server as well as Rexter server need to be up to use this API.

=head1 INTERFACE 

All of the methods defined here return hash reference which converted form JSON response.
As Net::Rexster::Client provides low level interface, please use Data::Dumper to check the contect of data. 

=head2 get_graphs()

get all the graphs

=head2 get_graph($graph_name)

get the graph named 

=head2 get_all_vertices()

get all vertices

=head2 lookup_vertex($key, $value)

get all vertices for a key index given the specified 

=head2 get_vertex($id) 

get vertex with id

=head2 outV($id) 

get the adjacent out vertices of vertex 

=head2 inV($id)

get the adjacent in vertices of vertex

=head2 bothV() 

get the both adjacent in and out vertices of vertex 

=head2 outVcount($id) 

get the number of out vertices of vertex

=head2 inVcount($id) 

get the number of in vertices of vertex 

=head2 bothVcount($id) 

get the number of adjacent in and out vertices of vertex 

=head2 outIds($id)

get the identifiers of out vertices of vertex 

=head2 inIds($id)

get the identifiers of in vertices of vertex

=head2 bothIds($id)

get the identifiers of adjacent in and out vertices of vertex 

=head2 get_all_edges()

get all edges

=head2 lookup_edges($key, $value) 

get all edges for a key index given the specified 

=head2 get_edge($id) 

get edge with id 

=head2 outE($id) 

get the out edges of vertex

=head2 inE($id) 

get the in edges of vertex

=head2 bothE($id) 

get the both in and out edges of vertex

=head2 get_indices() 

get all the indices associated with the graph 

=head2 lookup_index($index, $key, $value) 

get all elements with $key property equal to $value in $index

=head2 index_count($key, $value) 

get a count of all elements with $key property equal to $value in index

=head2 create_vertex($id) 

create a vertex with no specified identifier. Note some graphDB doesn't support the arrument $id.
If it's not supported, the new $id is created automatically by DB server.

=head2 create_vertex_property($id, { $key1 => $value1,,, })

create a vertex with $id and the provided properties (or update vertex properties if vertex already exists). 

=head2 create_edge($id1, $label, $id2) 

create an out edge with no specified identifier from vertex <id> to vertex 2 labeled “friend” with provided properties. 

=head2 create_edge_property($id, {$key1 => $value1,,,}) 

create the properties of the edge with id 

=head2 create_index($index) 

create a new manual index named $index 

=head2 replace_vertex_property($id, {$key1 => $value1,,,}) 

replaces the all existing properties of the vertex $id with those specified 

=head2 replace_edge_property($id, {$key1 => $value1,,,}) 

replaces the all existing properties of the edge $id with those specified 

=head2 put_vertex_to_index($vertex_id, $index, $key, $value) 

put vertex with $id into index at $key/$value

=head2 delete_vertex($id)

remove vertex $id

=head2 delete_vertex_property($id, [$key1,$key2,,,])

remove properties keys from vertex $id

=head2 delete_edge($id) 

remove the edge with $id

=head2 delete_edge_property($id, [$key1,$key2,,,])

remove properties keys from edge

=head2 delete_index($index)

drop the index named $index

=head2 delete_vertex_from_index($id, $index, $key, $value)

remove the vertex $id from $index at $key/$value

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 CONFIGURATION AND ENVIRONMENT

Net::Rexster requires no configuration files or environment variables.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Shohei Kameda  C<< <shoheik@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Shohei Kameda C<< <shoheik@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
