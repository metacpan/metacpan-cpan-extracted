package Paths::Graph;

@ISA = qw(Exporter);
@EXPORT_OK = qw/shortest_path() free_path_event() debug()/;

require 5.005_62;
our $VERSION = '0.03';

use strict;

# New Object 
sub new {
        my ($class , %vals)  = @_;
	my $self;
        bless $self = {	
			graph   => $vals{-graph},
			origin  => $vals{-origin},
			destiny => $vals{-destiny},
			sub	=> $vals{-sub},
	} , $class;
	return $self;
}

# Push array of array to analisys the graph's shortest cost.
sub push_paths {
        my ($self,@nodes) = @_;
	push @{$self->{paths}} , \@nodes;
}

# Return the result of nodes in recursive path
sub get_path_cost {
        my ($self,@nodes) = @_;
        return unless @nodes;
	my $ant_node = shift @nodes;
	my $cur_node = shift @nodes;
	return 0 if (!$cur_node) || 
		    ($ant_node eq $cur_node) || 
		    (!$self->{graph}{$ant_node}{$cur_node});
	return  $self->{graph}{$ant_node}{$cur_node} + $self->get_path_cost($cur_node,@nodes);
}

# Famous algorithm to get all possibles paths into the graph.
sub shortest_path {
	my ($self,$father) = @_;
	$father = 'zero' if $father eq '0';
	my $tmp = $self->{sub} if $self->{sub};
	$self->{sub} = \&push_paths;
	$self->free_path_event($father);
	$self->{sub} = $tmp;
	my ($minor_cost,$pass,%paths_minor_cost) = (0,0,());
	for my $path (@{$self->{paths}}) {
		my $cost = $self->get_path_cost(@{$path});
		if ( ($cost <= $minor_cost) || ($minor_cost == 0) ) {
			push @{$paths_minor_cost{$cost}} , $path; 
			$minor_cost = $cost;
		}
		$pass=1;
	}
	return @{$paths_minor_cost{$minor_cost}} if $pass;
	return [0] unless $pass;
}

#Execution time for feedback of the graph's paths.
sub free_path_event {
	my ($self , $father ) = @_;
	$father = 'zero' if $father eq '0';
	$father = $self->{origin} unless $father;
	$self->{fathers}{$father}=1;
	push @{$self->{path}} , $father;
	foreach my $node (keys %{$self->{graph}{$father}}) {
		my $pass=0;
		$pass=1 if $node eq $self->{origin} || $node eq $self->{destiny};
		if ($node eq $self->{destiny}) {
			push @{$self->{path}} , $self->{destiny};	
			$self->{sub}->($self,@{$self->{path}});
			pop @{$self->{path}};
		}
		$self->free_path_event($node) if (!$self->{fathers}{$node}) && (!$pass);
	}
	$self->{fathers}{$father}=0;
	pop @{$self->{path}};
}

#Educational method to undertand the steps to trace the graph.
sub debug {
	my ($self , $father ,$level) = @_;
	$father = 'zero' if $father eq '0';
	$level = 1 unless $level;
	$father = $self->{origin} unless $father;
	$self->debug_msg($level,"Node:[$father] Save node into path hash\n");
	$self->{fathers}{$father}=1;
	push @{$self->{path}} , $father;
	$self->debug_msg($level,"Node:[$father] Finding path into graph hash\n");
	foreach my $node (keys %{$self->{graph}{$father}}) {
		my $pass=0;
		$self->debug_msg($level,"_Node:[$node] Checking if is not origin or detiny Node\n");
		if ($node eq $self->{origin} || $node eq $self->{destiny}) {
			$self->debug_msg($level,"__Node:[$node] Is equal\n");
			$pass=1 
		} else {
			$self->debug_msg($level,"__Node:[$node] Is not equal\n");
		}
		$self->debug_msg($level,"_Node:[$node] Checking is Node equal destiny Node\n");
		if ($node eq $self->{destiny}) {
			$self->debug_msg($level,"__Node:[$node] Is equal\n");
			$self->debug_msg($level,"__Got Current Path :" . join("->",@{$self->{path}}) . "\n") ;
			push @{$self->{path}} , $self->{destiny};	
			#$self->{sub}->($self, @{$self->{path}});
			pop @{$self->{path}};
		} else {
			$self->debug_msg($level,"__Node:[$node] Is not equal\n");
		}
		$self->debug_msg($level,"_Node:[$node] Calling method self recurcive\n");
		$self->debug($node,$level + 1) if (!$self->{fathers}{$node}) && (!$pass);
	}
	$level--;
	$self->{fathers}{$father}=0;
	my $tmp = pop @{$self->{path}};
	$self->debug_msg($level,"Node[$father] Exiting Node\n");
}

