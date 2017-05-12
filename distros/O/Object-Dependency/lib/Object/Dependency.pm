
package Object::Dependency;

use strict;
use warnings;
use Scalar::Util qw(refaddr blessed);
use Hash::Util qw(lock_keys);
use Carp qw(confess);
use List::MoreUtils qw(uniq);
use Data::Dumper;   # XXX

my $debug = 0;

our $VERSION = 0.41;

sub new
{
	my ($pkg, %more) = @_;
	my $self = {
		addrmap		=> {},	# maps object id to object for non-stuck objects
		independent	=> {},  # set of objects that have no dependencies
		stuck		=> {},  # maps object id to object for stuck objects
		%more,
	};
	bless $self, $pkg;
	lock_keys(%$self);
	return $self;
}

sub newitem
{
	my ($self, $i) = @_;
	my $addr = refaddr($i) || $i;
	my %item = (
		dg_addr		=> $addr,	# item number
		dg_item		=> $i,		# reference to object
		dg_depends	=> {},		# items this depends upon
		dg_blocks	=> {},		# items that depend upon this item
		dg_active	=> 0,		# item has been returned by independent() but not unlocked or removed
		dg_lock		=> 0,		# item is locked
		dg_desc		=> undef,	# description
		dg_stuck	=> undef,	# item is stuck, why it's stuck
	);
	return %item if wantarray;
	my $o = bless \%item, 'Object::Dependency::Item';
	lock_keys(%$o);
	return $o;
}

sub get_item
{
	my ($self, $addr) = @_;
	return $self->{addrmap}{$addr} || $self->{stuck}{$addr};
}

sub get_addr
{
	my ($self, $item) = @_;
	my $addr = refaddr($item) || $item;
	die unless $self->{addrmap}{$addr} || $self->{stuck}{$addr};
	return $addr;
}

sub unlock
{
	my ($self, $item) = @_;
	my $da = refaddr($item) || $item;
	my $dao = $self->{addrmap}{$da} || $self->{stuck}{$da} or confess;
	$dao->{dg_lock} = 0;
}

sub add
{
	my ($self, $item, @depends_upon) = @_;
	for my $i ($item, @depends_upon) {
		my $addr = refaddr($i) || $i;
		next if $self->{addrmap}{$addr};
		next if $self->{stuck}{$addr};
		$self->{addrmap}{$addr} = $self->newitem($i);
		$self->{independent}{$addr} = $self->{addrmap}{$addr};
		printf STDERR "ADD ITEM %s\n", $self->desc($addr) if $debug;
	};
	my $da = refaddr($item) || $item;
	my $dao = $self->{addrmap}{$da} || $self->{stuck}{$da};
	delete $self->{independent}{$da}
		if @depends_upon;
	for my $d (@depends_upon) {
		my $addr = refaddr($d) || $d;
		my $o = $self->{addrmap}{$addr} || $self->{stuck}{$addr};
		$o->{dg_blocks}{$da} = $dao;
		$dao->{dg_depends}{$addr} = $o;
		$self->stuck_dependency($da, "Stuck on " . $self->desc($o))
			if $self->{stuck}{$addr};
	}
}

sub remove_all_dependencies
{
	my ($self, @items) = @_;
	my (@remove);
	for my $i (@items) {
		my $addr = refaddr($i) || $i;
		my $o = $self->{addrmap}{$addr} || $self->{stuck}{$addr};
		for my $ubi (keys %{$o->{dg_blocks}}) {
			my $unblock = delete $o->{dg_blocks}{$ubi};
			delete $unblock->{dg_depends}{$addr};
			$self->remove_all_dependencies($unblock);
			push(@remove, $unblock);
			next if keys %{$unblock->{dg_depends}};
			next if $unblock->{dg_stuck};
			$self->{independent}{$unblock->{dg_addr}} = $unblock;
		}
	}
	$self->remove_dependency(grep { $self->{addrmap}{refaddr($_) || $_} || $self->{stuck}{refaddr($_) || $_} } uniq @remove);
}

sub is_dependency
{
	my ($self, $item) = @_;
	my $addr = refaddr($item) || $item;
	return defined($self->{addrmap}{$addr} || $self->{stuck}{$addr});
}

