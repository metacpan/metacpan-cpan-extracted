package Podman::Containers;

use Mojo::Base 'Podman::Client';

use Mojo::Collection qw(c);
use Scalar::Util qw(blessed);

use Podman::Container;

has 'names_only' => undef;

sub list {
  my $self = shift;

  if (!blessed($self)) {
    $self = __PACKAGE__->new();
    my %opts = @_;
    $self->names_only($opts{names_only});
  }

  my $containers = $self->get('containers/json', parameters => {all => 1})->json;
  my @list = map {
    my $name = $_->{Names}->[0] || $_->{Id};
    $self->names_only ? $name : Podman::Container->new(name => $name);
  } @{$containers};

  return c(@list);
}

sub prune {
  my $self = shift;

  $self = __PACKAGE__->new() unless blessed($self);

  $self->post('containers/prune');

  return 1;
}

1;

__END__

=encoding utf8

=head1 NAME

Podman::Containers - Manage containers.

=head1 SYNOPSIS

    # List available containers sorted by Id
    my $containers = Podman::Containers->new->list->sort(sub { $a->inspect->{Id} cmp $b->inspect->{Id} } );
    say $_->name for $containers->each;

    # Prune unused containers
    Podman::Containers->prune;

=head1 DESCRIPTION

=head2 Inheritance

    Podman::Containers
        isa Podman::Client

L<Podman::Containers> lists all available containers and prunes stopped ones.

=head1 ATTRIBUTES

L<Podman::Containers> implements following attributes.

=head2 names_only

If C<true>, C<list> returns L<Mojo::Collection> of image names only, defaults to C<false>.

=head1 METHODS

L<Podman::Containers> implements following methods, which can be used as object or class methods.

=head2 list

    my $list = Podman::Containers->list(names_only => 1);

Returns a L<Mojo::Collection> of L<Podman::Container> objects or container names only of stored images. See attribute
C<names_only>.

=head2 prune

    Podman::Containers->->prune;

Prune all stopped containers.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=cut
