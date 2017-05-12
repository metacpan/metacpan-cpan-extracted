[![Build Status](https://travis-ci.org/clicktx/p5-Mojolicious-Plugin-Scrypt.svg?branch=master)](https://travis-ci.org/clicktx/p5-Mojolicious-Plugin-Scrypt)
# NAME

Mojolicious::Plugin::Scrypt - Scrypt salted password hashing for Mojolicious

# SYNOPSIS

    # Mojolicious
    $self->plugin('Scrypt');

    # Mojolicious::Lite
    plugin 'Scrypt';

## Plugin Configurations

    $self->plugin( 'Scrypt', {
        salt_length     => int,     # default: 32
        cost            => int,     # default: 16384
        block_size      => int,     # default: 8
        parallelism     => int,     # default: 1
        derived_length  => int,     # default: 32
    });

For more infomation see [Crypt::ScryptKDF](https://metacpan.org/pod/Crypt::ScryptKDF).

# DESCRIPTION

[Mojolicious::Plugin::Scrypt](https://metacpan.org/pod/Mojolicious::Plugin::Scrypt) module use Scrypt algorithm creates a password hash.
Other encryption algorithms include Argon2 or PBKDF2, Bcrypt and more.

# HELPERS

## scrypt

    my $encoded = $app->scrypt($password);

Use random salt, default length 32.

    # or use your salt
    my $salt     = 'saltSalt';
    my $encoded2 = $app->scrypt($password, $salt);

**Do you want to generate salt?**

[Mojolicious::Plugin::Scrypt](https://metacpan.org/pod/Mojolicious::Plugin::Scrypt) using [Crypt::PRNG](https://metacpan.org/pod/Crypt::PRNG).
You can use `Crypt::PRNG::random_bytes()`, `Crypt::PRNG::random_string()`, ...and more.

## scrypt\_verify

    sub login {
        my $c        = shift;
        my $password = $c->param('password');
        my $encoded  = get_hash_from_db();

        if ( $c->scrypt_verify($password, $encoded) ){
            # Correct
            ...
        } else {
            # Incorrect
            ...
        }
    }

# METHODS

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# AUTHOR

Munenori Sugimura <clicktx@gmail.com>

# SEE ALSO

[Crypt::ScryptKDF](https://metacpan.org/pod/Crypt::ScryptKDF), [Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [http://mojolicious.org](http://mojolicious.org).

# LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).
