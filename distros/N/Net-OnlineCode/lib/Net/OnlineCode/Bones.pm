package Net::OnlineCode::Bones;

use strict;
use warnings;

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION);

$VERSION = '0.04';

# 
sub new {
  my ($class, $graph, $top, $nodes) = @_;
  my $bone = $nodes;
  my $unknowns = scalar(@$nodes);

  die "Bones: refusing to create a bone with empty node list\n"
    unless $unknowns;

  #print "new bone $top with list @$nodes\n";

  unshift @$bone, $unknowns;	# count unknowns
  push    @$bone, $top;		# add "top" node to knowns

  #print "bone after unshift/push: @$nodes\n";

  my $index = 1;

  while ($index <= $unknowns) {
    if ($graph->{solution}->[$bone->[$index]]) {
#      print "swapping bone known bone index $index with $unknowns\n";
      @{$bone}[$index,$unknowns] = @{$bone}[$unknowns,$index];
      --$unknowns;
    } else {
#      print "bone index $index is not known\n";
      ++$index;
    }
  }    

  $bone->[0] = $unknowns;	# save updated count

  bless $bone, $class;
}

# Throw the caller a bone (ahem) if they want to construct the object
# themself (useful in GraphDecoder constructor)
sub bless {
  my ($class, $object) = @_;

  die "Bones: bless is a class method (call with ...::Bones->bless())\n"
    if ref($class);

  die "Net::OnlineCode::Bones::bless can only bless an ARRAY reference\n"
    unless ref($object) eq "ARRAY";

#  warn "Bones got ARRAY to bless: " . (join ", ", @$object) . "\n";

  die "Net::OnlineCode::Bones::bless was given an incorrectly constructed array\n"
    if scalar(@$object) == 0 or $object->[0] > scalar(@$object);

  bless $object, $class;
}


# "Firm up" a bone by turning an unknown node from the left side of
# the equation into a known one on the right side
sub firm {
  my ($bone, $index) = @_;
  my $unknowns = $bone->[0]--;

  @{$bone}[$index,$unknowns] = @{$bone}[$unknowns,$index];
}
 

# The "top" node is the number of the check or aux block where the
# bone was first created. It's always the last value of the list
sub top {
  my $bone = shift;

  return $bone->[scalar(@$bone)];  
}

# The "bottom" node will shuffle to the start of the list of unknown
# blocks (call only when there is just a single unknown left)
sub bottom {
  my $bone = shift;

  die "Bones: multiple bottom nodes exist\n" if $bone->[0] > 1;
  return $bone->[1];
}

# how many unknowns on left side?
sub unknowns {
  my $bone = shift;
  return $bone->[0];
}

# how many knowns on right side?
sub knowns {
  my $bone = shift;
  return @$bone - $bone->[0];
}


# For extracting the actual known or unknown elements, rather than
# return a list or spliced part of it, return the range of the knowns
# part of the array for the caller to iterate over. (more efficient)
#
# Both the following subs return an inclusive range [first, last]
# that's suitable for iterating over with for ($first .. $last)
#

sub knowns_range {
  my $bone = shift;
  return ($bone->[0] + 1, scalar(@$bone) - 1); 
}

# unknowns_range can return [1, 0] if there are no unknowns. Beware!
sub unknowns_range {
  my $bone = shift;
  return (1, $bone->[0]); 
}

# The following two routines find a single unknown, shift it to the
# start of the array and mark all other nodes as known (used in
# propagation rule). They differ only in whether a node number or a
# graph are passed in. (modelled on C code)
sub known_unsolved {

  my ($bone, $node) = @_;

  # If given a node number, we just scan the list to find it

  for (1 .. $bone->[0]) {
    if ($node == $bone->[$_]) {
      @{$bone}[$_,1] = @{$bone}[1,$_] if $_ != 1;
      $bone->[0] = 1;
      return $bone->[1];
    }
  }
  die "Bones: Didn't find unsolved node $node\n";
}

