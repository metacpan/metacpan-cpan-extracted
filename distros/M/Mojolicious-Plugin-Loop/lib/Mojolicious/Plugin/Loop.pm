package Mojolicious::Plugin::Loop;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.03';

our $ITERATOR;

sub count { $_[0]->{index} + 1 }
sub even  { $_[0]->{index} % 2 ? 0 : 1 }
sub first { $_[0]->{index} == 0 }
sub index { $_[0]->{index} }
sub key   { $_[0]->{key} }
sub last  { $_[0]->{index} + 1 == @{$_[0]->{items}} }
sub max   { $_[0]->size - 1 }

sub next {
  my $self = shift;
  return 0 if @{$self->{items}} <= ++$self->{index};
  $self->{item} = $self->{items}[$self->{index}];
  $self->{key} = $self->{map} ? $self->{item} : $self->{index};
  return 1;
}

sub odd    { $_[0]->{index} % 2 ? 1     : 0 }
sub parity { $_[0]->{index} % 2 ? 'odd' : 'even' }

sub peek {
  my ($self, $offset) = @_;
  my $index = $_[0]->{index} + $offset;
  return $index < 0 ? undef : $_[0]->{items}[$index];
}

sub reset { $_[0]->{index} = -1; $_[0] }
sub size { int @{$_[0]->{items}} }
sub val { $_[0]->{map} ? $_[0]->{map}{$_[0]->{item}} : $_[0]->{item} }

sub register {
  my ($self, $app, $config) = @_;

  $app->helper(
    loop => sub {
      my ($c, $data, $cb) = @_;
      return $ITERATOR if @_ == 1;
      return Mojolicious::Plugin::Loop->_iterate($data, $cb);
    }
  );
}

sub _iterate {
  my ($class, $data, $cb) = @_;
  my $bs = Mojo::ByteStream->new;
  my $self = bless {cb => $cb}, $class;

  if (UNIVERSAL::isa($data, 'ARRAY')) {
    @$self{qw(items)} = ($data);
  }
  elsif (UNIVERSAL::isa($data, 'HASH')) {
    @$self{qw(items map)} = ([sort keys %$data], $data);
  }
  elsif (UNIVERSAL::can($data, 'to_array')) {
    @$self{qw(items)} = $data->to_array;
  }

  $self->reset;
  return $self unless $cb;
  local $ITERATOR = $self;

LOOP:
  while ($self->next) {
    $bs .= $cb->($self->{item}, $self->{index});
  }

  return $bs;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Loop - Loop plugin for Mojolicious

=head1 SYNOPSIS

=head2 Application

  use Mojolicious::Lite;
  plugin 'loop';

=head2 Template

  %= loop [1,2,3,4], begin
  ---
  key/val: <%= loop->key %>/<%= loop->val %>
  count: <%= loop->index %> + 1 = <%= loop->count %> (index + 1)
  size: <%= loop->max %> + 1 = <%= loop->size %> (max + 1)
  prev: <%= loop->peek(-1) // 'undef' %> (peek -1)
  next: <%= loop->peek(1) // 'undef' %> (peek +1)
  parity: <%= loop->parity %>
  odd/even: <%= loop->odd ? 'odd' : loop->even ? 'even' : 'unknown' %>
  first: <%= loop->first ? 'yes' : 'no' %>
  last: <%= loop->last ? 'yes' : 'no' %>
  % end

  %= loop {a => 1, b => 2, c => 3}, begin
  ---
  key/val: <%= loop->key %>/<%= loop->val %>
  count: <%= loop->index %> + 1 = <%= loop->count %> (index + 1)
  size: <%= loop->max %> + 1 = <%= loop->size %> (max + 1)
  prev: <%= loop->peek(-1) // 'undef' %> (peek -1)
  next: <%= loop->peek(1) // 'undef' %> (peek +1)
  parity: <%= loop->parity %>
  odd/even: <%= loop->odd ? 'odd' : loop->even ? 'even' : 'unknown' %>
  first: <%= loop->first ? 'yes' : 'no' %>
  last: <%= loop->last ? 'yes' : 'no' %>
  % end

=head1 DESCRIPTION

L<Mojolicious::Plugin::Loop> is a plugin with helpers for iterating over either array,
hashes or array/hash-like structures. 

NOTE: THIS MODULE IS EXPERIMENTAL AND THE API MAY CHANGE AT ANY TIME

=head1 TEMPLATE METHODS

=head2 count

  $int = $loop->count;

Returns L</index> + 1.

=head2 even

  $bool = $loop->even;

Returns true if L</count> is 2, 4, 6, ...

=head2 first

  $bool = $loop->first;

Returns true if L</index> is zero.

=head2 index

  $int = $loop->index;

Returns the index number, starting on 0.

=head2 key

  $str = $self->key; # hash
  $int = $self->key; # array

Returns L</index> if iterating over an array or the current key if iterating
over a hash.

=head2 last

  $bool = $loop->last;

Returns true if L</index> is L</max>.

=head2 max

  $int = $loop->max;

Returns L</size> - 1.

=head2 next

  $bool = $self->next;

Move the iterator forward one step. Example:

  % my $i = loop [1, 2, 3];
  % while ($i->next) {
  %= $i->val;
  % }

=head2 odd

  $bool = $loop->odd;

Returns true if L</count> is 1, 3, 5, ...

=head2 parity

  $str = $loop->parity;

Returns either the string "odd" or "even".

=head2 peek

  $any = $loop->peek($index);
  $any = $loop->peek(-3);

Returns either the value in the array, or the key in the hash, relative to the
current item. Examples:

  # [24, 25, 26]
  $loop->index == 2
  $loop->peek(-1) == 25

  # {a => 24, b => 25, c => 26}
  $loop->index == 1
  $loop->peek(1) == "c"

=head2 reset

  $self = $self->reset;

Used to reset the iterator.

=head2 size

  $int = $loop->size;

Returns the number of items in the array, or number of keys in the hash.

=head2 val

  $any = $loop->val;

Returns the value of the current item in the array or hash.

=head1 METHODS

=head2 register

Used to register the plugin in the L<Mojolicious> application.

=head1 AUTHOR

Jan Henning Thorsen

Marcus Ramberg

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Template::Iterator>.

=cut
