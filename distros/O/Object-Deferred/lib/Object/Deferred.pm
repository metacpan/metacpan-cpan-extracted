package Object::Deferred;
use Moose;
use namespace::autoclean;

# ABSTRACT: A simple API for handling asynchronous events.


has _resolve_callbacks => (
  is        => 'rw',
  isa       => 'ArrayRef',
  default   => sub {[]},
  init_arg  => undef,
  traits     => ['Array'],
  handles => {
    add_resolve_callback => 'push',
    resolve_callbacks => 'elements'
  }
);

has _reject_callback => (
  is        => 'rw',
  isa       => 'ArrayRef',
  default   => sub {[]},
  init_arg  => undef,
  traits     => ['Array'],
  handles => {
    add_reject_callback => 'push',
    reject_callbacks => 'elements'
  }
);

has _is_unfulfilled => (
  is      => 'rw',
  isa     => 'Bool',
  default => 1,
  reader  => 'is_unfulfilled',
  writer  => '_is_unfulfilled'
);


has resolution => (
  is        => 'rw',
  isa       => 'ArrayRef',
  predicate => 'is_resolved',
  reader    => 'resolution',
  writer    => '_resolution',
  trigger   => sub { shift->_is_unfulfilled(0) }
);


has rejection => (
  is        => 'rw',
  isa       => 'ArrayRef',
  predicate => 'is_rejected',
  reader    => 'rejection',
  writer    => '_rejection',
  trigger   => sub { shift->_is_unfulfilled(0) }
);


sub then {
  my ( $self, $resolve, $reject ) = @_;

  $self->add_resolve_callback($resolve)
    if defined($resolve);

  $self->add_reject_callback($reject)
    if defined($reject);

  my $chain = Object::Deferred->new;
  $self->add_resolve_callback(sub { $chain->resolve(@{$self->resolution}) });
  $self->add_reject_callback(sub { $chain->reject(@{$self->rejection}) });
  return $chain;
}


sub resolve {
  my $self = shift;
  return unless $self->is_unfulfilled;
  $self->_resolution([@_]);
  foreach my $cb ( $self->resolve_callbacks ) {
    $cb->(@_);
  }
}

after add_resolve_callback => sub {
  my($self, $cb) = @_;
  $cb->(@{$self->resolution}) if $self->is_resolved;
};


sub reject {
  my $self = shift;
  return unless $self->is_unfulfilled;
  $self->_rejection([@_]);
  foreach my $cb ( $self->reject_callbacks ) {
    $cb->(@_);
  }
}

after add_reject_callback => sub {
  my($self, $cb) = @_;
  $cb->(@{$self->rejection}) if $self->is_rejected;
};

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Object::Deferred - A simple API for handling asynchronous events.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Object::Deferred;

  my $print = Object::Deferred->new;
  my $hello = Object::Deferred->new;
  my $world = Object::Deferred->new;
  my $out = 'Not Enough Info Yet';

  $print->then( sub { $out = join '', @_ } );

  print $out, "\n";

  $world->resolve('World');

  print $out, "\n";

  $world->then(
    sub {
      my $w = shift;
      $hello->then(
        sub {
          my $h = shift;
          $print->resolve("$h $w\n");
        }
      );
    }
  );

  print $out, "\n";

  $hello->resolve('Hello');

  print $out, "\n";

=head1 DESCRIPTION

This is an implementation of the CommonJS promise API specification
draft. It provides a clean way to create events and install hooks that run
when those events are triggered.

=head1 ATTRIBUTES

=head2 resolution

An ArrayRef containing the resolution value for this deferred
object. Returns undef if the object is in an unfulfilled state.

=head2 rejection

An ArrayRef containing the rejection value for this deferred object. Returns
undef if the object is in an unfulfilled state.

=head1 METHODS

=head2 then

my $chain_deferred = $deferred->then(\&resolve, \&reject);

This method installs callbacks that run when the deferred object is resolved
or rejected. If the object is an unfulfilled state, callback execution is
deferred until the object is resolved or rejected. If the object has already
been resolved or rejected, newly installed callbacks execute immediately
taking the appropriate resolution or rejection values as a parameter.

=head2 resolve

Resolve a deferred object by passing it a resolution value. Resolution
callbacks will be fired the first time this value is provided.

=head2 reject

Reject a deferred object by passing it a rejection value. Rejection
callbacks will be fired the first time this value is provided.

=for test_synopsis use strict;
use warnings;

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Eden Cardim <edencardim@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

