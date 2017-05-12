package OpusVL::AppKit::FormFu::Constraint::AppKitPassword;


use strict;
use base 'HTML::FormFu::Constraint';



sub constrain_value
{
    my $self                = shift;
    my ($value, $params)    = @_;
    my $c                   = $self->form->stash->{context};
    return 1 unless $value;
    my $password            = $value;

    my ($pass_min_length, $pass_numerics, $pass_symbols) = (
        $c->config->{AppKit}->{password_min_characters},
        $c->config->{AppKit}->{password_force_numerics},
        $c->config->{AppKit}->{password_force_symbols},
    );

    if ($pass_min_length && length($password) < $pass_min_length) {
        $self->{message} = "Minimum length for password is ${pass_min_length} characters";
        return 0;
    }

    if ($pass_numerics && $password !~ /[0-9]/) {
        $self->{message} = "Expecting a numeric character in password. None found";
        return 0;
    }

    if ($pass_symbols && $password !~ /\W/) {
        $self->{message} = "Expecting a symbol character in password. None found";
        return 0;
    }

    return 1;
}

##
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::FormFu::Constraint::AppKitPassword

=head1 VERSION

version 2.29

=head1 DESCRIPTION

Ensures that passwords are validated against the preferences set in the Catalyst config

=head1 NAME

OpusVL::AppKit::FormFu::Constraint::AppKitPassword - constraint to validate passwords.

=head1 METHODS

=head2 constrain_value

This method is used by formfu to hook into this constraints, constraining code.

Returns:
    boolean     - 0 = did not validate, 1 = validated

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
