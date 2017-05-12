package Mojar::Cache;
use Mojo::Base -base;

# Attributes

has namespace => 'main';
has on_get_error => sub { sub { require Carp; Carp::croak @_ } };
has on_set_error => sub { sub { require Carp; Carp::croak @_ } };

has slots => sub { [] };
has 'max_keys';

# Public methods

sub new {
  my ($proto, %param) = @_;
  my $self = $proto->SUPER::new(%param);
  $self->{store} = {};
  return $self;
}

# Getting and setting

sub get {
  my ($self, $key) = @_;
  my $value;
  eval {
    $value = $self->{store}{$self->namespace}{$key};
    1;
  }
  or do {
    my $e = $@ // 'Failed get';
    $self->on_get_error->($e);
  };
  return $value;
}

sub set {
  my ($self, $key, $value) = @_;
  eval {
    my $slots = $self->slots;
    unless ($self->is_valid($key)) {
      push @$slots, $key;
      while ($self->max_keys and scalar @$slots > $self->max_keys) {
        # Too many in the bed
        $self->remove(shift @$slots);
      }
    }
    $self->{store}{$self->namespace}{$key} = $value;
    1;
  }
  or do {
    my $e = $@ // 'Failed set';
    $self->on_set_error->($e);
  };
  return $self;
}

sub compute {
  my ($self, $key, $code) = @_;
  my $cache = $self->{store}{$self->namespace};
  return $cache->{$key} if exists $cache->{$key};

  my $value = $code->($key);
  $self->set($key => $value);
  return $value;
}

# Removing

sub remove {
  my ($self, $key) = @_;
  delete $self->{store}{$self->namespace}{$key};
  return $self;
}

# Inspecting keys

sub is_valid {
  my ($self, $key) = @_;
  return exists $self->{store}{$self->namespace}{$key};
}

# Atomic operations

sub append {
  my ($self, $key, $further_text) = @_;
  $self->{store}{$self->namespace}{$key} .= $further_text;
  return $self;
}

# Namespace operations

sub clear {
  my $self = shift;
  $self->{store}{$self->namespace} = {};
  return $self;
}

sub get_keys { keys %{ $_[0]{store}{$_[0]->namespace} } }

# Multiple key/value operations

sub get_multi_arrayref {
  my ($self, $keys_ref) = @_;
  my $cache = $self->{store}{$self->namespace};
  return [ map $cache->{$_}, @$keys_ref ];
}

sub get_multi_hashref {
  my ($self, $keys_ref) = @_;
  my $cache = $self->{store}{$self->namespace};
  return { map $_ => $cache->{$_}, @$keys_ref };
}

sub set_multi {
  my ($self, $hashref) = @_;
  while (my ($k, $v) = each %$hashref) {
    $self->set($k => $v);
  }
  return $self;
}

sub remove_multi {
  my ($self, $keys_ref) = @_;
  $self->remove($_) foreach @$keys_ref;
  return $self;
}

sub to_hashref { $_[0]{store}{$_[0]->namespace} || {} }

1;
__END__

=head1 NAME

Mojar::Cache - Bare-bones in-memory cache

=head1 SYNOPSIS

  use Mojar::Cache;

  my $cache = Mojar::Cache->new;
  $cache->set(foo => 'bar');
  my $foo = $cache->get('foo');

=head1 DESCRIPTION

A minimalist cache intended to be easily upgradeable to L<CHI>.

=head1 ATTRIBUTES

L<Mojar::Cache> implements the following attributes.

=head2 C<namespace>

  $cache->namespace('Admin');
  $namespace = $cache->namespace;

Namespace for the cache, defaults to C<main>.

#=head2 C<on_get_error>
#
#  my $cb = $cache->on_get_error;
#  $cache = $cache->on_get_error(sub { ... });
#
#Callback triggered by C<get> exception, defaults to a null sub.
#
#=head2 C<on_set_error>
#
#  my $cb = $cache->on_set_error;
#  $cache = $cache->on_set_error(sub { ... });
#
#Callback triggered by C<set> exception, defaults to a null sub.

=head1 METHODS

=head2 C<get>

  my $value = $cache->get('foo');

Get cached value.

=head2 C<set>

  $cache = $cache->set(foo => 'bar');

Set cache value.

=head1 RATIONALE

Mojo::Cache is beautifully simple but sometimes too barebones; CHI is the proper
way to do serious cacheing but cannot be done on a small footprint.  I wanted
minor extensions to the former with an upgrade path to the latter.

=head1 SEE ALSO

L<Mojo::Cache>, L<CHI>.
