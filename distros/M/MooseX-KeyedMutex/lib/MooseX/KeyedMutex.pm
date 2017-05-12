# $Id: /mirror/coderepos/lang/perl/MooseX-KeyedMutex/trunk/lib/MooseX/KeyedMutex.pm 86987 2008-10-01T17:11:59.535183Z daisuke  $

package MooseX::KeyedMutex;
use 5.008;
use Moose::Role;
use Moose::Util::TypeConstraints;
use KeyedMutex;
use Carp();

our $VERSION   = '0.00003';
our $AUTHORITY = 'cpan:DMAKI';

subtype 'MooseX::KeyedMutex::MaybeKeyedMutex'
    => as 'Maybe[KeyedMutex]';

coerce 'MooseX::KeyedMutex::MaybeKeyedMutex'
    => from 'HashRef'
        => via {
            my $h = $_;
            return unless $h;
            return KeyedMutex->new($h->{args});
        }
;

has 'mutex' => (
    is => 'rw',
    isa => 'MooseX::KeyedMutex::MaybeKeyedMutex',
    coerce => 1,
    default => sub {
        # If no keyedmutex was provided explicitly, we attempt to create one.
        # however,  if the creation of this object fails, we let the
        # user go in "degraded mode", without locks.
        my $mutex = eval { KeyedMutex->new };
        return $mutex;
    }
);

has 'mutex_required' => (
    is => 'rw',
    isa => 'Bool',
    required => 1,
    default => 0
);

no Moose::Role;

sub lock {
    my ($self, $key) = @_;

    my $mutex = $self->mutex;

    if (! $mutex && $self->mutex_required) {
        Carp::confess("No mutex object provided, and mutex_required is on");
    }
    # if no mutex is available, let if ($self->lock) pass, but don't
    # provide an object.
    return '0E0' unless $mutex;

    my $rv = eval { $mutex->lock($key, 1) };

    return $rv;
}

1;

__END__

=head1 NAME

MooseX::KeyedMutex - Role To Add KeyedMutex

=head1 SYNOPSIS

  package MyClass;
  use Moose;

  with 'MooseX::KeyedMutex';

  no Moose;

  $object = MyClass->new( mutex => $mutex );
  $object = MyClass->new(
    mutex => {
      args => {
        sock => '....',
      }
    }
  );

  if (my $lock = $object->lock($name)) {
    ....
  }

=head1 DESCRIPTION

MooseX::KeyedMutex adds instant distributed locking to you objects via
KeyedMutex.

=head1 METHODS

=head2 lock($key)

Attempts to acquire a lock by the name $key.
On success, returns a KeyedMutex::Lock object. On failure, returns undef.

In case the object has *NOT* been initialized with a proper keyedmutex,
lock() automatically goes into degraded mode and will immediately return
success. In such cases, '0E0' will be returned.

=head2 mutex_required

If set to true, MooseX::KeyedMutex will croak whenever an attempt to lock
is issued but no mutex is available

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut