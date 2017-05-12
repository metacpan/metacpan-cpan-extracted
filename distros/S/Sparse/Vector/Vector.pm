package Sparse::Vector;

use 5.008;
use strict;
use warnings;

use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use overload
	'++' => 'incr',
	'+' => 'add',
	'fallback' => undef;

@ISA = qw(Exporter);

%EXPORT_TAGS = ();

@EXPORT_OK = ();

@EXPORT = ();

$VERSION = '0.03';

# sparse vector contructor 
# creates an empty sparse vector
sub new 
{
	my $class = shift;
	my $self = {};
	bless($self,$class);
	return $self;
}

# sets value at given index
sub set
{
	my $self = shift;
	my $key = shift;
	my $value = shift;
	if(!defined $key || !defined $value)
	{
		print STDERR "Usage: vector->set(key,value)\n";
		exit;
	}
	if($value==0)
	{
		print STDERR "Can not store 0 in the Sparse::Vector.\n";
		exit;
	}
	$self->{$key} = $value;
}

# returns value at given index
sub get
{
	my $self = shift;
	my $key = shift;
	if(!defined $key)
	{
		print STDERR "Usage: vector->get(key)\n";
		exit;
	}
	if(defined $self->{$key})
	{
		return $self->{$key};
	}
	return 0;
}

# returns indices of non-zero values in sorted order
sub keys
{
	my $self = shift;
	my @indices = keys %{$self};
	my @sorted = sort {$a <=> $b} @indices;
	return @sorted;
}

# returns 1 if the vector is empty
sub isnull
{
	my $self = shift;
	my @indices = $self->keys;
	if(scalar(@indices)==0)
	{
		return 1;
	}
	return 0;
}

# prints sparse vector
sub print
{
	my $self = shift;
	foreach my $ind ($self->keys)
	{
		print "$ind " . $self->get($ind) . " ";
	}
	print "\n";
}

# returns the equivalent string form
sub stringify
{
	my $self = shift;
	my $str="";
        foreach my $ind ($self->keys)
        {
                $str.= "$ind " . $self->get($ind) . " ";
        }
	chop $str;
	return $str;
}

# increments value at given index
sub incr 
{
	my $self = shift;
	my $key = shift;
	if(!defined $key)
	{
		print STDERR "Usage: vector->incr(key)\n";
		exit;
	}
	$self->{$key}++;
}

# adds 2 sparse vectors
sub add
{
	my $self = shift;
	my $v2 = shift;
	if(!defined $v2)
	{
		print STDERR "Usage: v1->add(v2)\n";
		exit;
	}
	foreach my $key ($v2->keys)
	{
		if(defined $self->{$key})
		{
			$self->{$key}+=$v2->get($key);
		}
		else
		{
			$self->{$key}=$v2->get($key);
		}
	}
}

# returns the norm 
sub norm
{
	my $self = shift;
	my $sum = 0;
	foreach my $key ($self->keys)
	{
		my $value = $self->{$key};
		$sum += $value ** 2;
	}
	return sqrt $sum;
}

# normalizes given sparse vector
sub normalize
{
	my $self = shift;
	my $vnorm = $self->norm;
	if($vnorm != 0)
	{
		$self->div($vnorm);
	}
}

sub dot
{
	my $self = shift;
	my $v2 = shift;
	if(!defined $v2)
	{
		print STDERR "Usage: v1->dot(v2)\n";
		exit;
	}
	my $dotprod = 0;
	foreach my $key ($v2->keys)
	{
		if(defined $self->{$key})
		{
			$dotprod += $v2->get($key) * $self->{$key};
		}
	}
	return $dotprod;
}

# divides each vector entry by a given divisor
sub div
{
	my $self = shift;
	my $divisor = shift;
	if(!defined $divisor)
	{
		print STDERR "Usage: v1->div(DIVISOR)\n";
		exit;
	}
	if($divisor==0)
	{
		print STDERR "Divisor 0 not allowed in Sparse::Vector::div().\n";
		exit;
	}
	foreach my $key ($self->keys)
	{
		$self->{$key}/=$divisor;
	}
}

# adds a given sparse vector to a binary sparse vector
sub binadd
{
	my $v1 = shift;
	my $v2 = shift;

	if(!defined $v2)
	{
		print STDERR "Usage: v1->binadd(v2)\n";
		exit;
	}

	foreach my $key ($v2->keys)
	{
		$v1->{$key}=1;
	}
}

# deallocates all the vector entries
sub free
{
	my $self = shift;
	%{$self}=();
	undef %{$self};
}

1;
__END__

=head1 NAME

Sparse::Vector - Implements Sparse Vector Operations 

=head1 USAGE

  use Sparse::Vector;

  # creating an empty sparse vector object
  $spvec=Sparse::Vector->new;

  # sets the value at index 12 to 5
  $spvec->set(12,5);

  # returns value at index 12
  $value = $spvec->get(12);

  # returns the indices of non-zero values in sorted order
  @indices = $spvec->keys;

  # returns 1 if the vector is empty and has no keys
  if($spvec->isnull)
  {
	print "vector is null.\n";
  }
  else
  {
	print "vector is not null.\n";
  }

  # print sparse vector to stdout
  $spvec->print;

  # returns the string form of sparse vector
  # same as print except the string is returned
  # rather than displaying on stdout
  $spvec->stringify;

  # adds sparse vectors v1, v2 and stores 
  # result into v1
  $v1->add($v2);

  # adds binary equivalent of v2 to v1
  $v1->binadd($v2);
  # binary equivalnet treats all non-zero values 
  # as 1s

  # increments the value at index 12
  $spvec->incr(12);

  # divides each vector entry by a given divisor 4
  $spvec->div(4);

  # returns norm of the vector
  $spvec_norm = $spvec->norm;

  # normalizes a sparse vector
  $spvec->normalize;

  # returns dot product of the 2 vectors
  $dotprod = $v1->dot($v2);

  # deallocates all entries
  $spvec->free;

=head1 ABSTRACT

Sparse::Vector is a Perl module that implements basic vector operations on 
sparse vectors.

=head1 AUTHOR

Amruta D Purandare, <pura0010@d.umn.edu>

Ted Pederse, <tpederse@d.umn.edu>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004,

Amruta Purandare, University of Minnesota, Duluth.
pura0010@umn.edu

Ted Pedersen, University of Minnesota, Duluth.
tpederse@umn.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

=cut
