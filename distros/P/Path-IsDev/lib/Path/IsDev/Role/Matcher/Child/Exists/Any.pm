use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Path::IsDev::Role::Matcher::Child::Exists::Any;

our $VERSION = '1.001003';

# ABSTRACT: Match if any of a list of children exists

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Role::Tiny;




















sub child_exists {
  my ( $self, $result_object, $child ) = @_;

  my $child_path = $result_object->path->child($child);

  my $ctx = { 'child_name' => $child, child_path => "$child_path", tests => [] };
  my $tests = $ctx->{tests};

  if ( -e $child_path ) {
    push @{$tests}, { 'child_path_exists?' => 1 };
    $result_object->add_reason( $self, 1, "$child exists", $ctx );
    return 1;
  }
  push @{$tests}, { 'child_path_exists?' => 0 };
  $result_object->add_reason( $self, 0, "$child does not exist", $ctx );
  return;
}









sub child_exists_any {
  my ( $self, $result_object, @children ) = @_;
  for my $child (@children) {
    return 1 if $self->child_exists( $result_object, $child );
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::IsDev::Role::Matcher::Child::Exists::Any - Match if any of a list of children exists

=head1 VERSION

version 1.001003

=head1 METHODS

=head2 C<child_exists>

    $class->child_exists( $result_object, $path );

Return match if C<$path> exists as a child of C<< $result_object->path >>

=head2 C<child_exists_any>

    $class->child_exists_any( $result_object, @childnames );

Return match if any of C<@childnames> exist under C<< $result_object->path >>.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::Role::Matcher::Child::Exists::Any",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
