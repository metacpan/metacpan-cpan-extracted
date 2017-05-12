package Pod::Abstract::Node;
use strict;
use warnings;

use Pod::Abstract::Tree;
use Pod::Abstract::Serial;

use Scalar::Util qw(weaken);

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Node - Pod Document Node.

=head1 SYNOPSIS

 $node->nest( @list );          # Nests list as children of $node. If they
                                # exist in a tree they will be detached.
 $node->clear;                  # Remove (detach) all children of $node
 $node->hoist;                  # Append all children of $node after $node.
 $node->detach;                 # Detaches intact subtree from parent
 $node->select( $path_exp );    # Selects the path expression under $node
 $node->select_into( $target, $path_exp );
                                # Selects into the children of the
                                # target node.  (copies)

 $node->insert_before($target); # Inserts $node in $target's tree
                                # before $target
 $node->insert_after($target);

 $node->push($target);          # Appends $target at the end of this node
 $node->unshift($target);       # Prepends $target at the start of this node

 $node->path();                 # List of nodes leading to this one
 $node->children();             # All direct child nodes of this one
 $node->next();                 # Following sibling if present
 $node->previous();             # Preceding sibling if present

 $node->duplicate();            # Duplicate node and children in a new tree.

 $node->pod;                    # Convert node back into literal POD
 $node->ptree;                  # Show visual (abbreviated) parse tree

=head1 METHODS

=for sorting

=cut

=head2 new

 my $node = Pod::Abstract::Node->new(
    type => ':text', body => 'Some text',
 );

Creates a new, unattached Node object. This is NOT the recommended way
to make nodes to add to a document, use Pod::Abstract::BuildNode for
that. There are specific rules about how data must be set up for these
nodes, and C<new> lets you ignore them.

Apart from type and body, all other hash arguments will be converted
into "params", which may be internal data or node attributes.

Type may be:

=over

=item *

A plain word, which is taken to be a command name.

=item *

C<:paragraph>, C<:text>, C<:verbatim> or <:X> (where X is an inline
format letter). These will be treated as you would expect.

=item *

C<#cut>, meaning this is literal, non-pod text.

=back

Note that these do not guarantee the resulting document structure will
match your types - types are derived from the document, not the other
way around. If your types do not match your document they will mutate
when it is reloaded.

See L<Pod::Abstract::BuildNode> if you want to make nodes easily for
creating/modifying a document tree.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $type = $args{type};
    my $body = $args{body};
    delete $args{type};
    delete $args{body};
    
    my $self = bless {
        tree => Pod::Abstract::Tree->new(),
        serial => Pod::Abstract::Serial->next,
        parent => undef,
        type => $type,
        body => $body,
        params => { %args },
    }, $class;
    
    return $self;
}

=head2 ptree

 print $n->ptree;

Produces a formatted, readable, parse tree. Shows node types, nesting
structure, abbreviated text. Does NOT show all information, but shows
enough to help debug parsing/traversal problems.

=cut

sub ptree {
    my $self = shift;
    my $indent = shift || 0;
    my $width = 72 - $indent;
    
    my $type = $self->type;
    my $body = $self->body;
    if(my $body_attr = $self->param('body_attr')) {
        $body = $self->param($body_attr)->pod;
    }
    $body =~ s/[\n\t]//g if $body;
    
    my $r = ' ' x $indent;
    if($body) {
        $r .= substr("[$type] $body",0,$width);
    } else {
        $r .= "[$type]";
    }
    $r = sprintf("%3d %s",$self->serial, $r);
    $r .= "\n";
    my @children = $self->children;
    foreach my $c (@children) {
        $r .= $c->ptree($indent + 2);
    }
    return $r;
}

=head2 text

 print $n->text;

Returns the text subnodes only of the given node, concatenated
together - i,e, the text only with no formatting at all.

=cut

my %escapes = (
    'gt'     => '>',
    'lt'     => '<',
    'sol'    => '/',
    'verbar' => '|',
    );

sub text {
    my $self = shift;
    
    my $r = '';
    my $type = $self->type;
    my $body = $self->body;
    
    my @children = $self->children;
    if($type eq ':text') {
	    $r .= $body;
    } elsif( $type eq ':E' ) {
        my $code = '';
        foreach my $c (@children) {
            $code .= $c->text;
        }
        if($escapes{$code}) {
            $r .= $escapes{$code};
        }
        return $r;
    }
    
    foreach my $c (@children) {
        $r .= $c->text;
    }
    
    return $r;
}

=head2 pod

 print $n->pod;

Returns the node (and all subnodes) formatted as POD. A newly loaded
node should produce the original POD text when pod is requested.

=cut

