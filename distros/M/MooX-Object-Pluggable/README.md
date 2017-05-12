# NAME

MooX::Object::Pluggable - Moo eXtension to inject plugins to exist objects as a role

# VERSION

version 0.0.5

# SYNOPSIS

In your package:

    package MyPackage;
    use Moo;
    use namespace::clean;

    with 'MooX::Object::Pluggable';
    1

Define your plugin package:

    package MyPackage::Plugin::Foo;
    use Moo::Role;
    use namespace::clean;

    sub foo { 'foo' }

Then in your script:

    #!perl
    use MyPackage;
    my $object = MyPackage->new;
    $object->load_plugins('Foo');

Or `new` with pluggable options:

    use MyPackage;
    MyPackage->new(
      pluggable_options => { search_path => 'MyPackage::Plugin' }, # optional
      load_plugins => [ "Foo", qr/::Bar$/ ]
    );

Or use MooX with this:

    use MooX 'Object::Pluggable' => { ... };

# DESCRIPTION

`MooX::Object::Pluggable` for moo is designed to perform like `MooseX::Object::Pluggable`
for Moose staff. Mainly it use Moo::Role's `apply_roles_to_object` to load plugins
at runtime, but with the ability to choose plugins with package [Module::Pluggable::Object](https://metacpan.org/pod/Module::Pluggable::Object).

# METHODS

## load\_plugins

In most situation, your need only call the fuction `load_plugins` on an object.
The parameters support String, Regexp, or Array or ArrayRef of them.

eg.

    $o->load_plugins("Foo", "Bar", qr/^Class::Plugin::(Abc|N)[0-9]/, [ qw/Other Way/ ]);

And there's another syntax sugar, when you just want to load a specific role:

    $o->load_plugins("+MooX::ConfigFromFile::Role");
    # Notice that the '+' sign does not support Regexp, use whole package name with it.

## plugins

The method `plugins` returns a array of plugins, defaultly in the namespace
`Your::Package::Plugin::`. You can manage it by implement the `_build_pluggable_options`
in your package and given the avaliable options' HashRef.

    package MyPackage;
    use Moo;
    with 'MooX::Object::Pluggable';
    sub _build_pluggable_options {
      { search_path => __PACKAGE__.'::Funtionals' }
    }

All the avaliable options will be found in tutorial of package [Module::Pluggable](https://metacpan.org/pod/Module::Pluggable).

## loaded\_plugins

This will list all loaded plugins of current object for you.

# DESIGN

Considering not import any new attributes to the consumers,
I'm using a private variable for help to maintain [Module::Pluggable::Object](https://metacpan.org/pod/Module::Pluggable::Object)
objects so that it only create once for each package,
and could provide private configuration for specific objects
that use diffent pluggable options in `new`.

There's two way to configure user defined pluggable options.

## new(pluggable\_options => {}, load\_plugins => \[\])

User could directly use there specific options for plugin.
And create objects with some plugins after `BUILD` step.

## \_build\_pluggable\_options

Implement this build function in your package, and `MooX::Object::Pluggable`
will apply the options for you.

And you still could change default options in `new` method.

# MooX

A [MooX](https://metacpan.org/pod/MooX)-compatible interface like this:

    package MyPackage::Hello;
    use Moo::Role;
    sub hello { 'hello' }

...

    package MyPackage;
    use MooX::Object::Pluggable -pluggable_options => { search_path => ["MyPackage"] }, -load_plugins => ['Hello'];

Or:

    use MooX
      'Object::Pluggable' => { -pluggable_options => { search_path => ["MyPackage"] }, -load_plugins => ['Hello'] };

# SEE ALSO

[Module::Pluggable](https://metacpan.org/pod/Module::Pluggable), [MooseX::Object::Pluggable](https://metacpan.org/pod/MooseX::Object::Pluggable)

# AUTHOR

Huo Linhe &lt;linhehuo@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Huo Linhe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
