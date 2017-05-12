use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Path::IsDev::Role::Matcher::Child::BaseName::MatchRegexp::File;

our $VERSION = '1.001003';

# ABSTRACT: Match if any children have basename's that match a regexp and are files

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Role::Tiny qw( with );
with 'Path::IsDev::Role::Matcher::Child::BaseName::MatchRegexp';





















sub _this_child_isfile {
  my ( $self, $result_object, $child ) = @_;
  my $ctx = {
    'child' => "$child",
    tests   => [],
  };
  my $tests = $ctx->{tests};

  ## no critic (ValuesAndExpressions::ProhibitFiletest_f)
  if ( -f $child ) {
    push @{$tests}, { 'child_isfile?' => 1 };
    $result_object->add_reason( $self, 1, "$child is a file", $ctx );
    return 1;
  }
  push @{$tests}, { 'child_isfile?' => 0 };
  $result_object->add_reason( $self, 0, "$child is not a file", $ctx );

  return;
}














sub child_basename_matchregexp_file {
  my ( $self, $result_object, $regexp ) = @_;
  for my $child ( $result_object->path->children ) {
    return 1
      if $self->_this_child_matchregexp( $result_object, $child, $regexp )
      and $self->_this_child_isfile( $result_object, $child );
  }
  return;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::IsDev::Role::Matcher::Child::BaseName::MatchRegexp::File - Match if any children have basename's that match a regexp and are files

=head1 VERSION

version 1.001003

=head1 METHODS

=head2 C<child_basename_matchregexp_file>

    $class->child_basename_matchregexp_file( $result_object, $regexp );

Given a regexp C<$regexp>, match if any of C<< $result_object->path->children >> match the given regexp,
on the condition that those that match are also files.

    if ( $self->child_basename_matchregexp_file( $result_object, qr/^Change(.*)$/i ) ) {
        # result_object->path() contains at least one child that is a file and matches the regexp
    }

=head1 PRIVATE METHODS

=head2 C<_this_child_isfile>

    if ( $class->_this_child_isfile( $result_object, $child_path ) ) {
        ...
    }

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::Role::Matcher::Child::BaseName::MatchRegexp::File",
    "interface":"role",
    "does":"Path::IsDev::Role::Matcher::Child::BaseName::MatchRegexp"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
