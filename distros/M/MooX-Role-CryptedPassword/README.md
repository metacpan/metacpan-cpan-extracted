# NAME

MooX::Role::CryptedPassword - Password attribute from a encrypted file.

# SYNOPSIS

Prepare:

    $ create_crypted_password --file-name etc/password.private \
                              --cipher-key 'This-is-the-cipher-key' \
                              --password 'This-is-a-nice-password'

Your class:

```perl
    package MyUserData;
    use Moo;
    with 'MooX::Role::CryptedPassword';

    has username => (is => 'ro', required => 1);

    ...

    1;
```

Somewhere else:

```perl
    my $ud = MyUserData->new(
        username => 'abeltje',

        password_file => 'etc/password.private',
        cipher_key    => 'This-is-the-cipher-key',
    );
```

# ATTRIBUTES

## password => $password

The decrypted version of the password found in the `password_file` parameter.

# DESCRIPTION

This role adds an attribute `password` to your class. If the parameter
`password_file` is passed, the contents are assumed to be encrypted with the
Rijndael cipher (and you should supply the `cipher_key` argument).

Use the supplied `create_crypted_password` tool to generate the file.

In case the password (for development reasons) doesn't need to be encrypted or
comes from a different source (like a key-value-store), one can always pass a
plain-text password directly by passing it as the `password` parameter.

# AUTHOR

© MMXVII - Abe Timmerman <abeltje@cpan.org>

# LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
