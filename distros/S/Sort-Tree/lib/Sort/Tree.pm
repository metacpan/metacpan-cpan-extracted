package Sort::Tree;

#========================================================================
#
# Sort::Tree
#
# DESCRIPTION
#                                                                       
# Pair of routines for reorganizing a list into a parent/child tree,
# useful for generating directory-tree like displays.
#
# AUTHOR
#   Bryce Harrington <brycehar@bryceharrington.com>
#
# CONTRIBUTIONS BY
#   Pat Deegan, psychogenic.com.  2004-05-06 Sort bug fix and traversal algo.
#
# COPYRIGHT
#   Copyright (C) 2003 Bryce Harrington & Open Source Development Lab
#   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#------------------------------------------------------------------------
#
# Last Modified:  $Date: 2004/05/06 20:46:04 $
#
# $Id: Tree.pm,v 1.3 2004/05/06 20:46:04 bryce Exp $
#
# $Log: Tree.pm,v $
# Revision 1.3  2004/05/06 20:46:04  bryce
# Adding patch from Pat Deegan
#
# Revision 1.2  2003/09/09 23:59:36  bryce
# Adding Kevin's patch
#
# Revision 1.1.1.1  2003/09/09 23:19:46  bryce
# Initial import
#
#
#========================================================================
=head1 NAME

B<Sort::Tree> - Organize list of objects into parent/child order.


=head1 SYNOPSIS

    use Sort::Tree;

    my @tree = list_to_tree(\@my_list, 
                            $id_field, 
                            $parent_field);

    my @sorted_list = tree_to_list(\@tree,
                                   [$id_field],
                                   [\&Sort::Tree::numerically],
                                   $parent_field));

=head1 DESCRIPTION

B<Sort::Tree> includes three routines, list_to_tree, tree_to_list and traverse.
These are used to organize an unordered list of objects into a tree
form.  For example, you'd perform a database query to gain a list of
folders in a document system, and then order them by parentage for
display in a webpage.

=head1 EXAMPLE

    use Sort::Tree;

    my @creatures = (
                 { id => 1, class => -1, name => 'animal' },
                 { id => 2, class => 1,  name => 'mammal' },
                 { id => 3, class => 1,  name => 'bird' },
                 { id => 4, class => 1,  name => 'reptile' },
                 { id => 5, class => 2,  name => 'primate' },
                 { id => 6, class => 2,  name => 'feline' },
                 { id => 7, class => 5,  name => 'human' },
                 { id => 8, class => 6,  name => 'housecat' },
                 { id => 9, class => 3,  name => 'penguin' },
                 { id => 10,class => 4,  name => 'gecko' }
                 );

    my @tree = Sort::Tree::list_to_tree(\@creatures, 'id', 'class');

    foreach my $row (Sort::Tree::tree_to_list(\@tree,
                                          ['id'],
                                          [\&Sort::Tree::numerically],
                                          'class')) {
        print ' ' x $row->{class}, $row->{name}, "\n";
    }

The following is displayed:

animal
 mammal
  primate
     human
  feline
      housecat
 bird
   penguin
 reptile
    gecko

=head1 METHODS

=cut


use strict;
use Carp;

require Exporter;


use vars qw($VERSION @ISA $TreeChildrenKey);
@ISA = qw( Exporter );
$VERSION = '1.09';
@Sort::Tree::EXPORT = qw( 
			  list_to_tree 
			  tree_to_list 
			  numerically 
			  alphabetically 
			  chronologically 
			  reverse_numerically 
			  reverse_alphabetically
			  reverse_chronologically 
			  );
@Sort::Tree::EXPORT_OK = qw( list_to_tree tree_to_list );
@Sort::Tree::EXPORT_TAGS = qw( 'all' => [ qw( list_to_tree tree_to_list ) ] );

use constant DEBUGGING => 0;

$TreeChildrenKey = 'kids';

=head3 list_to_tree($list, $idField, $parentField)

Takes a list of queried objects and builds a tree, resorting it into
tree order and including the nesting level.  Inspired by DBIx::Tree.

