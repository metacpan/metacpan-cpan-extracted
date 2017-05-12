package Parse::Vipar::Graph; # -*- cperl -*-
use strict;
use Carp;

sub PI () { atan2(0, -1) };
my $SCALE = 1.7;

sub note ($) {
#    print $_[0];
}

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub newnode {
    my ($self, $id) = @_;
    $self->{nodes}->{$id} = bless { id => $id, in => [], out => [] }, 'node';
}

sub addedge {
    my ($self, $from, $to, $label) = @_;
    $from = $self->{nodes}->{$from}
      unless UNIVERSAL::isa($from, 'node');
    $to = $self->{nodes}->{$to}
      unless UNIVERSAL::isa($to, 'node');

    push @{ $from->{out} }, $to;
    push @{ $to->{in} }, $from;

    $self->{edges}->{$from,$to} = [ $from, $to ];
    $self->{edgelabels}->{$from,$to} = $label;
    $self->{backedges}->{$to,$from} = [ $to, $from ];
}

sub edgelabel {
    my ($self, $from, $to) = @_;
    my $fwd = $self->{edgelabels}->{$from,$to};
    my $back = $self->{edgelabels}->{$to,$from};
    # HACK
    if (defined $fwd && defined $back) {
        return ">$fwd\n<$back";
    } else {
        return $fwd;
    }
}

sub nodes {
    my $self = shift;
    return values %{ $self->{nodes} };
}

sub max_outdegree {
    my ($self, @nodes) = @_;
    my $max = 0;
    my $maxnode;

    foreach my $node (@nodes) {
        my $outdegree = @{ $node->{out} };
        if ($max < $outdegree) {
            $max = $outdegree;
            $maxnode = $node;
        }
    }

    return $maxnode;
}

sub undirected_dfs {
    my ($self, $start, $howfar, @nodes) = @_;

    $self->{distance}->{$start} = $howfar;
    $start->{distance} = $howfar;
    delete $start->{forward};

    my %nodes = map { $_ => 1 } @nodes;
    my @neighbors = grep { exists $nodes{$_} }
      (@{ $start->{out} }, @{ $start->{in} });

    foreach (@neighbors) {
        next if exists $self->{distance}->{$_};
        $_->{back} = $start;
        push(@{ $start->{forward} }, $_);
        undirected_dfs_work($self, $_, $howfar+1, @nodes);
    }
}

sub undo_dfs {
    my ($self, @nodes) = @_;
    delete $self->{distance};
    foreach my $node (@nodes) {
        delete $node->{back};
        delete $node->{forward};
        delete $node->{distance};
    }
}

sub grab_node_line {
    my ($self, @nodes) = @_;

    my $maxnode = $self->max_outdegree(@nodes);
    $self->undo_dfs(@nodes);
    $self->undirected_dfs($maxnode, 0, @nodes);

    # Find farthest from $maxnode (should not be called with an empty graph)
    my $farthest;
    my $max = 0;
    foreach my $node (@nodes) {
        my $d = $node->{distance};
        if ($max < $d) {
            $max = $d;
            $farthest = $node;
        }
    }

    # Kill the path back from $farthest
    my $node = $farthest;
    $node->{taken} = 1 while (($node = $farthest->{back}) != $maxnode);
    # (should not be called with a single node graph)
    $maxnode->{taken} = 1;

    # Find the farthest remaining node (should not be called with graph size 2)
    my $other_farthest;
    $max = 0;
    foreach my $node (@nodes) {
        next if $node->{taken};
        my $d = $node->{distance};
        if ($max < $d) {
            $max = $d;
            $other_farthest = $node;
        }
    }

    # Clean up mess
    delete $_->{taken} foreach (@nodes);

    my @path; # farthest -> maxnode -> other_farthest

    push(@path, $node = $farthest);
    push(@path, $node) while (($node = $node->{back}) != $maxnode);
    push(@path, $maxnode);
    # @path now is farthest -> maxnode

    my @subpath = ($node = $other_farthest);
    push(@subpath, $node) while (($node = $node->{back}) != $maxnode);
    push(@path, reverse @subpath);

    return @path;
}