sub unknown_unsolved {

  my ($bone, $graph) = @_;

  # If given a graph, we look up nodes in it to see if they're solved

  for (1 .. $bone->[0]) {
    if (!$graph->{solution}->[$bone->[$_]]) {
      @{$bone}[$_,1] = @{$bone}[1,$_] if $_ != 1;
      $bone->[0] = 1;
      return $bone->[1];
    }
  }
  die "Bones: Bone has no unsolved nodes\n";
}


# We can use the propagation rule from an aux block to a message
# block, but if the aux block itself is not solved, we end up with two
# unknown values in the list. This routine takes the aux block number
# and the single unknown down edge, marks both of them as unknown and
# the rest as known.
sub two_unknowns {
  my ($bone, $graph)   = @_;
  my ($index, $kindex) = (1,1);
  my $unknowns         = $bone->[0];

  print "two_unknowns: Looking for two unsolved in " . $bone->pp . 
    " (had $unknowns unknowns)\n";

  while ($index <= $unknowns + 1) {
    my $node = $bone->[$index];
    print "two_unknowns: Considering node $node at index $index\n";
    if ($graph->{solution}->[$node]) {
      print "two_unknowns: Node $node is solved; skipping\n";
      --$unknowns;
    } else {
      print "two_unknowns: Node $node is unsolved; shuffling to position $kindex\n";
      @{$bone}[$index,$kindex] = @{$bone}[$kindex,$index]
	if $index != $kindex;
      ++$kindex;
    }
    ++$index;
  }
  die "Bones: didn't find two unknowns\n" unless $kindex == 3;

  # swap elments if needed so that message node is first
  @{$bone}[1,2] = @{$bone}[2,1] if $bone->[1] > $bone->[2];
 
  $bone->[0] = 2;

  print "two_unknowns: Final contents are " . $bone->pp . "\n";

  return $bone->[1];
}

# "pretty printer": output in the form "[unknowns] <- [knowns]"
sub pp {

  my $bone = shift;
  my ($s, $min, $max) = ("[");

#  print "raw bone is ". (join ",", @$bone) . "\n";

  ($min, $max) = $bone->unknowns_range;
#  print "unknown range: [$min,$max]\n";
  $s.= join ", ", map { $bone->[$_] } ($min .. $max) if $min <= $max;

  $s.= "] <- [";

  ($min, $max) = $bone->knowns_range;
#  print "known range: [$min,$max]\n";
  $s.= join ", ", map { $bone->[$_] } ($min .. $max) if $min <= $max;

  return $s . "]";

}

1;

=head1 NAME

Net::OnlineCode::Bones - Graph decoding internals 

=head1 DESCRIPTION

This page gives an overview of how the decoding algorithm for Online
Codes work.

The decoding algorithm can be described in one of two ways:

=over

=item * in terms of solving a set of algebraic equations; and

=item * in terms of resolving a graph.

=back

The first of these explains I<what> the algorithm does, while the
second describes I<how> it does it.

=head2 Solving a system of algebraic equations

Recall that the Online Codes algorithm works with:

=over

=item * I<message> blocks, which are portions of the original file

=item * I<auxiliary> blocks, which are the XOR sum of one or more
I<message> blocks.

=item * I<check> blocks,  which are the XOR sum of one or more
I<message> and/or I<auxiliary> blocks.

=back

On the encoder side, the algorithm generates I<auxiliary> blocks by
using a pseudo-random number generator (PRNG). These blocks are stored
locally by the encoder, but are never transmitted. However, by sending
the seed value for the PRNG to the decoder, the decoder knows how the
auxiliary blocks were constructed, even though it does not know the
values of them. In other words, give the PRNG seed value, the decoder
can construct a set of equations, one for each auxiliary block:

 aux   = msg   XOR msg   XOR ...
    1       x         y         ...
 aux   = ...
    2
   :


Initially, all the values in these equations are unknown on the
decoder side.

