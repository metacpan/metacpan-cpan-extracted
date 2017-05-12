# $Id: APO_ID_Set.pm 2010-11-29 erick.antezana $
#
# Module  : APO_ID_Set.pm
# Purpose : A set of APO id's.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#

package OBO::APO::APO_ID_Set;


=head1 NAME

OBO::APO::APO_ID_Set - An implementation of a set of OBO::APO::APO_ID objects.

=head1 SYNOPSIS

use OBO::APO::APO_ID_Set;

use OBO::APO::APO_ID;


$apo_id_set = OBO::APO::APO_ID_Set->new();

$id = OBO::APO::APO_ID->new();

$size = $apo_id_set->size();

if ($apo_id_set->add($id)) { ... }

$new_id = $apo_id_set->get_new_id("APO", "C");

$other_id = $apo_id_set->get_new_id("APO", "Ca");

=head1 DESCRIPTION

The OBO::APO::APO_ID_Set class implements a Cell-Cycle Ontology identifiers set.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

our @ISA = qw(OBO::XO::OBO_ID_Set);
use OBO::XO::OBO_ID_Set;
use OBO::APO::APO_ID;

use strict;
use warnings;
use Carp;

=head2 add_as_string

  Usage    - $set->add_as_string($id)
  Returns  - the added id (OBO::APO::APO_ID)
  Args     - the APO id (string) to be added
  Function - adds an APO_ID to this set
  
=cut

sub add_as_string () {
	my ($self, $id_as_string) = @_;
	my $result;
	if ($id_as_string) {
		my $new_obo_id_obj = OBO::APO::APO_ID->new();
		$new_obo_id_obj->id_as_string($id_as_string);
		$result = $self->add($new_obo_id_obj);
	}
	return $result;
}

=head2 get_new_id

  Usage    - $set->get_new_id($local_idspace, $subnamespace)
  Returns  - a new APO id (string)
  Args     - none
  Function - returns a new APO ID as string and adds this id to the set
  
=cut

sub get_new_id {
	my ($self, $local_idspace, $subnamespace) = @_;
	my $new_apo_id = OBO::APO::APO_ID->new();
	confess "The idspace is invalid: ", $local_idspace if ($local_idspace !~ /[A-Z][A-Z][A-Z]/);
	$new_apo_id->idspace($local_idspace);
	confess "The subnamespace is invalid: ", $subnamespace if ($subnamespace !~ /[A-Z][a-z]?/);
	$new_apo_id->subnamespace($subnamespace);
	# get the last 'localID'
	if ($self->is_empty()){
		$new_apo_id->localID("0000001");
	} else {
		my @arr = sort {$a cmp $b} keys %{$self->{MAP}};
		$new_apo_id->localID( $self->{MAP}->{$arr[$#arr]}->localID() );
	}
	while (!defined ($self -> add( $new_apo_id = $new_apo_id->next_id() ))) {}
	return $new_apo_id->id_as_string ();
}

1;