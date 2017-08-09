# NAME

Plack::Middleware::Auth::Negotiate - Negotiate authentication middleware (SPNEGO)

# VERSION

version 0.172130

# SYNOPSIS

```perl
use Plack::Builder;
my $app = sub { ... };

builder {
    enable 'Auth::Negotiate', keytab => 'FILE:www.keytab';
    $app;
};
```

# DESCRIPTION

Plack::Middleware::Auth::Negotiate provides Negotiate (SPNEGO) authentication
for your Plack application (for use with Kerberos).

This is a very alpha module, and I am still testing some of the security corner
cases. Help wanted.

# CONFIGURATION

- keytab: path to the keytab to use. This value is set as
`$ENV{KRB5_KTNAME}` if provided.

Note that there is no option for matching URLs. You can do this yourself with
[Plack::Middleware::Conditional](https://metacpan.org/pod/Plack::Middleware::Conditional)'s `enable_if` syntax (for [Plack::Builder](https://metacpan.org/pod/Plack::Builder)).

# TODO

- More security testing.
- Ability to specify a list of valid realms. If REALM.EXAMPLE.COM trusts
REALM.FOOBAR.COM, and we don't want to allow REALM.FOOBAR.COM users, we have to
check after accepting the ticket.
- Option to automatically trim the @REALM.EXAMPLE.COM portion of the user
value.
- Method to also provide Basic auth if Negotiate fails.
- Some way to cooperate with other Auth middleware. `enable_if` is your
best bet right now (with different URLs for each type of authentication, and
writing a session).
- Better interaction with [Plack::Middleware::Session](https://metacpan.org/pod/Plack::Middleware::Session), since this
authentication is slow in my experience.
- Better implementation of the actual RFC.
- Custom "Authorization Required" message

# SEE ALSO

[Plack](https://metacpan.org/pod/Plack), [Plack::Builder](https://metacpan.org/pod/Plack::Builder), [Plack::Middleware::Auth::Basic](https://metacpan.org/pod/Plack::Middleware::Auth::Basic)

[GSSAPI](https://metacpan.org/pod/GSSAPI), mod\_auth\_kerb

# ACKNOWLEDGEMENTS

This code is based off of [Plack::Middleware::Auth::Basic](https://metacpan.org/pod/Plack::Middleware::Auth::Basic) and a sample script
provided with [GSSAPI](https://metacpan.org/pod/GSSAPI).

# AUTHOR

Adrian Kreher <avuserow@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Adrian Kreher <avuserow@cpan.org>.

This is free software, licensed under:

```perl
The (three-clause) BSD License
```
