package Net::GraphSpace::Graph;
use Moose;

use Carp qw(croak);
use JSON qw(decode_json);
use Net::GraphSpace::Edge;
use Net::GraphSpace::Node;
use Net::GraphSpace::Types;

has name        => (is => 'rw', isa => 'Str');
has description => (is => 'rw', isa => 'Str');
has tags        => (is => 'rw', isa => 'ArrayRef');

has _nodes => (
    is => 'rw',
    isa => 'ArrayRef[Net::GraphSpace::Node]',
    default => sub { [] },
);
has _edges      => (
    is => 'rw',
    isa => 'ArrayRef[Net::GraphSpace::Edge]',
    default => sub { [] },
);
has _nodes_map  => (
    is => 'rw',
    isa => 'HashRef[Net::GraphSpace::Node]',
    default => sub { {} },
);

sub add_node {
    my ($self, $node) = @_;
    push @{ $self->_nodes }, $node;
    $self->_nodes_map->{$node->id} = $node;
}

sub add_edge {
    my ($self, $edge) = @_;
    croak "No such node corresponds to the edge's source node " . $edge->source
        unless $self->_nodes_map->{$edge->source};
    croak "No such node corresponds to the edge's target node " . $edge->target
        unless $self->_nodes_map->{$edge->target};
    push @{ $self->_edges }, $edge;
}

sub add_nodes { $_[0]->add_node($_) foreach @{$_[1]} }

sub add_edges { $_[0]->add_edge($_) foreach @{$_[1]} }

sub TO_JSON {
    my ($self) = @_;
    return {
        metadata => {
            map { defined($self->$_) ? ( $_ => $self->$_ ) : () }
                qw(name description tags)
        },
        graph => {
            data => { nodes => $self->_nodes, edges => $self->_edges }
        }
    };
}

sub new_from_http_response {
    my($class, $res) = @_;

    my $data = decode_json($res->content);
    my $metadata = $data->{metadata};
    my $graph = Net::GraphSpace::Graph->new();
    $graph->description($metadata->{description})
        if defined $metadata->{description};
    $graph->tags($metadata->{tags}) if defined $metadata->{tags};

    my $graphdata = $data->{graph}{data};
    for my $node (@{$graphdata->{nodes}}) {
        $graph->add_node(Net::GraphSpace::Node->new(%$node));
    }
    for my $edge (@{$graphdata->{edges}}) {
        $graph->add_edge(Net::GraphSpace::Edge->new(%$edge));
    }

    return $graph;
}


1;

__END__
=pod

=head1 NAME

Net::GraphSpace::Graph

=head1 VERSION

version 0.0009

=head1 SYNOPSIS

    my $graph = Net::GraphSpace::Graph->new(
        description => 'a great graph',
        tags => ['foo', 'bar'],
    );
    my $node1 = Net::GraphSpace::Node->new(id => 'node-a', label => 'A');
    my $node2 = Net::GraphSpace::Node->new(id => 'node-b', label => 'B');
    $graph->add_nodes([$node1, $node2]);
    my $edge = Net::GraphSpace::Edge->new(
        id => 'a-b', source => 'node-a', target => 'node-b');
    $graph->add_edge($edge);
    $graph->add_node(Net::GraphSpace::Node->new(id => 3, label => 'C'));

=head1 DESCRIPTION

Represents a graph in GraphSpace.

=head1 ATTRIBUTES

Optional:

=over

=item description

Graph description. Can contain some html.

=item tags

An arrayref of tag names.

=back

=head1 METHODS

=head2 add_node($node)

=head2 add_nodes(\@nodes)

=head2 add_edge($edge)

=head2 add_edges(\@edges)

=head1 AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

