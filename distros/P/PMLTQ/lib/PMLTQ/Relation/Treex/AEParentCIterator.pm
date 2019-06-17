package PMLTQ::Relation::Treex::AEParentCIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::Treex::AEParentCIterator::VERSION = '3.0.2';
# ABSTRACT: Different implementation of effective parent relation iterator on a-nodes for Treex treebanks


use strict;
use warnings;
use base qw(PMLTQ::Relation::SimpleListIterator);
use PMLTQ::Relation {
  name              => 'eparentC',
  table_name        => 'adata__#eparents_c',
  schema            => 'treex_document',
  reversed_relation => 'implementation:echildC',
  start_node_type   => 'a-node',
  target_node_type  => 'a-node',
  iterator_class    => __PACKAGE__,
  test_code         => q(grep($_ == $end, PMLTQ::Relation::Treex::AGetEParentsC($start)) ? 1 : 0),
};
use PMLTQ::Relation::Treex;

BEGIN {
  {
    local $@; # protect existing $@
    eval {
      require PMLTQ::PML2BASE::Relation::Treex::AEParentCIterator;
      PMLTQ::PML2BASE::Relation::Treex::AEParentCIterator->import();
    };
    print STDERR "PMLTQ::PML2BASE::Relation::Treex::AEParentCIterator is not installed\n" if $@;
  }
}

sub get_node_list {
  my ( $self, $node ) = @_;
  my $fsfile = $self->start_file;
  return [ map [ $_, $fsfile ], PMLTQ::Relation::Treex::AGetEParentsC($node) ];
}

sub dump_relation {
  my ($tree, $hash, $fh ) = @_;
  PMLTQ::PML2BASE::Relation::Treex::AEParentCIterator::dump_relation($tree, $hash, $fh);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::Treex::AEParentCIterator - Different implementation of effective parent relation iterator on a-nodes for Treex treebanks

=head1 VERSION

version 3.0.2

=head1 DESCRIPTION

Classic effective parent implementation is skipping nodes with afuns that match /Aux[CP]/. This one doesn't.

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