=cut
sub list_to_tree {
    my ($list, $idField, $parentField, $startId) = @_;

    $idField ||= 'id';
    $parentField ||= 'parent_id';
    return () unless ($list);

    my $root_id = -1;

    warn "Using id field $idField and parent field $parentField\n" if DEBUGGING;

    # If given a startId the find that object in the list and ensure that
    # that is processed first.  Patch from Kevin White [kevin.white/oupjournals-org]
    if( defined $startId ) {
        for( my $i = 0; $i < scalar @{$list}; $i++ ) {
            if( ${$list}[$i]->{$idField} =~ /^$startId$/ ) {
                unshift( @{$list}, splice( @{$list}, $i, 1 ) );
                last;
            }
        }
    }

    my @tree;
    my %index;
    # Put objects into a nested tree structure
    foreach my $obj (@{$list}) {
	die "list_to_tree:  Object undefined\n" unless $obj;
	my $id = $obj->{$idField} || die "list_to_tree:  No $idField in object\n";
	my $pid = $obj->{$parentField} || $id;

	if ($root_id == -1) {
	    $pid = $id;
	    $root_id = $id;
	}

	warn "Adding object #$id to parent #$pid\n" if DEBUGGING;

	# Add object node to index
	if (defined $index{$id}) {
	    if (defined $index{$id}->{$idField}) {
		die "Sort::Tree::list_to_tree:  Duplicate object $id.\n";
	    } else {
		$obj->{$TreeChildrenKey} = $index{$id}->{$TreeChildrenKey};
		$index{$id} = $obj;
	    }
	} else {
	    $index{$id} = $obj;
	}

	# If this is a root object, put into tree directly
	if ($id == $pid) {
	    warn "Adding $id to tree\n" if DEBUGGING;
	    push @tree, $obj;

	    warn "Now there are ", $#tree+1, " items in tree\n" if DEBUGGING;
	# Add it as a child of the appropriate parent object
	} else {
	    warn "Adding $id as child of $pid\n" if DEBUGGING;
	    push @{$index{$pid}->{$TreeChildrenKey}}, $obj;
	}
    }   

    warn "Tree:  @tree  (", $#tree+1, " items)\n" if DEBUGGING;

    return @tree;
}

# Various sorting routines
#  Look at Date::Interval for comparing date ranges
#  Look at Sort::Versions for comparing version numbers
#  Look at Number::Compare for comparing file sizes (1G, 42k, etc.)
#  Look at Date::Manip for parsing dates for comparison
sub numerically {             my ($a,$b,$f) = @_;  $a->{$f} <=> $b->{$f} }
sub alphabetically {          my ($a,$b,$f) = @_;  $a->{$f} cmp $b->{$f} }
sub chronologically {         my ($a,$b,$f) = @_;  $a->{$f} cmp $b->{$f} }
sub reverse_numerically {     my ($a,$b,$f) = @_;  $b->{$f} <=> $a->{$f} }
sub reverse_alphabetically {  my ($a,$b,$f) = @_;  $b->{$f} cmp $a->{$f} }
sub reverse_chronologically { my ($a,$b,$f) = @_;  $a->{$f} cmp $b->{$f} }

	
						
=head3 tree_to_list(tree, cmpFields, cmpFuncs, idField, depth, max_depth)

Takes a tree and serializes it into a sorted list.  Recursive.
Inspired by DBIx::Tree (but not derived from it)

  Parameters:
    $tree - the tree data structure
    $cmpFields - Field to do comparison on (default idField)
    $cmpFuncs - Ordering function (default &numerically)
    $idField - 
    $depth - Depth to display (default 0)
    $max_depth - Maximum depth to display; -1 for all (default -1)

=cut
sub tree_to_list {
    my ($tree, $cmpFields, $cmpFuncs, $idField, $depth, $max_depth) = @_;

    # error checking
    die "No valid tree object" unless $tree;

    # Get the cmp items for the current level
    my $cmpField = shift @{$cmpFields} || $idField;
    my $cmpFunc = shift @{$cmpFuncs} || \&numerically;

    # Defaults
    $idField ||= 'id';
    $depth ||= 0;
    $max_depth ||= -1;

    # If we're at the end of the list, reuse last cmp item
    $cmpFuncs = [$cmpFunc] unless @{$cmpFuncs};
    $cmpFields = [$cmpField] unless @{$cmpFields};

    while (! defined $tree->[0]->{$cmpField} && @{$cmpFields}>0) {
	$cmpField = shift @{$cmpFields};
    }

    # Iterate through tree and generate sorted threaded list
    
    my @list;
    foreach my $node (sort { &$cmpFunc($a,$b,$cmpField);
			    } @{$tree}) {
	$node->{depth} = $depth;
	push @list, $node;

	# If this obj has children, sort & parse those next
	if (defined $node->{$TreeChildrenKey} && $depth != $max_depth) {
	    push @list, tree_to_list($node->{$TreeChildrenKey},
				     [ $cmpField ], [ $cmpFunc ],
				     $idField,$depth+1,$max_depth);
	}
    }

    return @list;
}




=head3 traverse(tree, %traverseArgs)

Performs a depth-first traversal of the tree, calling a specified callback method for each element.

  Parameters:
    $tree - the tree data structure
    %traverseArgs - two or more key/value paired arguments ('method' and 'idField' required)

