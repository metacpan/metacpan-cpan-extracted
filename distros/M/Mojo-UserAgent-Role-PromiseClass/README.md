# mojo-useragent-role-promiseclass

`Mojo::UserAgent::Role::PromiseClass` is a role that can be
added to [Mojo::UserAgent](https://metacpan.org/pod/Mojo/UserAgent)
in order to make `get_p()` and friends return enhanced Promises.

Essentially this is a way to not be having to write `$ua->get_p->with_roles('+Stuff')` everywhere.
Instead you just do `$ua->promise_roles('+Stuff')` once and for all when creaing the user agent.

[Module documentation](lib/Mojo/UserAgent/Role/PromiseClass.pm).

[Installation directions](INSTALL.md).

[Getting started with Mojolicious](https://metacpan.org/pod/Mojolicious)

## author

Roger Crew <wrog@cpan.org>

## copyright and license

This software is copyright (c) 2018 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