sub remove_dependency
{
	my ($self, @items) = @_;
	for my $i (@items) {
		my $addr = refaddr($i) || $i;
		if ($debug) {
			my($p,$f,$l) = caller;
			printf STDERR "REMOVE ITEM %s:%d: %s %s\n", $f, $l, $self->desc($addr), ($i->{desc} ? $i->{desc} : ($i->{trace} ? $i->{trace} : "$i"));
		}
		delete $self->{independent}{$addr};

		# we won't complain about removing stuck dependencies
		my $o = delete($self->{addrmap}{$addr}) || delete($self->{stuck}{$addr}) or confess;

		if (keys %{$o->{dg_depends}}) {
			printf STDERR "attempting to remove %s but it has dependencies that aren't met:\n", $self->desc($o);
			for my $da (keys %{$o->{dg_depends}}) {
				printf STDERR "\t%s\n", $self->desc($da);
			}
			die "fatal error";
		}
		for my $unblock (values %{$o->{dg_blocks}}) {
			delete $unblock->{dg_depends}{$addr};
			$unblock->{dg_active} = 0;
			next if keys %{$unblock->{dg_depends}};
			next if $unblock->{dg_stuck};
			$self->{independent}{$unblock->{dg_addr}} = $unblock;
		}
	}
}

sub stuck_dependency
{
	my ($self, $item, $problem) = @_;
	my $addr = refaddr($item) || $item;
	my $o = $self->{addrmap}{$addr} || $self->{stuck}{$addr};
	return if $o->{dg_stuck};
	confess unless blessed $o;
	$o->{dg_stuck} = $problem || sprintf("stuck called from %s line %d", (caller())[1,2]);
	$self->{stuck}{$addr} = $o;
	delete $self->{independent}{$addr};
	delete $self->{addrmap}{$addr};
	for my $also_stuck (keys %{$o->{dg_blocks}}) {
		$self->stuck_dependency($also_stuck, "Stuck on " . $self->desc($addr));
	}
}

sub independent
{
	my ($self, %opts) = @_;

	my $count = $opts{count} || 0;
	my $active = $opts{active} || 0;
	my $lock = $opts{lock} || 0;
	my $stuck = $opts{stuck} || 0;

	my @ind;
	for my $o (values %{$self->{$stuck ? 'stuck' : 'independent'}}) {
		next if $active && $o->{dg_active};
		next if $o->{dg_lock};
		push(@ind, $o->{dg_item});
		$o->{dg_active} = 1;
		$o->{dg_lock} = $lock;
		last if $count && @ind == $count;
	}
	return @ind if @ind;
	return () if keys %{$self->{independent}};
	return () unless keys %{$self->{addrmap}};
	confess "No independent objects, but there are still objects in the dependency graph:\n" . $self->dump_graph_string();
}

sub alldone
{
	my ($self) = @_;
	return 0 if keys %{$self->{independent}};
	return 0 if keys %{$self->{addrmap}};
	return 1;
}

sub desc
{
	my ($self, $addr, $desc) = @_;
	my $o;
	if (ref($addr)) {
		$o = $addr;
		$addr = refaddr($addr) || $addr;
	} else {
		$o = $self->{addrmap}{$addr} || $self->{stuck}{$addr};
	}
	return "NO SUCH OBJECT $addr" unless $o;
	my $node = $o->{dg_item};
	$o->{dg_desc} = $desc
		if defined $desc;
	$desc = '';
	$desc .= 'INDEPENDENT ' if $self->{independent}{$addr};
	$desc .= 'LOCKED ' if $o->{dg_lock};
	$desc .= 'ACTIVE ' if $o->{dg_lock};
	$desc .= "$addr ";
	if ($o->{dg_desc}) {
		$desc .= $o->{dg_desc};
	} elsif (blessed($node)) {
		if ($node->isa('Proc::JobQueue::Job')) {
			no warnings;
			$desc .= "JOB$node->{jobnum} $node->{status} $node->{desc}";
		} elsif ($node->isa('Proc::JobQueue::DependencyTask')) {
			$desc .= "TASK $node->{desc}";
		} else {
			die;
		}
	} else {
		$desc .= "???????????????????";
	}
	$desc .= " STUCK: $o->{dg_stuck}" if $o->{dg_stuck};
	return $desc;
}

sub dump_graph
{
	my ($self) = @_;
	print $self->dump_graph_string();
}

