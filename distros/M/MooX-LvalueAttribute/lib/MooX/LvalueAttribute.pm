#
# This file is part of MooX-LvalueAttribute
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MooX::LvalueAttribute;
{
  $MooX::LvalueAttribute::VERSION = '0.16';
}
use strictures 1;

# ABSTRACT: Provides Lvalue accessors to Moo class attributes

require Moo;
require Moo::Role;

our %INJECTED_IN_ROLE;
our %INJECTED_IN_CLASS;

sub import {
    my $class = shift;
    my $target = caller;

    if ($Moo::Role::INFO{$target} && $Moo::Role::INFO{$target}{is_role}) {

        # We are loaded from a Moo role
        $Moo::Role::INFO{$target}{accessor_maker} ||= do {
            require Method::Generate::Accessor;
            Method::Generate::Accessor->new
          };
        Moo::Role->apply_roles_to_object(
            $Moo::Role::INFO{$target}{accessor_maker},
            'Method::Generate::Accessor::Role::LvalueAttribute',
        );
        $INJECTED_IN_ROLE{$target} = 1;

    } elsif ($Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class}) {

        # We are loaded from a Moo class
        if ( !$INJECTED_IN_CLASS{$target} ) {
            Moo::Role->apply_roles_to_object(
              Moo->_accessor_maker_for($target),
              'Method::Generate::Accessor::Role::LvalueAttribute',
            );
            $INJECTED_IN_CLASS{$target} = 1;        
        }
    } else {
        die "MooX::LvalueAttribute can only be used in Moo classes or Moo roles.";        
    }

}


1;

__END__
=pod

=head1 NAME

MooX::LvalueAttribute - Provides Lvalue accessors to Moo class attributes

=head1 VERSION

version 0.16

=head1 SYNOPSIS

=head2 From a Moo class

  package App;
  use Moo;
  use MooX::LvalueAttribute;
  
  has name => (
    is => 'rw',
    lvalue => 1,
  );

  # Elsewhere

  my $app = App->new(name => 'foo');
  $app->name = 'Bar';
  print $app->name;  # Bar

=head2 From a Moo role

  package MyRole;
  use Moo::Role;
  use MooX::LvalueAttribute;

  has name => (
    is => 'rw',
    lvalue => 1,
  );

  package App;
  use Moo;
  with('MyRole');

  # Elsewhere

  my $app = App->new(name => 'foo');
  $app->name = 'Bar';
  print $app->name;  # Bar

=head1 DESCRIPTION

This modules provides Lvalue accessors to your Moo attributes. It won't break
Moo's encapsulation, and will properly call any accessor method modifiers,
triggers, builders and default values creation. It can be used from a Moo class
or role.

It means that instead of writing:

  $object->name("Foo");

you can use:

  $object->name = "Foo"; 

=head1 ATTRIBUTE SPECIFICATION

To enable Lvalue access to your attribute, simply use C<MooX::LvalueAttribute>
in the class or role, and add:

  lvalue => 1,

in the attribute specification (see synopsis).

=head1 NOTE ON IMPLEMENTATION

The implementation doesn't use AUTOLOAD, nor TIESCALAR. Instead, it uses a
custom accessor and C<Variable::Magic>, which is faster and cheaper than the
tie / AUTOLOAD mechanisms.

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

