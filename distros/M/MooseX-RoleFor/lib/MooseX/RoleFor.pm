package MooseX::RoleFor;

use 5.010;
use strict;
use utf8;

BEGIN
{
	$MooseX::RoleFor::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::RoleFor::VERSION   = '0.003';
}

use Moose::Exporter;

Moose::Exporter->setup_import_methods(
	with_meta      => [qw/role_for/],
	role_metaroles => { role => ['MooseX::RoleFor::Meta::Role::Trait::RoleFor'] },
);

sub role_for
{
	my ($meta, $is_for, $consequence) = @_;
	$meta->role_is_for($is_for);
	$meta->role_misapplication_consequence($consequence)
		if defined $consequence;
}

'Yay!';

__END__

=head1 NAME

MooseX::RoleFor - limit the applicability of a Moose::Role

=head1 SYNOPSIS

  package Watchdog;
  
  use Moose::Role;
  use MooseX::RoleFor;
  
  role_for 'Dog';
  requires 'make_noise';
  
  sub hear_intruder
  {
    my ($self) = @_;
    $self->make_noise;
  }
  
  1;

=head1 DESCRIPTION

This package allows your Moose roles to limit what classes and objects
they may be composed with. This is often not a good idea - one of the
advantages of roles is that they can be reused in such different contexts.

However, if you search CPAN for "TraitFor" you'll see that it's quite a
common desire to indicate that a role should only be applies to certain
classes.

=head2 C<< role_for $class, $consequence >>

C<< $class >> is a string (class name) or arrayref of strings indicating
which classes this role may be composed with. Inheritance is respected.

C<< $consequence >> is either "carp" (the default) or "croak".

=head2 How it works

Adding C<< use MooseX::RoleFor >> to your role imports the C<role_for>
function to your class, and applies the
C<MooseX::RoleFor::Meta::Role::Trait::RoleFor> role to your role's metaclass.

The C<role_for> function is basically:

  sub role_for
  {
    __PACKAGE__->meta->role_is_for($_[0])
    __PACKAGE__->meta->role_misapplication_consequence($_[1])
      if defined $_[1];
  }

C<MooseX::RoleFor::Meta::Role::Trait::RoleFor> hooks onto
C<Moose::Meta::Role>'s C<apply> method to enforce your restriction.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-RoleFor>.

=head2 Known

When misapplying a role to an instance (rather than a class), you get not
one warning, but two: one for the object, and one for its metaclass.

=head1 SEE ALSO

L<Moose>,
L<Moose::Meta::Role>.

L<MooseX::RoleFor::Meta::Role::Trait::RoleFor> - internals.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

