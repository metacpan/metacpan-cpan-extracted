# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More 'no_plan';
use strict;
use warnings;

# This functions takes a reference to a devicetree object and a test
# function. For each node in the tree the function is called and
# during the function call $_ is bound to the visited node.
# The tree traversal is done in a depth-first search.
sub test_all_nodes {
  my ($tree, $testfunc) = @_;
  my @child_nodes = ($tree);
  while( @child_nodes ) {
    local $_ = shift @child_nodes;
    if( !$testfunc->() ) {
      diag( "Function has not succeeded for node " . $_->devfs_path );
      return 0;
    }
    push @child_nodes, $_->child_nodes;
  }
  return 1;
}

# This contains 21 tests for the tree applied for all kinds of trees
sub test_Solaris_DeviceTree {
  my $tree = shift;

  # Test - traverse the tree to all childs and see if there is at most instance per child
  my %seen_childs;
  ok( test_all_nodes( $tree, sub {
      return 0 if( exists $seen_childs{$_} );
      $seen_childs{$_} = 1;
    } ), "  Checking that traversal visits nodes at most once by object reference" );
  
  # Test - traverse the tree to all childs and see if there is at most instance per path
  # (helps finding corrupted child generation).
  # This test includes checking the 'devfs_path' method.
  my %seen_pathes;
  ok( test_all_nodes( $tree, sub {
      return 0 if( exists $seen_pathes{$_->devfs_path} );
      $seen_childs{$_->devfs_path} = 1;
    } ), "  Checking that traversal visits nodes at most once by device path" );
  
  # Test - test if we have at least three levels and at least 10 nodes total
  {
    my $expected_level = 3;
    my $expected_nodecount = 10;

    my %level;
    my @child_nodes = ($tree);
    $level{$tree} = 1;
    my $maxlevel = 1;
    my $nodecount = 1;
    while( @child_nodes ) {
      my $node = shift @child_nodes;
      $nodecount++;
      my @children = $node->child_nodes;
      foreach my $child (@children) {
        $level{$child} = $level{$node} + 1;
        $maxlevel = $level{$child} if( $level{$child} > $maxlevel );
      }
      push @child_nodes, @children;
    }
    ok( $maxlevel >= $expected_level && $nodecount >= $expected_nodecount,
        "  Checking for minimum size of the devicetree arbitrarily chosen as " .
        "$expected_level levels and $expected_nodecount nodes" );
  }
  
  # Test - check topology of tree according to parent/child relationship of root node
  {
    my @child_nodes = ($tree);
    my $parent_ok = 1;
    ok( !defined $tree->parent_node,
        "  Checking that the root node does not have a parent node" );
  
  # Test - continue test 5 for the rest of the tree
    while( @child_nodes ) {
      my $parent = shift @child_nodes;
      my @children = $parent->child_nodes;
      foreach my $child (@children) {
        $parent_ok = 0 if( $parent ne $child->parent_node );
      }
      push @child_nodes, @children;
    }
    ok( $parent_ok,
        "  Checking the parent of a nodes child is itself" );
  }
  
  # Test - check for correct root node reference from all nodes
  ok( test_all_nodes( $tree, sub { $tree eq $_->root_node } ),
      "  Checking that root node is the same for all nodes in the tree" );
  
  # Test - check siblings for all nodes
  {
    my @child_nodes = ($tree);
    my $siblings_ok = 1;
    while( @child_nodes ) {
      my $node = shift @child_nodes;
      foreach my $sibling ($node->sibling_nodes) {
        $siblings_ok = 0 if( $node eq $sibling );
        $siblings_ok = 0 if( $node->parent_node ne $sibling->parent_node );
      }
      push @child_nodes, $node->child_nodes;
    }
    ok( $siblings_ok,
        "  Checking that the sibling nodes are childs from the same parent and not itself" );
  }
  
  # Test - check node_name
  # (node names are allowed to be undefined)
  ok( test_all_nodes( $tree, sub { $_->node_name; 1 } ),
      "  Checking that querying for the node name does not produce an error" );
  
  # Test - binding_name
  ok( test_all_nodes( $tree, sub { $_->binding_name; 1 } ),
      "  Checking that querying for the binding name does not produce an error" );
  
  # Test - bus_addr
  ok( test_all_nodes( $tree, sub { $_->bus_addr; 1 } ),
      "  Checking that querying for the bus address does not produce an error" );
  
  # Test - compatible_names
  ok( test_all_nodes( $tree, sub { $_->compatible_names; 1 } ),
      "  Checking that querying for the compatible names does not produce an error" );
  
  # Test - devid
  TODO: {
    todo_skip "libdevid access not currently implemented", 1;
    ok( test_all_nodes( $tree, sub { $_->devid; 1 } ),
      "  Checking that querying for the device id does not produce an error" );
  }
  
  # Test - driver_name
  ok( test_all_nodes( $tree, sub { $_->driver_name; 1 } ),
      "  Checking that querying for the driver name does not produce an error" );
  
  # Test - driver_ops
  ok( test_all_nodes( $tree, sub { $_->driver_ops; 1 } ),
      "  Checking that querying for the driver operations does not produce an error" );
  
  # Test - instance
  ok( test_all_nodes( $tree, sub { $_->instance; 1 } ),
      "  Checking that querying for the instance number does not produce an error" );
  
  # Test - state
  ok( test_all_nodes( $tree, sub { $_->state; 1 } ),
      "  Checking that querying for the state does not produce an error" );
  
  # Test - nodeid
  ok( test_all_nodes( $tree, sub { $_->nodeid; 1 } ),
      "  Checking that querying for the node id does not produce an error" );
  
  
  # Test - is_pseudo_node, is_sid_node, is_prom_node
  ok( test_all_nodes( $tree, sub {
      $_->is_pseudo_node;
      $_->is_sid_node;
      $_->is_prom_node;
      1
    } ),
      "  Checking that querying if the node is of type pseudo, sid or prom does not produce an error" );
  
  # Test - props
  # -> TODO: Enhance test
  ok( test_all_nodes( $tree, sub { $_->props; 1 } ),
      "  Checking that querying for properties does not produce an error" );
  
  # Test - prom_props
  # -> TODO: Skip over test only if we are using libdevinfo
  SKIP: { 
    skip( "  Skipping query for PROM properties if we are not allowed to read /dev/openprom", 1 )
      if( ! -r "/dev/openprom" );
    ok( test_all_nodes( $tree, sub { $_->prom_props; 1 } ),
        "  Checking that querying for PROM properties does not produce an error" );
    }

  # Test - minor_nodes
  # -> TODO: Inspect minor nodes further
  ok( test_all_nodes( $tree, sub { $_->minor_nodes; 1 } ),
      "  Checking that querying for minor nodes does not produce an error" );
  
}

