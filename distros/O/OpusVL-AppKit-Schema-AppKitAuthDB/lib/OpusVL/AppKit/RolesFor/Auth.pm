package OpusVL::AppKit::RolesFor::Auth;

use Moose::Role;

requires 'check_password';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::RolesFor::Auth

=head1 VERSION

version 6

=head1 SYNOPSIS

    package FailLogin;
    use Moose;
    with 'OpusVL::AppKit::RolesFor::Auth';

    sub check_password 
    {
        my ($self, $user, $password) = @_;
        return 0;
    }

=head1 DESCRIPTION

This role is used to supply a method for authenticating a users password.

=head1 NAME

OpusVL::AppKit::RolesFor::Auth

=head1 METHODS

=head2 check_password

The role expects the classes that support it to implement the check_password method
which should take a username and password and return 0 or 1 depending on whether the
password is correct.

    $obj->check_password('user', 'password'); # return 0 or 1

=head1 SEE ALSO

See L<OpusVL::AppKit::LDAPAuth> for an example of this role in use.

=head1 AUTHOR

Colin Newell <colin@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
