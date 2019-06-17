package PMLTQ::Relation::Treex;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::Treex::VERSION = '3.0.2';
# ABSTRACT: Treex user defined relations

use warnings;
use strict;

use PMLTQ::Relation::Treex::AEChildCIterator;
use PMLTQ::Relation::Treex::AEParentCIterator;
use PMLTQ::Relation::Treex::TEParentIterator;
use PMLTQ::Relation::Treex::AEParentIterator;
use PMLTQ::Relation::Treex::AEChildIterator;
use PMLTQ::Relation::Treex::TEChildIterator;

#
# This file implements the following user-defined relations for PML-TQ
#
# - eparentC, echildC - Slightly modified (skipping only coordinarion nodes) eparent/echild for a-layer
# - eparent (both t-layer and a-layer)
# - echild (both t-layer and a-layer)
#

sub AGetEParentsC {
  return shift->get_eparents({or_topological => 1, ignore_incorrect_tree_structure => 1, ordered => 1});
}

sub AGetEChildrenC {
  return shift->get_echildren({or_topological => 1, ignore_incorrect_tree_structure => 1, ordered => 1});
}

sub AGetEParents {
  return shift->get_eparents({dive => 'AuxCP', or_topological => 1, ignore_incorrect_tree_structure => 1, ordered => 1});
}

sub AGetEChildren {
  return shift->get_echildren({dive => 'AuxCP', or_topological => 1, ignore_incorrect_tree_structure => 1, ordered => 1});
}

sub TGetEChildren {
  return shift->get_echildren({or_topological => 1, ignore_incorrect_tree_structure => 1, ordered => 1});
}

sub TGetEParents {
  return shift->get_eparents({or_topological => 1, ignore_incorrect_tree_structure => 1, ordered => 1});
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::Treex - Treex user defined relations

=head1 VERSION

version 3.0.2

=head1 AUTHORS

=over 4

=item *

Petr Pajas <pajas@ufal.mff.cuni.cz>

=item *

Jan Štěpánek <stepanek@ufal.mff.cuni.cz>

=item *

Michal Sedlák <sedlak@ufal.mff.cuni.cz>

=item *

Matyáš Kopp <matyas.kopp@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Institute of Formal and Applied Linguistics (http://ufal.mff.cuni.cz).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