sub pod {
    my $self = shift;
    
    my $r = '';
    my $body = $self->body;
    my $type = $self->type;
    my $should_para_break = 0;
    my $p_break = $self->param('p_break');
    $p_break = "\n\n" unless defined $p_break;
    
    my $r_delim = undef; # Used if a interior sequence needs closing.

    if($type eq ':paragraph') {
        $should_para_break = 1;
    } elsif( $type eq ':text' or $type eq '#cut' or $type eq ':verbatim') {
        $r .= $body;
    } elsif( $type =~ m/^\:(.+)$/ ) { # Interior sequence
        my $cmd = $1;
        my $l_delim = $self->param('left_delimiter');
        $r_delim = $self->param('right_delimiter');
        $r .= "$cmd$l_delim";
    } elsif( $type eq '[ROOT]' or $type =~ m/^@/) {
        # ignore
    } else { # command
        my $body_attr = $self->param('body_attr');
        if($body_attr) {
            $body = $self->param($body_attr)->pod;
        }
        if(defined $body && $body ne '') {
            $r .= "=$type $body$p_break";
        } else {
            $r .= "=$type$p_break";
        }
    }
    
    my @children = $self->children;
    foreach my $c (@children) {
        $r .= $c->pod;
    }
    
    if($should_para_break) {
        $r .= $p_break;
    } elsif($r_delim) {
        $r .= $r_delim;
    }
    
    if($self->param('close_element')) {
        $r .= $self->param('close_element')->pod;
    }
    
    return $r;
}

=head2 select

 my @nodes = $n->select('/:paragraph[//:text =~ {TODO}]');

Select a pPath expression against this node. The above example will
select all paragraphs in the document containing 'TODO' in any of
their text nodes.

The returned values are the real nodes from the document tree, and
manipulating them will transform the document.

=cut

sub select {
    my $self = shift;
    my $path = shift;
    
    my $p_path = Pod::Abstract::Path->new($path);
    return $p_path->process($self);
}

=head2 select_into

 $node->select_into($target_node, $path)

As with select, this will match a pPath expression against $node - but
the resulting nodes will be copied and added as children to
$target_node. The nodes that were added will be returned as a list.

=cut

sub select_into {
    my $self = shift;
    my $target = shift;
    my $path = shift;
    
    my @nodes = $self->select($path);
    my @dup_nodes = map { $_->duplicate } @nodes;
    
    return $target->nest(@dup_nodes);
}

=head2 type

 $node->type( [ $new_type ] );

Get or set the type of the node.

=cut

sub type {
    my $self = shift;
    if(@_) {
        my $new_val = shift;
        $self->{type} = $new_val;
    }
    return $self->{type};
}

=head2 body

 $node->body( [ $new_body ] );

Get or set the node body text. This is NOT the child tree of the node,
it is the literal text as used by text/verbatim nodes.

=cut

sub body {
    my $self = shift;
    if(@_) {
        my $new_val = shift;
        $self->{body} = $new_val;
    }
    return $self->{body};
}

=head2 param

 $node->param( $p_name [, $p_value ] );

Get or set the named parameter. Any value can be used, but for
document attributes a Pod::Abstract::Node should be set.

=cut

sub param {
    my $self = shift;
    my $param_name = shift;
    if(@_) {
        my $new_val = shift;
        $self->{params}{$param_name} = $new_val;
    }
    return $self->{params}{$param_name};
}

=head2 duplicate

 my $new_node = $node->duplicate;

Make a deep-copy of the node. The duplicate node returned has an
identical document tree, but different node identifiers.

=cut

sub duplicate {
    my $self = shift;
    my $class = ref $self;
 
    # Implement the new() call with all the data needed.
    my $params = $self->{params};
    my %new_params = ( );
    foreach my $param (keys %$params) {
        my $pv = $params->{$param};
        if(ref $pv && eval { $pv->can('duplicate') } ) {
            $new_params{$param} = $pv->duplicate;
        } elsif(! ref $pv) {
            $new_params{$param} = $pv;
        } else {
            die "Don't know how to copy a ", ref $pv;
        }
    }
    my $dup = $class->new(
        type => $self->type,
        body => $self->body,
        %new_params,
        );
    
    my @children = $self->children;
    my @dup_children = map { $_->duplicate } @children;
    $dup->nest(@dup_children);
    
    return $dup;
}

=head2 insert_before

 $node->insert_before($target);

Inserts $node before $target, as a sibling of $target. If $node is
already in a document tree, it will be removed from it's existing
position.

=cut

sub insert_before {
    my $self = shift;
    my $target = shift;
    
    my $target_tree = $target->parent->tree;
    die "Can't insert before a root node" unless $target_tree;
    if($target_tree->insert_before($target, $self)) {
        $self->parent($target->parent);
    } else {
        die "Could not insert before [$target]";
    }
}

=head2 insert_after

 $node->insert_after($target);

Inserts $node after $target, as a sibling of $target. If $node is
already in a document tree, it will be removed from it's existing
position.

=cut

sub insert_after {
    my $self = shift;
    my $target = shift;
    
    my $target_tree = $target->parent->tree;
    die "Can't insert after a root node" unless $target_tree;
    if($target_tree->insert_after($target, $self)) {
        $self->parent($target->parent);
    } else {
        die "Could not insert before [$target]";
    }
}

=head2 hoist

 $node->hoist;

Inserts all children of $node, in order, immediately after
$node. After this operation, $node will have no children. In pictures:

 - a
  - b
  - c
   - d
 -f

 $a->hoist; # ->

 - a
 - b
 - c
  - d
 - f

=cut

