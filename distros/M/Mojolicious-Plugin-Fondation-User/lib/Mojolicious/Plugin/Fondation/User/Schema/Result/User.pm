package Mojolicious::Plugin::Fondation::User::Schema::Result::User;
$Mojolicious::Plugin::Fondation::User::Schema::Result::User::VERSION = '0.01';
# ABSTRACT: DBIx::Class Result class for users table

use strict;
use warnings;

use base 'DBIx::Class::Core';
use Crypt::Passphrase;

__PACKAGE__->load_components(qw/TimeStamp Core/);

# ── Internal ──────────────────────────────────────────────────────────

# Lazy-initialized passphrase instance (per-process singleton).
my $_PASSPHRASE;

sub _passphrase {
    return $_PASSPHRASE //= Crypt::Passphrase->new(
        encoder => {
            module  => 'Argon2',
            time    => 3,
            memory  => 64 * 1024,
            threads => 4,
        },
    );
}

sub _hash_password {
    my ($password) = @_;
    return _passphrase()->hash_password($password);
}

__PACKAGE__->table('users');

__PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },

    username => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
        extra       => {
            openapi => {
                minLength   => 4,
                pattern     => '^[a-zA-Z0-9_-]{4,}$',
            }
        },
    },

    email => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
        extra       => { openapi => { format => 'email' } },
    },

    password => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
        extra       => {
            openapi => {
                writeOnly => 1,
                format    => 'password',
                minLength => 8,
                create    => { required => 1 },
                update    => { required => 0 },
            },
        },
    },

    created_at => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 1 },

    updated_at => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 1 },

    active => {
        data_type     => 'integer',
        default_value => 1,
        is_nullable   => 0,
        extra         => {
            openapi => {
                enum   => [0, 1],
                create => { required => 0 },
                update => { required => 0 },
            },
        },
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint([qw(username email)]);
__PACKAGE__->resultset_class('Mojolicious::Plugin::Fondation::User::Schema::ResultSet::User');

# Hash password automatically on create
sub insert {
    my $self = shift;
    if (defined $self->password) {
        $self->password(_hash_password($self->password));
    }
    $self->next::method(@_);
}

# Hash password automatically on update (when password column is changed)
sub update {
    my $self = shift;
    my $upd = {@_};
    if (exists $upd->{password} && defined $upd->{password}) {
        $upd->{password} = _hash_password($upd->{password});
    }
    $self->next::method($upd);
}


# ── Verify a plaintext password against the stored hash ───────────────

sub check_password {
    my ($self, $password) = @_;

    my $hash = $self->password;
    return undef unless $hash;

    my $pp = Crypt::Passphrase->new(
        encoder => {
            module  => 'Argon2',
            time    => 3,
            memory  => 64 * 1024,
            threads => 4,
        },
    );

    return $pp->verify_password($password, $hash);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::User::Schema::Result::User - DBIx::Class Result class for users table

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
