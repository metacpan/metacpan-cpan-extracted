package POE::Filter::XML::Handler;
{
  $POE::Filter::XML::Handler::VERSION = '1.140700';
}

#ABSTRACT: Default SAX Handler for POE::Filter::XML

use Moose;
use MooseX::NonMoose;

extends 'XML::SAX::Base';

use POE::Filter::XML::Node;


has current_node =>
(
    is => 'rw',
    isa => 'POE::Filter::XML::Node',
    predicate => '_has_current_node',
    clearer => '_clear_current_node'
);


has finished_nodes =>
(
    is => 'ro',
    traits => ['Array'],
    isa => 'ArrayRef',
    default => sub { [] },
    handles =>
    {
        all_finished_nodes => 'elements',
        has_finished_nodes => 'count',
        add_finished_node => 'push',
        get_finished_node => 'shift',
        _clear_finished_nodes => 'clear',
    }
);


has depth_stack =>
(
    is => 'ro',
    traits => ['Array'],
    isa => 'ArrayRef',
    default => sub { [] },
    clearer => '_clear_depth_stack',
    handles =>
    {
        push_depth_stack => 'push',
        pop_depth_stack => 'pop',
        depth => 'count',
    }
);


has not_streaming => ( is => 'ro', isa => 'Bool', default => 0 );


sub reset {
    my ($self) = @_;
    $self->_clear_current_node();
    $self->_clear_finished_nodes();
    $self->_clear_depth_stack();
}


sub start_element {
    my ($self, $data) = @_;
    my $node = POE::Filter::XML::Node->new($data->{'Name'});

    foreach my $attrib (values %{$data->{'Attributes'}})
    {
        $node->setAttribute
        (
            $attrib->{'Name'},
            $attrib->{'Value'}
        );
    }

    if($self->depth() == 0)
    {
        #start of a document
        $self->push_depth_stack($node);

        if($self->not_streaming)
        {
            $self->current_node($node);
        }
        else
        {
            $node->_set_stream_start(1);
            $self->add_finished_node($node);
        }
    }
    else
    {
        # Top level fragment
        $self->push_depth_stack($self->current_node);

        if($self->depth() == 2)
        {
            if($self->not_streaming)
            {
                $self->current_node->appendChild($node);
            }
            $self->current_node($node);
        }
        else
        {
            # Some node within a fragment
            $self->current_node->appendChild($node);
            $self->current_node($node);
        }
    }

    $self->SUPER::start_element($data);
}


sub end_element {
    
    my ($self, $data) = @_;

    if($self->depth() == 1)
    {
        if($self->not_streaming)
        {
            $self->add_finished_node($self->pop_depth_stack());
        }
        else
        {
            my $end = POE::Filter::XML::Node->new($data->{'Name'});
            $end->_set_stream_end(1);
            $self->add_finished_node($end);
        }
    }
    elsif($self->depth() == 2)
    {
        if($self->not_streaming)
        {
            $self->current_node($self->pop_depth_stack());
        }
        else
        {
            $self->add_finished_node($self->current_node);
            $self->_clear_current_node();
            $self->pop_depth_stack();
        }
    }
    else
    {
        $self->current_node($self->pop_depth_stack());
    }

    $self->SUPER::end_element($data);
}


sub characters {

    my ($self, $data) = @_;

    if($self->depth() == 1)
    {
        return;
    }

    $self->current_node->appendText($data->{'Data'});

    $self->SUPER::characters($data);
}

1;



=pod

=head1 NAME

POE::Filter::XML::Handler - Default SAX Handler for POE::Filter::XML

=head1 VERSION

version 1.140700

=head1 DESCRIPTION

POE::Filter::XML::Handler is the default SAX handler for POE::Filter::XML. It
extends XML::SAX::Base to provide different semantics for streaming vs.
non-streaming contexts. This handle by default builds POE::Filter::XML::Nodes.

=head1 PUBLIC_ATTRIBUTES

=head2 not_streaming

    is: ro, isa: Bool, default: false

not_streaming determines the behavior for the opening tag parsed. If what is
being parsed is not a stream, the document will be parsed in full then placed
into the finished_nodes attribute. Otherwise, the opening tag will be placed
immediately into the finished_nodes bucket.

=head1 PRIVATE_ATTRIBUTES

=head2 current_node

    is: rw, isa: POE::Filter::XML::Node

current_node holds the node being immediately parsed.

=head2 finished_nodes

    is: ro, isa: ArrayRef, traits: Array

finished_nodes holds the nodes that have been completely parsed. Access to this
attribute is provided through the following methods:

    handles =>
    {
        all_finished_nodes => 'elements',
        has_finished_nodes => 'count',
        add_finished_node => 'push',
        get_finished_node => 'shift',
    }

=head2 depth_stack

    is: ro, isa: ArrayRef, traits: Array

depth_stack holds the operating stack for the parsed nodes. As nodes are
processed, ancendants of the current node are stored in the stack. When done
they are popped off the stack. Access to this attribute is provided through the
following methods:

    handles =>
    {
        push_depth_stack => 'push',
        pop_depth_stack => 'pop',
        depth => 'count',
    }

=head1 PUBLIC_METHODS

=head2 reset

reset will clear the current node, the finished nodes, and the depth stack.

=head1 PROTECTED_METHODS

=head2 override start_element

    (HashRef $data)

start_element is overriden from the XML::SAX::Base class to provide our custom
behavior for dealing with streaming vs. non-streaming data. It builds Nodes
then attaches them to either the root node (non-streaming) or as stand-alone
top level fragments (streaming) sets them to the current node. Children nodes
are appended to their parents before getting set as the current node. Then the
base class method is called via super()

=head2 override end_element

    (HashRef $data)

end_element is overriden from the XML::SAX::Base class to provide our custom
behavior for dealing with streaming vs. non-streaming data. Mostly this method
is in charge of stack management when the depth of the stack reaches certain
points. In streaming documents, this means that top level fragments (not root)
are popped off the stack and added to the finished_nodes collection. Otherwise
a Node is created with stream_end set and added to the finished nodes.

Then the base class method is called via super()

=head2 override characters

    (HashRef $data)

characters merely applies the character data as text to the current node being
processed. It then calls the base class method via super().

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

