package Nitesi::Account::Provider::Test;

use Moo;
use Nitesi::Core::Types;

with 'Nitesi::Core::Role::Account';

=head1 NAME

Nitesi::Account::Provider::Test - Test account provider for Nitesi Shop Machine

=cut

has users => (
    is => 'rw',
    isa => HashRef,
);

=head1 METHODS

=head2 login

Login method.

=cut

sub login {
    my ($self, %args) = @_;
    my ($users, $username);

    for (qw/username password/) {
        return unless exists $args{$_};
    }

    $users = $self->users;
    $username = $args{username};

    if (exists $users->{$username}
        && $args{password} eq $users->{$username}->{password}) {
        my $last_login = $users->{$username}->{last_login} || 0;

        $users->{$username}->{last_login} = time;

        return {uid => $users->{$username}->{uid},
                username => $args{username},
                permissions => $users->{$args{username}}->{permissions},
                last_login => $last_login,
               };
    }
}




=head1 SEE ALSO

L<MooX::Types::MooseLike> for more available types

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
