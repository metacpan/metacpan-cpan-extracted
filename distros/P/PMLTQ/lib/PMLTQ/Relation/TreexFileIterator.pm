package PMLTQ::Relation::TreexFileIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::TreexFileIterator::VERSION = '3.0.2';
# ABSTRACT: Same as L<PMLTQ::Relation::FileIterator> but for Treex files

use 5.006;
use strict;
use warnings;

use Carp;
use base qw(PMLTQ::Relation::CurrentFileIterator);
use constant TREES=>PMLTQ::Relation::CurrentFileIterator::FIRST_FREE;
use constant TREEX_DOC=>PMLTQ::Relation::CurrentFileIterator::FIRST_FREE+1;

use PMLTQ::Loader 'load_class';
use English qw(-no_match_vars); # Load this because otherwise Treex::Core ends up with error on Perl 5.14

our $PROGRESS; ### newly added
our $STOP; ### newly added

sub new {
  my ($class,$conditions,$schema_root_name)=@_;

  croak 'Please install Treex::Core if you want to use PML-TQ with treex files' unless load_class('Treex::Core::Document');

  my $self = CurrentFileIterator->new($conditions, $schema_root_name);
  $self->[TREES] = [];
  return bless $self, $class; # rebless
}

sub tree {
  my ($self, $n)=@_;
  return $self->[TREES]->[$n];
}

sub _next_file {
  my ($self)=@_;
  my $f;
  my $schema_name = $self->[PMLTQ::Relation::CurrentFileIterator::SCHEMA_ROOT_NAME];
  while (@{$self->[PMLTQ::Relation::CurrentFileIterator::FILE_QUEUE]}) {
    $f = shift @{$self->[PMLTQ::Relation::CurrentFileIterator::FILE_QUEUE]};
    if ($f) {
      push @{$self->[PMLTQ::Relation::CurrentFileIterator::FILE_QUEUE]}, TredMacro::GetSecondaryFiles($f);
      if (!defined($schema_name) or $schema_name eq PML::SchemaName($f)) {
        $self->[PMLTQ::Relation::CurrentFileIterator::FILE]=$f;
        $self->[TREEX_DOC] = Treex::Core::Document->new({pmldoc => $f}); # This will rebless the file document as Treex::Core::Document
        $self->[PMLTQ::Relation::CurrentFileIterator::TREE_NO]=0;
        $self->_extract_trees;
        my $n = $self->[PMLTQ::Relation::CurrentFileIterator::NODE] = $self->tree(0);
        return ($n && $self->[PMLTQ::Relation::CurrentFileIterator::CONDITIONS]->($n,$f)) ? $n : ($n && $self->next)
      }
    }
  }
  return;
}

# Don't use any treex specific methods, nodes might not be reblessed
sub _extract_trees {
  my ($self)=@_;
  my $doc = $self->[TREEX_DOC];
  # lets assume it's a treex doc
  $self->[TREES] = [];
  foreach my $bundle ($doc->get_bundles) {
    last unless defined $bundle->{zones};
    foreach my $zone ($bundle->get_all_zones) {
      push @{$self->[TREES]}, $zone->get_all_trees;
    }
  }
}

sub next {
  my ($self)=@_;
  my $conditions=$self->[PMLTQ::Relation::CurrentFileIterator::CONDITIONS];
  my $n=$self->[PMLTQ::Relation::CurrentFileIterator::NODE];
  my $f=$self->[PMLTQ::Relation::CurrentFileIterator::FILE];
  while ($n) {
    # Treex has following hacked but we want to have classic following
    $n = Treex::PML::Node::following($n) ||
      (($PROGRESS ? $PROGRESS->() : 1) && $STOP && do { $n = undef; last }) ||
        $self->tree(++$self->[PMLTQ::Relation::CurrentFileIterator::TREE_NO]) || $self->_next_file();

    last if $conditions->($n,$f);
  }
  return $self->[PMLTQ::Relation::CurrentFileIterator::NODE]=$n;
}

1; # End of PMLTQ::Relation::TreexFileIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::TreexFileIterator - Same as L<PMLTQ::Relation::FileIterator> but for Treex files

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
