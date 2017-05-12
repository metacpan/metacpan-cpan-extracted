use strict;
use warnings;

package MooseX::LexicalRoleApplication;
our $VERSION = '0.03';
# ABSTRACT: Apply roles for a lexical scope only

use Scope::Guard;
use Scalar::Util 'blessed';

use namespace::clean;


sub apply {
    my ($class, $role, $instance, $rebless_params, $application_options) = @_;
    my $previous_metaclass = Class::MOP::class_of($instance);

    $role->apply($instance => (
        %{ $application_options || {} },
        rebless_params => $rebless_params || {},
    ));

    return Scope::Guard->new(sub {
        $previous_metaclass->rebless_instance_back($instance);
    });
}

1;

__END__
=pod

=head1 NAME

MooseX::LexicalRoleApplication - Apply roles for a lexical scope only

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  my $obj = SomeClass->new;
  $obj->method_from_role; # fails

  {
    my $guard = MooseX::LexicalRoleApplication->apply(SomeRole->meta, $obj);
    $obj->method_from_role; # works
  }

  $obj->method_from_role; # fails

=head1 DESCRIPTION

This module allows applying a role for the duration of a lexical scope only.

=head1 CAVEATS

Actual I<lexical> role application isn't quite supported yet. The following
example won't do what it's supposed to just yet:

  {
    my $guard = MooseX::LexicalRoleApplication->apply($role, $obj);
    $other_role->apply($obj);
  }

=head1 METHODS

=head2 apply ($role, $instance, \%rebless_params, \%application_options)

Will apply C<$role> to C<$instance>. C<%rebless_params> will be passed to
L<Class::MOP::Class/rebless_instance>. C<%application_options> will be passed
to L<Moose::Meta::Role/apply>.

A L<Scope::Guard|Scope::Guard> will be returned. Keep it around as long as you
want C<$role> to be applied to C<$instance>. You can cancel role removal by
calling C<dismiss> on the returned scope guard. If you want to remove the role
immediately, you can simply undef the guard.

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

