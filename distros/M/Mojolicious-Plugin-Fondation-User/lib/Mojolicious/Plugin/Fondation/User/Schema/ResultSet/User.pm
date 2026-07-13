package Mojolicious::Plugin::Fondation::User::Schema::ResultSet::User;
# ABSTRACT: DBIx::Class ResultSet class for users table
$Mojolicious::Plugin::Fondation::User::Schema::ResultSet::User::VERSION = '0.01';
use base 'DBIx::Class::ResultSet';

use strict;
use warnings;
use DateTime;

# Example of useful method: active users (if you add an 'active' field)
sub active {
    shift->search({ active => 1 });
}

# Example: users created today
sub created_today {
    my $self = shift;
    my $today = DateTime->today->strftime('%Y-%m-%d');
    return $self->search({
        created_at => { '>=' => $today, '<' => DateTime->today->add( days => 1 )->strftime('%Y-%m-%d') },
    });
}

# Example: search by email or username (case insensitive)
sub search_by_login {
    my ($self, $login) = @_;
    return $self->search([
        { username => { -like => "%$login%" } },
        { email    => { -like => "%$login%" } },
    ]);
}

# Example: latest registered user (sorted by created_at DESC)
sub latest {
    shift->search(undef, { order_by => { -desc => 'created_at' }, rows => 10 });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::User::Schema::ResultSet::User - DBIx::Class ResultSet class for users table

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
