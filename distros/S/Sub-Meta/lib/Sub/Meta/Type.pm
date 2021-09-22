package Sub::Meta::Type;
use 5.010;
use strict;
use warnings;

use parent qw(Type::Tiny);

use Type::Coercion;
use Types::Standard qw(Ref InstanceOf);

sub submeta              { my $self = shift; return $self->{submeta} }
sub submeta_strict_check { my $self = shift; return $self->{submeta_strict_check} }
sub find_submeta         { my $self = shift; return $self->{find_submeta} }

## override
sub new {
    my $class  = shift;
    my %params = ( @_ == 1 ) ? %{ $_[0] } : @_;

    ## no critic (Subroutines::ProtectPrivateSubs)
    Type::Tiny::_croak "Need to supply submeta" unless exists $params{submeta};
    Type::Tiny::_croak "Need to supply submeta_strict_check" unless exists $params{submeta_strict_check};
    Type::Tiny::_croak "Need to supply find_submeta" unless exists $params{find_submeta};
    ## use critic

    if (!exists $params{name}) {
        $params{name} = $params{submeta_strict_check} ? 'StrictSubMeta' : 'SubMeta';
    }

    $params{inlined} = $params{submeta_strict_check}
                     ? sub { my ($self, $var) = @_; $self->submeta->is_strict_same_interface_inlined($var) }
                     : sub { my ($self, $var) = @_; $self->submeta->is_relaxed_same_interface_inlined($var) };

    return $class->SUPER::new(%params);
}

## override
sub has_parent          { return !!0 }
sub can_be_inlined      { return !!1 }
sub has_coercion        { return !!1 }
sub _is_null_constraint { return !!0 } ## no critic (ProhibitUnusedPrivateSubroutines)

## override
sub _build_display_name { ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    return sprintf('%s[%s]', $self->name, $self->submeta->display);
}

#
# e.g.
# Reference bless( sub { "DUMMY" }, 'Sub::WrapInType' ) did not pass type constraint "SubMeta"
#   Reason : invalid scalar return. got: Str, expected: Int
#   Expected : sub (Int,Int) => Int
#   Got      : sub (Int,Int) => Str
#
## override
sub get_message {
    my $self = shift;
    my $other_meta = shift;

    my $default_message = $self->SUPER::get_message($other_meta);
    my $detail_message  = $self->get_detail_message($other_meta);

    my $message = <<"```";
$default_message
$detail_message
```

    return $message;
}

sub get_detail_message {
    my $self = shift;
    my $other_meta = shift;

    state $SubMeta = InstanceOf['Sub::Meta'];

    my ($error_message, $expected, $got);
    if ($self->submeta_strict_check) {
        $error_message = $self->submeta->error_message($other_meta);
        $expected      = $self->submeta->display;
        $got           = $SubMeta->check($other_meta) ? $other_meta->display : "";
    }
    else {
        $error_message = $self->submeta->relaxed_error_message($other_meta);
        $expected      = $self->submeta->display;
        $got           = $SubMeta->check($other_meta) ? $other_meta->display : "";
    }

    my $message = <<"```";
    Reason : $error_message
    Expected : $expected
    Got      : $got
```

    return $message;
}

## override
sub _build_coercion { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    return Type::Coercion->new(
        display_name      => "to_${self}",
        type_constraint   => $self,
        type_coercion_map => [
            Ref['CODE'] => sub {
                my $sub = shift;
                return $self->find_submeta->($sub);
            },
        ],
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::Type - type constraints for Sub::Meta

=head1 SYNOPSIS

    my $submeta = Sub::Meta->new(
        subname => 'hello',
    );

    my $type = Sub::Meta::Type->new(
        submeta              => $submeta,
        submeta_strict_check => !!0,
        find_submeta         => \&Sub::Meta::CreatorFunction::find_submeta,
    );

    sub hello {}
    my $meta = $type->coerce(\&hello);
    $type->check($meta)

=head1 DESCRIPTION

This module provides types for Sub::Meta.

=head1 ATTRIBUTES

=head2 submeta

    method submeta() => InstanceOf[Sub::Meta]

Accessor for Sub::Meta.

=head2 submeta_strict_check

    method submeta_strict_check() => Bool

Whether Sub::Meta::Type check by C<is_strict_same_interface> or not.
If false, then check by C<is_relaxed_same_interface>.

=head2 find_submeta

     method find_submeta() => CodeRef[ Ref['CODE'] => Maybe[InstanceOf[Sub::Meta]] ]

Code reference for finding Sub::Meta from a subroutine like C<Sub::Meta::CreatorFunction::find_submeta>

=head1 METHODS

=head2 get_detail_message

    method get_detail_message(InstanceOf['Sub::Meta'] $submeta) => Str

Returns the detailed reason for the error message for a value; even if the value passes the type constraint.
This method is used inside C<Type#get_message> and C<TypeSub#get_message>.

=head1 SEE ALSO

L<Types::Sub>, L<Sub::Meta::TypeSub>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
