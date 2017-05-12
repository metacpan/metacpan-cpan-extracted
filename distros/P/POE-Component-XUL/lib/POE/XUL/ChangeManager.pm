package POE::XUL::ChangeManager;

use strict;
use warnings;
use Carp;
use Aspect;
use XUL::Node;
use XUL::Node::State;

# creating --------------------------------------------------------------------

# windows is list of all top level nodes
# destroyed is buffer of all states scheduled for destruction on next flush
# next_node_id is next available node ID - 1
sub new {
	my $class = shift;
	bless { windows => [], destroyed => [], next_node_id => 0 }, $class
}

# public interface for sessions -----------------------------------------------

sub run_and_flush {
	my ($self, $code) = (shift,shift);
	local $_;
	$code->($self,@_);
	my $out =	(join '', map { $self->flush_node($_) } @{$self->windows}).
				(join '', map { $_->flush } @{$self->{destroyed}});
	$self->{destroyed} = [];
	return $out;
}

sub destroy {
	my $self = shift;
	$_->destroy for @{$self->{windows}};
	delete $self->{windows};
}

# advice ----------------------------------------------------------------------

my $Self_Flow = cflow source => __PACKAGE__.'::run_and_flush';

# when node changed register change on state
# if it has no state, give it one, give it an id, register the node, and
# register the node as a window if node is_window
after {
	my $context = shift;
	my $self    = $context->source->self;
	my $node    = $context->self;
	my $key     = $context->params->[1];
	my $value   = $context->params->[2];
	my $state   = $self->node_state($node);

	unless ($state) {
		push @{$self->windows}, $node if $node->is_window;
		$state = XUL::Node::State->new;
		my $id = 'E'. ++$self->{next_node_id};
		$state->set_id($id);
		$self->node_state($node, $state);
		$self->event_manager->register_node($id, $node)
			if $self->event_manager;
	}

	if ($key eq 'tag') { $state->set_tag($value) }
	else               { $state->set_attribute($key, $value) }

} call 'XUL::Node::set_attribute' & $Self_Flow;

# when node added, set parent node state id on child node state
before {
	my $context     = shift;
	my $self        = $context->source->self;
	my $parent      = $context->self;
	my $child       = $context->params->[1];
	my $index       = $context->params->[2];
	my $child_state = $self->node_state($child);
	$child_state->set_parent_id($self->node_state($parent)->get_id);
	$child_state->set_index($index);
} call 'XUL::Node::_add_child_at_index' & $Self_Flow;

# when node destroyed, update state using set_destoyed
before {
	my $context     = shift;
	my $self        = $context->source->self;
	my $parent      = $context->self;
	my $child       = $parent->_compute_child_and_index($context->params->[1]);
	my $child_state = $self->node_state($child);
	$child_state->set_destroyed;
	push @{$self->{destroyed}}, $child_state;
} call 'XUL::Node::remove_child' & $Self_Flow;

# private ---------------------------------------------------------------------

sub flush_node {
	my ($self, $node) = @_;
	my $out = $self->node_state($node)->flush;
	$out .= $self->flush_node($_) for $node->children;
	return $out;
}

sub node_state {
	my ($self, $node, $state) = @_;
	croak "not a node: [$node]" unless UNIVERSAL::isa($node, 'XUL::Node');
	return $node->{state} unless $state;
	$node->{state} = $state;
}

sub event_manager {
	my ($self, $event_manager) = @_;
	return $self->{event_manager} unless $event_manager;
	$self->{event_manager} = $event_manager;
}

# testing ---------------------------------------------------------------------

sub windows { shift->{windows} }

1;

