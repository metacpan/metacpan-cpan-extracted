#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin - Plugin base class for the Nile framework.

=head1 SYNOPSIS
        
=head1 DESCRIPTION

Nile::Plugin - Plugin base class for the Nile framework.

This module is the base class for plugins. You include it by using it which also makes itself as a parent class for the plugin and inherts
the method setting which has the plugin setting loaded automatically from the config files.

Creating your first plugin C<Hello> is simple like that, just create a module file called C<Hello.pm> in the folder C<Nile/Plugin> and 
put the following code in it:

    package Nile::Plugin::Hello;
    
    our $VERSION = '0.55';
    
    # this also extends Nile::Plugin, the plugin base class
    use Nile::Plugin;
    
    # optional our alternative for sub new {} called automaticall on object creation
    sub main {

        my ($self, $arg) = @_;
        
        # plugin settings from config files section
        my $setting = $self->setting();
        #same as
        #my $setting = $self->setting("hello");
        
        # get app context
        my $app = $self->app;

        # good to setup hooks here
        # run this hook after the "start" method
        $app->hook->after_start( sub { 
            my ($me, @args) = @_;
            #...
        });
        
    }
    
    sub welcome {
        my ($self) = @_;
        return "Hello world";
    }

    1;

Then inside other modules or plugins you can access this plugin as
    
	# get the plugin object
	$hello = $app->plugin->hello;
	
	# or
	$hello = $app->plugin("Hello");
	
	# if plugin name has sub modules
	my $redis = $app->plugin("Cache::Redis");
	
	# call plugin method
    say $app->plugin->hello->welcome;

    # in general, you access plugins like this:
    $app->plugin->your_plugin_name->your_plugin_method([args]);

Plugins will be loaded automatically on the first time it is used and can be load on application startup in the C<init> method:

    $app->init({
        plugin  => [ qw(hello) ],
    });

Plugins also can be loaded on application startup by setting the C<autoload> variable in the plugin configuration in the
config files. 

Example of plugin configuration to auto load on application startup:

    <plugin>

        <hello>
            <autoload>1</autoload>
        </hello>

    </plugin>

At the plugin load, the plugin optional method C<main> will be called automatically if it exists, this is an alternative for the method C<new>.

Inside the plugin methods, you access the application context by the injected method C<app> and you use it in this way:

    my $app = $self->app;
    $app->request->param("name");
    ...
    $app->config->get("email");

Plugins that setup C<hooks> must be set to autoload on startup for hooks to work as expected.

=cut

use Nile::Base;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use Moose;
use MooseX::Declare;
use MooseX::MethodAttributes;

use Import::Into;
use Module::Runtime qw(use_module);

no warnings 'redefine';
no strict 'refs';
# disable the auto immutable feature of Moosex::Declare, or use class Nile::Home is mutable {...}
*{"MooseX::Declare::Syntax::Keyword::Class" . '::' . "auto_make_immutable"} = sub { 0 };
#around auto_make_immutable => sub { 0 };

our @EXPORT_MODULES = (
        Moose => [],
        utf8 => [],
        'Nile::Say' => [],
        'MooseX::Declare' => [],
        'MooseX::MethodAttributes' => [],
    );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub import {

    my ($class, @args) = @_;

    my ($caller, $script) = caller;

    my $package = __PACKAGE__;
    
    # ignore calling from child import
    return if ($class ne $package);

    my @modules = @EXPORT_MODULES;

    while (@modules) {
        my $module = shift @modules;
        my $imports = ref($modules[0]) eq 'ARRAY' ? shift @modules : [];
        use_module($module)->import::into($caller, @{$imports});
    }

    {
        no strict 'refs';
        @{"${caller}::ISA"} = ($package, @{"${caller}::ISA"});
    }

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 setting()
    
    # inside plugin classes, return current plugin class config settings
    my $setting = $self->setting();
    my %setting = $self->setting();

    # 
    # inside plugin classes, return specific plugin class config settings
    my $setting = $self->setting("email");
    my %setting = $self->setting("email");

Returns plugin class settings from configuration files loaded.

Helper plugin settings in config files must be in inside the plugin tag. The plugin class name can be lower case tag, so plugin C<Email> can be C<email>.

Exampler settings for C<email> and  C<cache> plugins class below:

    <plugin>
        <email>
            <transport>Sendmail</transport>
            <sendmail>/usr/sbin/sendmail</sendmail>
        </email>
        <cache>
            <autoload>1</autoload>
        </cache>
    </plugin>

=cut

sub setting {

    my ($self, $plugin) = @_;

    $plugin ||= caller();
    
	#$plugin =~ s/^(.*):://;

	$plugin =~ s/^Nile::Plugin:://;
	$plugin =~ s/::/_/g;

    $plugin = lc($plugin);

    my $app = $self->app;
    
    # access plugin name as "email" or "Email"
    if (!exists $app->config->get("plugin")->{$plugin} && exists $app->config->get("plugin")->{ucfirst($plugin)}) {
        $plugin = ucfirst($plugin);
    }
    
    my $setting = $app->config->get("plugin")->{$plugin};

    delete $setting->{autoload};

    return wantarray ? %{$setting} : $setting;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
