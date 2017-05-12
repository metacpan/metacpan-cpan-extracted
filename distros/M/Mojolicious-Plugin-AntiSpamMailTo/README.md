# NAME

Mojolicious::Plugin::AntiSpamMailTo - Mojolicious plugin for obfuscating email addresses

# SYNOPSIS

    #!/usr/bin/env perl

    use Mojolicious::Lite;

    plugin 'AntiSpamMailTo';
    app->mailto('zoffix@cpan.com'); # save the address

    get '/' => 'index';

    app->start;

    __DATA__

    @@ index.html.ep

    <p><a
        href="<%== mailto_href %>">
            Send me an email at <%== mailto %>
    </a></p>

Every call to `mailto_href()` or `mailto()` updates the globally
stored email address. But you can use a different address each time:

    #!/usr/bin/env perl

    use Mojolicious::Lite;

    plugin 'AntiSpamMailTo';

    get '/' => 'index';

    app->start;

    __DATA__

    @@ index.html.ep

    <p><a
        href="<%== mailto_href 'foo@example.com' %>">
            Send me an email at <%== mailto 'bar@example.com' %>
    </a></p>

The output in the browser would be this, with each character in the
email address HTML encoded:

    <p><a
        href="&#109;&#97;&#105;&#108;&#116;&#111;&#58;&#122;&#111;&#102;&#102;&#105;&#120;&#64;&#99;&#112;&#97;&#110;&#46;&#99;&#111;&#109;">
            Send me an email at &#122;&#111;&#102;&#102;&#105;&#120;&#64;&#99;&#112;&#97;&#110;&#46;&#99;&#111;&#109;
    </a></p>

# DESCRIPTION

[Mojolicious::Plugin::AntiSpamMailTo](https://metacpan.org/pod/Mojolicious::Plugin::AntiSpamMailTo) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin for
outputting email addresses as encoded HTML entities, which
(kinda seems to) confuses a bunch of noobish spam bots, lowering the
amount of crap you get sent to the address.

# METHODS

[Mojolicious::Plugin::AntiSpamMailTo](https://metacpan.org/pod/Mojolicious::Plugin::AntiSpamMailTo) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# HELPERS

## `mailto`

    Send me an email at <%== mailto 'zoffix@cpan.com' %>

Takes one optional argument, an email address, and returns an encoded
version of it. The email address gets stored, so any future
calls without any arguments will use the address from the
previous call to `mailto` or `mailto_href`.

## `mailto_href`

    <a href="<%== mailto_href 'zoffix@cpan.com' %>">Send me an email</a>

This is what's you use in `href=""` attributes. Takes one
optional argument, an email address, prepends string `mailto:` to it,
and returns an encoded version of it.
The email address gets stored so any future
calls without any arguments will use the address from the
previous call to `mailto` or `mailto_href`.

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/Mojolicious-Plugin-AntiSpamMailTo](https://github.com/zoffixznet/Mojolicious-Plugin-AntiSpamMailTo)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/Mojolicious-Plugin-AntiSpamMailTo/issues](https://github.com/zoffixznet/Mojolicious-Plugin-AntiSpamMailTo/issues)

If you can't access GitHub, you can email your request
to `bug-mojolicious-plugin-antispammailto at rt.cpan.org`

# AUTHOR

Zoffix Znet `zoffix at cpan.org`, ([http://zoffix.com/](http://zoffix.com/))

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
