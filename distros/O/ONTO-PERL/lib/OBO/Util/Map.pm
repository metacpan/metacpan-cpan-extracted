# $Id: Map.pm 2014-06-06 erick.antezana $
#
# Module  : Map.pm
# Purpose : An implementation of a Map. An object that maps keys to values.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Util::Map;

use OBO::Util::Set;

use Carp;
use strict;
use warnings;


sub new {
	my $class       = shift;
	my $self        = {};	
	%{$self->{MAP}} = (); # key; value
	
	bless ($self, $class);
	return $self;
}

=head2 clear

  Usage    - $map->clear()
  Returns  - none
  Args     - none
  Function - removes all mappings from this map
  
=cut

sub clear {
	my $self = shift;
	%{ $self->{MAP} } = ();
}

=head2 contains_key

  Usage    - $map->contains_key($key)
  Returns  - 1 (true) if this map contains a mapping for the specified key
  Args     - a key whose presence in this map is to be tested
  Function - checks if this map contains a mapping for the specified key
  
=cut

sub contains_key {
	my ($self, $key) = @_;
	return ( defined $self->{MAP}->{$key} ) ? 1 : 0;
}

=head2 contains_value

  Usage    - $map->contains_value($value)
  Returns  - 1 (true) if this map maps one or more keys to the specified value
  Args     - a value whose presence in this map is to be tested
  Function - checks if this map maps one or more keys to the specified value
  
=cut

sub contains_value {
	my ($self, $value) = @_;
	my $found = 0;
	foreach my $key ( sort keys %{$self->{MAP}} ) {
		if ($self->{MAP}->{$key} eq $value) {
			$found = 1;
			last;
		}
	}
	return $found;
}

=head2 equals

  Usage    - $map->equals($another_map)
  Returns  - either 1 (true) or 0 (false)
  Args     - the map (OBO::Util::Map) to compare with
  Function - tells whether this map is equal to the given one
  
=cut

sub equals {
	my $self = shift;
	my $result = 0; # I initially guess they're NOT identical
	if (@_) {
		my $other_map = shift;
		if ($self->size() == $other_map->size()) {
			my %cmp = map { $_ => 1 } sort keys %{$self->{MAP}};
			for my $key ($other_map->key_set()->get_set()) {
				last unless exists $cmp{$key};
				last unless $self->{MAP}->{$key} eq $other_map->get($key);
				delete $cmp{$key};
			}
			if (%cmp) {
				#warn "they don't have the same keys or values\n";
				$result = 0;
			} else {
				#warn "they have the same keys or values\n";
				$result = 1;
			}
		} else {
			$result = 0;
		}
	}
	return $result;
}

=head2 get

  Usage    - $map->get($key)
  Returns  - the value to which this map maps the specified key
  Args     - a key whose associated value is to be returned
  Function - gets the value to which this map maps the specified key
  
=cut

sub get {
	my ($self, $key) = @_;
	return (!$self->is_empty())?$self->{MAP}->{$key}:undef;
}

=head2 is_empty

  Usage    - $map->is_empty()
  Returns  - true if this map contains no key-value mappings
  Args     - none
  Function - checks if this map contains no key-value mappings
  
=cut

sub is_empty {
	my $self = shift;
	return (scalar keys %{$self->{MAP}} == 0)?1:0;
}

=head2 key_set

  Usage    - $map->key_set()
  Returns  - a set (OBO::Util::Set) view of the keys contained in this map
  Args     - none
  Function - gets a set view of the keys contained in this map
  
=cut

sub key_set {
	my $self = shift;
	my $set = OBO::Util::Set->new();
	$set->add_all(sort keys %{$self->{MAP}});
	return $set;
}

=head2 put

  Usage    - $map->put("GO", "Gene Ontology")
  Returns  - previous value associated with specified key, or undef if there was no mapping for key
  Args     - a key (string) with which the specified value is to be associated and a value to be associated with the specified key. 
  Function - associates the specified value with the specified key in this map (optional operation)
  Remark   - if the map previously contained a mapping for this key, the old value is replaced by the specified value
  
=cut

sub put {
	my ( $self, $key, $value ) = @_;
	my $old_value = undef;
	if ( $key && $value ) {
		my $has_key = $self->contains_key($key);
		$old_value  = $self->{MAP}->{$key} if ($has_key);
		$self->{MAP}->{$key} = $value;
	} else {
		croak "You should provide both a key and value -> ('$key', '$value')\n";
	}    
	return $old_value;
}

=head2 put_all

  Usage    - $map->put_all($my_other_map)
  Returns  - none
  Args     - a map (OBO::Util::Map) to be stored in this map
  Function - copies all of the mappings from the specified map to this map (optional operation)
  Remark   - the effect of this call is equivalent to that of calling put(k, v) on this map once for each mapping from key k to value v in the specified map
  
