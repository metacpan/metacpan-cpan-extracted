#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::LazyInflator::Meta::Role::Attribute;
{
  $MooseX::Attribute::LazyInflator::Meta::Role::Attribute::VERSION = '2.2.2';
}

# ABSTRACT: Lazy inflate attributes
use strict;
use warnings;
use Moose::Role;
use Eval::Closure;

with 'MooseX::Attribute::Deflator::Meta::Role::Attribute';

override verify_against_type_constraint => sub {
    my ( $self, $value, undef, $instance ) = @_;
    return $value if ( !$self->is_inflated( $instance, undef, $value ) );
    return super();
};

before get_value => sub {
    my ( $self, $instance ) = @_;
    return
        if ( !$self->has_value($instance) || $self->is_inflated($instance) );
    my $value = $self->inflate( $instance, $self->get_raw_value($instance) );
    $value = $self->type_constraint->coerce($value)
        if ( $self->should_coerce && $self->type_constraint->has_coercion );
    $self->verify_against_type_constraint( $value, instance => $instance );
    $self->set_raw_value( $instance, $value );
};

# this is just for reference, this method is replaced with an inlined version
sub is_inflated {
    my ( $self, $instance, $value, $from_constructor ) = @_;
    return $instance->_inflated_attributes->{ $self->name } = $value
        if ( defined $value );
    if ( $instance->_inflated_attributes->{ $self->name } ) {
        return 1;
    }
    else {
        my $value
            = defined $from_constructor
            ? $from_constructor
            : $self->get_raw_value($instance);
        return 1 if(!defined $value && $self->is_required);
        $value = $self->type_constraint->coerce($value)
            if ( $self->should_coerce
            && $self->type_constraint->has_coercion );
        return
               $self->has_type_constraint
            && $self->type_constraint->check($value)
            && ++$instance->_inflated_attributes->{ $self->name };
    }
}

after install_accessors => sub {
    my $self = shift;
    my @code
        = $self->_inline_instance_is_inflated( '$_[1]', '$type_constraint',
        '$type_coercion', '$value', );
    my $role = Moose::Meta::Role->create_anon_role;
    $role->add_method(
        'is_inflated' => eval_closure(
            environment => $self->_eval_environment,
            source      => join( "\n",
                'sub {',
                'return $_[1]->{_inflated_attributes}->{"'
                    . quotemeta( $self->name )
                    . '"} = $_[2] if(defined $_[2]);',
                'my $value = defined $_[3] ? $_[3] : '
                    . $self->_inline_instance_get('$_[1]') . ';',
                @code,
                '}' ),
        )
    );
    Moose::Util::apply_all_roles($self, $role);
} if ( $Moose::VERSION >= 1.9 );

if ( Moose->VERSION < 1.9900 ) {
    require MooseX::Attribute::LazyInflator::Meta::Role::Method::Accessor;
    override accessor_metaclass => sub {
        'MooseX::Attribute::LazyInflator::Meta::Role::Method::Accessor';
    };
}

sub _inline_instance_is_inflated {
    my ( $self, $instance, $tc, $tc_obj, $value ) = @_;
    my @code
        = (   $instance
            . '->{_inflated_attributes}->{"'
            . quotemeta( $self->name )
            . '"}' );
    return 1 if ( !$self->has_type_constraint );    # TODO return 1 ?
    $value ||= $self->_inline_instance_get($instance);
    my $coerce
        = $self->should_coerce && $self->type_constraint->has_coercion
        ? $tc_obj . '->coerce(' . $value . ')'
        : $value;
    push @code,
        (     ' || (' 
            . $tc . '->(' 
            . $coerce
            . ') && ++'
            . $instance
            . '->{_inflated_attributes}->{"'
            . quotemeta( $self->name )
            . '"})' );
    return @code;
}

