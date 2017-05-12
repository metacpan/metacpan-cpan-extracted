#
# This file is part of MooseX-AutoDestruct
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::AutoDestruct::V2::Trait::Attribute;
{
  $MooseX::AutoDestruct::V2::Trait::Attribute::VERSION = '0.009';
}

# ABSTRACT: Clear your attributes after a certain time

use Moose::Role;
use namespace::autoclean;

# debugging
#use Smart::Comments '###', '####';

has ttl => (is => 'ro', isa => 'Int', required => 1, predicate => 'has_ttl');

has value_slot => (is => 'ro', isa => 'Str', lazy_build => 1, init_arg => undef);
has destruct_at_slot => (is => 'ro', isa => 'Str', lazy_build => 1, init_arg => undef);

sub _build_value_slot       { shift->name }
sub _build_destruct_at_slot { shift->name . '__DESTRUCT_AT__' }

around slots => sub {
    my ($orig, $self) = (shift, shift);

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

around _inline_clear_value => sub {
    my ($orig, $self) = (shift, shift);
    my ($instance) = @_;

    my $mi = $self->associated_class->get_meta_instance;

    return $self->$orig(@_)
        . $mi->inline_deinitialize_slot($instance, $self->destruct_at_slot)
        . ';'
        ;
};

sub _inline_destruct {
    my $self = shift;
    my ($instance) = @_;

    my $slot_exists = $self->_inline_instance_has(@_);
    my $destruct_at_slot_value = $self
        ->associated_class
        ->get_meta_instance
        ->inline_get_slot_value($instance, $self->destruct_at_slot)
        ;

    my $clear_attribute;
    if ($self->has_clearer) {

        # if we have a clearer method, we should call that -- it may have
        # been wrapped in the class

        my $clearer = $self->clearer;
        ($clearer) = keys %$clearer if ref $clearer;

        $clear_attribute = "${instance}->" . $clearer . '()';
    }
    else {
        # otherwise, just deinit all the slots we use
        $clear_attribute = $self->_inline_clear_value(@_);
    }

    return " if ($slot_exists && time() > $destruct_at_slot_value) { $clear_attribute } ";
}

my $destruct_wrapper = sub {
    my $self = shift;
    return ($self->_inline_destruct(@_), super);
};

override _inline_has_value => $destruct_wrapper;
override _inline_get_value => $destruct_wrapper;

sub _inline_set_doomsday {
    my ($self, $instance) = @_;
    my $mi = $self->associated_class->get_meta_instance;

    my $code = $mi->inline_set_slot_value(
        $instance,
        $self->destruct_at_slot,
        'time() + ' . $self->ttl,
    );

    return "$code;\n";
}

override _inline_instance_set => sub {
    my $self = shift;
    return 'do { ' . $self->_inline_set_doomsday(@_) . ';' . super . ' }';
};

!!42;



=pod

=head1 NAME

MooseX::AutoDestruct::V2::Trait::Attribute - Clear your attributes after a certain time

=head1 VERSION

version 0.009

=head1 DESCRIPTION

Attribute trait of L<MooseX::AutoDestruct> for L<Moose> version
2.xx.

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

