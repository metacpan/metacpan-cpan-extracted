# PurpleWiki::View::Driver.pm
#
# $Id: Driver.pm 366 2004-05-19 19:22:17Z eekim $
#
# Copyright (c) Blue Oxen Associates 2002-2004.  All rights reserved.
#
# This file is part of PurpleWiki.  PurpleWiki is derived from:
#
#   UseModWiki v0.92          (c) Clifford A. Adams 2000-2001
#   AtisWiki v0.3             (c) Markus Denker 1998
#   CVWiki CVS-patches        (c) Peter Merel 1997
#   The Original WikiWikiWeb  (c) Ward Cunningham
#
# PurpleWiki is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
#    Free Software Foundation, Inc.
#    59 Temple Place, Suite 330
#    Boston, MA 02111-1307 USA

package PurpleWiki::View::Driver;
use 5.005;
use strict;
use warnings;
use Carp;
use PurpleWiki::Config;
use PurpleWiki::Tree;

######## Package Globals ########

our $VERSION;
$VERSION = sprintf("%d", q$Id: Driver.pm 366 2004-05-19 19:22:17Z eekim $ =~ /\s(\d+)\s/);

# This probably belongs in StructuralNode.pm
our @structuralNodeTypes = qw(document section indent ul ol dl h p li dd dt 
                              pre sketch);

# This probably belongs in InlineNode.pm
our @inlineNodeTypes = qw(b i tt text nowiki transclusion link url wikiword 
                          freelink image);

# I don't know where this belongs, but here is as good a place as any.
our @allNodeTypes = (@structuralNodeTypes, @inlineNodeTypes);

# Used to quickly see if a node type is valid, we need to do this in AUTOLOAD
# and so we make this a package global so as to incur the cost only once.
our %lookupTable = map { $_ => 1 } @allNodeTypes;


######## Public Methods ########

# Create a new driver.
sub new {
    my $proto = shift;
    my $self = { @_ };
    my $class = ref($proto) || $proto;

    # Make sure we have a PurpleWiki::Config object.
    $self->{config} = PurpleWiki::Config->instance();
    croak "PurpleWiki::Config object not found" unless $self->{config};

    # Object state.
    $self->{depth} = 0;

    bless($self, $class);
    return $self;
}

# View starts the processing of the PurpleWiki::Tree and returns the
# finished string.
sub view {
    my ($self, $wikiTree) = @_;
    $self->processNode($wikiTree->root) if defined $wikiTree->root;
}

# Recurse decends down the PurpleWiki::Tree depth first.  Structural nodes
# have two kinds of children: Inline and Structural, so we need to process
# the Inline children of a Structural Node seperately.
sub recurse {
    my ($self, $nodeRef) = @_;

    # recurse() should never be called on an undefined node.
    if (not defined $nodeRef) {
        carp "Warning: tried to recurse on an undefined node\n";
        return;
    }

    if ($nodeRef->isa('PurpleWiki::StructuralNode')) {
        $self->traverse($nodeRef->content) if defined $nodeRef->content;
    }

    $self->traverse($nodeRef->children) if defined $nodeRef->children;
}

# Traverse goes through a list of nodes calling their pre, main, and post
# handlers (in that order).  Recursion is depth first because the default
# main handler is recurse().
sub traverse {
    my ($self, $nodeListRef) = @_;

    # traverse() should never be called on an undefined node.
    if (not defined $nodeListRef) {
        carp "Warning: tried to traverse on an undefined node list\n";
        return;
    }
  
    foreach my $nodeRef (@{$nodeListRef}) {
        $self->processNode($nodeRef) if defined $nodeRef;
    }
}

# Call the pre, main, and post handlers for a specific node, as well as the
# generic structural/inline pre, main, and post handlers.
sub processNode {
    my ($self, $nodeRef) = @_;

    # processNode() should never be called on an undefined node.
    if (not defined $nodeRef) {
        carp "Warning: tried to process an undefined node\n";
        return;
    }

    # We have to construct each method name.  The method names are of the form
    # fooPre, fooMain, and fooPost where foo = $node->type.
    my $nodePre = $nodeRef->type."Pre";
    my $nodeMain = $nodeRef->type."Main";
    my $nodePost = $nodeRef->type."Post";

    $self->{depth}++;

    # Run all the handlers
    $self->Pre($nodeRef);
    $self->$nodePre($nodeRef);

    $self->Main($nodeRef);
    $self->$nodeMain($nodeRef);

    $self->$nodePost ($nodeRef);
    $self->Post($nodeRef);

    $self->{depth}--;
}

