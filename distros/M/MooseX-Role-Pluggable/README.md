# NAME

MooseX::Role::Pluggable - add plugins to your Moose classes

# VERSION

version 0.04

# SYNOPSIS

    package MyMoose;
    use Moose;
    with 'MooseX::Role::Pluggable';

    my $moose = MyMoose->new({
      plugins => [ 'Antlers' , 'Tail' , '+After::Market::GroundEffectsPackage' ] ,
      # other args here
    });

    foreach my $plugin ( @{ $moose->plugin_list } ) {
      if ( $plugin->can( 'some_method' )) {
        $plugin->some_method();
      }
    }

    # call a method in a particular plugin directly
    # (plugin_hash() returns a hash ref of 'plugin_name => plugin')
    $moose->plugin_hash->{Antlers}->gore( $other_moose );

    # plugins are indexed by the name that was used in the original 'plugins' list
    $moose->plugin_hash->{After::Market::GroundEffectsPackage}->light_up();

    # see the documentation for MooseX::Role::Pluggable::Plugin for info on
    # how to write plugins...

# DESCRIPTION

This is a role that allows your class to consume an arbitrary set of plugin
modules and then access those plugins and use them to do stuff.

Plugins are loaded based on the list of plugin names in the 'plugins'
attribute. Names that start with a '+' are used as the full name to load;
names that don't start with a leading '+' are assumed to be in a 'Plugins'
namespace under your class name. (E.g., if your app is 'MyApp', plugins will
be loaded from 'MyApp::Plugin').

NOTE: Plugins are lazily loaded -- that is, no plugins will be loaded until
either the 'plugin\_list' or 'plugin\_hash' methods are called. If you want to
force plugins to load at object instantiation time, your best bet is to call
one of those method right after you call 'new()'.

Plugin classes should consume the 'MooseX::Role::Pluggable::Plugin' role; see
the documentation for that module for more information.

# NAME

MooseX::Role::Pluggable - add plugins to your Moose classes

# METHODS

## plugin\_hash

Returns a hashref with a mapping of 'plugin\_name' to the actual plugin object.

## plugin\_list

Returns an arrayref of loaded plugin objects. The arrayref will have the
same order as the plugins array ref passed in during object creation.

## plugin\_run\_method( $method\_name )

Looks for a method named $method\_name in each plugin in the plugin list. If a
method of given name is found, it will be run. (N.b., this is essentially the
`foreach` loop from the ["SYNOPSIS"](#SYNOPSIS).)

# AUTHOR

John SJ Anderson, `genehack@genehack.org`

# SEE ALSO

[MooseX::Role::Pluggable::Plugin](http://search.cpan.org/perldoc?MooseX::Role::Pluggable::Plugin), [MooseX::Object::Pluggable](http://search.cpan.org/perldoc?MooseX::Object::Pluggable),
[Object::Pluggable](http://search.cpan.org/perldoc?Object::Pluggable)

# COPYRIGHT AND LICENSE

Copyright 2010, John SJ Anderson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

# AUTHOR

John SJ Anderson <genehack@genehack.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
