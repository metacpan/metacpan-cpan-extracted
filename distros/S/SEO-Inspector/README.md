# NAME

SEO::Inspector - Run SEO checks on HTML or URLs

# VERSION

Version 0.02

# SYNOPSIS

    use SEO::Inspector;

    my $inspector = SEO::Inspector->new(url => 'https://example.com');

    # Run plugins
    my $html = '<html><body>......</body></html>';
    my $plugin_results = $inspector->check_html($html);

    # Run built-in checks
    my $builtin_results = $inspector->run_all($html);

    # Check a single URL and get all results
    my $all_results = $inspector->check_url('https://example.com');

# DESCRIPTION

SEO::Inspector provides:

- 14 built-in SEO checks
- Plugin system: dynamically load modules under SEO::Inspector::Plugin namespace
- Methods to check HTML strings or fetch and analyze a URL

# PLUGIN SYSTEM

In addition to the built-in SEO checks, `SEO::Inspector` supports a flexible
plugin system.
Plugins allow you to extend the checker with new rules or
specialized analysis without modifying the core module.

## How Plugins Are Found

Plugins are loaded dynamically from the `SEO::Inspector::Plugin` namespace.
For example, a module called:

    package SEO::Inspector::Plugin::MyCheck;

will be detected and loaded automatically if it is available in `@INC`.

You can also tell the constructor to search additional directories by passing
the `plugin_dirs` argument:

    my $inspector = SEO::Inspector->new(
      plugin_dirs => ['t/lib', '/path/to/custom/plugins'],
    );

Each directory must contain files under a subpath corresponding to the
namespace, for example:

    /path/to/custom/plugins/SEO/Inspector/Plugin/Foo.pm

## Plugin Interface

A plugin must provide at least two methods:

- `new`

    Constructor, called with no arguments.

- `run($html)`

    Given a string of raw HTML, return a hashref describing the result of the check.
    The hashref should have at least these keys:

        {
          name   => 'My Check',
          status => 'ok' | 'warn' | 'error',
          notes  => 'human-readable message',
          resolution => 'how to resolve'
        }

## Running Plugins

You can run all loaded plugins against a piece of HTML with:

    my $results = $inspector->check_html($html);

This returns a hashref keyed by plugin name (lowercased), each value being the
hashref returned by the plugin's `run` method.

Plugins are also run automatically when you call `check_url`:

    my $results = $inspector->check_url('https://example.com');

That result will include both built-in checks and plugin checks.

## Example Plugin

Here is a minimal example plugin that checks whether the page contains
the string "Hello":

        package SEO::Inspector::Plugin::HelloCheck;
        use strict;
        use warnings;

        sub new { bless {}, shift }

        sub run {
                my ($self, $html) = @_;
                if($html =~ /Hello/) {
                        return { name => 'Hello Check', status => 'ok', notes => 'found Hello' };
                } else {
                        return { name => 'Hello Check', status => 'warn', notes => 'no Hello', resolution => 'add a hello field' };
                }
        }

        1;

Place this file under `lib/SEO/Inspector/Plugin/HelloCheck.pm` (or another
directory listed in `plugin_dirs`), and it will be discovered automatically.

## Naming Conventions

The plugin key stored in `$inspector->{plugins}` is derived from the final
part of the package name, lowercased. For example:

        SEO::Inspector::Plugin::HelloCheck -> "hellocheck"

This is the key you will see in the hashref returned by `check_html` or
`check_url`.

# METHODS

## new(%args)

Create a new inspector object. Accepts optional `url` and `plugin_dirs` arguments.
If `plugin_dirs` isn't given, it tries hard to find the right place.

## load\_plugins

Loads plugins from the `SEO::Inspector::Plugin` namespace.

## check($check\_name, $html)

Run a single built-in check or plugin on provided HTML (or fetch from object URL if HTML not provided).

## run\_all($html)

Run all built-in checks on HTML (or object URL).

## check\_html($html)

Run all loaded plugins on HTML.

## check\_url($url)

Fetch the URL and run all plugins and built-in checks.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

- Test coverage report: [https://nigelhorne.github.io/SEO-Inspector/coverage/](https://nigelhorne.github.io/SEO-Inspector/coverage/)
- [https://github.com/nigelhorne/SEO-Checker](https://github.com/nigelhorne/SEO-Checker)
- [https://github.com/sethblack/python-seo-analyzer](https://github.com/sethblack/python-seo-analyzer)

# REPOSITORY

[https://github.com/nigelhorne/SEO-Inspector](https://github.com/nigelhorne/SEO-Inspector)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-seo-inspector at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SEO-Inspector](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SEO-Inspector).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc SEO::Inspector

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/SEO-Inspector](https://metacpan.org/dist/SEO-Inspector)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=SEO-Inspector](https://rt.cpan.org/NoAuth/Bugs.html?Dist=SEO-Inspector)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=SEO-Inspector](http://matrix.cpantesters.org/?dist=SEO-Inspector)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=SEO::Inspector](http://deps.cpantesters.org/?module=SEO::Inspector)

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
