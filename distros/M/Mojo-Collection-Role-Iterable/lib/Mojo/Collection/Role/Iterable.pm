use strict;
use warnings;
package Mojo::Collection::Role::Iterable;

use Role::Tiny;

use Hash::Util::FieldHash qw(fieldhash);

# ABSTRACT: Iterator role for Mojo::Collection

fieldhash my %idx;
fieldhash my %_iter_pos;

use overload
    '++' => sub { shift->increment },
    '--' => sub { shift->decrement },
    "fallback" => 1;


sub idx {
    my ($self, $val) = @_;
    $idx{$self} //= 0;
    $idx{$self} = $val if @_ > 1;
    return $idx{$self};
}
 
sub _iter_pos {
    my ($self, $val) = @_;
    $_iter_pos{$self} //= 0;
    $_iter_pos{$self} = $val if @_ > 1;
    return $_iter_pos{$self};
}

sub prev { $_[0]->idx > 0 ? $_[0]->[$_[0]->idx - 1] : undef }
sub curr    { @{$_[0]} ? $_[0]->[$_[0]->idx] : undef }; *current = \&curr; *item = \&curr;
sub next { $_[0]->idx < (-1 + scalar $_[0]->@*) ?  $_[0]->[$_[0]->idx + 1] : undef }

sub increment { $_[0]->idx($_[0]->idx + 1) if $_[0]->idx < -1 + scalar $_[0]->@*; return $_[0] }
sub decrement { $_[0]->idx($_[0]->idx - 1) if $_[0]->idx > 0; return $_[0] }


sub reset {
    $_[0]->idx(0);
    $_[0]->_iter_pos(0);
}

sub iterate {
    my $self = shift;
    return () unless @$self;          # empty collection fast-exit
    my $pos = $self->_iter_pos;
    return () if $pos >= scalar @$self;
    my $ret = $self->[$pos];
    if ($pos < scalar $self->@*) {
        $self->idx($self->_iter_pos);
    } 
    $self->_iter_pos($pos + 1);
    return $ret;
}

sub each {
    my ($self, $cb) = @_;
    return $self->@* unless $cb;

    my $i = 1;
    $self->reset;
    for ($self->@*) {
	$_->$cb($i++);
	$self->increment;
    }
    return $self;
}



1;


=encoding utf8
 
=head1 NAME
 
Mojo::Collection::Role::Iterable - Iterator capabilities as a composable role for Mojo::Collection
 
=head1 SYNOPSIS
 
  use Mojo::Collection;
 
  my $c = Mojo::Collection->with_roles('+Iterable')->new(qw(foo bar baz));
 
  # Sequential iteration
  while (defined(my $item = $c->iterate)) {
      say $item;
  }
 
  # Cursor movement
  $c->reset;
  say $c->curr;       # foo
  $c->increment;
  say $c->curr;       # bar
  say $c->next;       # baz
  say $c->prev;       # foo
 
  # Rewind and go again
  $c->reset;
 
=head1 DESCRIPTION
 
L<Mojo::Collection::Role::Iterable> is a L<Mojo::Role> for
iterator-style cursor access in L<Mojo::Collection>.
 
=head1 METHODS
 
=head2 curr / current / item
 
  my $thing = $c->curr;
 
Returns the element at the current cursor position.
 
=head2 prev
 
  my $thing = $c->prev;
 
Returns the element before the cursor, or C<undef> at the beginning.
 
=head2 next
 
  my $thing = $c->next;
 
Returns the element after the cursor, or C<undef> at the end.
 
=head2 increment
 
  $c->increment;   # chainable
 
Moves the cursor forward by one (no-op at the last element).
 
=head2 decrement
 
  $c->decrement;   # chainable
 
Moves the cursor backward by one (no-op at the first element).
 
=head2 reset
 
  $c->reset;   # chainable
 
Rewinds both the cursor and the C<iterate> position to 0.
 
=head2 iterate
 
  while (defined(my $item = $c->iterate)) { ... }
 
Returns the item at the current iteration position and advances it,
keeping the cursor in sync. Returns C<undef> when exhausted.
Call C<reset> to iterate again.

=head3 CAVEAT

The safe iteration idiom is:

  while (my ($item) = $c->iterate) { ... }

Note the parentheses around C<$item> — this is a list assignment, not a scalar
one. The loop terminates only when C<iterate> returns an empty list, which
happens exclusively when the collection is exhausted. This means the loop
handles false values (C<0>, C<"">, C<"0">) and even C<undef> as legitimate
collection items without terminating early.

The simpler forms are tempting but have failure modes:

  while (my $item = $c->iterate) { ... }          # terminates early on 0, "", undef
  while (defined(my $item = $c->iterate)) { ... } # terminates early on undef

Use these only if you can guarantee your collection contains no false or
C<undef> values respectively. When in doubt, use the list form.

=cut
 
=head1 OVERLOADING

This role installs two operator overloads:

=over 4

=item C<++>

Calls C<increment>, moving the cursor forward by one. The collection
contents are not affected; only the cursor position changes.

=item C<-->

Calls C<decrement>, moving the cursor backward by one. Same caveat applies.

=back
 
=head1 SEE ALSO
 
L<Mojo::Collection>, L<Mojo::Base>, L<Hash::Util::FieldHash>
 
=head1 AUTHOR
 
Simone Cesano <scesano@cpan.org>
 
=head1 COPYRIGHT AND LICENSE
 
Copyright (C) Simone Cesano.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut
