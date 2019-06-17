package PMLTQ::Relation::TreexFilelistIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::TreexFilelistIterator::VERSION = '3.0.2';
# ABSTRACT: Same as L<PMLTQ::Relation::FileListIterator> but for Treex files

use 5.006;
use strict;
use warnings;
use base qw(PMLTQ::Relation::TreexFileIterator);

our $PROGRESS; ### newly added
our $STOP; ### newly added

sub next {
  my ($self)=@_;
  my $conditions=$self->[PMLTQ::Relation::CurrentFileIterator::CONDITIONS];
  my $n=$self->[PMLTQ::Relation::CurrentFileIterator::NODE];
  my $f=$self->[PMLTQ::Relation::CurrentFileIterator::FILE];
  while ($n) {
    $n = $n->following
      || (($PROGRESS ? $PROGRESS->() : 1) && $STOP && do { $n = undef; last })
      || $self->tree(++$self->[PMLTQ::Relation::CurrentFileIterator::TREE_NO])
      || $self->_next_file();
    unless ($n) {
      while (TredMacro::NextFile()) {
        $self->[PMLTQ::Relation::CurrentFileIterator::TREE_NO]=0;
        $f = $TredMacro::grp->{FSFile};
        $self->[PMLTQ::Relation::CurrentFileIterator::FILE_QUEUE] = [$f];
        $n = $self->_next_file();
        last if $n;
      }
    }
    last if $conditions->($n,$f);
  }
  return $self->[PMLTQ::Relation::CurrentFileIterator::NODE]=$n;
}

1; # End of PMLTQ::Relation::TreexFilelistIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::TreexFilelistIterator - Same as L<PMLTQ::Relation::FileListIterator> but for Treex files

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