sub generate_circles {
    my ($self, $center) = @_;
    $self->{circle}->[0] = [ $center ];
    my $circle = 0;
    $center->{circled} = 1;
    $center->{angle} = 0;
    $center->{x} = 0;
    $center->{'y'} = 0;

    note "Node in center: $center->{id}\n";

    my @inner = ($center);
    while (1) {
        $circle++;

        my %neighbors;
        $neighbors{$_->{id}} = $_
          foreach (map { (@{$_->{out}}, @{$_->{in}}) } @inner);

        note "(Possibly duplicated) neighbors: ".join(" ", map $_->{id}, values %neighbors)."\n";
        my @outer = grep { ! $_->{circled} } (values %neighbors);
        note "Nodes in circle $circle: ".join(" ", map $_->{id}, @outer)."\n";
        last if @outer == 0;

        $self->{circle}->[$circle] = [ @outer ];
        $_->{circled} = 1 foreach (@outer);
        @inner = @outer;
    }

    push @{ $self->{circle}->[$circle-1] },
      grep { @{$_->{in}} == 0 && @{$_->{out}} == 0 } $self->nodes();

    $self->{numcircles} = $circle;
    note "$circle total circles\n";
}

sub normalized ($) {
    use POSIX;
    my $angle = shift;
    return POSIX::fmod($angle + 7 * PI, 2 * PI) - PI;
}

sub todegrees ($) {
    my $angle = shift;
    return int((normalized($angle)+PI)/2/PI*360);
}

sub angledesc ($) {
    my $angle = shift;
    sprintf("%2.3f=%2.3f=".todegrees($angle)."deg",$angle,normalized($angle));
}

sub coorddesc {
    my $x = shift;
    my $y;
    if (ref $x eq 'ARRAY') {
        ($x, $y) = @$x;
    } else {
        $y = shift;
    }
    sprintf("(%3.2f,%3.2f)", $x, $y);
}

sub groupdesc {
    return "[".join(" ", map $_->{id}, @_)."]";
}

sub groupangledesc {
    my $g = shift;
    return "(don't care)" if ! exists $g->{angle};
    return todegrees($g->{angle})." := atan2".coorddesc($g->{cog}->[1], $g->{cog}->[0]);
}

sub place_near_neighbors {
    my ($self, $nodes, $neighbors, $radius) = @_;

    my @groups = $self->separate_by_connectedness(@$nodes);

    # Compute average center of gravity for each connected component
    for my $group (@groups) {
        my @nodes = @{$group->{nodes}};
        my @cogs = map { $self->center_of_gravity($_, $neighbors) } @nodes;
        my $cog;
        if (@cogs) {
            my ($x, $y) = (0, 0);
            foreach (@cogs) {
                $x += $_->[0];
                $y += $_->[1];
            }
            $x /= @cogs;
            $y /= @cogs;
            $group->{cog} = [ $x, $y ];
            # Compute angle for that center of gravity
            $group->{angle} = atan2($y, $x)
              if ($y || $x);
        }
    }

    note "Angle $_->{desc} = ".groupangledesc($_)."\n" foreach (@groups);

    # Sort by angle (-PI .. PI)
    my @toplace = grep { exists $_->{angle} } @groups;
    @toplace = sort { $a->{angle} <=> $b->{angle} } @toplace;

    my $min_distance = 0.95;
    my $min_angle = $min_distance / ($radius * $SCALE);

    # Place things as close to their preferred angles as
    # possible. Do not permute the order, and do not place
    # anything closer than $min_angle.

    # Algorithm: let the first group have its preferred
    # placement. Then each succeeding group gets its preferred
    # placement if possible, otherwise put it as close after the
    # preceding group as possible. If there isn't enough space for
    # everything, abort and place everything evenly around the
    # circle.

    my $first;
    my $prev;
    foreach my $group (@toplace) {
        my $n = @{ $group->{nodes} };
        my $start_angle = $group->{angle} - $min_angle * ($n-1)/2;

#        note "Group: $group->{desc} first=$first prev=$prev req=$group->{angle}\n";

        if (defined $prev && $start_angle - $prev < $min_angle) {
            $start_angle = $prev + $min_angle;
            note "Bumping start angle to $start_angle\n";
        }
        my $end_angle = $start_angle + $min_angle * ($n-1);
        $first = $start_angle if (!defined $first);
        $prev = $end_angle;

        foreach (@{ $group->{nodes} }) {
            $_->{angle} = $start_angle;
            note "Placed $_->{id} at $start_angle\n";
            $start_angle += $min_angle;
        }
    }

    # Check to see if we wrapped around
    if (defined $prev && $prev > PI && ($prev - PI) > $first) {
        note "Giving up ($prev > $first)\n";
        # Give up
        foreach my $group (@toplace) {
            delete $_->{angle} foreach (@{ $group->{nodes} });
        }
    }

    return if !defined wantarray;

    my @placed = grep { exists $_->{angle} } @$nodes;
    my @unplaced = grep { ! exists $_->{angle} } @$nodes;

    return \@placed, \@unplaced;
}

