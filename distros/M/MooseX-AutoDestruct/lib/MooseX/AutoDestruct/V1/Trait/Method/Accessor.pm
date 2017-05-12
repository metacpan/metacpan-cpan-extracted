#
# This file is part of MooseX-AutoDestruct
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::AutoDestruct::V1::Trait::Method::Accessor;
{
  $MooseX::AutoDestruct::V1::Trait::Method::Accessor::VERSION = '0.009';
}

# ABSTRACT: Accessor trait for Moose v1

use Moose::Role;
use namespace::autoclean;

# debug!
#before _eval_closure => sub { print "$_[2]\n" };

override _inline_pre_body => sub {
    my ($self, $instance) = @_;
    my $attr          = $self->associated_attribute;
    my $attr_name     = $attr->name;
    my $mi            = $attr->associated_class->instance_metaclass;

    my $code = super();
    my $type = $self->accessor_type;

    return $code
        unless $type eq 'accessor' || $type eq 'reader' || $type eq 'predicate';

    my $slot_exists = $self->_inline_has('$_[0]');

    $code .= "\n    if ($slot_exists && time() > "
        . $mi->inline_get_slot_value('$_[0]', $attr->destruct_at_slot)
        . ") {\n"
        ;

    if ($attr->has_clearer) {

        # if we have a clearer method, we should call that -- it may have
        # been wrapped in the class

        my $clearer = $attr->clearer;
        ($clearer) = keys %$clearer if ref $clearer;

        $code .= '$_[0]->' . $clearer . '()';

    }
    else {

        # otherwise, just deinit all the slots we use
        $code .= '    ' .$mi->inline_deinitialize_slot('$_[0]', $_) . ";\n"
            for $attr->slots;
    }

    $code .= "}\n";

    return $code;
};

override _generate_predicate_method_inline => sub {
    my $self          = shift;
    my $attr          = $self->associated_attribute;
    my $attr_name     = $attr->name;
    my $meta_instance = $attr->associated_class->instance_metaclass;

    my ( $code, $e ) = $self->_eval_closure(
        {},
        'sub {'
        . $self->_inline_pre_body(@_)
        . $meta_instance->inline_is_slot_initialized('$_[0]', $attr->value_slot)
        . $self->_inline_post_body(@_)
        . '}'
    );
    confess "Could not generate inline predicate because : $e" if $e;

    return $code;
};

override _generate_clearer_method_inline => sub {
    my $self      = shift;
    my $attr      = $self->associated_attribute;
    my $attr_name = $attr->name;
    my $mi        = $attr->associated_class->instance_metaclass;

    my $deinit;
    $deinit .= $mi->inline_deinitialize_slot('$_[0]', $_) . ';'
        for $attr->slots;

    my ( $code, $e ) = $self->_eval_closure(
        {},
        'sub {'
        . $self->_inline_pre_body(@_)
        . $deinit
        . $self->_inline_post_body(@_)
        . '}'
    );
    confess "Could not generate inline clearer because : $e" if $e;

    return $code;
};

# we need to override/wrap _inline_store() so we can deal with there being
# two valid slots here that mean two different things: the value and when
# it autodestructs.

override _inline_store => sub {
    my ($self, $instance, $value) = @_;
    my $attr = $self->associated_attribute;
    my $mi   = $attr->associated_class->get_meta_instance;

    my $code = $mi->inline_set_slot_value($instance, $attr->value_slot, $value);
    $code   .= ";\n    ";
    $code   .= $self->_inline_set_doomsday($instance);
    $code   .= $mi->inline_weaken_slot_value($instance, $attr->value_slot, $value)
        if $attr->is_weak_ref;

    return $code;
};

sub _inline_set_doomsday {
    my ($self, $instance) = @_;
    my $attr = $self->associated_attribute;
    my $mi   = $attr->associated_class->get_meta_instance;

    my $code = $mi->inline_set_slot_value(
        $instance,
        $attr->destruct_at_slot,
        'time() + ' . $attr->ttl,
    );

    return "$code;\n";
}

!!42;



=pod

=head1 NAME

MooseX::AutoDestruct::V1::Trait::Method::Accessor - Accessor trait for Moose v1

=head1 VERSION

version 0.009

=head1 DESCRIPTION

Implementation attribute trait of L<MooseX::AutoDestruct> for L<Moose> version
1.xx.

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

