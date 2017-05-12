# $Id: SubsetDefMap.pm 2014-10-29 erick.antezana $
#
# Module  : SubsetDefMap.pm
# Purpose : Subset Definition Map.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#

package OBO::Util::SubsetDefMap;

#
# key   = subset name
# value = subset def 
#

our @ISA = qw(OBO::Util::Map);
use OBO::Util::Map;

use Carp;
use strict;
use warnings;

=head2 equals

  Usage    - $map->equals($another_subset_def_map)
  Returns  - true or false
  Args     - the set (OBO::Util::SubsetDefMap) to compare with
  Function - tells whether this set is equal to the given one
  
=cut
sub equals {
	my $self = shift;
	my $result = 0; # I initially guess they're NOT identical
	if (@_) {
		my $other_map = shift;
		if ($other_map && eval { $other_map->isa('OBO::Util::SubsetDefMap') }) {
			if ($self->size() == $other_map->size()) {
				my %cmp = map { $_ => 1 } sort keys %{$self->{MAP}};
				for my $key ($other_map->key_set()->get_set()) {
					last unless exists $cmp{$key};
					last unless $self->{MAP}->{$key}->equals($other_map->get($key)); # 'equals'
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
		} else {
			croak "An unrecognized object type (not a OBO::Util::SubsetDefMap) was found: '", $other_map, "'";
		}
	}
	return $result;
}

1;

__END__


=head1 NAME

OBO::Util::SubsetDefMap - A Map implementation of a subset definition.
    
=head1 SYNOPSIS

use OBO::Core::SubsetDef;

use OBO::Util::SubsetDefMap;


use strict;

my $my_set = OBO::Util::SubsetDefMap->new();

my @arr = $my_set->get_set();

my $n1 = OBO::Core::SubsetDef->new();

my $n2 = OBO::Core::SubsetDef->new();

my $n3 = OBO::Core::SubsetDef->new();


$n1->name("GO_SLIM");

$n2->name("APO_SLIM");

$n3->name("SO_SLIM");

$n1->description("GO terms");

$n2->description("APO terms");

$n3->description("SO terms");


$my_set->add($n1);

$my_set->add($n2);

$my_set->add($n3);


$my_set->remove($n1);

$my_set->add($n1);

$my_set->remove($n1);

=head1 DESCRIPTION

A map (OBO::Util::Map) of subset definitions (OBO::Core::SubsetDef) where:

 key   = subset name

 value = subset definition itself 

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut