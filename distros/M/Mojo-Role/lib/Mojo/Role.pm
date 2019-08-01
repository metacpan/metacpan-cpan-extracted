package Mojo::Role;

# imports
use Mojo::Base -strict;
use Role::Tiny       ();
use Role::Tiny::With ();
use Mojo::Util       ();

# version
our $VERSION = '0.999';

sub import {
  # caller is a consumer, import with
  # it is assumed that the caller's Mojo::Base imported strict already
  if (@_ > 1 and $_[1] eq '-with') {
    @_ = 'Role::Tiny::With';
    goto &Role::Tiny::With::import;
  }

  # the caller is a role
  # roles are strict
  Mojo::Base->import('-strict');
  my $target = caller;
  Mojo::Util::monkey_patch $target, has => sub { Mojo::Base::attr($target, @_) };

  @_ = 'Role::Tiny';
  goto &Role::Tiny::import;
}

1;
__END__
=encoding utf8

=head1 NAME

Mojo::Role - Tiny and simple role system for Mojo (DEPRECATED)

=head1 DESCRIPTION

This module has been renamed to L<Mojo::RoleTiny> and the namespace may be
repurposed in the future. Instead of using it, you can now create roles using
L<Mojo::Base> directly.

  # For a role class
  use Mojo::Base -role;

  # To use/consume a role
  use Role::Tiny::With;
  with 'Role::SomeRoleClass';

=head1 AUTHOR

Daniel Vinciguerra <daniel.vinciguerra at bivee.com.br>

=head1 CONTRIBUTORS

Joel Berger (jberger)

Matt S. Trout (mst)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, Daniel Vinciguerra and L</CONTRIBUTORS>.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<https://github.com/kraih/mojo>, L<Mojo::Base>, L<Role::Tiny>, L<http://mojolicious.org>.