# Noop == No Operation.  Just a little stub since it's used by most of
# the handlers.  Most handlers are a noop by default.
sub noop {
    return;
}

######## Private Methods ########

# The AUTOLOAD function captures calls to non-existant methods.  This allows
# us to define a default behavior for a whole set of methods without having
# to declare each one individually.  
#
# AUTOLOAD is passed in the method name that was called, but not found.  Two 
# checks are done to resolve the method name and if they both fail the method
# is considered unfound.  The checks are as follow:
#
#       1) See if method name is is exactly equal to "Pre", "Main", or "Post"
#          and if it is call the noop method, which is the default behavior
#          for these methods.
#
#       2) Pattern match the method name pulling out the nodeType and opType
#          (opType is one of Pre, Main, or Post).  If the pattern match was
#          successful we just call the noop method for Pre and Post handlers,
#          and we call the recurse() method for Main handlers.
sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = shift;
    my $method = $AUTOLOAD;

    # Remove all but the method name
    $method =~ s/(.*)://g;  # Reduces Foo::Bar::Baz::Quz::method to "method"

    # Bail on DESTROY, otherwise we'll cause an infinite loop when our object
    # is garbage collected.
    return if $method =~ /DESTROY/;

    # The generic Pre, Main, and Post handlers apply to every single node
    # and are noops by default, we just provide them for ease of use.
    if ($method eq "Pre" or $method eq "Main" or $method eq "Post") {
        $self->noop(@_);
        return;
    }  
    
    # Do a pattern match to see if $method is a node specific handler, and
    # extract out the nodeType and the opType if it is.
    if ($method =~ /^([a-z]+)(Pre|Main|Post)$/) {
        my ($nodeType, $opType) = ($1, $2);

        goto notFound if not exists $lookupTable{$nodeType};

        # Invoke the default behavior for undefined methods.
        if ($opType eq "Main") {
            $self->recurse(@_);  # fooMain handlers recurse by default
        } else {
            $self->noop(@_);  # fooPre/Post handlers are noops by default.
        }

        return;
    }

    notFound:
        croak "Could not locate $AUTOLOAD.\n";
}
1;
__END__

=head1 NAME

PurpleWiki::View::Driver - View driver base class

=head1 SYNOPSIS

The PurpleWiki::View::Driver is primarily used as a base class, because by
itself it doesn't do anything but traverse a PurpleWiki::Tree.  This example
defines a view driver that extracts image links from a PurpleWiki::Tree.
    
    package PurpleWiki::View::getImages;
    use strict;
    use warnings;
    use PurpleWiki::View::Driver;

    use vars qw(@ISA);
    @ISA = qw(PurpleWiki::View::Driver);

    sub new {
        my $prototype = shift;
        my $class = ref($prototype) || $prototype;
        my $self = $class->SUPER::new(@_);

        # Object State
        $self->{images} = [];

        bless($self, $class);
        return $self;
    }

    sub view {
        my ($self, $tree) = @_;
        $self->SUPER::view($tree);
        return @{$self->{images}};
    }

    sub imageMain {
        my ($self, $nodeRef) = @_;
        push @{$self->{images}}, $nodeRef->href;
    }

    1;

=head1 DESCRIPTION

PurpleWiki::View::Driver is the base class used by all of the view drivers.
Its default behavior is to recurse down a PurpleWiki::Tree depth first from
left most (oldest) child to right most (youngest) child.  Child nodes are
represented as a list within a PurpleWiki::Tree, so left most means the first
child in the list and right most means the last child in the list.

Other than the methods mentioned in the B<METHODS> section, this class also
uses B<AUTOLOAD> to export pre, main, and post handling methods for every node
type.  Three generic handlers are also exported via B<AUTOLOAD> and they are
called simply "Pre()", "Main()", and "Post()" and get called on every node. 

