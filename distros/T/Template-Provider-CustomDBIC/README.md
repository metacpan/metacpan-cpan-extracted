# NAME

Template::Provider::CustomDBIC - Load templates using DBIx::Class

# SYNOPSIS

    use My::CustomDBIC::Schema;
    use Template;
    use Template::Provider::CustomDBIC;

    my $schema = My::CustomDBIC::Schema->connect(
        $dsn, $user, $password, \%options
    );
    my $resultset = $schema->resultset('Template');

If all of your templates are stored in a single table the most convenient
method is to pass the provider a [DBIx::Class::ResultSet](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AResultSet).

    my $template = Template->new({
        LOAD_TEMPLATES => [
            Template::Provider::CustomDBIC->new({
                RESULTSET => $resultset,
                # Other template options like COMPILE_EXT...
            }),
        ],
    });

    # Process the template in 'column' referred by reference from resultset 'Template'.
    $template->process('table/reference/column');

# DESCRIPTION

Template::Provider::CustomDBIC allows a [Template](https://metacpan.org/pod/Template) object to fetch its data using
[DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) instead of, or in addition to, the default filesystem-based
[Template::Provider](https://metacpan.org/pod/Template%3A%3AProvider).

## SCHEMA

This provider requires a schema containing at least the following:

- A column containing the template name. When `$template->provider($name)`
is called the provider will search this column for the corresponding `$name`.
For this reason the column must be a unique key, else an exception will be
raised.
- A column containing the actual template content itself. This is what will be
compiled and returned when the template is processed.
- A column containing the time the template was last modified. This must return
- or be inflated to - a date string recognisable by [Date::Parse](https://metacpan.org/pod/Date%3A%3AParse).

## OPTIONS

In addition to supplying a RESULTSET or SCHEMA and the standard
[Template::Provider](https://metacpan.org/pod/Template%3A%3AProvider) options, you may set the following preferences:

- COLUMN\_NAME

    The table column that contains the template name. This will default to 'name'.

- COLUMN\_CONTENT

    The table column that contains the template data itself. This will default to
    'content'.

- COLUMN\_MODIFIED

    The table column that contains the date that the template was last modified.
    This will default to 'modified'.

# METHODS

## ->fetch( $name )

This method is called automatically during [Template](https://metacpan.org/pod/Template)'s `->process()`
and returns a compiled template for the given `$name`, using the cache where
possible.

# USE WITH OTHER PROVIDERS

By default Template::Provider::CustomDBIC will raise an exception when it cannot
find the named template 

    my $template = Template->new({
        LOAD_TEMPLATES => [
            Template::Provider::CustomDBIC->new({
                RESULTSET => $resultset,
            }),
            Template::Provider->new({
                INCLUDE_PATH => $path_to_templates,
            }),
        ],
    });

# CACHING

When caching is enabled, by setting COMPILE\_DIR and/or COMPILE\_EXT,
Template::Provider::CustomDBIC will create a directory consisting of the database
DSN and table name. This should prevent conflicts with other databases and
providers.

# SEE ALSO

[Template](https://metacpan.org/pod/Template), [Template::Provider](https://metacpan.org/pod/Template%3A%3AProvider), [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema)

# DIAGNOSTICS

In addition to errors raised by [Template::Provider](https://metacpan.org/pod/Template%3A%3AProvider) and [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass),
Template::Provider::CustomDBIC may generate the following error messages:

- `A valid DBIx::Class::Schema or ::ResultSet is required`

    One of the SCHEMA or RESULTSET configuration options _must_ be provided.

- `%s not valid: must be of the form $table/$template`

    When using Template::Provider::CustomDBIC with a [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) object, the
    template name passed to `->process()` must start with the name of the
    result set to search in.

- `'%s' is not a valid result set for the given schema`

    Couldn't find the result set %s in the given [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) object.

- `Could not retrieve '%s' from the result set '%s'`

# DEPENDENCIES

- [Carp](https://metacpan.org/pod/Carp)
- [Date::Parse](https://metacpan.org/pod/Date%3A%3AParse)
- [File::Path](https://metacpan.org/pod/File%3A%3APath)
- [File::Spec](https://metacpan.org/pod/File%3A%3ASpec)
- [Template::Provider](https://metacpan.org/pod/Template%3A%3AProvider)

Additionally, use of this module requires an object of the class
[DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) or [DBIx::Class::ResultSet](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AResultSet).

# BUGS

Please report any bugs or feature requests through the web interface at
[https://github.com/itnode/Template-Provider-CustomDBIC/issues](https://github.com/itnode/Template-Provider-CustomDBIC/issues)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Provider::CustomDBIC

You may also look for information at:

- Template::Provider::CustomDBIC
- AnnoCPAN: Annotated CPAN documentation
- RT: CPAN's request tracker

    [https://github.com/itnode/Template-Provider-CustomDBIC/issues](https://github.com/itnode/Template-Provider-CustomDBIC/issues)

- Search CPAN

# AUTHOR

Jens Gassmann <jegade@cpan.org>

Based on work from Dave Cardwell <dcardwell@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (c) 2015 Jens Gassmann. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).