As for I<check> blocks, the encoder picks a random seed value for its
PRNG and uses this to generate a list of message and/or check blocks
to XOR together to calculate the check block's value. It sends both
the seed used and the final XOR value to the decoder. As with
auxiliary blocks, the decoder can use the PRNG with the transmitted
seed value to construct an equation for a received check block:

 chk  = msg_or_aux  XOR msg_or_aux   XOR ...
    1             x               y

Unlike the equations constructed for auxiliary blocks, however, the
value of the check block is also sent to the decoder, so each equation
includes a single known value on the left-hand side of the
equation.

Before the first check block is received, the decoder has a set of
equations involving unknown values. As check blocks are received,
eventually one of them will be composed of just a single message or
auxiliary block. In algebraic terms, we have:

 chk    = msg_or_aux
    x               y

Since there is just a single unknown value in the equation, we can
reverse the order of it and use the new form of the equation

 msg_or_aux    = chk
           y        x

Since we have a single unknown value on the left side and only known
values on the right side, this new rule solves the value on the left.
Now wherever this message/aux block appears in another equation, we
can substitute the right side of the equation. This removes one
unknown value from the set of equations each time this step is taken.

Decoding progresses in this way by finding an equation with only a
single unknown value, solving that unknown value then substituting the
result into any other equation that mentions this value. This proceeds
until there are no unknowns left. At that point the entire file has
been "solved".

=head2 Solution in terms of a graph

The method of solving all of the equations above can be re-expressed
in terms of a graph. Nodes in the graph represent blocks, while the
edges capture the relation between blocks on the left side of an
equation and those on the right. So for example, a check block C
(on the left hand side of an equation) is composed of an auxiliary
node A and a message node M is represented by:

=over

=item * three nodes M, A and C

=item * an edge between M and C

=item * an edge between A and C

=back

There is also an additional structure imposed on the nodes in the
graph so that edges can be unambiguously identified as belonging to a
particular equation. Technically, the graph is a I<bipartite>
graph. It keeps each of the block types grouped with other blocks of
that type and orders the groups like so:

 message blocks < auxiliary blocks < check blocks

Graphically, the example rule above could be illustrated as follows:

  message           auxiliary           check
 
     M <--------------------------------- C
                                        /
                        A <------------/
 

This diagram could equally have been written with the check blocks on
the left and the message blocks on the right, or turned 90
degrees. It's merely a matter of convention, similar to the two ways
of writing out the equation as either:

 C <- M xor A

or 

 M xor A -> C

For the remainder of the document, I'll go with the convention of
saying that auxiliary blocks are to the right of the message blocks
and check blocks are to the right of both of them. (My code uses a
different convention again and talks about check nodes being higher
than auxiliary and message nodes).

Besides information about edges, the graph also stores a status bit
for each node to indicate whether that node is known (solved) or
unknown. Check nodes are always taken to be solved since the encoder
sends the value of that block, whereas message and auxiliary nodes are
all initially unknown/unsolved.

In the explanation of the algebraic interpretation, I talked about
finding an equation that had just a single unknown and rearranging it
so that the single unknown value moves to one side and all the other
knowns move to the other side. There is an analoguous operation on the
graph, and this is named the "propagation rule".

The propagation rule involves finding a known node which has exactly
one unsolved neighbour on the left. In the above example, if we are
considering whether to propagate from node C (which is known) both M
and A are unknown, so the rule does not match. If, on the other hand,
one of M or A are known, the rule does match.

When the propagation rule matches, the solution for the newly-solved
node on the left becomes the XOR of the node on the right plus all the
other nodes emanating from that (right) node. When a node is solved in
this way, all edges from the node on the right are removed from the
graph.

In my code, the propagation rule is handled in a routine called
resolve().

=head2 Cascades

When matched, the propagation rule solves one extra node somewhere to
the left of the starting node. In the algebraic interpretation, I
talked about substituting a newly-solved variable into all other
equations where the variable appeared. There is an analogous procedure
in the graph-based implementation, which is implemenented in the
cascade() routine.