sub dump_graph_string
{
	my ($self) = @_;

	my $r = sprintf "Dependency Graph, alldone=%d\n", $self->alldone;
	my %desc;
	for my $addr (sort (keys %{$self->{addrmap}}, keys %{$self->{stuck}})) {
		$desc{$addr} = $self->desc($addr);
	}
	for my $addr (sort (keys %{$self->{addrmap}}, keys %{$self->{stuck}})) {
		$r .= "\t$desc{$addr}\n";
		my $node = $self->{addrmap}{$addr} || $self->{stuck}{$addr};
		for my $b (keys %{$node->{dg_blocks}}) {
			$r .= "\t\tBLOCKS\t$desc{$b}\n";
		}
		for my $d (keys %{$node->{dg_depends}}) {
			$r .= "\t\tDEP_ON\t$desc{$d}\n";
		}
	}
	return $r;
}

;

__END__

=head1 NAME

Object::Dependency - maintain a dependency graph

=head1 SYNOPSIS

 use Object::Dependency;

 my $graph = Object::Dependency->new()

 $graph->add($object, @objects_the_first_object_depends_upon)

 $graph->remove_dependency(@objects_that_are_no_longer_relevant)

 @objects_without_dependencies = $graph->independent;

=head1 DESCRIPTION

This module maintains a simple dependency graph.    
Items can be C<add>ed more than once to note additional depenencies.
Dependency relationships cannot be removed except by removing 
objects entirely.

We do not currently check for cycles so please be careful!  

Items are expected to be objects, but do not have to be.   Objects
are identified by their refadd() so if you combine objects and
other scalers, there is some chance of a collision between large
intetgers and the refaddr().  The C<undef> value will cause warnings.

=head1 CONSTRUCTION

Construction is easy: no parameters are expected.

=head1 METHODS

=over 

=item add($object, @depends_upon_objects)

Adds an item (C<$object>) to the dependency graph and notes which items
it depends upon.  The same object may be added multiple times so if you
want to declare what object depends upon an object, just use C<add>
in reverse multiple times.

The @depends_upon_objects are the prerequisites for $object.  $object
is blocked by its @depends_upon_objects.

=item remove_all_dependencies(@objects)

Removes the C<@objects> from the dependency graph.  
All objects dependent on C<@objects> will also be removed.

=item remove_dependency(@objects)

Removes the C<@objects> from the dependency graph.  
Dependencies upon
these objects will be considered to be satisfied.
Objects that had been dependent upon C<@objects> will no longer be
dependent upon them.

=item stuck_dependency($object, $description_of_problem)

Mark that the C<$object> will never be removed from the dependency graph because
there is some problem with it.   All objects that depend upon C<$object> will now
be considered "stuck".  Behavior of removing a stuck dependency is not defined.

=item independent(%opts)

Returns a list of objects that do not depend upon other objects.  Mark the returned
objects as active and locked.

Options are:

=over

=item count => COUNT

Return at most COUNT items.

=item active => 1

Normally active objects are included in the returned list.  With C<active =E<gt> 1>, 
active objects are not returned.  Yes, this is backwards.  Sorry.

=item lock => 1

Locked objects are not included in the returned list.  With C<lock =E<gt> 1>, 
objects are locked when they are returned.

=item stuck => 1

Normally items that have been marked as "stuck" are not returned.  With C<stuck =E<gt> 1>,
stuck objects are returned.  Stuck objects are not indpendent of the rest of the graph.
This capability is simply to provide a way to find out what is stuck.  With C<stuck =E<gt> 1>,
normal independent objects are not returned -- only stuck ones are returned.

=back

If the graph is not empty but there are no independent objects then there is a loop
in the graph and C<independent()> will die.  Wrap it in an C<eval()> if you care.

=item alldone()

Returns true if there are no non-stuck objects in the dependency graph.

=item desc($object, $description)

Sets the description of the object (if C<$description> is defined).

Returns the description of the object, annotated by it's dependency graph
status: LOCKED, INDEPENDENT, ACTIVE, or STUCK.

Special handling is done for L<Proc::JobQueue::Job> 
and L<Proc::JobQueue::DependencyTask> objects.

=item dump_graph / dump_graph_string

Prints/returns the dependency graph (described objects with the dependencies).

=item is_dependency($object)

Returns true if C<$object> is in the dependency graph.

=back

=head1 SEE ALSO

L<Proc::JobQueue::DependencyQueue>

=head1 LICENSE

Copyright (C) 2007-2008 SearchMe, Inc.
Copyright (C) 2009-2010 David Muir Sharnoff
Copyright (C) 2011-2014 Google, Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

