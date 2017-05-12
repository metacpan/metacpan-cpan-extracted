package Net::GraphSpace::Node;
use Moose;

use Net::GraphSpace::Types;

with 'Net::GraphSpace::AttributesToJSON';

has id    => (is => 'ro', isa => 'Str', required => 1);
has label => (is => 'rw', isa => 'Str');
has popup => (is => 'rw', isa => 'Str');
has color => (is => 'rw', isa => 'Str');
has size  => (is => 'rw', isa => 'Str');
has shape => (is => 'rw', isa => 'Str');
has graph_id        => (is => 'rw', isa => 'Str');
has borderWidth     => (is => 'rw', isa => 'Num');
has labelFontWeight => (is => 'rw', isa => 'LabelFontWeight');


1;

__END__
=pod

=head1 NAME

Net::GraphSpace::Node

=head1 VERSION

version 0.0009

=head1 SYNOPSIS

    my $node = Net::GraphSpace::Node->new(
        id    => 'node-a', # Required
        label => 'Node A',
        popup => 'stuff that goes in the popup window',
        color => '#FF0000',
        size  => 'auto',
        shape => 'RECTANGLE',
        graph_id        => 'graph22',
        borderWidth     => 2.5,
        labelFontWeight => 'bold',
    );

=head1 DESCRIPTION

Represents a node in a GraphSpace graph.

=head1 ATTRIBUTES

Required:

=over

=item id

A string id unique amonge all nodes.

=back

Optional:

=over

=item label

The node label.

=item popup

Stuff that goes in the popup window.
Currently, this can contain some html.

=item color

The node color in hex format. Examples: '#F00', '#F2F2F2'

=item size

The node size.
If set to 'auto', the node is automatically sized to fit the label.
Examples: 42, 10.5, 'auto'

=item shape   

The shape of the node.
See L<http://cytoscapeweb.cytoscape.org/documentation/shapes>
for possible values.

=item graph_id

The id of a related graph. Example: 'graph42'

=item borderWidth

The width of the node border. Example: 2.5

=item labelFontWeight

Can be set to 'normal' or 'bold'.

=back

=head1 SEE ALSO

L<http://cytoscapeweb.cytoscape.org/documentation>

=head1 AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

