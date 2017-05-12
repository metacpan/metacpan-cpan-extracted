use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Path::IsDev::Heuristic::Changelog;

our $VERSION = '1.001003';

# ABSTRACT: Determine if a path contains a Changelog (or similar)

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Role::Tiny::With qw( with );
with 'Path::IsDev::Role::Heuristic', 'Path::IsDev::Role::Matcher::Child::BaseName::MatchRegexp::File';












sub basename_regexp {
  ## no critic (RegularExpressions::RequireLineBoundaryMatching)
  return qr/\AChange(s|log)(|[.][^.\s]+)\z/isx;
}







sub matches {
  my ( $self, $result_object ) = @_;
  if ( $self->child_basename_matchregexp_file( $result_object, $self->basename_regexp ) ) {
    $result_object->result(1);
    return 1;
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::IsDev::Heuristic::Changelog - Determine if a path contains a Changelog (or similar)

=head1 VERSION

version 1.001003

=head1 DESCRIPTION

This heuristic matches any case variation of C<Changes> or C<Changelog>,
including any files of that name with a suffix.

e.g.:

    Changes
    CHANGES
    Changes.mkdn

etc.

=head1 METHODS

=head2 C<basename_regexp>

Indicators for this heuristic is the existence of a file such as:

    Changes             (i)
    Changes.anyext      (i)
    Changelog           (i)
    Changelog.anyext    (i)

=head2 C<matches>

Returns a match if any child of C<path> exists matching the regexp C<basename_regexp>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::Heuristic::Changelog",
    "interface":"single_class",
    "does":[ "Path::IsDev::Role::Heuristic", "Path::IsDev::Role::Matcher::Child::BaseName::MatchRegexp::File" ]
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
