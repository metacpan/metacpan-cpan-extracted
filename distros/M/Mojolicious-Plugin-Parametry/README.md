# NAME

Mojolicious::Plugin::Parametry - Mojolicious plugin providing param helpers

# SYNOPSIS

    $self->plugin('Parametry');

    # Trim whitespace on the value of param `the_test_param` and
    # set it to empty string if it doesn't exist:
    my $p  = $self->P->the_test_param;

    # Access `matching` param helper, to gather all params starting with `foo_`
    my $ps = $self->PP->matching('foo_');


    # These are regular helpers, and so available inside templates too:

    <p>Param meow_meow has value <%= P->meow_meow %></p>
    <p>Meowy params: <%= PP->matching(qr/meow/, vals => 1)->join(', ') %></p>


    # And if you're not a fan of 1-letter helper names, you can change them:

    $self->plugin(Parametry
        => shortcut_key => 'paramer', helpers_key => 'param_helpers');
    my $par_val = $self->paramer->the_test;
    my $params  = $self->param_helpers->matching(qr/^foo_/);

# DESCRIPTION

[Mojolicious::Plugin::Parametry](https://metacpan.org/pod/Mojolicious::Plugin::Parametry) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin that provides
a simpler (to a taste) way to access parameter values as well as a set of
helpers for managing params and their values.

# CAVEATS

No testing or support has been made for handling multi-value params. Some
helpers provided by the plugin only support params named with valid Perl
method named.

# METHODS

[Mojolicious::Plugin::Parametry](https://metacpan.org/pod/Mojolicious::Plugin::Parametry) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# HELPERS

## `P`

    $c->P->some_param_value;

    # Equivalent to:
    # ($c->param('some_param_value') // '') =~ s/^\s+|\s+$//gr;

This is the default name for the _Paramer_ shortcut param access helper and
can be changed using `shortcut_key` plugin configuration key.

To access a param value, make a method call on the object returned by
this helper, with the name of the method matching the name of the param.
If param value is \`undef\`, the helper will set it to an emptry string. The
helper will also trim leading and trailing whitespace.

**CAVEATS:** this helper can be used to access only params named with valid
Perl method names and no support for other names is currently planned.

## `P`

    $c->PP

Provides access to [Mojolicious::Plugin::Parametry::ParamerHelpers](https://metacpan.org/pod/Mojolicious::Plugin::Parametry::ParamerHelpers)
object, initialized with the current controller object. Available methods
are:

### `matching`

    $c->PP->matching('foo_'); # all param names starting with 'foo_'

    # all param values of params whose name match regex /foo/
    $c->PP->matching(qr/foo/, vals => 1);

    # all param names starting with 'foo_', with 'foo_' stripped from names
    $c->PP->matching('foo_', strip => 1);

    # all param names starting with 'foo_', with 'foo_' changed to 'bar_'
    $c->PP->matching('foo_', subst => 'bar_');

    # all param names starting with 'foo_', with 'foo_' changed to 'bar_'
    # returned together with their values, as a hashref
    $c->PP->matching('foo_', subst => 'bar_', as_hash => 1);

Gathers matching params, optionally complemented with their values, and
returns them as a [Mojo::Collection](https://metacpan.org/pod/Mojo::Collection) (or a hashref, if `as_hash` is set),
optionally manipulating the names. Available args:

#### first positional

    $c->PP->matching('foo_');
    $c->PP->matching(qr/foo.+bar/);

**Mandatory**. Specifies the matcher for parameter **name** matching.
Takes either a `Regexp` object or a plain string. _String match is anchored
to the start of the parameter name_
(`'fo.o'` is equivalent to `qr/^fo\.o/`).

#### `vals`

    $c->PP->matching(qr/foo/, vals => 1);

**Optional**. Causes the method to return a [Mojo::Collection](https://metacpan.org/pod/Mojo::Collection) of
the values of parameter whose names match the matcher.

#### `as_hash`

    $c->PP->matching(qr/foo/, as_hash => 1);

**Optional**. Causes the method to return a _hashref_ where keys are
parameter names
and values are parameter values. No attempt to handle multi-value parameters
is done. This argument takes precedence over `vals` arugment.

#### `subst`

    # all param names starting with 'foo_', with 'foo_' changed to 'bar_'
    $c->PP->matching('foo_', subst => 'bar_');

**Optional**. Replaces the matching part of parameter names with
the provided replacement. When used with `as_hash`, the modified names
will become the new keys (the values are still obtained from original
param names)

#### `subst`

    # all param names starting with 'foo_', with 'foo_' stripped from names
    $c->PP->matching('foo_', strip => 1);

**Optional**. Alternative way of specifying `subst => ''`

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/Mojolicious-Plugin-Parametry](https://github.com/zoffixznet/Mojolicious-Plugin-Parametry)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/Mojolicious-Plugin-Parametry/issues](https://github.com/zoffixznet/Mojolicious-Plugin-Parametry/issues)

If you can't access GitHub, you can email your request
to `bug-mojolicious-plugin-parametry at rt.cpan.org`

# AUTHOR

Zoffix Znet `zoffix at cpan.org`, ([https://zoffix.com/](https://zoffix.com/))

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
