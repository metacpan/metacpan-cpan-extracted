#
# This file is part of MooseX-AutoDestruct
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::AutoDestruct::V1::Trait::Attribute;
{
  $MooseX::AutoDestruct::V1::Trait::Attribute::VERSION = '0.009';
}

# ABSTRACT: Moose 1.x autodestruct traits

use Moose::Role;
use namespace::autoclean;

has ttl => (is => 'ro', isa => 'Int', required => 1, predicate => 'has_ttl');

# generate / store our metaclass
has _accessor_metaclass => (is => 'rw', isa => 'Str', predicate => '_has_accessor_metaclass');

around accessor_metaclass => sub {
    my ($orig, $self) = (shift, shift);

    return $self->_accessor_metaclass if $self->_has_accessor_metaclass;

    # get our base metaclass...
    my $base_class = $self->$orig();

    # ...and apply our trait to it
    ### superclasses: $base_class->meta->name
    my $new_class_meta = Moose::Meta::Class->create_anon_class(
        superclasses => [ $base_class->meta->name ],
        roles => [ 'MooseX::AutoDestruct::V1::Trait::Method::Accessor' ],
        cache => 1,
    );

    ### new accessor class: $new_class_meta->name
    $self->_accessor_metaclass($new_class_meta->name);
    return $new_class_meta->name;
};

has value_slot => (is => 'ro', isa => 'Str', lazy_build => 1, init_arg => undef);
has destruct_at_slot => (is => 'ro', isa => 'Str', lazy_build => 1, init_arg => undef);

sub _build_value_slot       { shift->name }
sub _build_destruct_at_slot { shift->name . '__DESTRUCT_AT__' }

around slots => sub {
    my ($orig, $self) = (shift, shift);

    my $base = $self->$orig();
    return ($self->$orig(), $self->destruct_at_slot);
};

sub set_doomsday {
    my ($self, $instance) = @_;

    # ...

    # set our destruct_at slot
    my $doomsday = $self->ttl + time;

    ### doomsday set to: $doomsday
    ### time() is: time()
    $self
        ->associated_class
        ->get_meta_instance
        ->set_slot_value($instance, $self->destruct_at_slot, $doomsday)
        ;

    return;
}

sub has_doomsday {
    my ($self, $instance) = @_;

    return $self
        ->associated_class
        ->get_meta_instance
        ->is_slot_initialized($instance, $self->destruct_at_slot)
        ;
}

# return true if this value has expired
sub doomsday {
    my ($self, $instance) = @_;

    my $doomsday = $self
        ->associated_class
        ->get_meta_instance
        ->get_slot_value($instance, $self->destruct_at_slot)
        ;
    $doomsday ||= 0;

    ### $doomsday
    ### time > $doomsday: time > $doomsday
    return time > $doomsday;
}

sub avert_doomsday {
    my ($self, $instance) = @_;

    ### in avert_doomsday()...
    $self
        ->associated_class
        ->get_meta_instance
        ->deinitialize_slot($instance, $self->destruct_at_slot)
    ;

    return;
}

after set_initial_value => sub { shift->set_doomsday(shift) };
after set_value         => sub { shift->set_doomsday(shift) };
after clear_value       => sub { shift->avert_doomsday(shift) };

before get_value => sub { shift->enforce_doomsday(@_) };
before has_value => sub { shift->enforce_doomsday(@_) };

sub enforce_doomsday {
    my ($self, $instance, $for_trigger) = @_;

    # if we're not set yet...
    $self->clear_value($instance) if $self->doomsday($instance);
    return;
}

# FIXME do we need this?
after get_value => sub {
    my ($self, $instance, $for_trigger) = @_;

    $self->set_doomsday unless $self->has_doomsday($instance);
};

!!42;



=pod

=head1 NAME

MooseX::AutoDestruct::V1::Trait::Attribute - Moose 1.x autodestruct traits

=head1 VERSION

version 0.009

=head1 DESCRIPTION

Implementation attribute trait of L<MooseX::AutoDestruct> for L<Moose> 1.xx.

=begin Pod::Coverage




=end Pod::Coverage

=head1 SEE ALSO

L<MooseX:AutoDestruct>.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut


__END__

