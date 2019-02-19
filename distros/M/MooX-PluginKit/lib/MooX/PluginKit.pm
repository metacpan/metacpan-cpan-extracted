package MooX::PluginKit;

our $VERSION = '0.05';

# I don't do anything.

1;
__END__

=head1 NAME

MooX::PluginKit - A comprehensive plugin system.

=head1 SYNOPSIS

    package MyApp::Plugin::LogEngine;
    use Moo::Role;
    use MooX::PluginKit::Plugin;
    plugin_applies_to 'MyApp::Engine';
    before start => sub{ print "Starting app.\n" };
    after stop => sub{ print "Stopped app.\n" };

    package MyApp::Engine;
    use Moo;
    sub start { ... }
    sub stop { ... }

    package MyApp;
    use Moo;
    use MooX::PluginKit::Consumer;
    has_pluggable_object engine => (
        class   => 'MyApp::Engine',
        default => sub{ {} },
    );

    my $app = MyApp->new(
        plugins => ['LogEngine'],
    );
    $app->engine->start(); # Prints: Starting app.

=head1 INTRODUCTION

PluginKit provides a simple interface for creating plugins and
consuming those plugins at run-time.

PluginKit is comprised of two main pieces: the plugins, and the
classes which consume the plugins.  A plugin is just a regular
old L<Moo::Role> with some extra (optional) metadata, and the
consumers of plugins are regular old L<Moo> classes.

But, what makes this all interesting and useful is the intersection
of the two primary features provided by this module.

=over

=item *

Plugins are contextual, in that they may choose which classes
they apply to.

=item *

Plugins may include other plugins.

=back

This means that you can make groups of plugins which apply to various
classes in a hierarchy.

=head1 CREATING PLUGINS

=head2 Basics

The most minimal plugin is a L<Moo::Role>:

    package MyApp::Plugin::Foo;
    use Moo::Role;

This sort of plugin will apply to any class.

=head2 Bundling

Let's include another plugin in this plugin:

    use MooX::PluginKit::Plugin;
    plugin_includes 'MyApp::Plugin::Foo::Bar';

We could also write that using a relative (to the including plugin)
plugin name:

    plugin_includes '::Bar';

C<plugin_includes> takes a list, so you may include multiple plugins.

=head2 Contextual

    plugin_applies_to 'MyApp::SomeClass';

This declares that this plugins only applies to the specified class (or
subclasses of it).  This is where PluginKit's power really shines as it
allows plugin authors to transparently decide how and where plugins get
applied and plugin users to not need to know the intricate details.

Note that when you specify the C<plugin_applies_to> you can provide a package
name, a regex, an array ref of method names (aka duck type), or a custom subroutine
reference.

Read more about implementing plugins at L<MooX::PluginKit::Plugin>.

=head1 CONSUMING PLUGINS

You've got a few options here, but the typical way to consume plugins
involves enabling it on the class people use as the main entry point
to your library.

=head2 Plugins Argument

L<MooX::PluginKit::Consumer>, when C<use>d sets the subclass, applies a role,
and exports some candy functions for building your plugin consuming class.

A class which accepts a C<plugins> argument looks like this:

    package MyApp;
    use Moo;
    use MooX::PluginKit::Consumer;

This class now supports the C<plugins> argument when calling C<new()>, like
so:

    my $app = MyApp->new( plugins=>[...] );

=head2 Object Attributes

    has_pluggable_object engine => (
        class => 'MyApp::Enging',
    );

C<has_pluggable_object> takes many of the same arguments as L<Moo/has>.  When setup like
above, rather than passing an object as the argument you'd pass a hashref which will be
automatically coerced into an object with all relevant plugins applied.  If you'd like
to default the object you can with something like this:

    has_pluggable_object engine => (
        class     => 'MyApp::Engine',
        default => sub{ {} },
    );

See more at L<MooX::PluginKit::Consumer/has_pluggable_object>.

=head2 Class Attributes

    has_pluggable_class response_class => (
        default => 'MyApp::Response',
    );

This is useful for when you want to dynamically create instances of a class which supports
plugins.  The value of this attribute will be the composed class name with all plugins applied.

See more at L<MooX::PluginKit::Consumer/has_pluggable_class>.

=head2 Relative Plugin Namespace

If your user specifies a plugin starting with C<::> that means the plugin is
relative.  By default it will be relative to your consuming class name, so
if your class is C<MyApp> and the user wants to apply the C<::Foo> plugin then
that will resolve to the C<MyApp::Foo> plugin.  This default behavior can be
changed:

    plugin_namespace 'MyApp::Plugin';

Now if the user specified C<::Foo> as a plugin it would resolve to
C<MyApp::Plugin::Foo>.

See more at L<MooX::PluginKit::Consumer/plugin_namespace>.

=head2 The Factory

Behind the scenes there is a factory object which does all the heavy lifting of this
library.  This factory can be accessed as the C<plugin_factory> attribute on
consumer classes or an instance of the factory class may be created directly.

See more at L<MooX::PluginKit::Factory>.

=head1 TODO

=head2 Use Coercion

The L<MooX::PluginKit::Consumer/has_pluggable_object> function jumps through a bunch
of hoops due to the fact that L<Moo/coerce> subroutines do not get access to the
instance that the value is being set on.  Due to this we create two accessors, one
which acts as the writer, and the other which acts as the object builder and reader.

This design makes it difficult to support common L<Moo/has> arguments such as
C<predicate> and C<clearer>, etc.  For now the design of C<has_pluggable_object>
has been limited somewhat so that we don't have to come back later and make
backwards-incompatible changes.

=head2 Cleanly Alter Constructor

Its totally funky that L<MooX::PluginKit::Consumer> sets L<MooX::PluginKit::ConsumerBase>
as the base class.  This is only done because when calling new with plugins changes the
class name that new is being called on, which means we need to change the behavior of new
itself to return the object blessed into a different package than it was called with.

The problem is that C<Method::Generator::Constructor>, a part of L<Moo>, throws exceptions
if you try to alter the behavior of new with an C<around()> modifier or somesuch.  So,
to circumvent these exceptions we use a non-Moo parent class with a custom C<new>, but then
L<Moo> gets into this mode where it acts slightly differently because its inheriting from
a non-Moo class.  For example, when inheriting from a non-Moo class in Moo you don't get a
BUILDARGS.  Despite that, BUILDARGS support has been shimmed in, but there may be other
non-Moo Moo issues.

It would be nice to find a fix for this as I expect it might bite someone.

=head2 Document Core Library

The L<MooX::PluginKit::Core> library contains a bunch of functions for low-level interaction
with plugins and consumers.  This API should be formalized with documentation, once it is in
a final state that can be relied on to not change much.  For now, don't use anything in there
directly.

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

