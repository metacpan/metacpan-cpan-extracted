package PDK::Utils::Cache;

use v5.30;
use Moose;
use namespace::autoclean;

has cache => (is => 'ro', isa => 'HashRef[Ref]', default => sub { {} }, );

sub get {
  my ($self, @keys) = @_;
  return $self->locate(@keys);
}

sub set {
  my ($self, @args) = @_;

  confess("错误：至少需要一个键和一个值") if @args < 2;

  my $value   = pop @args;
  my $lastKey = pop @args;
  my @keys    = @args;

  my @step;
  my $ref = $self->cache;

  for my $key (@keys) {
    push @step, $key;
    $ref->{$key} //= {};
    $ref = $ref->{$key};

    confess("错误：cache->" . join('->', @step) . " 不是一个哈希引用") if defined $ref && ref($ref) ne 'HASH';
  }

  $ref->{$lastKey} = $value;
}

sub clear {
  my ($self, @keys) = @_;

  if (@keys) {
    my $lastKey = pop @keys;
    my $ref     = $self->locate(@keys);
    delete $ref->{$lastKey} if defined $ref && ref($ref) eq 'HASH';
  }
  else {
    $self->{cache} = {};
  }
}

sub locate {
  my ($self, @keys) = @_;
  my $ref = $self->cache;

  for my $key (@keys) {
    return undef unless exists $ref->{$key};
    $ref = $ref->{$key};
  }

  return $ref;
}

__PACKAGE__->meta->make_immutable;

1;