# Show messages sended from education method debug
sub debug_msg {
	my ($self, $level , $msg ) = @_;
	print "|_" for 1 .. $level;
	print $msg;
	sleep 1;
}


1;
__END__

=head1 NAME

Path::Graph - Generate paths from hash graph.

=head1 SYNOPSIS

=head2 Code 1

#!usr/bin/perl

my %graph = (
                A => {B=>1,C=>4},
                B => {A=>1,C=>2},
                C => {A=>4,B=>2}

);

use Paths::Graph;

my $g = Paths::Graph->new(-origin=>"A",-destiny=>"C",-graph=>\%graph);

my @paths = $g->shortest_path();

for my $path (@paths) {

        print "Shortest Path:" . join ("->" , @$path) . " Cost:". $g->get_path_cost(@$path) ."\n";

}


=head1 RECOMMENDED

Understanding the Graph's filosofy and how to trace it. 

Reach for graph's books , also Dijkstra's algorithm.

=head1 ABSTRACT

This example cover all possibilities to find the graph's paths from Node A to Node C and the cost for itself.

=head2 Graph

		     (A)---4---(C)
		    /   \     /   \
		   2     1   2     6
		  /       \ /       \
		(G)---8---(B)---9---(F)
		  \       / \       /
		   3     1   5     2
		    \   /     \   /
		     (D)---7---(E)





=head2 Matriz costs nodes 

		-----------------  
		|.|A|B|C|D|E|F|G| 
		|-+-+-+-+-+-+-+-|  
		|A|0|1|4|0|0|0|2|
		|-+-+-+-+-+-+-+-| 
		|B|1|0|2|1|5|9|8| 
		|-+-+-+-+-+-+-+-| 
		|C|4|2|0|0|0|6|0|
		|-+-+-+-+-+-+-+-+ 
		|D|0|1|0|0|7|0|3|
		|-+-+-+-+-+-+-+-| 
		|E|0|5|0|7|0|2|0|
		|-+-+-+-+-+-+-+-| 
		|F|0|9|6|0|2|0|0| 
		|-+-+-+-+-+-+-+-| 
		|G|2|8|0|3|0|0|0|
		----------------- 

=head1 From A to C paths and costs

		A->B->G->D->E->F->C = 27

		A->G->B->E->F->C    = 23

		A->G->B->C          = 12

		A->B->D->E->F->C    = 17

		A->G->D->E->B->C    = 19

		A->C                = 4

		A->G->D->E->B->F->C = 28

		A->G->D->B->C       = 8

		A->B->C             = 3

		A->G->D->B->F->C    = 21

		A->B->F->C          = 16

		A->G->D->B->E->F->C = 19

		A->G->D->E->F->C    = 18

		A->B->D->E->F->C    = 17

		A->G->B->D->E->F->C = 26

		A->G->B->F->C       = 25

		A->G->D->E->F->B->C = 19


=head1 DESCRIPTION

This package provides an object class which can be used to get diferents graph paths , with only pure perl code and I don't use other packet or module cpan.

This class calculates the shortest path between two nodes in a graph and return in other method , vals in the execution time (free_path_event).

Technically , the graph is composed of vertices (nodes) and edges (with optional weights) linked between them.

The shortest path is found using the Dijkstra's algorithm. This algorithm is the fastest and requires all weights to be positive. 

The object builds a help about this concept of the graph's , exist a method named debug().

Three Case how to call Object and get a good performance as following:

=head2 CASE 1 $obj->shortest_path

	#!/usr/bin/perl

	my %graph = (
			A => {B=>1,C=>4,G=>2},

			B => {A=>1,C=>2,D=>1,E=>5,F=>9,G=>8},

			C => {A=>4,B=>2,F=>6},

			D => {B=>1,E=>7,G=>3},

			E => {B=>5,D=>7,F=>2},

			F => {B=>9,C=>6,E=>2},

			G => {A=>2,B=>8,D=>3}

	);

	use Paths::Graph;

		my $obj = Paths::Graph->new(-origin=>"A",-destiny=>"F",-graph=>\%graph);

		my @paths = $obj->shortest_path();

		for my $path (@paths) {

			print "Shortest Path:" . join ("->" , @$path) . 
			" Cost:". $obj->get_path_cost(@$path) . "\n";

		}