For the sake of discussion, let's assume that the message block M was
solved by the propagation rule and that it had the solution:

 M <- A xor C

To simulate substituting M into all other equations where it appears,
we need to work backwards (from left to right) from node M and see if
any of those nodes now match the propagation rule. Since there will be
one rightward edge in the graph from that node for each equation the
left node appears in, this effectively reaches all equations that
could could become solvable.

In the case where the left node which has become solved is an
auxiliary block, the cascade() routine also queues up the auxiliary
node itself for checking the propagation rule.

=head2 Special handling for auxiliary nodes

Although in theory the propagation rule could be applied to unsolved
auxiliary nodes, in practice this has proved troublesome, so I have
not implemented it. Instead I have implemented a special "auxiliary
rule" that gives comparable results.

Recall that the propagation rule works with a single known node on the
right and a single unknown node on the left. It is also possible to
devise a rule where there is a message node on the left and an
unsolved aux rule on the right. If the auxiliary node has only one
unsolved left neighbour (ie the message node) and that message node
becomes solved, then the auxiliary block can be solved too.

Initially, each auxiliary block will be composed of some number of
message blocks:

 aux   = msg   xor  msg   xor ...
    x       i          j

When the last unsolved message block on the right becomes solved then
this equation has no more unknowns apart from the aux block
itself. Therefore, it can be marked as solved (with the above
solution) and we can cascade up from that aux block to see if it
solves any more equations.

=head2 Optimising by tracking counts of unsolved left nodes

When aux or check nodes are created, the number of unknown/unsolved
edges that they are comprised of is calculated. Whenever a node
becomes solved, each of the nodes that include that node in its list
of edges has their unsolved count decremented.

This improves performance by avoiding having to scan the node's full
list of leftward edges when it is considered for resolving.

=head2 "Bones" ("Bundles of Node Elements")

In a previous version of the program, edges in the graph were stored
by keeping track of the left (bottom) end of the edge in a hash, while
the right (top) end was stored in a list. I also had a separate array
for storing the solutions of each node. The "Bones" structure
essentially combines the top part of the edge and the solution into a
single fixed-size array. This was done to improve performance by
eliminating lots of list copying as the graph was processed.

The Bones structure is a fixed-sized array with three elements:

=over

=item * count of unsolved left (down) edges

=item * node ids of unsolved left (down) edges

=item * list of known node ids

=back

Bones can also be viewed as encapsulating an algebraic equation of the
form:

 [unknown nodes] <- [known nodes]

At the start of decoding, each auxiliary node has a Bone object
created for it:

 [aux node, message nodes] <- []

That is, the aux node and all its constituent message nodes are all
marked as unknown/unsolved (there are no knowns in the equation).

The "Bone" is attached to the auxiliary node and reciprocal links (the
other end of the edges) are created in each of the component message
nodes. All the nodes in the left hand side except the aux node itself
are considered to be the top parts of edges.

When a check node is created, its Bone is of the form:

 [unsolved msg/aux nodes] <- [ check node, solved msg/aux nodes ]

The check node is placed on the right along with other known nodes
because the decoder knows the value of all received check nodes.
Reciprocal links are only created for unsolved nodes.

As can be seen, Bones have aspects of algebraic equations, but they
also encapsulate edge structure.

As nodes become solved by the propagation or auxiliary rule, elements
are shifted in the array to take this form:

 [newly-solved node] <- [list of nodes to XOR to get value]

This is exactly the form of a solution to a node, so the Bone is
stored in the solution array. The right-hand side is also scanned and
any reciprocal links are deleted, as is the top part of the edge.

In summary, a Bone always represents an equation. At the start of the
decoding process it also encapsulates edge structure, but at the end
it becomes a solution for either a message block or an auxiliary block.

From version 0.04 of the Net::OnlineCode modules onwards, the resolver
returns a Bone object for each solved node. It will always be an array
of the form mentioned above, and encoded as follows:

 [
    1,           # the number of "unknowns"
    msg_or_aux,  # the node that was just solved
    list of component nodes 
 ]

