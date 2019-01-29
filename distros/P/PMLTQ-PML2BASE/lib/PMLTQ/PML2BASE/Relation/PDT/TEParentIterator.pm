package PMLTQ::PML2BASE::Relation::PDT::TEParentIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::PML2BASE::Relation::PDT::TEParentIterator::VERSION = '3.0.1';
# ABSTRACT: Effective parent relation iterator on t-nodes for PDT like treebanks

use strict;
use warnings;
use PMLTQ::PML2BASE;
use PMLTQ::Relation::PDT;


sub dump_relation {
  my ($tree,$hash,$fh)=@_;

  my $name = $tree->type->get_schema->get_root_name;
  die 'Trying dump relation eparent for incompatible schema' unless $name =~ /^tdata/;

  for my $node ($tree->descendants) {
    for my $p (PMLTQ::Relation::PDT::TGetEParents($node)) {
      $fh->print(PMLTQ::PML2BASE::mkdump($hash->{$node}{'#idx'},$hash->{$p}{'#idx'}));
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::PML2BASE::Relation::PDT::TEParentIterator - Effective parent relation iterator on t-nodes for PDT like treebanks

=head1 VERSION

version 3.0.1

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
