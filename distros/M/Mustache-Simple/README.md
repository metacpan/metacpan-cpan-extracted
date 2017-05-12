# NAME

Mustache::Simple - A simple Mustache Renderer

See [http://mustache.github.com/](http://mustache.github.com/).

# VERSION

This document describes Mustache::Simple version 1.3.0

# SYNOPSIS

A typical Mustache template:

        my $template = <<EOT;
    Hello {{name}}
    You have just won ${{value}}!
    {{#in_ca}}
    Well, ${{taxed_value}}, after taxes.
    {{/in_ca}}
    EOT

Given the following hashref:

    my $context = {
        name => "Chris",
        value => 10000,
        taxed_value => 10000 - (10000 * 0.4),
        in_ca => 1
    };

Will produce the following:

    Hello Chris
    You have just won $10000!
    Well, $6000, after taxes.

using the following code:

    my $tache = new Mustache::Simple(
        throw => 1
    );
    my $output = $tache->render($template, $context);

# DESCRIPTION

Mustache can be used for HTML, config files, source code - anything. It works
by expanding tags in a template using values provided in a hash or object.

There are no if statements, else clauses, or
for loops. Instead there are only tags. Some tags are replaced with a value,
some nothing, and others a series of values.

This is a simple perl implementation of the Mustache rendering.  It has
a single class method, new() to obtain an object and a single instance
method render() to convert the template and the hashref into the final
output.

As of version 1.2.0, it has support for nested contexts, for the dot notation
and for the implicit iterator.

As of version 1.3.0, it will accept a blessed object.  For any `{{item}}`
where the object has a method called item (as returned by `$object->can`),
the value will be the return from the method call (with no parameters).
If `$object->can(item)` returns `undef`, the object will be treated
as a hash and the value looked up directly. See ["MANAGING OBJECTS"](#managing-objects) below.

## Rationale

I wanted a simple rendering tool for Mustache that did not require any
subclassing.

# METHODS

## Creating a new Mustache::Simple object

- new

        my $tache = new Mustache::Simple(%options)

### Parameters:

- path

    The path from which to load templates and partials. This may be
    a string or a reference to an array of strings.  If it is a reference,
    each string will be searched in order.

    Default: '.'

- extension

    The extension to add to filenames when reading them off disk. The
    '.' should not be included as this will be added automatically.

    Default: 'mustache'

- throw

    If set to a true value, Mustache::Simple will croak when there
    is no key in the context hash for a given tag.

    Default: undef

- partial

    This may be set to a subroutine to be called to generate the
    filename or the template for a partial.  If it is not set, partials
    will be loaded using the same parameters as render().

    Default: undef

## Configuration Methods

The configuration methods match the %options array thay may be passed
to new().

Each option may be called with a non-false value to set the option
and will return the new value.  If called without a value, it will return
the current value.

- path()

        $tache->path('/some/new/template/path');
    or
        $tache->path([ qw{/some/new/template/path .} ]);
        my $path = $tache->path;    # defaults to '.'

- extension()

        $tache->extension('html');
        my $extension = $tache->extension;  # defaults to 'mustache'

- throw()

        $tache->throw(1);
        my $throwing = $tache->throw;       # defaults to undef

- partial()

        $tache->partial(\&resolve_partials)
        my $partial = $tache->partial       # defaults to undef

## Instance methods

- read\_file()

        my $template = read_file('templatefile');

    You will not usually need to call this directly as it's called by
    ["render"](#render) to load the file.  If it is passed a string that looks like
    a template (i.e. has {{ in it) it simply returns it.  Similarly, if,
    after prepending the path and adding the suffix, it cannot load the file,
    it simply returns the original string.

- render()

        my $context = {
            "name" => "Chris",
            "value" => 10000,
            "taxed_value" => 10000 - (10000 * 0.4),
            "in_ca" => true
        }
        my $html = $tache->render('templatefile', $context);

    This is the main entry-point for rendering templates.  It can be passed
    either a full template or path to a template file.  See ["read\_file"](#read_file)
    for details of how the file is loaded.  It must also be passed a hashref
    containing the main context.

    In callbacks (sections like ` {{#this}} ` with a subroutine in the context),
    you may call render on the passed string and the current context will be
    remembered.  For example:

        {
            name => "Willy",
            wrapped => sub {
                my $text = shift;
                chomp $text;
                return "<b>" . $tache->render($text) . "</b>\n";
            }
        }

    Alternatively, you may pass in an entirely new context when calling
    render() from a callback.

# COMPLIANCE WITH THE STANDARD

The original standard for Mustache was defined at the
[Mustache Manual](http://mustache.github.io/mustache.5.html)
and this version of [Mustache::Simple](https://metacpan.org/pod/Mustache::Simple) was designed to comply
with just that.  Since then, the standard for Mustache seems to be
defined by the [Mustache Spec](https://github.com/mustache/spec).

The test suite on this version skips a number of tests
in the Spec, all of which relate to Decimals or White Space.
It passes all the other tests. The YAML from the Spec is built
into the test suite.

# MANAGING OBJECTS

If a blessed object is passed in (at any level) as the context for
rendering a template, [Mustache::Simple](https://metacpan.org/pod/Mustache::Simple) will check each tag to
see if it can be called as a method on the object.  To achieve this, it
calls `can` from [UNIVERSAL](http://perldoc.perl.org/UNIVERSAL.html)
on the object.  If `$object->can(tag)`
returns code, this code will be called (with no parameters).  Otherwise,
if the object is based on an underlying HASH, it will be treated as that
HASH.  This works well for objects with AUTOLOADed "getters".

For example:

    package Test::Mustache;

    sub new
    {
        my $class = shift;
        my %params = @_;
        bless \%params, $class;
    }

    sub name    # Ensure the name starts with a capital
    {
        my $self = shift;
        (my $name = $self->{name}) =~ s/.*/\L\u$&/;
        return $name;
    }

    sub AUTOLOAD    # generic getter / setter
    {
        my $self = shift;
        my $value = shift;
        (my $method = our $AUTOLOAD) =~ s/.*:://;
        $self->{$method} = $value if defined $value;
        return $self->{$method};
    }

    sub DESTROY { }

Using the above object as `$object`, `{{name}}` would call
`$object->can('name')` which would return a reference to
the `name` method and thus that method would be called as a
"getter".  On a call to `{{address}}`, `$object->can` would
return undef and therefore `$object->{address}` would be
used.

This is usually what you want as it avoids the call to `$object->AUTOLOAD`
for each simple lookup.  If, however, you want something different to
happen, you either need to declare a "Forward Declaration"
(see [perlsub](http://perldoc.perl.org/perlsub.html))
or you need to override the object's `can`
(see [UNIVERSAL](http://perldoc.perl.org/UNIVERSAL.html)).

# BUGS

- White Space

    Much of the more esoteric white-space handling specified in
    [The Mustache Spec](https://github.com/mustache/spec) is not strictly adhered to
    in this version.  Most of this will be addressed in a future version.

    Because of this, the following tests from the Mustache Spec are skipped:

    - Indented Inline
    - Indented Inline Sections
    - Internal Whitespace
    - Standalone Indentation
    - Standalone Indented Lines
    - Standalone Line Endings
    - Standalone Without Newline
    - Standalone Without Previous Line

- Decimal Interpolation

    The spec implies that the template `"{{power}} jiggawatts!"` when passed
    `{ power: "1.210" }` should return `"1.21 jiggawatts!"`.  I believe this to
    be wrong and simply a mistake in the YAML of the relevant tests or possibly
    in [YAML::XS](https://metacpan.org/pod/YAML::XS). I am far from being a YAML expert.

    Clearly `{ power : 1.210 }` would have the desired effect.

    Because of this, all tests matching `/Decimal/` have been skipped.  We can just
    assume that Perl will do the right thing.

# EXPORTS

Nothing.

# SEE ALSO

[Template::Mustache](https://metacpan.org/pod/Template::Mustache) - a much more complex module that is
designed to be subclassed for each template.

# AUTHOR INFORMATION

Cliff Stanford `<cliff@may.be>`

# SOURCE REPOSITORY

The source is maintained at a public Github repository at
[https://github.com/CliffS/mustache-simple](https://github.com/CliffS/mustache-simple).  Feel free to fork
it and to help me fix some of the above issues. Please leave any
bugs or issues on the [Issues](https://github.com/CliffS/mustache-simple/issues)
page and I will be notified.

# LICENCE AND COPYRIGHT

Copyright © 2014, Cliff Stanford `<cliff@may.be>`. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
