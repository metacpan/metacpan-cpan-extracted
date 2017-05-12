use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Path::IsDev::Heuristic::DevDirMarker;

our $VERSION = '1.001003';

# ABSTRACT: Determine if a path contains a .devdir file

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY
















use Role::Tiny::With qw( with );
with 'Path::IsDev::Role::Heuristic', 'Path::IsDev::Role::Matcher::Child::Exists::Any::File';









sub files {
  return qw( .devdir );
}







sub matches {
  my ( $self, $result_object ) = @_;
  if ( $self->child_exists_any_file( $result_object, $self->files ) ) {
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

Path::IsDev::Heuristic::DevDirMarker - Determine if a path contains a .devdir file

=head1 VERSION

version 1.001003

=head1 DESCRIPTION

This Heuristic is a workaround that is likely viable in the event none of the other Heuristics work.

All this heuristic checks for is the presence of a special file called C<.devdir>, which is intended as an explicit notation that
"This directory is a project root".

An example case where you might need such a Heuristic, is the scenario where you're not working with a Perl C<CPAN> dist, but are
instead working on a project in a different language, where Perl is simply there for build/test purposes.

=head1 METHODS

=head2 C<files>

Matches files named:

    .devdir

=head2 C<matches>

Matches if any of the files in C<files> exist as children of the C<path>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::Heuristic::DevDirMarker",
    "interface":"single_class",
    "does":[
        "Path::IsDev::Role::Heuristic",
        "Path::IsDev::Role::Matcher::Child::Exists::Any::File"
    ]
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
