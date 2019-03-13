# PiFlash::Plugin - plugin extension interface for PiFlash
# by Ian Kluft

use strict;
use warnings;
use v5.14.0; # require 2011 or newer version of Perl

package PiFlash::Plugin;
$PiFlash::Plugin::VERSION = '0.3.1';
use autodie; # report errors instead of silently continuing ("die" actions are used as exceptions - caught & reported)
use parent 'PiFlash::Object';
use PiFlash::State;
use Module::Pluggable require => 1, search_path => [__PACKAGE__]; # RPM: perl-Module-Pluggable, DEB: libmodule-pluggable-perl

# ABSTRACT: plugin extension interface for PiFlash


# required parameter list
# class method
# used by PiFlash::Object for new() method
sub object_params
{
	return qw(name class);
}

# initialize enabled plugins
# class method
sub init_plugins
{
	# get list of enabled plugins from command line and config file
	my %enabled;
	if (PiFlash::State::has_cli_opt("plugin")) {
		foreach my $plugin ( split(/[^\w:]+/, PiFlash::State::cli_opt("plugin") // "")) {
			next if $plugin eq "";
			$plugin =~ s/^.*:://;
			$enabled{$plugin} = 1;
		}
	}
	if (PiFlash::State::has_config("plugin")) {
		foreach my $plugin ( split(/[^\w:]+/, PiFlash::State::config("plugin") // "")) {
			next if $plugin eq "";
			$plugin =~ s/^.*:://;
			$enabled{$plugin} = 1;
		}
	}

	# for each enabled plugin, allocate state storage, load its config (if any) and run its init method
	my @plugins_available = PiFlash::Plugin->plugins();
	foreach my $plugin (@plugins_available) {
		# fool function that it was called as class method
		# we don't call the subclass' method until we're sure the class is loaded
		# but we know it will inherit the method function from here
		my $modname = PiFlash::Plugin::get_modname($plugin);

		# check if the module is enabled by user from config or CLI
		if (exists $enabled{$modname}) {
			# load the plugin code if its symbol table doesn't already exist (not already defined by a loaded module)
			(defined(*{$plugin."::"})) or require $plugin;

			# verify it's a subclass of PiFlash::Plugin
			if ($plugin->isa("PiFlash::Plugin")) {
				# skip if its object/storage area exists
				if (PiFlash::State::has_plugin($modname)) {
					next;
				}

				# find any YAML documents addressed to this plugin from the config file
				my @data;
				my $plugin_docs = PiFlash::State::plugin("docs");
				if (exists $plugin_docs->{$modname}) {
					push @data, ("config" => $plugin_docs->{$modname});
				}

				# if the plugin class has an init() method, inherited PiFlash::Object->new() will call it
				PiFlash::State::plugin($modname, $plugin->new({name => $modname, class => $plugin, @data}));
			}
		}
	}
}

# derive module name from class name
# class method
sub get_modname
{
	my $class = shift;
	if ($class =~ /^PiFlash::Plugin::([A-Z]\w+)/) {
		return $1;
	}
	return;
}

# find the data/instance for the plugin
# class method
sub get_data
{
	my $class = shift;
	my $modname = $class->get_modname();
	return PiFlash::State::plugin($modname);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PiFlash::Plugin - plugin extension interface for PiFlash

=head1 VERSION

version 0.3.1

=head1 SYNOPSIS

 package PiFlash::Plugin::Example;
 use parent 'PiFlash::Plugin';

 # optional init class method - if defined it will be called upon creation of the plugin object
 sub init
 {
	my $self = shift;

	# perform any object initialization actions here
	$self->{data} = "value";

	# example: subscribe to PiFlash::Hook callbacks
	PiFlash::Hook::add("fs_mount", sub { ... code to run on callback ... });
	PiFlash::Hook::add("post_install", \&function_name);
 }

 # get a reference to the plugin's instance variable & data (same as $self in the init function)
 my $data = PiFlash::Plugin::Example->get_data;

=head1 DESCRIPTION

 The PiFlash::Plugin module has class methods which manage all the plugins and
 instance methods which are the base class inherited by each plugin.  L<PiFlash::Hook>
 can be used to receive callback events at various stages of the PiFlash run.

 To create a plugin for PiFlash, write a new class under the namespace of PiFlash::Plugin,
 such as PiFlash::Plugin::Example.  All PiFlash plugins must be named under and inherit
 from PiFlash::Plugin. Otherwise they will not be enabled or accessible.

 If the plugin class contains or inherits an init() method, it will be called when the
 plugin object is created. You don't need to write a new() routine, and shouldn't, because
 PiFlash::Plugin provides one which must be used by all plugins. That will be called by
 PiFlash during plugin initialization.

=head1 SEE ALSO

L<piflash>, L<PiFlash::State>, L<PiFlash::Hook>, 

=head1 AUTHOR

Ian Kluft <cpan-dev@iankluft.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2019 by Ian Kluft.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
