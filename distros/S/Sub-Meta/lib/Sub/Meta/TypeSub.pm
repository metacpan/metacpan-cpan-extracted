package Sub::Meta::TypeSub;
use 5.010;
use strict;
use warnings;
use parent qw(Type::Tiny);

use Types::Standard qw(InstanceOf);

sub submeta_type { my $self = shift; return $self->{submeta_type} }

## override
sub new {
    my $class  = shift;
    my %params = ( @_ == 1 ) ? %{ $_[0] } : @_;

    ## no critic (Subroutines::ProtectPrivateSubs)
    Type::Tiny::_croak "Need to supply submeta_type" unless exists $params{submeta_type};

    if (!exists $params{name}) {
        $params{name} = $params{submeta_type}->submeta_strict_check ? 'StrictSub' : 'Sub';
    }

    return $class->SUPER::new(%params);
}

## override
sub can_be_inlined { return !!0 }

## override
sub _build_display_name { ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    return sprintf('%s[%s]', $self->name, $self->submeta_type->submeta->display);
}

## override
sub _build_constraint { ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    return sub {
        my $sub = shift;
        my $other_meta = $self->submeta_type->coerce($sub);
        $self->submeta_type->check($other_meta)
    }
}

## override
sub get_message {
    my $self = shift;
    my $sub = shift;

    my $default = $self->SUPER::get_message($sub);
    my $meta    = $self->submeta_type->coerce($sub);

    state $SubMeta = InstanceOf['Sub::Meta'];

    my $message = "$default\n";
    if ($SubMeta->check($meta)) {
        $message .= $self->submeta_type->get_detail_message($meta);
    }
    else {
        my $s = Type::Tiny::_dd($sub); ## no critic (Subroutines::ProtectPrivateSubs)
        $message .= "    Cannot find submeta of `$s`";
    }
    return $message;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::TypeSub - type constraints for subroutines

=head1 SYNOPSIS

    my $type = Sub::Meta::TypeSub->new(
        parent       => Ref['CODE'],
        submeta_type => $SubMeta, # InstanceOf[Sub::Meta::Type]
    );

    $type->check(sub {})

=head1 DESCRIPTION

This module provides types for subroutines.

=head1 ATTRIBUTES

=head2 submeta_type

    method submeta_type() => InstanceOf[Sub::Meta::Type]

Accessor for Sub::Meta::Type.

=head1 SEE ALSO

L<Types::Sub>, L<Sub::Meta::Type>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
