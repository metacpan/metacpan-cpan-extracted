# NAME

**Plack::Middleware::Auth::BrowserID** - Plack Middleware to integrate with Mozilla Persona, cross-browser login system for the Web.

# DESCRIPTION

Mozilla Persona is a secure solutions, to identify (login) users based on email address.

> "Simple, privacy-sensitive single sign-in: let your users sign into your website with their email address, and free yourself from password management."

An alternative for those who do not want store the user passwords.

> "Combined with our Identity Bridge for Yahoo, Persona now natively supports more than 700,000,000 active email users. That covers roughly 60-80% of people on most North American websites."
_-- [Persona makes signing in easy for Gmail users](http://identity.mozilla.com/post/57712756801/persona-makes-signing-in-easy-for-gmail-users)_


Is a functional example with three concept apps to test.

```shell
plackup -s Starman -r -p 8082 -E development -I lib example/app.psgi
```

All of then use the **Plack::Session** and are one [Dancer2](https://github.com/PerlDancer/Dancer2), one [Mojolicous](https://github.com/kraih/mojo) and one [Plack](https://github.com/plack/Plack), all of them sharing the same *app.psgi* and *session*.



# SEE ALSO

* [Identity "Sign in with your email" (on my blog)](http://bolila.com/2013/11/14/browserid/)
* [MDN Persona](https://developer.mozilla.org/en-US/Persona)
* [Identity at Mozilla](http://identity.mozilla.com/)

# LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
