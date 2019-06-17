package PMLTQ::Relation::PDT::ALexOrAuxRFIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::PDT::ALexOrAuxRFIterator::VERSION = '3.0.2';
# ABSTRACT: a/lex.rf or a/aux.rf relation iterator for PDT like treebanks

use strict;
use warnings;
use base qw(PMLTQ::Relation::SimpleListIterator);
use PMLTQ::Relation {
  name             => 'a/lex.rf|a/aux.rf',
  table_name       => 'tdata__#a_rf',
  schema           => 'tdata',
  tree_root        => 't-root',
  start_node_type  => 't-node',
  target_node_type => 'a-node',
  iterator_class   => __PACKAGE__,
  iterator_weight  => 2,
  test_code        => q(grep($_ eq $end->{id}, PMLTQ::Relation::PDT::TGetANodeIDs($start)) ? 1 : 0),
};

BEGIN {
  {
    local $@; # protect existing $@
    eval {
      require PMLTQ::PML2BASE::Relation::PDT::ALexOrAuxRFIterator;
      PMLTQ::PML2BASE::Relation::PDT::ALexOrAuxRFIterator->import();
    };
    print STDERR "PMLTQ::PML2BASE::Relation::PDT::ALexOrAuxRFIterator is not installed\n" if $@;
  }
}


sub get_node_list {
  my ($self, $node) = @_;
  my $fsfile = $self->start_file;
  my $a_file = TAFile($fsfile); # TODO: TAFile is not defined !!
  return [ $a_file ? map [ $_, $a_file ], PMLTQ::Relation::PDT::TGetANodes($node, $fsfile) : () ];
}

sub init_sql {
  my ($table_name, $schema, $desc, $fh) = @_;

  PMLTQ::PML2BASE::Relation::PDT::ALexOrAuxRFIterator::init_sql($table_name, $schema, $desc, $fh);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::PDT::ALexOrAuxRFIterator - a/lex.rf or a/aux.rf relation iterator for PDT like treebanks

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
