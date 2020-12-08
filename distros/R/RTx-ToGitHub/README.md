# NAME

RTx::ToGitHub - Convert rt.cpan.org tickets to GitHub issues

# VERSION

version 0.09

# SYNOPSIS

    $> rt-to-github.pl

# DESCRIPTION

This is a tool to convert RT tickets to GitHub issues. When you run it, it
will:

- 1. Prompt you for any info it needs

    Run with `--no-prompt` to disable prompts, in which case it will either use
    the command line options you provide or look in various config files and `git
    config` for needed info.

- 2. Make GitHub issues for each RT ticket

    The body of the ticket will be the new issue body, with replies converted to
    comments. Requestors and others participating in the discussion will be
    converted to `@username` mentions on GitHub. The conversion is based on a
    one-time data dump made by pulling author data from MetaCPAN to make an email
    address to GitHub username map. Patches to this map are welcome.

    Only tickets with the "new", "open", "patched", or "stalled" status are
    converted. Stalled tickets are given a "stalled" label on GitHub.

- 3. Close the RT ticket

    Unless you pass the `--no-resolve` option.

# COMMAND LINE OPTIONS

This command accepts the following flags:

## --dry

Run in dry-run mode. No issues will be created and no RT tickets will be
resolved. This will just print some output to indicate what \_would\_ have
happened.

## --no-prompt

By default you will be prompted to enter various bits of info, even if you
give everything needed on the CLI. If you pass this flag, then only CLI
options and inferred config values will be used.

## --github-user

The github user to use. This defaults to looking for a "github.user" config
item in your git config.

## --github-token

The github token to use. This defaults to looking for a "github.token" config
item in your git config.

## --repo

The repo name to use. By default this is determined by looking at the URL for
the remote named "origin". This should just be the repo name by itself,
without a username. So pass "Net-Foo", not "username/Net-Foo".

## --pause-id

Your PAUSE ID. If you have a `~/.pause` file this will be parsed for your
username.

## --pause-password

Your PAUSE password. If you have a `~/.pause` file this will be parsed for
your password.

## --dist

The distribution name which is used for your RT queue name. By default, this
is taken by looking for `[MY]META.*` files or looking in a `dist.ini` in the
current directory. This falls back to the repo name.

## --no-resolve

If you pass this flag then the RT tickets are not marked as closed as they are
converted.

## --ticket

You can specify a single RT ticket to convert by giving a ticket ID number.

## --force

By default, if a matching issue already exists on GitHub, the ticket will not
be converted. Pass this flag to force a new issue to be created anyway.

# CREDITS

Much of the code in this module was taken from David Golden's conversion
script at [https://github.com/dagolden/zzz-rt-to-github](https://github.com/dagolden/zzz-rt-to-github).

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/RTx-ToGitHub/issues](https://github.com/houseabsolute/RTx-ToGitHub/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for RTx-ToGitHub can be found at [https://github.com/houseabsolute/RTx-ToGitHub](https://github.com/houseabsolute/RTx-ToGitHub).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [https://www.urth.org/fs-donation.html](https://www.urth.org/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Dan Stewart <danielandrewstewart@gmail.com>
- Michiel Beijen <michiel.beijen@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by David Golden and Dave Rolsky.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004

The full text of the license can be found in the
`LICENSE` file included with this distribution.
