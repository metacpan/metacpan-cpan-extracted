package Mojo::RoleTiny;

# ABSTRACT: Mojo::RoleTiny - Tiny and simple role system for Mojo

# imports
use Mojo::Base -strict;
use Role::Tiny       ();
use Role::Tiny::With ();
use Mojo::Util       ();

# version
our $VERSION = 0.022;

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

Mojo::RoleTiny - Tiny and simple role system for Mojo

=head1 SYNOPSIS

  # role class
  package MojoCoreMantainer;
  use Mojo::RoleTiny;

  sub mantaining_mojo {
    say "I'm making improvements for Mojolicious..."
  }


  # base class
  package Developer;
  use Mojo::Base -base;

  sub make_code {
    say "I'm making code for Mojolicious ecosystem..."
  }


  # class
  package People;
  use Mojo::Base 'Developer';

  # using roles
  use Mojo::RoleTiny -with;
  with 'MojoCoreMantainer';

  # method
  sub what_can_i_do {
    my $self = shift;
    say "I can do people things...";
    $self->make_code;
    $self->mantaining_mojo;
  }


=head1 DESCRIPTION

B<Explanation>

This module init named as Mojo::Role but was changed at the request of L<sri>
because an official Mojolicious role implementation is in development.


This module provide a simple and light dependence way to use roles in
L<Mojolicious|http://mojolicious.org/> classes.

  # For a role class
  use Mojo::RoleTiny;

  # To use/consume a role
  use Mojo::RoleTiny -with;
  with 'Role::SomeRoleClass';


=head1 FUNCTIONS

Mojo::RoleTiny optionally exports a C<with> function, that can be imported with the C<-with> flag.
When exported the caller is not implementing a role but rather consuming them.

=head2 with

  with 'SomeRoleClass';

Import a role or a list of roles to use.


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


