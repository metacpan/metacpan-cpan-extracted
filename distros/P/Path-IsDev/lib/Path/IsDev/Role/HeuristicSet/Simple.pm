use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Path::IsDev::Role::HeuristicSet::Simple;

our $VERSION = '1.001003';

# ABSTRACT: Simple excludes/includes set

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

































use Role::Tiny qw( with requires );

with 'Path::IsDev::Role::HeuristicSet';
requires 'heuristics', 'negative_heuristics';










sub modules {
  my ($self) = @_;
  my @out;
  for my $heur ( $self->negative_heuristics ) {
    push @out, $self->_expand_negative_heuristic($heur);
  }
  for my $heur ( $self->heuristics ) {
    push @out, $self->_expand_heuristic($heur);
  }
  return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::IsDev::Role::HeuristicSet::Simple - Simple excludes/includes set

=head1 VERSION

version 1.001003

=head1 ROLE REQUIRES

=head2 C<heuristics>

Consuming classes must provide this method,
and return a list of shorthand Heuristics.

    sub heuristics {
        return qw( MYMETA )
    }

=head2 C<negative_heuristics>

Consuming classes must provide this method,
and return a list of shorthand Negative Heuristics.

    sub negative_heuristics {
        return qw( IsDev::IgnoreFile )
    }

=head1 METHODS

=head2 C<modules>

Returns the list of fully qualified module names that comprise this heuristic.

expands results from C<< ->heuristics >> and C<< ->negative_heuristics >>,
with negative ones preceding positive.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::Role::HeuristicSet::Simple",
    "interface":"role",
    "does":"Path::IsDev::Role::HeuristicSet"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
