package MooseX::Singleton::Role::Meta::Instance;
use Moose::Role;
use Scalar::Util qw(weaken blessed);

our $VERSION = '0.30';

sub get_singleton_instance {
    my ( $self, $instance ) = @_;

    return $instance if blessed $instance;

    # optimization: it's really slow to go through new_object for every access
    # so return the singleton if we see it already exists, which it will every
    # single except the first.
    no strict 'refs';
    return ${"$instance\::singleton"} if defined ${"$instance\::singleton"};

    # We need to go through ->new in order to make sure BUILD and
    # BUILDARGS get called.
    return $instance->meta->name->new;
}

override clone_instance => sub {
    my ( $self, $instance ) = @_;
    $self->get_singleton_instance($instance);
};

override get_slot_value => sub {
    my ( $self, $instance, $slot_name ) = @_;
    $self->is_slot_initialized( $instance, $slot_name )
        ? $self->get_singleton_instance($instance)->{$slot_name}
        : undef;
};

override set_slot_value => sub {
    my ( $self, $instance, $slot_name, $value ) = @_;
    $self->get_singleton_instance($instance)->{$slot_name} = $value;
};

override deinitialize_slot => sub {
    my ( $self, $instance, $slot_name ) = @_;
    delete $self->get_singleton_instance($instance)->{$slot_name};
};

override is_slot_initialized => sub {
    my ( $self, $instance, $slot_name, $value ) = @_;
    exists $self->get_singleton_instance($instance)->{$slot_name} ? 1 : 0;
};

override weaken_slot_value => sub {
    my ( $self, $instance, $slot_name ) = @_;
    weaken $self->get_singleton_instance($instance)->{$slot_name};
};

override inline_slot_access => sub {
    my ( $self, $instance, $slot_name ) = @_;
    sprintf "%s->meta->instance_metaclass->get_singleton_instance(%s)->{%s}",
        $instance, $instance, $slot_name;
};

no Moose::Role;

1;

# ABSTRACT: Instance metaclass role for MooseX::Singleton

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Singleton::Role::Meta::Instance - Instance metaclass role for MooseX::Singleton

=head1 VERSION

version 0.30

=head1 DESCRIPTION

=for Pod::Coverage *EVERYTHING*

This role overrides all object access so that it gets the appropriate
singleton instance for the class.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Singleton>
(or L<bug-MooseX-Singleton@rt.cpan.org|mailto:bug-MooseX-Singleton@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Shawn M Moore <code@sartak.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
