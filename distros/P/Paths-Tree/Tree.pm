package Paths::Tree;

@ISA = qw(Exporter);
@EXPORT_OK = qw/tree()/;

require 5.005_62;
our $VERSION = '0.02';

use strict;

sub new {
        my ($class , %vals)  = @_;
	my $self;
        bless $self = {	
			tree =>  $vals{-tree} ,
			origin=> $vals{-origin},
			sub  =>  $vals{-sub} ,
	} , $class;
	return $self;
}



sub tree {
        my ($self , $father, $level ,%h) = @_;
	$father = $self->{origin} unless $father;
        foreach my $child ( @{$self->{tree}{$father} }) {
		last if $h{$child};$h{$child}=1;
		$self->{sub}->($child,$level);
                $self->tree($child, ($level + 1),%h ) if $self->{tree}{$child};
        }
}

__END__

=head1 NAME

Paths::Tree - Generate path from a hash tree.

=head1 SYNOPSIS

	#!/usr/bin/perl

	my %tree = (	2 => [3,"HELLO"],

			HELLO => ["YOU",WORLD],

			"RAIZ" => [1,2],

	);

	sub show {
		my ($child , $level) = @_;

		print "    " for 0 .. $level; #fifth spaces of level or anything separator;

		print "$child \n";

	}

	use Paths::Tree;

	my $n = Paths::Tree->new(-tree=>\%tree,-sub=>\&show);

	$n->tree("RAIZ");


=head1 RECOMMENDED

Understanding the Tree's filosofy and how to trace it. 

Reach for tree's books.

=head1 ABSTRACT

This example show how to generate itself.

=head2 Example tree

	(RAIZ) ----> (1)

	       ----> (2) ---->(HELLO)---->(YOU) 

				     ---->(WORLD)

=head1 DESCRIPTION

This package provides an object class which can be used to get tree paths , with only pure perl code and I don't use other packet or module cpan.

This class generate the paths of a tree from a base node and return in a method , vals in the execution time (tree).

Technically , the tree is composed of childs ans fhathers linked between them.

=head1 PARAMETERS

=head2 $obj->{tree}

Tree hash , the component so strings caracter or numbers. example.

Hash is pass how reference hash.

	my %tree = (	2 => [3,"HELLO"],

			HELLO => ["YOU",WORLD],

			"RAIZ" => [1,2],

	);

	$obj->{tree} = \%tree;

=head2 $obj->{origin}

Origin node what will begin to recursive process tree. 

	$obj->{origin} = "A";

=head2 $obj->{sub}

Receive parameters from object in execution time.

	sub params_receive {

		my ($level , $node) = @_; 

		print " $level , $node \n";

	}

	$obj->{sub} = \&params_receive();

=head2 $obj->tree()

This method is the core of object and unique export for use.

Return in execution time two values level and node.

The method is executed and follow is return parameters while recurcive process live.

	sub show {

		my ($child , $level) = @_;

		print "     " for 0 .. $level; #fifth spaces of level or anything separator;

		print "$child \n";

	}

	use Paths::Tree;

	my $obj = Paths::Tree->new(-tree=>\%tree,-sub=>\&show,-origin=>"RAIZ");

	$obj->tree();


=head1 GLOBAL PROCESSING

Using the recursive technique in the object methods.

=head1 EXPORT

This method is exported as follow: tree()

=head1 SEE ALSO

None by default. But can be exported if it's required.

Please report bugs using: <cristian@codigolibre.cl>.

Powerfull features in the future on object method how for example: find_tree() binary_tree().

=head1 AUTHOR

Cristian Vasquez Diaz , cristian@codigolibre.cl.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Cristian Vasquez Diaz

This library is free software you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
