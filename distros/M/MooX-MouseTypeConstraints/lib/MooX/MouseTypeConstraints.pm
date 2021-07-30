package MooX::MouseTypeConstraints;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use B::Hooks::EndOfScope;
use Mouse::Util::TypeConstraints ();

sub import {
    my $class = shift;
    my $target = caller;

    on_scope_end {
        my $has = $target->can('has')
            or die q|Moo's internal DSL keyword `has` is not found. (perhaps you forgot to load "Moo"?)|;
        my $code = sub {
            my ($name, %args) = @_;
            if (exists $args{isa} && !ref $args{isa}) {
                my $type = Mouse::Util::TypeConstraints::find_or_create_isa_type_constraint($args{isa});
                $args{isa} = _generate_isa($type);
            }
            @_ = ($name, %args);
            goto $has;
        };

        my $glob = "${target}::has";
        {
            no strict qw/refs/;
            no warnings qw/prototype redefine/;
            *{$glob} = $code;
        };
    };
}

sub _generate_isa {
    my $type = shift;
    if ($type->has_coercion) {
        return sub {
            die $type->get_message(@_) unless $type->check($type->coerce(@_));
        };
    } else {
        return sub {
            die $type->get_message(@_) unless $type->check(@_);
        };
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

MooX::MouseTypeConstraints - Mouse type constraints for Moo

=head1 SYNOPSIS

    use Moo;
    use MooX::MouseTypeConstraints;

    has bar => (
        is  => 'ro',
        isa => 'Int', # make it as Mouse::Meta::TypeContraints validator
    );

=head1 DESCRIPTION

MooX::MouseTypeConstraints provides L<Mouse> type constraints support for L<Moo>.

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

