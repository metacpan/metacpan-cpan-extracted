use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Path::IsDev::Heuristic::TestDir;

our $VERSION = '1.001003';

# ABSTRACT: Determine if a path contains a t/ or xt/ directory

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY
















use Role::Tiny::With qw( with );

with 'Path::IsDev::Role::Heuristic', 'Path::IsDev::Role::Matcher::Child::Exists::Any::Dir';










sub dirs {
  return qw( xt t );
}









sub matches {
  my ( $self, $result_object ) = @_;
  if ( $self->child_exists_any_dir( $result_object, $self->dirs ) ) {
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

Path::IsDev::Heuristic::TestDir - Determine if a path contains a t/ or xt/ directory

=head1 VERSION

version 1.001003

=head1 METHODS

=head2 C<dirs>

Directories relevant to this heuristic:

    t/
    xt/

=head2 C<matches>

    if ( $heuristic->matches( $result_object ) ) {
        # one of the directories in ->dirs exists
    }

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::Heuristic::TestDir",
    "interface":"single_class",
    "does":[
        "Path::IsDev::Role::Heuristic",
        "Path::IsDev::Role::Matcher::Child::Exists::Any::Dir"
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
