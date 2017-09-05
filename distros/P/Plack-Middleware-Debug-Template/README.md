# NAME

Plack::Middleware::Debug::Template - storing profiling
information on template use.

![Screenshot of template debug panel](https://raw.githubusercontent.com/mysociety/Plack-Middleware-Debug-Template/master/screenshot.png)

# VERSION

1.00

# SYNOPSIS

To activate this panel:

    plack_middlewares:
      Debug:
        - panels
        -
          - Template

Or in your app.psgi, something like:

    builder {
        enable 'Debug', panels => ['Template'];
        $app;
    };

# DESCRIPTION

This middleware adds timers around calls to ["process" in
Template::Context](https://metacpan.org/pod/Template::Context#process)
to track the time spent rendering the template and the layout for
the page.

# HOOKS

Subclass this module and implement the below functions if you
wish to change its behaviour.

* `show_pathname`

    Return true if the panel should show the path name rather than
    the template name, or false to have the path name in a title
    attribute.

* `hook_pathname`

    This function can alter the full template path name provided
    to it for display.

* `ignore_template`

    If you don't want output for any particular template, test
    for it here. Return true to ignore.

# SUPPORT

You can look for information on GitHub at
<https://github.com/mysociety/Plack-Middleware-Debug-Template>.

# ACKNOWLEDGEMENTS

This module is based on a combination of
Plack::Middleware::Debug::Dancer::TemplateTimer and
Template::Timer.

# AUTHOR

Matthew Somerville, `<matthew at mysociety.org>`

# LICENSE AND COPYRIGHT

Copyright 2017 Matthew Somerville.

This library is free software; you can redistribute it and/or
modify it under the terms of either the GNU Public License v3,
or the Artistic License 2.0. See <http://dev.perl.org/licenses/>
for more information.


