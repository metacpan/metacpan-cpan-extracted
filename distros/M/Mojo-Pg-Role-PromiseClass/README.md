# mojo-pg-role-promiseclass

`Mojo::Pg::Role::PromiseClass` is a role that can be
added to [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg)
in order to make `query_p()` and friends return enhanced Promises.

Essentially this is a way to not be having to write `$pg->db->query_p(...)->with_roles('+Stuff')` everywhere.
Instead you just do `$pg->promise_roles('+Stuff')` once and for all when creating the Postgresql wrapper.

[Module documentation](https://metacpan.org/pod/Mojo::Pg::Role::PromiseClass).

[Installation directions](INSTALL.md).

[Getting started with Mojolicious](https://metacpan.org/pod/Mojolicious)

## author

Roger Crew <wrog@cpan.org>

## copyright and license

This software is Copyright (c) 2019 by Roger Crew.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