=cut

sub put_all {
	my ( $self, $my_other_map ) = @_;
	if ( $my_other_map ) {
		foreach my $key ($my_other_map->key_set()->get_set()) {
			$self->{MAP}->{$key} = $my_other_map->get($key);
		}
	}
}

=head2 remove

  Usage    - $map->remove($key)
  Returns  - the previous value associated with specified key, or undef if there was no mapping for the given key 
  Args     - a key whose mapping is to be removed from the map
  Function - removes the mapping for this key from this map if it is present (optional operation)
  
=cut

sub remove {
	my ($self, $key) = @_;
	my $has_key = $self->contains_key($key);
	my $old_value = undef;
	$old_value = $self->{MAP}->{$key} if ($has_key);
	delete $self->{MAP}->{$key};
	return $old_value;
}

=head2 size

  Usage    - $map->size()
  Returns  - the size of this map
  Args     - none
  Function - tells the number of elements held by this map
  
=cut

sub size {
	my $self = shift;
	my $s = 0;
	$s += scalar keys %{$self->{MAP}};
	return $s;
}

=head2 values 

  Usage    - $map->values()
  Returns  - a collection view of the values contained in this map
  Args     - none
  Function - gets a collection view of the values contained in this map
  
=cut

sub values  {
	my $self       = shift;
	my @collection = sort values %{$self->{MAP}};
	return @collection;
}

1;

__END__


=head1 NAME

OBO::Util::Map - An implementation of a map (key -> value).
    
=head1 SYNOPSIS

use OBO::Util::Map;

use strict;


my $my_map = OBO::Util::Map->new();


if(!$my_map->contains_key("GO"))  { print "doesn't contain key: GO"; }

if(!$my_map->contains_value("Gene Ontology"))  { print "doesn't contain value: Gene Ontology"; }

if ($my_map->size() == 0) { print "empty map"; }

if ($my_map->is_empty())  { print "empty map"; }


$my_map->put("GO", "Gene Ontology");

if ($my_map->contains_key("GO"))  { print "contains key: GO"; }

if ($my_map->contains_value("Gene Ontology")) { print "contains value: Gene Ontology"; }

if ($my_map->size() == 1) { print "map size is 1"; }

if (!$my_map->is_empty()) { print "map is not empty"; }



$my_map->put("APO", "Application Ontology");

$my_map->put("PO", "Plant Ontology");

$my_map->put("SO", "Sequence Ontology");

if ($my_map->size() == 4) { print "map size is 4"; }



if ($my_map->equals($my_map)) { print "my map is identical to itself"; }



my $my_map2 = OBO::Util::Map->new();

if (!$my_map->equals($my_map2)) { print "my map is not identical to map2"; }

if (!$my_map2->equals($my_map)) { print "map2 is not identical to my map"; }

$my_map2->put("APO", "Application Ontology");

$my_map2->put("PO", "Plant Ontology");

$my_map2->put("SO", "Sequence Ontology");

if (!$my_map2->equals($my_map)) { print "map2 is not identical to my map"; }

if (!$my_map->equals($my_map2)) { print "my map is not identical to map2"; }



$my_map2->put("GO", "Gene Ontology");

if ($my_map2->equals($my_map)) { print "map2 is not identical to my map"; }

if ($my_map->equals($my_map2)) { print "my map is not identical to map2"; }



if ($my_map2->get("GO") eq "Gene Ontology") { print "get GO"}

if ($my_map2->get("APO") eq "Application Ontology") { print "get APO"}

if ($my_map2->get("PO") eq "Plant Ontology") { print "get PO"}

if ($my_map2->get("SO") eq "Sequence Ontology") { print "get SO"}



$my_map2->put("TO", "Trait Ontology");

if (!$my_map->equals($my_map2)) { print "my map is not identical to map2"; }

if (!$my_map2->equals($my_map)) { print "map2 is not identical to my map"; }

if ($my_map2->size() == 5) { print "map size is 5"; }



$my_map->clear();

if ($my_map->size() == 0) { print "map size is 0"; }



$my_map->put_all($my_map2);

if ($my_map->equals($my_map2)) { print "my map is identical to map2"; }

if ($my_map2->equals($my_map)) { print "map2 is identical to my map"; }

if ($my_map->size() == 5) { print "map size is 5"; }



my $UD = $my_map->remove("XO");

my $GO = $my_map->remove("GO");

if (!$my_map->contains_key("GO") && !$my_map->contains_value("Gene Ontology")) { print "GO is gone"}

print $GO; # "Gene Ontology"

if ($my_map->size() == 4) { print "map size is 4"; }

=head1 DESCRIPTION

An object that maps keys to values. A map cannot contain duplicate keys; 
each key can map to at most one value. 

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut