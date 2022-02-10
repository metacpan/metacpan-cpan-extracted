package Podman::Images;

use Mojo::Base 'Podman::Client';

use Mojo::Collection;
use Scalar::Util qw(blessed);

use Podman::Image;

has 'names_only' => undef;

sub list {
  my $self = shift;

  if (!blessed($self)) {
    $self = __PACKAGE__->new();
    my %opts = @_;
    $self->names_only($opts{names_only});
  }

  my $images = $self->get('images/json', parameters => {all => 1},)->json;

  my @list = map {
    my ($name) = split /:/, $_->{Names}->[0] || 'none';
    $self->names_only ? $name : Podman::Image->new(name => $name);
  } @{$images};

  return Mojo::Collection->new(@list);
}

sub prune {
  my $self = shift;

  $self = __PACKAGE__->new() unless blessed($self);

  $self->post('images/prune');

  return 1;
}

1;

__END__

=encoding utf8

=head1 NAME

Podman::Images - Manage images.

=head1 SYNOPSIS

    # List local stored images sorted by Id
    my $images = Podman::Images->new->list->sort(sub { $a->inspect->{Id} cmp $b->inspect->{Id} } );
    say $_->name for $images->each;

    # Prune unused images
    Podman::Images->prune;

=head1 DESCRIPTION

=head2 Inheritance

    Podman::Images
        isa Podman::Client

L<Podman::Images> lists images and prunes unused ones.

=head1 ATTRIBUTES

L<Podman::Images> implements following attributes.

=head2 names_only

If C<true>, C<list> returns L<Mojo::Collection> of image names only instead of L<Podman::Image> objects, defaults to
C<false>.

=head1 METHODS

L<Podman::System> implements following methods, which can be used as object or class methods.

=head2 list

    my $list = Podman::Images->list;

Returns a L<Mojo::Collection> of L<Podman::Image> objects or image names only of stored images.

=head2 Prune

    Podman::Images->prune;

Prune all unused stored images.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