if ( Moose->VERSION >= 2.0100 ) {
    override _inline_get_value => sub {
        my ( $self, $instance, $tc, $coercion, $message ) = @_;
        $tc       ||= '$type_constraint';
        $coercion ||= '$type_coercion';
        $message  ||= '$type_message';
        my $slot_exists = $self->_inline_instance_has($instance);
        my @code        = (
            "if($slot_exists && !(",
            $self->_inline_instance_is_inflated( $instance, $tc, $coercion ),
            ")) {",
            'my $inflated = '
                . "\$attr->inflate($instance, "
                . $self->_inline_instance_get($instance) . ");",
            $self->has_type_constraint
            ? ( $self->_inline_check_coercion(
                    '$inflated', $tc, $coercion, 1
                ),
                $self->_inline_check_constraint(
                    '$inflated', $tc, $message, 1
                )
                )
            : (),
            $self->_inline_init_slot( $instance, '$inflated' ),
            "}"
        );
        push @code, super();
        return @code;
    };

    __PACKAGE__->meta->add_method(
        _inline_instance_is_inflated => sub {
            my ( $self, $instance, $tc, $coercion, $value ) = @_;
            my @code
                = (   $instance
                    . '->{_inflated_attributes}->{"'
                    . quotemeta( $self->name )
                    . '"}' );
            return @code if ( !$self->has_type_constraint );
            $value ||= $self->_inline_instance_get($instance);
            my $coerce
                = $self->should_coerce && $self->type_constraint->has_coercion
                ? $coercion . '->(' . $value . ')'
                : $value;
            my $check
                = $self->type_constraint->can_be_inlined
                ? $self->type_constraint->_inline_check($coerce)
                : $tc . '->(' . $coerce . ')';
            push @code,
                (     ' || (' 
                    . $check 
                    . ' && ++'
                    . $instance
                    . '->{_inflated_attributes}->{"'
                    . quotemeta( $self->name )
                    . '"})' );
            return @code;
        }
    );

    override _inline_tc_code => sub {
        my $self = shift;
        my ( $value, $tc, $coercion, $message, $is_lazy ) = @_;
        return (
            $self->_inline_check_coercion(
                $value, $tc, $coercion, $is_lazy,
            ),

            # $self->_inline_check_constraint(
            #     $value, $tc, $message, $is_lazy,
            # ),
        );
    };

    override _eval_environment => sub {
        my $self = shift;
        return { %{ super() }, '$attr' => \$self, };
    };
}
else {
    override _inline_get_value => sub {
        my ( $self, $instance, $tc, $tc_obj ) = @_;
        $tc     ||= '$type_constraint';
        $tc_obj ||= '$type_constraint_obj';
        my $slot_exists = $self->_inline_instance_has($instance);
        my @code        = (
            "if($slot_exists && !(",
            $self->_inline_instance_is_inflated( $instance, $tc, $tc_obj ),
            ")) {",
            'my $inflated = '
                . "\$attr->inflate($instance, "
                . $self->_inline_instance_get($instance) . ");",
            $self->has_type_constraint
            ? ( $self->_inline_check_coercion( '$inflated', $tc, $tc_obj, 1 ),
                $self->_inline_check_constraint(
                    '$inflated', $tc, $tc_obj, 1
                )
                )
            : (),
            $self->_inline_init_slot( $instance, '$inflated' ),
            "}"
        );
        push @code, super();
        return @code;
        }
        if Moose->VERSION >= 1.9900;

    __PACKAGE__->meta->add_method(
        _inline_instance_is_inflated => sub {
            my ( $self, $instance, $tc, $tc_obj ) = @_;
            my @code
                = (   $instance
                    . '->{_inflated_attributes}->{"'
                    . quotemeta( $self->name )
                    . '"}' );
            return @code if ( !$self->has_type_constraint );
            my $value = $self->_inline_instance_get($instance);
            my $coerce
                = $self->should_coerce && $self->type_constraint->has_coercion
                ? $tc_obj . '->coerce(' . $value . ')'
                : $value;
            push @code,
                (     ' || (' 
                    . $tc . '->(' 
                    . $coerce
                    . ') && ++'
                    . $instance
                    . '->{_inflated_attributes}->{"'
                    . quotemeta( $self->name )
                    . '"})' );
            return @code;
        }
    );

    override _inline_tc_code => sub {
        my $self = shift;
        return (
            $self->_inline_check_coercion(@_),

            # $self->_inline_check_constraint(@_),
        );
        }
        if Moose->VERSION >= 1.9900;
}

1;



=pod

=head1 NAME

MooseX::Attribute::LazyInflator::Meta::Role::Attribute - Lazy inflate attributes

=head1 VERSION

version 2.2.2

=head1 SYNOPSIS

  package Test;

  use Moose;
  use MooseX::Attribute::LazyInflator;
  # Load default deflators and inflators
  use MooseX::Attribute::Deflator::Moose;

  has hash => ( is => 'rw', 
               isa => 'HashRef',
               traits => ['LazyInflator'] );

  package main;
  
  my $obj = Test->new( hash => '{"foo":"bar"}' );
  # Attribute 'hash' is being inflated to a HashRef on access
  $obj->hash;

=head1 ROLES

This role consumes L<MooseX::Attribute::Deflator::Meta::Role::Attribute>.

=head1 METHODS

=over 8

=item B<is_inflated( $intance )>

Returns a true value if the value of the attribute passes the type contraint
or has been inflated.

=item before B<get_value>

The attribute's value is being inflated and set if it has a value and hasn't been inflated yet.

=item override B<verify_against_type_constraint>

Will return true if the attribute hasn't been inflated yet.

=back

=head1 FUNCTIONS

=over 8

=item B<accessor_metaclass>

The accessor metaclass is set to L<MooseX::Attribute::LazyInflator::Meta::Role::Method::Accessor>.

=back

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

