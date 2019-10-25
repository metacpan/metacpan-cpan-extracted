package MongoHosting::ReplicaSet;

use Moo;
use Class::Load qw(load_class);
use List::Util qw(all);
has name    => (is => 'ro');
has type    => (is => 'ro');
has members => (is => 'lazy', init_arg => undef, predicate => 1);
has _member_specs => (is => 'ro', init_arg => 'members');
has siblings      => (is => 'rw', default  => sub { [] });
has checked       => (is => 'lazy');

sub _build_members {
  my $self = shift;
  my $class = load_class('MongoHosting::ReplicaSet::' . (ucfirst lc $self->type));
  return [map { $class->new(%$_, type => $self->type, parent => $self) }
      @{$self->_member_specs}];
}

sub _build_checked {
  return 1 if all { $_->checked } @{shift->members || []};
  return 0;
}

sub deploy {
  my $self = shift;
  $_->deploy for @{$self->members};
  $_->init   for @{$self->members};
}

sub arbiter {
  my ($arbiter) = grep { $_->is_arbiter } @{shift->members};
  return $arbiter;
}


sub sharding_dsn {
  my $self = shift;
  $self->name . '/'
    . join(q{,}, map { $_->private_ip . ':' . $_->port } @{$self->members});
}

1;
