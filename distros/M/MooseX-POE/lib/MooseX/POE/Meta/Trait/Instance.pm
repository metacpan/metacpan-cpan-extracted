package MooseX::POE::Meta::Trait::Instance;
{
  $MooseX::POE::Meta::Trait::Instance::VERSION = '0.215';
}
# ABSTRACT: A Instance Metaclass for MooseX::POE

use Moose::Role;
use POE;

use Scalar::Util ();

sub get_session_id {
    my ( $self, $instance ) = @_;
    return $instance->{session_id};
}

sub get_slot_value {
    my ( $self, $instance, $slot_name ) = @_;
    return $instance->{heap}{$slot_name};
}

sub set_slot_value {
    my ( $self, $instance, $slot_name, $value ) = @_;
    $instance->{heap}{$slot_name} = $value;
}

sub is_slot_initialized {
    my ( $self, $instance, $slot_name, $value ) = @_;
    exists $instance->{heap}{$slot_name} ? 1 : 0;
}

sub weaken_slot_value {
    my ( $self, $instance, $slot_name ) = @_;
    Scalar::Util::weaken( $instance->{heap}{$slot_name} );
}

sub inline_slot_access {
    my ( $self, $instance, $slot_name ) = @_;
    sprintf '%s->{heap}{%s}', $instance, $slot_name;
}

no POE;
no Moose::Role;
1;


=pod

=head1 NAME

MooseX::POE::Meta::Trait::Instance - A Instance Metaclass for MooseX::POE

=head1 VERSION

version 0.215

=head1 SYNOPSIS

    Moose::Util::MetaRole::apply_metaclass_roles(
      for_class => $for_class,
      metaclass_roles => [ 
        'MooseX::POE::Meta::Trait::Class' 
      ],
      instance_metaclass_roles => [
        'MooseX::POE::Meta::Trait::Instance',
      ],
    );

=head1 DESCRIPTION

A metaclass for MooseX::POE. This module is only of use to developers 
so there is no user documentation provided.

=head1 METHODS

=head2 create_instance

=head2 get_slot_value

=head2 inline_slot_access

=head2 is_slot_initialized

=head2 set_slot_value

=head2 weaken_slot_value

=head2 get_session_id

=head1 METHODS

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Ash Berlin <ash@cpan.org>

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Yuval (nothingmuch) Kogman

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Ash Berlin, Chris Williams, Yuval Kogman, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

