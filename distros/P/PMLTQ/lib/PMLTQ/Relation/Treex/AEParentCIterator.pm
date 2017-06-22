package PMLTQ::Relation::Treex::AEParentCIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::Treex::AEParentCIterator::VERSION = '1.3.2';
# ABSTRACT: Different implementation of effective parent relation iterator on a-nodes for Treex treebanks


use strict;
use warnings;
use base qw(PMLTQ::Relation::SimpleListIterator);
use PMLTQ::PML2BASE;
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

sub get_node_list {
  my ( $self, $node ) = @_;
  my $fsfile = $self->start_file;
  return [ map [ $_, $fsfile ], PMLTQ::Relation::Treex::AGetEParentsC($node) ];
}

sub dump_relation {
  my ($tree, $hash, $fh ) = @_;

  my $name = $tree->type->get_schema->get_root_name;
  die 'Trying dump relation eparent for incompatible schema' unless $name =~ /^treex_document/;

  my $struct_name = $tree->type->get_structure_name || '';
  return unless $struct_name eq 'a-root';

  for my $node ( $tree->descendants ) {
    for my $p ( PMLTQ::Relation::Treex::AGetEParentsC($node) ) {
      $fh->print( PMLTQ::PML2BASE::mkdump( $hash->{$node}{'#idx'}, $hash->{$p}{'#idx'} ) );
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::Treex::AEParentCIterator - Different implementation of effective parent relation iterator on a-nodes for Treex treebanks

=head1 VERSION

version 1.3.2

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