%traverseArgs is expected to contain valid 'method' (code ref) and 'idField' (string) keys. The 'method' should expect to
be called with a list of arguments and have a signature like

 
	sub mymethod {
		my %arguments = @_;
		# ...
	}



$traverseArgs{'method'} will be called for each tree element encountered with the following key/value arguments:
	
	'id'		string, id of current element
	'item'		actual tree element currently being processed
	'level'		integer, depth within tree
	'parent_id'	string, id of parent element if available
	'parent'	parent element of 'item'
	%traverseArgs	args passed to traverse()
	

The values passed to $traverseArgs{'method'} will also contain the arguments passed in 
the %traverseArgs used in the call to traverse(), which is a handy way to pass information along to the 
processing method.

The method specified with the $traverseArgs{'method'} parameter should return a FALSE value to continue processing of 
the tree.  Should the $traverseArgs{'method'} return something which evaluates to Perl 'true', traverse()
will abort and immediately return THAT value to the caller.

EXAMPLES of traverse(): 
 
 {
  	# Modifying all elements in a tree, by traversing it
  	# ... 
 	my $tree = Sort::Tree::list_to_tree(...);
	
	Sort::Tree::traverse($tree, 
				   'method'	=> \&uppercaseTitles,
				   'idField'	=> 'myid'
				);
	
	# $tree now contains uppercase titles in each element.
	# ...
 }
 
 # uppercaseTitles assumes tree items contain a 'title' key.
 sub uppercaseTitles {
 	my %details = @_;
	
	print "Uppercasing title from item " . $details{'id'} . "\n";
	
	$details{'item'}->{'title'} = uc($details{'item'}->{'title'});
	
	return false; # continue processing tree
 }


The above example demonstrated a traversal which needed to interact with each element in the tree.  In some instances, such as during
as search, it is desirable to abort the operation at some point.  This is accomplished by having the traverse method return a true value.  Since this
true value is returned to the original caller, it can be used to return a tree element or a portion thereof.
 
 
 {
  	# Search elements in tree, return first match
  	# ... 
 	my $tree = Sort::Tree::list_to_tree(...);
	
	my %traverseArgs = (
				'method'	=> \&findByOwner,
				'idField'	=> 'myid',
				'owner'		=> 'bob', # traversArgs are passed to callback method
		);
	
	my $bobsElement = Sort::Tree::traverse($tree, %traverseArgs) || die "can't find bob's stuff";
	
	# use the element
	
 }
 
 # findByOwner assumes tree elements have an 'owner' attribute
 sub findByOwner {
 	my %details = @_;
 
	if ($details{'item'}->{'owner'} eq $details{'owner'})
	{
		return $details{'item'};
	}
	
	return false; # continue processing tree
 }

=cut

sub traverse {
	my $tree = shift || return undef;
	my %args = @_;

	my $method = $args{'method'} || die "Must provide a 'method' key to traverse() args";
	my $idField = $args{'idField'} || 'idField';


	die "Tree is not an array ref?" unless (ref $tree eq 'ARRAY');

	my $level = $args{'_level'} || "0";
	my $pid = $args{'_pid'} ;
	my $parent = $args{'_parent'} ;
	foreach my $element (@{$tree})
	{
		my %methodArgs = (
					%args,
					'id'	=> $element->{$idField},
					'level'	=> $level,
					'parent_id'	=> $pid,
					'parent'	=> $parent,
					'item'	=> $element,
				);

		my $methReturn = &{$method}(%methodArgs);
		return $methReturn if ($methReturn);
		if ($element->{$TreeChildrenKey} && ref $element->{$TreeChildrenKey} )
		{
			my %traversArgs = %args;
			$traversArgs{'_level'}++;
			$traversArgs{'_pid'} = $element->{$idField};
			$traversArgs{'_parent'} = $element;

			my $travRet = traverse($element->{$TreeChildrenKey}, %traversArgs);
			return $travRet if ($travRet);
		}
	}

	return undef;
	
}
				
#========================================================================
# Subroutines
#------------------------------------------------------------------------


1;
__END__

=head1 PREREQUISITES

Nothing outside of the normal Perl core modules (Exporter & Carp).

=head1 BUGS

None reported.

=head1 VERSION

1.09 - Released on 2004/05/06.

=head1 SEE ALSO

L<perl(1)>

=head1 AUTHOR

Bryce Harrington E<lt>brycehar@bryceharrington.comE<gt>

L<http://www.osdl.org/|http://www.osdl.org/>

=head2 CONTRIBUTIONS

Pat Deegan, L<http://www.psychogenic.com>.  2004-05-06 Sort bugfix, traverse() method.

=head1 COPYRIGHT

Copyright (C) 2003 Bryce Harrington.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 REVISION

Revision: $Revision: 1.3 $

=cut