=head2 CASE 2 $obj->free_path_event

	#!/usr/bin/perl

	my %graph = (

			A => {B=>1,C=>4,G=>2},

			B => {A=>1,C=>2,D=>1,E=>5,F=>9,G=>8},

			C => {A=>4,B=>2,F=>6},

			D => {B=>1,E=>7,G=>3},

			E => {B=>5,D=>7,F=>2},

			F => {B=>9,C=>6,E=>2},

			G => {A=>2,B=>8,D=>3},

	);

	use Paths::Graph;

	my $obj = Paths::Graph->new(-origin=>"A",-destiny=>"F",-graph=>\%graph,-sub=>\&get_paths);

	$obj->free_path_event();

	sub get_paths {

		my ($self , @nodes) = @_;

		print join("->",@nodes) . "\n";

	}

=head2 CASE 3 $obj->debug()

	#!/usr/bin/perl

	my %graph = (
			A => {B=>1,C=>4,G=>2},

			B => {A=>1,C=>2,D=>1,E=>5,F=>9,G=>8},

			C => {A=>4,B=>2,F=>6},

			D => {B=>1,E=>7,G=>3},

			E => {B=>5,D=>7,F=>2},

			F => {B=>9,C=>6,E=>2},

			G => {A=>2,B=>8,D=>3},

	);

	use Paths::Graph;

	my $obj = Paths::Graph->new(-origin=>"A",-destiny=>"F",-graph=>\%graph);

	$obj->debug();

=head1 PARAMETERS

=head2 $obj->{graph}

This object is the main element to resolve the trace graph problem.

The following cases are options of how this hash operate.

Note:It's not important the nodes's names  , it's only important the nodes's values. example.

	my %g = ( 

		Linux => {Perl=>10,Regex=>20}

		CPAN  => {Modules=>1,Opensource=>100} 

	);

=head3 CASE 1 Directed Graph

The directed graph are covered too.

	my %g = (

		A => {B=>10,C=>20,D=>1},

		C => {B=>25,G=>1}

	); 

Fixed D and G do not exist , but it's fine.

=head3 CASE 2 Jumper Graph

	my %g = (

		A => {B=>1,C=>1,D=>1},

		C => {B=>1,G=>1}

	); 

Fixed D and G do not exist , but it's fine.

or

	my %g = (

		A => {B=>1,C=>1},

		B => {B=>1,C=>1},

		C => {A=>1,B=>1}

	); 

=head3 CASE 3 Cost Graph 

	my %graph = (

			A => {B=>1,C=>4},

			B => {A=>1,C=>2},

			C => {A=>4,B=>2},

	); 

The cost from A->C=4 and C->A=4

	my %graph = (

			A => {B=>1,C=>1},

			B => {A=>1,C=>2},

			C => {A=>4,B=>2},

	); 

The cost from A->C=1 and C->A=4

If the cost is distinct , it's not a problem.

=head2 $obj->{origin} and $obj->{destiny}

It's not important the order on the hash graph. 

	$obj->{origin} = "A";

	$obj->{destiny} = "B";

or

	$obj->{origin} = "A";

	$obj->{destiny} = "A";

Is not a problem if the origin and destiny nodes are equals. In this case the graph is traced from A to A.

=head2 $obj->{sub}

This method returns the parameters from the object:

$self  = some object control.
@nodes = vals of arrays.

Note:The values's names do not have to be necesary equals , example;

	$obj->{sub} = \&my_method;

	sub my_method {

		my ($obj,@nodes)  = @_ ; # good

	}
  
The method described above assigned its values to the object (my_method).  

=head2 $obj->shortest_path()

This object's method find the shortest path and cost for the graph using the hash.  

=head2 $obj->free_paths_event() 

This method return a paths array during the execution time , it's generated a method to receive an array and the object with its methods and values.

=head2 $obj->get_path_cost();

This method returns the paths cost (nodes array). 

Trace graph hash recurcive.   

=head2 $obj->debug()

Educational procedure traces and shows the algorithm during execution time ($obj->debug). This method shows how the algorithm is being deploy background. 

=head1 DEBUGGING

Implementation of educational procedure of the object to call the debug() method;

=head1 GLOBAL PROCESSING

Using the recursive technique in the object methods.

=head1 EXPORT

These methods are exported as follow: shortest_path() free_path_event() debug()

=head1 SEE ALSO

None by default. But can be exported if it's required.

Please report bugs using: <cristian@codigolibre.cl>.

Powerfull features in the future.

=head1 HISTORY

Update in 2008 problem found by Keunwan Park problem produced in search where node value is equal to '0'

Thank , Keunwan Park will be contribute to perl comunity

Solucionate by me ;) , update available in version 0.03


=head1 AUTHOR

Cristian Vasquez Diaz , cristian@codigolibre.cl.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Cristian Vasquez Diaz

This library is free software you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