sub place_circles {
    my $self = shift;

    # Kick things off by fixing down the outermost circle
    spread_around_circle($self->{circle}->[-1], $self->{numcircles}-1);
    assign_coords($self->{circle}->[-1], $self->{numcircles}-1);

    my $circle = $self->{numcircles} - 1;

    my @outer = @{ $self->{circle}->[-1] };

    # Now go to each inner circle and place it according to the next outer
    while (--$circle > 0) {
        note "\nPlacing circle $circle relative to outer...\n";
        my ($placed, $unplaced) =
          $self->place_near_neighbors($self->{circle}->[$circle], \@outer, $circle);
        push @outer, @$placed;
        assign_coords($placed, $circle);
    }

    # Repeat, except this time place unplaced things according to
    # their inner attachments, and force everything to be placed
    $circle = 0;
    my @inner = ();
    while (++$circle < $self->{numcircles}) {
        note "\nPlacing circle $circle relative to inner...\n";
        my @nodes = @{ $self->{circle}->[$circle] };
        my @toplace = grep { ! exists $_->{angle} } @nodes;
        $self->place_near_neighbors(\@toplace, \@inner, $circle);
        spread_around_circle(\@nodes, $circle);
        push @inner, @nodes;
        assign_coords(\@nodes, $circle);
    }
}

# Assign the (x,y) coordinates based on the angles of the given nodes.
sub assign_coords {
    my ($nodes, $radius) = @_;

#    confess "nothing to spread" if ! @$nodes;

    foreach my $node (@$nodes) {
        next if (!exists $node->{angle});
        $node->{x} = cos($node->{angle}) * $radius * $SCALE;
        $node->{'y'} = sin($node->{angle}) * $radius * $SCALE;
#        note "Assigned: $node->{angle},$radius => ($node->{x},$node->{y})\n";
    }
}