For example, for every node of type "section" the following handlers are
exported via B<AUTOLOAD>:

    sectionPre()
    sectionMain()
    sectionPost()

The pre handler is called before the node, the main is called to process the
node, and the post handler is called after the main handler has finished.  
Since we're in a tree, the main handler may not finish until much recursion
has occurred.

The default action of both the generic and node specific pre and post handlers
is to do a no-op.  The default generic Main handler is also a no-op.  The only
methods exported via B<AUTOLOAD> which are not no-ops are the node specific main
handlers.  Their default action is to call recurse(), which is documented in
the B<METHODS> section below.

The calling order of the handlers is as follows:

    generic Pre handler (defaults to no-op)
    node specific Pre handler (defaults to no-op)

    generic Main handler (defaults to no-op)
    node specific Main handler (defaults to recurse())

    node specific Post handler (defaults to no-op)
    generic Post handler (defaults to no-op)

The only data passed into a handler is a reference to a node object.  So for
example, the resulting method calls when processing a "ul" node would be as
follows:
    
    $self->Pre($nodeRef);
    $self->ulPre($nodeRef);

    $self->Main($nodeRef);
    $self->ulMain($nodeRef);

    $self->ulPost($nodeRef);
    $self->Post($nodeRef);

This calling order is defined in processNode(), so if you overload that method
you could possibly change the calling order.  Also remember that overloading
a node specific main handler will stop the recursion at that node unless you
explicitly call recurse() in your overloaded method.

=head1 OBJECT STATE

=head2 depth

The driver's current depth while recursing through the PurpleWiki::Tree.  The
value of depth should be 0 before and after a call to the view() method.  The
value of depth is changed in processNode() and so is only sure to be correct as
long as processNode() hasn't been overloaded in another class. 

Since our object is a blessed hash reference you retrieve the value of depth
like this: $self->{depth}

=head1 METHODS

The following methods are explicitly defined in F<Driver.pm> and are available
for overloading.  In addition to these all of the methods generated via the
B<AUTOLOAD> function are also availble for overloading.  The functions defined
via B<AUTOLOAD> are talked about in the B<DESCRIPTION> section.

=head2 new()

Returns a new PurpleWiki::View::Driver().  The state variable depth is set to 0
at this point.

=head2 view($wikiTree)

This method is the common entry point for most view drivers.  This method
should be overloaded in derived classes and should return whatever is 
appropriate for the derived class it's in.  

This method returns nothing by default and it's only action is to call
processNode() on the root of the wikiTree.  

Every derived class should call $self->SUPER::view() in their overloaded
version.

=head2 recurse($nodeRef)

If $nodeRef is a StructuralNode then recurse() calls traverse() on the
node's content field and then calls traverse() on the node's children field.

If $nodeRef is an InlineNode, then recurse() simply calls traverse() on the
node's children field.

This method returns nothing by default.  This method should only be overloaded
if you want to make major changes to how a PurpleWiki::Tree is processed.  

This method is the default action for the node specific main handlers defined
via B<AUTOLOAD>.

=head2 traverse($nodeListRef)

Iterates through a list of nodes and calls processNode() on each one.  This
method should only be overloaded if you want to make major changes to how a
PurpleWiki::Tree is processed.  It returns nothing by default.

=head2 processNode($nodeRef)

Calls all of the handlers for a node and updates the value of the object state
variable "depth."  The default behavior is as follows:

=over

=item * 

Increment depth.

=item *

Call generic Pre handler.

=item *

Call node specific Pre handler.

=item *

Call generic Main handler.

=item *

Call node specific Main handler.

=item *

Call node specific Post handler.

=item *

Call generic Post handler.

=item *

Decrement depth.

=back

This method returns nothing by default and should only be overloaded if you
want to make major changes to how a PurpleWiki::Tree is processed.

=head2 noop($nodeRef)

Does nothing and returns nothing.  This is the default behavior of all but the
node specific main handlers.  Sometimes it is useful to overload for debugging
purposes.

=head1 AUTHORS

Matthew O'Connor, E<lt>matthew@canonical.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Tree>, L<PurpleWiki::StructuralNode>, L<PurpleWiki::InlineNode>.

=cut