sub hoist {
    my $self = shift;
    my @children = $self->children;
    
    my $parent = $self->parent;

    my $target = $self;
    foreach my $n(@children) {
        $n->detach;
        $n->insert_after($target);
        $target = $n;
    }
    
    return scalar @children;
}

=head2 clear

 $node->clear;

Detach all children of $node. The detached nodes will be returned, and
can be safely reused, but they will no longer be in the document tree.

=cut

sub clear {
    my $self = shift;
    my @children = $self->children;
    
    foreach my $n (@children) {
        $n->detach;
    }
    
    return @children;
}

=head2 push

 $node->push($target);

Pushes $target at the end of $node's children.

=cut

sub push {
    my $self = shift;
    my $target = shift;
    
    my $target_tree = $self->tree;
    if($target_tree->push($target)) {
        $target->parent($self);
    } else {
        die "Could not push [$target]";
    }
}

=head2 nest

 $node->nest(@new_children);

Adds @new_children to $node's children. The new nodes will be added at
the end of any existing children. This can be considered the inverse
of hoist.

=cut

sub nest {
    my $self = shift;
    
    foreach my $target (@_) {
        $self->push($target);
    }
    
    return @_;
}

sub tree {
    my $self = shift;
    return $self->{tree};
}

=head2 unshift

 $node->unshift($target);

The reverse of push, add a node to the start of $node's children.

=cut

sub unshift {
    my $self = shift;
    my $target = shift;
    
    my $target_tree = $self->tree;
    if($target_tree->unshift($target)) {
        $target->parent($self);
    } else {
        die "Could not unshift [$target]";
    }
}

=head2 serial

 $node->serial;

The unique serial number of $node. This should never be modified.

=cut

sub serial {
    my $self = shift;
    return $self->{serial};
}

=head2 attached

 $node->attached;

Returns true if $node is attached to a document tree.

=cut

sub attached {
    my $self = shift;
    return defined $self->parent;
}

=head2 detach

 $node->detach;

Removes a node from it's document tree. Returns true if the node was
removed from a tree, false otherwise. After this operation, the node
will be detached.

Detached nodes can be reused safely.

=cut

sub detach {
    my $self = shift;
    
    if($self->parent) {
        $self->parent->tree->detach($self);
        return 1;
    } else {
        return 0;
    }
}

=head2 parent

 $node->parent;

Returns the parent of $node if available. Returns undef if no parent.

=cut

sub parent {
    my $self = shift;
    
    if(@_) {
        my $new_parent = shift;
        if( defined $self->{parent} && 
            $self->parent->tree->detach($self) ) {
            warn "Implicit detach when reparenting";
        }
        $self->{parent} = $new_parent;
        
        # Parent nodes have to be weak - otherwise we leak.
        weaken $self->{parent} 
           if defined $self->{parent};
    }
    
    return $self->{parent};
}

=head2 root

 $node->root

Find the root node for the tree holding this node - this may be the
original node if it has no parent.

=cut

sub root {
    my $n = shift;
    
    while(defined $n->parent) {
        $n = $n->parent;
    }
    
    return $n;
}

=head2 children

 my @children = $node->children;

Returns the children of the node in document order.

=cut

sub children {
    my $self = shift;
    return $self->tree->children();
}

=head2 next

 my $next = $node->next;

Returns the following sibling of $node, if one exists. If there is no
following node undef will be returned.

=cut

sub next {
    my $self = shift;
    my $parent = $self->parent;

    return undef unless $parent; # No following node for root nodes.
    return $parent->tree->index_relative($self,+1);
}

=head2 previous

 my $previous = $node->previous;

Returns the preceding sibling of $node, if one exists. If there is no
preceding node, undef will be returned.

=cut

sub previous {
    my $self = shift;
    my $parent = $self->parent;

    return undef unless $parent; # No preceding nodes for root nodes.
    return $parent->tree->index_relative($self,-1);
}

=head2 coalesce_body

 $node->coalesce_body(':verbatim');

This performs node coalescing as required by perlpodspec. Successive
verbatim nodes can be merged into a single node. This is also done
with text nodes, primarily for =begin/=end blocks.

The named node type will be merged together in the child document
wherever there are two or more successive nodes of that type. Don't
use for anything except C<:text> and C<:verbatim> nodes unless you're
really sure you know what you want.

=cut

sub coalesce_body {
    my $self = shift;
    my $node_type = shift;
    
    # Select all elements containing :verbatim nodes.
    my @candidates = $self->select("//[/$node_type]");
    foreach my $c (@candidates) {
        my @children = $c->children;
        my $current_start = undef;
        foreach my $n (@children) {
            if($n->type eq $node_type) {
                if(defined $current_start) {
                    my $p_break = $current_start->param('p_break');
                    $p_break = "" unless $p_break;
                    my $body_start = $current_start->body;
                    $current_start->body(
                        $body_start . $p_break . $n->body
                        );
                    $current_start->param('p_break',
                                          $n->param('p_break'));
                    $n->detach or die; # node has been appended to prev.
                } else {
                    $current_start = $n;
                }
            } else {
                $current_start = undef;
            }
        }
    }
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
