# $Id: OBO_ID_Set.pm 2010-09-29 erick.antezana $
#
# Module  : OBO_ID_Set.pm
# Purpose : A set of OBO id's.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#

package OBO::XO::OBO_ID_Set;

our @ISA = qw(OBO::Util::ObjectSet);
use OBO::Util::ObjectSet;
use OBO::XO::OBO_ID;

use Carp;
use strict;
use warnings;
    
=head2 add_as_string

  Usage    - $set->add_as_string($id)
  Returns  - the added id (OBO::XO::OBO_ID)
  Args     - the OBO id (string) to be added
  Function - adds an OBO_ID to this set
  
=cut

sub add_as_string () {
	my ($self, $id_as_string) = @_;
	my $result;
	if ($id_as_string) {
		my $new_obo_id_obj = OBO::XO::OBO_ID->new();
		$new_obo_id_obj->id_as_string($id_as_string);
		$result = $self->add($new_obo_id_obj);
	}
	return $result;
}

=head2 add_all_as_string

  Usage    - $set->add_all_as_string($id1, $id2, ...)
  Returns  - the last added id (OBO::XO::OBO_ID)
  Args     - the id(s) (strings) to be added
  Function - adds a series of OBO_IDs to this set
  
=cut

sub add_all_as_string () {
	my $self = shift;
	my $result;
	foreach (@_) {
		$result = $self->add_as_string ($_);
	}
	return $result;
}

=head2 get_new_id

  Usage    - $set->get_new_id($idspace)
  Returns  - a new OBO id (string)
  Args     - none
  Function - returns a new OBO ID as string and adds this id to the set
  
=cut

sub get_new_id {
	my ($self, $local_idspace) = @_;
	my $new_obo_id = OBO::XO::OBO_ID->new();
	croak 'The local idspace is invalid: ', $local_idspace if ($local_idspace !~ /\w+/);
	
	$new_obo_id->idspace($local_idspace);
	
	#
	# get the last 'localID'
	#
	if ($self->is_empty()){
		$new_obo_id->localID('0000001'); # use 7 'numeric placeholders'
	} else {
		my @arr = sort {$a cmp $b} keys %{$self->{MAP}};
		$new_obo_id->localID( $self->{MAP}->{$arr[$#arr]}->localID() );
	}
	while (!defined ($self -> add( $new_obo_id = $new_obo_id->next_id() ))) {}
	
	return $new_obo_id->id_as_string ();
}

1;

__END__


=head1 NAME

OBO::XO::OBO_ID_Set - An implementation of a set of OBO::XO::OBO_ID objects.

=head1 SYNOPSIS

use OBO::XO::OBO_ID_Set;

use OBO::XO::OBO_ID;


$obo_id_set = OBO::XO::OBO_ID_Set->new();

$id = OBO::XO::OBO_ID->new();

$size = $obo_id_set->size();

if ($obo_id_set->add($id)) { ... }

$new_id = $obo_id_set->get_new_id('XO');

=head1 DESCRIPTION

The OBO::XO::OBO_ID_Set class implements a set of identifiers for any OBO ontology.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut