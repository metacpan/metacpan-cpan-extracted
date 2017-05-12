# $Id: TermSet.pm 2014-09-29 erick.antezana $
#
# Module  : TermSet.pm
# Purpose : Term set.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Util::TermSet;

our @ISA = qw(OBO::Util::ObjectSet);
use OBO::Util::ObjectSet;

use strict;
use warnings;

=head2 contains_id

  Usage    - $set->contains_id($element_id)
  Returns  - true if this set contains an element with the given ID
  Args     - the ID to be checked
  Function - checks if this set constains an element with the given ID
  
=cut

sub contains_id {
	my ($self, $id) = @_;
	return ($self->{MAP}->{$id})?1:0;
}

=head2 contains_name

  Usage    - $set->contains_name($element_name)
  Returns  - true if this set contains an element with the given name
  Args     - the name to be checked
  Function - checks if this set constains an element with the given name
  
=cut

sub contains_name {
	my $self = shift;
	my $result = 0;
	if (@_) {
		my $term_id = shift;
		
		foreach my $ele (sort values %{$self->{MAP}}){
			if ($ele->name() eq $term_id) {
				$result = 1;
				last;
			}
		}
	}
	return $result;
}

1;

__END__


=head1 NAME

OBO::Util::TermSet - A Set implementation.
    
=head1 SYNOPSIS

use OBO::Util::TermSet;

use OBO::Core::Term;

use strict;


my $my_set = OBO::Util::TermSet->new;

my @arr = $my_set->get_set();


# three new terms

my $n1 = OBO::Core::Term->new;

my $n2 = OBO::Core::Term->new;

my $n3 = OBO::Core::Term->new;

$n1->id("APO:P0000001");

$n2->id("APO:P0000002");

$n3->id("APO:P0000003");


$n1->name("One");

$n2->name("Two");

$n3->name("Three");



# remove from my_set

$my_set->remove($n1);

$my_set->add($n1);

$my_set->remove($n1);


### set versions ###

$my_set->add($n1);

$my_set->add($n2);

$my_set->add($n3);



my $n4 = OBO::Core::Term->new;

my $n5 = OBO::Core::Term->new;

my $n6 = OBO::Core::Term->new;


$n4->id("APO:P0000004");

$n5->id("APO:P0000005");

$n6->id("APO:P0000006");


$n4->name("Four");

$n5->name("Five");

$n6->name("Six");


$my_set->add_all($n4, $n5, $n6);

$my_set->add_all($n4, $n5, $n6);


# remove from my_set

$my_set->remove($n4);

my $n7 = $n4;

my $n8 = $n5;

my $n9 = $n6;


my $my_set2 = OBO::Util::TermSet->new;

$my_set->add_all($n4, $n5, $n6);

$my_set2->add_all($n7, $n8, $n9, $n1, $n2, $n3);

$my_set2->clear();

=head1 DESCRIPTION

A set (OBO::Util::ObjectSet) of terms (OBO::Core::Term).

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut