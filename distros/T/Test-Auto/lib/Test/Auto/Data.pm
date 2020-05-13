package Test::Auto::Data;

use strict;
use warnings;

use Moo;

require Carp;

our $VERSION = '0.12'; # VERSION

# BUILD

has data => (
  is => 'ro',
  builder => 'new_data',
  lazy => 1
);

sub new_data {
  my ($self) = @_;

  my $file = $self->file or die [];
  my $data = $self->parser($self->lines);

  return $data;
}

has file => (
  is => 'ro',
  builder => 'new_file',
  lazy => 1
);

sub new_file {
  my ($self) = @_;

  my $from = $self->from or return;
  my $path = $from =~ s/::/\//gr;

  return $INC{"$path.pm"};
}

has from => (
  is => 'ro',
  lazy => 1
);

sub BUILD {
  my ($self, $args) = @_;

  $self->file;
  $self->data;

  return $self;
}

# METHODS

sub content {
  my ($self, $name) = @_;

  my $item = $self->item($name) or return;
  my $data = $item->{data};

  return $data;
}

sub contents {
  my ($self, $name, $seek) = @_;

  my $items = $self->list($name) or return;
  @$items = grep { $_->{name} eq $seek } @$items if $seek;
  my $data = [map { $_->{data} } @$items];

  return $data;
}

sub item {
  my ($self, $name) = @_;

  for my $item (@{$self->{data}}) {
    return $item if !$item->{list} && $item->{name} eq $name;
  }

  return;
}

sub lines {
  my ($self) = @_;

  my $file = $self->file;

  open my $fh, '<', $file or Carp::confess "$!: $file";
  my $lines = join "\n", <$fh>;
  close $fh;

  return $lines;
}

sub list {
  my ($self, $name) = @_;

  return if !$name;

  my @list;

  for my $item (@{$self->{data}}) {
    push @list, $item if $item->{list} && $item->{list} eq $name;
  }

  return [sort { $a->{index} <=> $b->{index} } @list];
}

sub list_item {
  my ($self, $list, $name) = @_;

  my $items = $self->list($list) or return;
  my $data = [grep { $_->{name} eq $name } @$items];

  return $data;
}

sub parser {
  my ($self, $data) = @_;

  $data =~ s/\n*$/\n/;

  my @chunks = split /^=\s*(.+?)\s*\r?\n/m, $data;

  shift @chunks;

  my $items = [];

  while (my ($meta, $data) = splice @chunks, 0, 2) {
    next unless $meta && $data;
    next unless $meta ne 'cut';

    my @info = split /\s/, $meta, 2;
    my ($list, $name) = @info == 2 ? @info : (undef, @info);

    $data = [split /\n\n/, $data];

    my $item = { name => $name, data => $data, index => @$items + 1, list => $list };

    push @$items, $item;
  }

  return $items;
}

sub pluck {
  my ($self, $type, $name) = @_;

  return if !$name;
  return if !$type || ($type ne 'item' && $type ne 'list');

  my (@list, @copy);

  for my $item (@{$self->{data}}) {
    my $matched = 0;

    $matched = 1 if $type eq 'list' && $item->{list} && $item->{list} eq $name;
    $matched = 1 if $type eq 'item' && $item->{name} && $item->{name} eq $name;

    push @list, $item if $matched;
    push @copy, $item if !$matched;
  }

  $self->{data} = [sort { $a->{index} <=> $b->{index} } @copy];

  return $type eq 'name' ? $list[0] : [@list];
}

1;
