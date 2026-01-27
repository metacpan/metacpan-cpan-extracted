# NAME

RT-Extension-BooleanCustomField - CF with checkbox to set or unset its value

# DESCRIPTION

Provide a new type of [custom field](https://metacpan.org/pod/RT%3A%3ACustomField), which value can only be set or unset. Editing a `BooleanCustomField` is done through a single checkbox.

This enhances the behaviour allowed by core `Request Tracker` through `SelectCustomField`, where editing a `SelectCustomField`, with only a single value, should be done through a dropdown menu, radio buttons or checkboxes, including the single value and `no value`. With `BooleanCustomField`, you have only a single checkbox to check or uncheck.

# RT VERSION

Works with RT 4.0 or greater. Use v0.03 for RT 4 and last version for RT 5 and upper.

It should be noted that from RT 5, you can use a `SelectCustomField` with `Checkbox` `RenderType` to have the same functionality than `BooleanCustomField`. The difference is that `Checkbox` expects two values, first for unchecked and the other for checked. While `BooleanCustomField` use `no value` for unchecked and `1` for checked. So if you want to migrate a `CustomField` from `BooleanCustomField` to `Checkbox`, you have to change the type of this `CustomField`, add two values (first for unchecked and the other for checked) and then update all objects (tickets, articles, assets…) where this `CustomField` can be set, moving values from `unset` to your first value and from c<1> to the second one. This can be tedious if your RT has a lot of tickets, and you should probably stick to `BooleanCustomField` in this case! Otherwise, you can use the `etc/boolean2checbox.initialdata` file provided in this distibution.

# INSTALLATION

- export `$RTHOME=/home/of/your/RT/installation/lib`

    This is needed if your `RT` installation directory is not `/opt/rt6/` (nor `/opt/rt5` for RT 5, nor `/opt/rt4` for RT 4).

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions

- Edit your `/opt/rt5/etc/RT_SiteConfig.pm`

    If you are using RT 4.2 or greater, add this line:

        Plugin('RT::Extension::BooleanCustomField');

    For RT 4.0, add this line:

        Set(@Plugins, qw(RT::Extension::BooleanCustomField));

    or add `RT::Extension::BooleanCustomField` to your existing `@Plugins` line.

- Clear your mason cache

        rm -rf /opt/rt5/var/mason_data/obj

- Restart your webserver

# AUTHOR

Gérald Sédrati <gibus@easter-eggs.com>

# REPOSITORY

[https://github.com/gibus/RT-Extension-BooleanCustomField](https://github.com/gibus/RT-Extension-BooleanCustomField)

# BUGS

All bugs should be reported via email to

[bug-RT-Extension-BooleanCustomField@rt.cpan.org](mailto:bug-RT-Extension-BooleanCustomField@rt.cpan.org)

or via the web at

[rt.cpan.org](http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-BooleanCustomField).

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2018-2026 by Gérald Sédrati, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007