# Test - load the module
require_ok( "Solaris::DeviceTree::Libdevinfo" );

# Test - make a tree
my $libdevinfo_tree = Solaris::DeviceTree::Libdevinfo->new;
ok( $libdevinfo_tree, "Generating devicetree Libdevinfo" );

# Test - test the tree
test_Solaris_DeviceTree( $libdevinfo_tree );


# Test - load the module
require_ok( "Solaris::DeviceTree::PathToInst" );

# Test - make a tree
my $pti_tree = Solaris::DeviceTree::PathToInst->new;
ok( $pti_tree, "Generating devicetree PathToInst" );

# Test - test the tree
test_Solaris_DeviceTree( $pti_tree );

  
# Test - load the module
require_ok( "Solaris::DeviceTree::Filesystem" );

# Test - make a tree
my $fs_tree = Solaris::DeviceTree::Filesystem->new;
ok( $fs_tree, "Generating devicetree Filesystem" );

# Test - test the tree
test_Solaris_DeviceTree( $fs_tree );

  
# Test - load the module
require_ok( "Solaris::DeviceTree::Overlay" );

# Test - make a tree
my $ovl_tree = Solaris::DeviceTree::Overlay->new(
  sources => {
    "libdevinfo" => $libdevinfo_tree,
    "path_to_inst" => $pti_tree,
    "filesystem" => $fs_tree,
  },
);
  
ok( $ovl_tree, "Generating unified devicetree" );

# Test - test the tree
test_Solaris_DeviceTree( $ovl_tree );

exit 0;
