package Module::Modular;

=head1 NAME

Module::Modular - Create optional plugins for your module

=head1 DESCRIPTION

Module::Modular allows you, or others, to create plugins for your modules. They are not loaded by default - only 
when you want them to be. This means you can even load them further on down in your module if you wish.
The idea is to have your plugins handle certain tasks you don't want cluttering the core code of your module.
I started writing this B<before> I came across another plugin module called L<Module::Pluggable>. So if you like 
how that one works better, or even prefer the name (I do), then go check it out. This one is different in the sense 
you explicitly tell your module what plugins to load, and each plugin may have an initialiser (C<__init>) that will 
get run once it has been loaded, which I found pretty neat.
This module is modular itself. By importing C<with> followed by an array of options you can extend the functionality 
of Module::Modular. Currently just the one option is available (C<Accessors>) which provides methods for accessing meta data of your plugins.
A plugin can only be loaded if it's within the same namespace and within your path (ie: YourModule::Plugin::*)

=head1 SYNOPSIS

    # MyModule.pm
    
    package MyModule;

    use Module::Modular;
    load_plugins qw<Foo Bar>;
    
    sub load_another_plugin {
        load_plugins 'DifferentOne';
    }

    # MyModule::Plugin::Foo
    package MyModule::Plugin::Foo;

    sub __init {
        my ($class, $name) = @_;
        # $class = MyModule::Plugin::Foo
        # $name  = Foo

        # some code here to be run when loaded
    }

    sub foo {
        print "You have been foo'd!\n";
    }

Now, when you C<use MyModule>, the Foo plugin will get loaded and run C<__init> from C<MyModule::Plugin::Foo>. Simple. The initialiser is completely optional.
It's quite simple to get a list of plugins, or you can get hold of a single plugin to do stuff with.

    # Run the foo() method within the Foo plugin
    my $foo_plugin = $module->plugin('Foo')->foo();

Calling the C<plugins> method will return an array of your loaded plugins. Each one will be blessed, so you have objects to work with which makes things easier.

    # call the foo() method on every loaded plugin
    for my $plugin ($module->plugins) {
        $plugin->foo();
    }

=head1 METHODS

C<Module::Modular> exports only a few functions into your module. They are...

=head2 load_plugins

  void load_plugins(@list)

Takes an array of plugins (Not their entire path, just the name of the plugin. For example, 
if I wanted to load C<MyModule::Plugin::Foo> I would only have to use C<load_plugins 'Foo'>.
If it can't load the module for any reason it will print out a warnings and move onto the next one if it's specified.

=head2 plugins

  @array plugins(void)

Returns an array of your loaded plugins. It will only register those introduced by C<load_plugins>, just having one in the right namespace and loaded by any other means will do nothing.

=head2 plugin

  $object plugin(string)

Returns a blessed reference of a plugin (ie: The plugin object). You only need to supply the name, not the entire path. For example

    my $plugin = $module->plugin('Foo');

=head2 stash

This is a plugin method (Called from a plugin only). It's a really simple method used to get the data of a specific global variable from the base module. After all, what's the point of a plugin if you have absolutely no way to share data, right?

    # MyModule.pm
    package MyModule;

    use Module::Modular;

    our $PluginStash = { bees => 'knees' };
    load_plugins 'Bees';

    # MyModule::Plugin::Bees
    package MyModule::Plugin::Bees;

    sub __init {
        my ($self, $name) = @_;
        print "The $name have " . $self->stash('bees');
    }

It's not overly useful, secure, or remotely interesting, but if you need a quick and dirty way to get some data to your plugins, it works. I am trying to find a neater solution..

=head2 OPTIONS

When you C<use Module::Modular> you can pass a key called C<with> as an arrayref of options or just a string for a single option. 

B<Accessors>

Implements specific accessors to access the meta data of a plugin

    # MyModule.pm
    use Module::Modular
        with => 'Accessors';

    load_plugins qw<Foo Bar>;

    # test.pl
    for my $plugin ($module->plugins) {
        say "Name: " . $plugin->name;
        say "Version: " . $plugin->version;
    }

B<Strict>

Will not allow you to get a plugin object directly from outside the core modules scope

    # MyModule.pm
    use Module::Modular
        with => [qw<Accessors Strict>];

    load_plugins 'Foo';
    sub get_plugin { my $self = shift; return $self->plugin('Foo'); }

    # test.pl
    my $c = MyModule->new;
    $c->plugin('Foo')->foo(); # fails
    my $plugin = $c->get_plugin(); # works, because it went through the core module first
   
=cut

use warnings;
use strict;

use Import::Into;

our $VERSION = '0.003';
our $LoadedPlugins = [];
our $Config        = {
    'accessors' => 0,
    'strict'    => 0,
};

sub import {
    my ($class, %opts) = @_;
    my $caller = scalar caller;

    if (exists $opts{with}) {
        if (ref($opts{with})) {
            for my $with (@{$opts{with}}) {
                _enable_option($with);
            }
        }
        else {
            _enable_option($opts{with});
        }
    }

    _import_defs($caller,
        qw<load_plugins plugin plugins>);
}

sub _enable_option {
    my $opt = shift;
    for ($opt) {
        if (/Accessors/) { $Config->{accessors} = 1; }
        elsif (/Strict/) { $Config->{strict}    = 1; }
    }
}

sub _import_defs {
    my ($caller, @methods) = @_;
    importmethods: {
        no strict 'refs';
        foreach my $method (@methods) {
            *{"${caller}::${method}"} = \&$method;
        }
    }
}

sub load_plugins {
    my (@plugins) = @_;
    my $caller = caller;
    my $name;
    loadplugins: {
        no strict 'refs';
        foreach my $plugin (@plugins) {
            $name   = $plugin;
            $plugin = "${caller}::Plugin::${plugin}";
            eval "use $plugin;";
            if ($@) {
                warn "Failed loading plugin ${plugin}: ${@}";
                next;
            }

            $plugin->import::into($caller);
            *{"${plugin}::stash"} = sub {
                my ($mod, $key) = @_;
                if ($mod = ref($mod)) {
                    my $module = (split('::', $mod))[0];
                    return ${"${module}::PluginStash"}->{$key};
                }
            };

            if ($plugin->can('__init')) {
                my $blessed_plugin = bless {}, $plugin;
                $blessed_plugin->__init($name);
            }
            push @$LoadedPlugins, bless {
                name    => $name,
                version => $plugin->VERSION||'Unknown',
            }, $plugin;
       
            if ($Config->{accessors}) { 
                *{"${plugin}::name"} = sub { return shift->{name}; };
                *{"${plugin}::version"} = sub { return shift->{version}; };
            }
        }
    }
}

sub plugin {
    my ($self, $plugin) = @_;
    my $caller  = caller();
    my @plugins = $self->plugins;
    if (my $first = $plugins[0]) {
        $plugin = ref($self) . "::Plugin::" . $plugin;
        if ($Config->{strict} and ref($first) ne "${caller}::Plugin::" . $first->{name}) {
            warn "Can't call plugin outside core modules scope";
            return 0;
        }
        if (grep { ref($_) eq $plugin } @$LoadedPlugins) {
            return bless {}, $plugin;
        }
        else {
            warn "Could not get plugin ${plugin}: Not loaded";
            return 0;
        }
    }
    else {
        warn "No plugins loaded";
        return 0;
    }
}

sub plugins {
    my $self = shift;
    return @$LoadedPlugins;
}

=head1 AUTHOR

Brad Haywood <brad@perlpowered.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;
