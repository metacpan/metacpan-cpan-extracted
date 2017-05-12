use v5.14;
use strict;
use warnings;
package Pantry::Role::Runlist;
# ABSTRACT: A role to manage entries in a run_list
our $VERSION = '0.012'; # VERSION

use Moose::Role;
use namespace::autoclean;

has run_list => (
  is => 'bare',
  isa => 'ArrayRef[Str]',
  traits => ['Array'],
  default => sub { [] },
  handles => {
    run_list => 'elements',
    _push_run_list => 'push',
    _clear_run_list => 'clear',
    is_empty => 'is_empty',
  },
);


sub in_run_list {
  my ($self, $item) = @_;
  return grep { $item eq $_ } $self->run_list;
}


sub append_to_run_list {
  my ($self, @items) = @_;
  for my $i (@items) {
    $self->_push_run_list($i)
      unless $self->in_run_list($i);
  }
  return;
}


sub remove_from_run_list {
  my ($self, @items) = @_;
  my %match = map { $_ => 1 } @items;
  my @keep = grep { ! $match{$_} } $self->run_list;
  $self->_clear_run_list;
  $self->_push_run_list(@keep);
  return;
}

1;

__END__

=pod

=head1 NAME

Pantry::Role::Runlist - A role to manage entries in a run_list

=head1 VERSION

version 0.012

=head1 DESCRIPTION

This is a L<Moose::Role> that provides a C<run_list> attribute and associated handlers
to the class that consumes it.

=head1 METHODS

=head2 C<run_list>

  for my $item ( $node->run_list ) { ... }

Returns a list of items in the C<run_list>

=head2 C<in_run_list>

  if ( $node->in_run_list("recipe[nginx]") ) { ... }

Tests whether an item is contained in the C<run_list>.

=head2 C<append_to_run_list>

  $node->append_to_run_list( @items );

Appends a list of items to the C<run_list>.

=head2 C<remove_from_run_list>

  $node->remove_from_run_list( @items );

Removes a list of items from the C<run_list>.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