# Spread the given nodes evenly around a circle, obeying already placed nodes
sub spread_around_circle {
    my ($nodes, $radius) = @_;

    my @placed = grep { exists $_->{angle} } @$nodes;
    my @unplaced = grep { ! exists $_->{angle} } @$nodes;

    note "placed: ".groupdesc(@placed)."\n";
    note "unplaced: ".groupdesc(@unplaced)."\n";

    @placed = sort { $a->{angle} <=> $b->{angle} } @placed;

    # No nodes placed yet? Distribute things evenly around the circle.
    if (! @placed) {
        my $step = 2*PI / @unplaced;
        my $angle = -1*PI/2;
        foreach (@unplaced) {
            $_->{angle} = normalized($angle);
#            note "Spread: (no node) placed $_->{id} at $_->{angle} rad\n";
            $angle += $step;
        }
        return;
    }

    while (@unplaced) {
        note "".(0+@unplaced)." unplaced nodes remaining\n";
        my @angles = map $_->{angle}, @placed;
        push @angles, $placed[0]->{angle}+2*PI;
#        note "angles=".join(" ", map sprintf("%3.2f", $_), @angles)."\n";

        my @gaps = map { [ $angles[$_], $angles[$_+1] ] } (0 .. $#angles-1);

        # Only one node placed? Distribute the rest evenly around the
        # rest of the circle
        if (@gaps == 1) {
            my $step = ($gaps[0]->[1] - $gaps[0]->[0]) / (@unplaced + 1);
            my $angle = $gaps[0]->[0];
            note "angle=$angle step=$step\n";
            foreach (@unplaced) {
                $angle += $step;
#                note "Prenorm: $angle\n";
                $_->{angle} = normalized($angle);
#                note "Spread: (one gap) placed $_->{id} at $_->{angle} rad\n";
            }
            return;
        }

        my ($g0, $g1) = sort { ($b->[1] - $b->[0]) <=> ($a->[1] - $a->[0]) }
          @gaps;

#        note "Gaps: ";
#        foreach (@gaps) {
#            note "$_->[0]..$_->[1] ";
#        }
#        note "\n";

#        note "g0=$g0->[0]..$g0->[1]\n";

        # Multiple nodes placed. Stuff in one more than the minimum
        # necessary to divide the largest gap into a gap smaller than
        # the next largest and recurse.

        my $w0 = $g0->[1] - $g0->[0];
        my $w1 = $g1->[1] - $g1->[0];
        my $num_to_place = 1 + int($w0 / $w1);
        if ($num_to_place > @unplaced) {
            $num_to_place = @unplaced;
        }

        my $step = $w0 / ($num_to_place + 1);
        my $angle = $g0->[0] + $step;
        for (1 .. $num_to_place) {
            my $node = pop(@unplaced);
            $node->{angle} = $angle;
#            note "Spread: placed $node->{id} at $node->{angle} rad\n";
            push(@placed, $node);
            $angle += $step;
        }
    }
}

sub center_of_gravity {
    my ($self, $node, $shell) = @_;
    my $id = $node->{id};

    confess("not array") if (ref $shell ne 'ARRAY');

    note "Computing cog for node $id based on ".groupdesc(@$shell).": ";

    my @neighbors =
      grep {
          my $sid = $_->{id};
          exists $self->{edges}->{$node,$_}
            || exists $self->{edges}->{$_,$node} } @$shell;

    do { note "none (unconnected)\n"; return } if @neighbors == 0;

    # Is this really correct?
    my $x = 0;
    $x += $_->{x} foreach (@neighbors);
    $x /= @neighbors;

    my $y = 0;
    $y += $_->{'y'} foreach (@neighbors);
    $y /= @neighbors;

    if (abs($x) + abs($y) < 1e-6) {
        $x = $y = 0;
    }

#    printf("(%4.2f,%4.2f) due to ".groupdesc(@neighbors)."\n", $x, $y);
    return [ $x, $y ];
}

# Separate into groups of connected things
sub separate_by_connectedness {
    my ($self, @nodes) = @_;

    my @groups;
    while (@nodes) {
        my $avatar = pop(@nodes);
        my $id = $avatar->{id};
        my (@in, @out);

        foreach (@nodes) {
            my $sid = $_->{id};
            my $inflag = exists $self->{edges}->{$id,$sid}
              || exists $self->{edges}->{$sid,$id};
            push @in, $_ if $inflag;
            push @out, $_ if ! $inflag;
        }

        my @group = $self->linear_order($avatar, @in);
        confess "not same size" if @group != @in + 1;
        push(@groups, \@group);
        @nodes = @out;
    }

    # Convert from array ( [ node ] ) to
    # list of hashes ( { nodes => [ node ] } )
    @groups = map { { nodes => $_ } } @groups;

    # Add in descriptions
    $_->{desc} = groupdesc(@{$_->{nodes}}) foreach (@groups);

    return @groups;
}

# Take a wad of connected nodes and order them appropriately.
sub linear_order {
    my ($self, @nodes) = @_;
    return @nodes if (@nodes <= 2);
    return $self->grab_node_line(@nodes);
}

sub dump {
    my $self = shift;
    foreach my $node ($self->nodes()) {
        note "Node $node->{id}\n";
        note "  OUT: $node->{id} -> $_->{id}\n" foreach (@{ $node->{out} });
        note "  IN : $node->{id} <- $_->{id}\n" foreach (@{ $node->{in} });
    }
}

sub layout {
    my ($self) = @_;
    my $maxnode = $self->max_outdegree($self->nodes());
    note "Max outdegree: node #$maxnode->{id}\n";
    $self->generate_circles($maxnode);
    $self->place_circles();
}

1;

#############################################################################

package Parse::Vipar::Graph::View;

sub phase ($) {
    print $_[0];
}

sub init {
    my ($class, $canvas, $graph) = @_;
    return bless { c => $canvas,
                   graph => $graph,
                   width => $canvas->cget(-width),
                   height => $canvas->cget(-height) }, $class;
}

sub scaleX { my $state = $_[0]; $_[1] = $_[1] * 40 + $state->{width} / 2 }
sub scaleY { my $state = $_[0]; $_[1] = $_[1] * 40 + $state->{height} / 2 }

sub placenode ($$$$) {
    my ($state, $x, $y, $id) = @_;
    my $canvas = $state->{c};
    $state->scaleX($x);
    $state->scaleY($y);
    my $tags = [ "node_$id", 'nodes' ];
    my $text = $canvas->create('text', $x, $y, -text => $id,
                               -tags => [ @$tags, "node_text_$id" ]);
    my @bbox = $canvas->bbox($text);
    $bbox[0] -= 1;
    $bbox[1] -= 1;
    $bbox[2] += 1;
    $bbox[3] += 1;
    return $canvas->create('oval', @bbox, -tags => $tags,
                           -tags => [ @$tags, "node_oval_$id" ]);
}

sub edgecoords {
    shift if UNIVERSAL::isa($_[0], __PACKAGE__);
    my ($delta, $x0, $y0, $x1, $y1) = @_;
    my $theta = atan2($y1 - $y0, $x1 - $x0);
    my $dx = $delta * cos($theta);
    my $dy = $delta * sin($theta);
    return ($x0 + $dx, $y0 + $dy, $x1 - $dx, $y1 - $dy);
}

sub drawedge ($$$$$$$$$) {
    my ($state, $x0, $y0, $x1, $y1, $dir, $node1, $node2, $label) = @_;
    my $canvas = $state->{c};
    $state->scaleX($x0);
    $state->scaleY($y0);
    $state->scaleX($x1);
    $state->scaleY($y1);

    my $amt = 7;

    my @coords = edgecoords($amt, $x0, $y0, $x1, $y1);
    my $arrow = 'last';
    $arrow = 'first' if $dir eq '<-';
    $arrow = 'both' if $dir eq 'both';
    my $tags = [ $label, 'edges',
                 "from_$node1->{id}",
                 "to_$node2->{id}" ];
    my $line = $canvas->create('line', @coords,
                               -arrow => $arrow,
                               -fill => 'red',
                               -tags => $tags);

    my ($mx, $my) = (($x0 + $x1)/2, ($y0+$y1)/2);
    $canvas->create('text', $mx, $my, -text => $label, -anchor => 'center',
                    -tags => "label_$line");
    $canvas->Subwidget('canvas')->lower('edges'); # Doesn't work
    return $label;
}

sub drawloop {
    my ($state, $x, $y, $label) = @_;
    my $canvas = $state;
}

sub bind {
    my ($state) = @_;
    my $c = $state->{c}; # Canvas

    my ($lastx, $lasty); # Global vars

    $c->bind('nodes', '<1>', sub {
                 $lastx = $Tk::event->x;
                 $lasty = $Tk::event->y });

    $c->bind('nodes', '<B1 Motion>',
             sub {
                 my ($x, $y) = ($Tk::event->x, $Tk::event->y);
                 my ($tag) = grep { /^node_/ } $c->gettags('current');
                 my ($dx, $dy) = ($x - $lastx, $y - $lasty);
                 $c->move($tag, $dx, $dy);
                 $lastx = $x;
                 $lasty = $y;
                 my ($label) = $tag =~ /^node_(.*)$/;
                 my @from = $c->find('withtag', "from_$label");
                 foreach (@from) {
                     my @coords = $c->coords($_);
                     $coords[0] += $dx;
                     $coords[1] += $dy;
                     $c->coords($_, @coords);
                     $c->coords("label_$_",
                                ($coords[0]+$coords[2])/2,
                                ($coords[1]+$coords[3])/2);
                 }
                 my @to = $c->find('withtag', "to_$label");
                 foreach (@to) {
                     my @coords = $c->coords($_);
                     $coords[-2] += $dx;
                     $coords[-1] += $dy;
                     $c->coords($_, @coords);
                     $c->coords("label_$_",
                                ($coords[0]+$coords[2])/2,
                                ($coords[1]+$coords[3])/2);
                 }
             });
}

sub draw {
    my ($state, @nodes) = @_;
    my $graph = $state->{graph};

    phase "Placing nodes...\n";
    if ($graph->nodes() > 300) {
	print "Aborting node placement. Too many nodes to make sense of.\n";
	return;
    }
    $state->placenode($_->{x}, $_->{'y'}, $_->{id})
      foreach (grep { defined $_->{x} } $graph->nodes());

    phase "Constructing edge view objects...\n";
    my $N = keys %{ $graph->{edges} };
    if ($N > 800) {
	print "Aborting edge placement. Too many of the damn things!\n";
	$state->{edges} = {};
	return;
    }

    my %edges;
    foreach (values %{ $graph->{edges} }) {
        if ($_->[0] == $_->[1]) {
            $edges{$_->[0],$_->[1]} = [ 'loop', $_->[0] ];
        } else {
            my $smaller = (($_->[0]->{id} cmp $_->[1]->{id})+1)/2;
            my ($a, $b) = @$_[$smaller,1-$smaller];
            if (exists $edges{$a,$b}) {
                $edges{$a,$b}->[0] = 'both';
            } else {
                $edges{$a,$b} = [ $smaller == 0 ? '->' : '<-', $a, $b ];
            }
        }
    }

    phase "Drawing edges...\n";
    my $n = 0;

    foreach (values %edges) {
        my ($dir, $n1, $n2) = @$_;
        my $label;

        if ($dir eq 'loop') {
            $label = $graph->edgelabel($n1,$n1);
            $state->drawloop($n1->{x}, $n1->{'y'}, $label);
        } else {
            $label = $graph->edgelabel($n1,$n2);
            $label = $graph->edgelabel($n2,$n1) if ($dir eq '<-');
            $state->drawedge($n1->{x}, $n1->{'y'},
                             $n2->{x}, $n2->{'y'},
                             $dir, $n1, $n2, $label);
        }

	if (++$n % 100 == 0) {
	    print "Placed $n/$N edges...\n";
	}
    }

    $state->{edges} = \%edges;
}

1;
