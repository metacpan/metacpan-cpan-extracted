# TODO
# - Install Module::Start::Flavor::Basic module on setup
# - Support `module-start -install M::S::F::Foo`
# - Finish start_module method
# - Support inheritance in __config__
# - Release IO::All without Spiffy

# XXX - Possible command line options:
# --module=             Explicit module_name
# --flavor=             Explicit flavor
# -add                  Action to add a new module to a dist
# -install              Action to install a plugin
# -setup                Action to (re)do initial setup

# XXX - Plugins to write:
# - Module::Start::Flavor::MSFlavor
# - Module::Start::Flavor::h2xs
# - Module::Start::Flavor::Kwiki
# - Module::Start::Flavor::Catalyst
# - Module::Start::Flavor::Jifty
# - Module::Start::Flavor::JSAN
# - Module::Start::Flavor::PBP

package Module::Start;
use 5.006001;
use strict;
use warnings;
our $VERSION = '0.10';

use base 'Module::Start::Base';
use Class::Field 'field';
use IO::All;
use XXX;

# Module::Start object properties
field 'config', -init => '$self->new_config_object';
field 'files',  -init => '$self->read_data_files("Module::Start")';

# Return usage message for module-start
sub usage {
    <<'.';

Usage: module-start module-name flavor

Example: module-start Catalyst::Model::Funky catalyst

Other Usages:

    module-start -setup
    module-start -add module-name flavor
    module-start -install flavor-plugin-name

.
}

# module-start calls here to interpret and run the command line
sub run {
    my ($self, @args) = @_;

    $self->setup_site_configuration()
      unless $self->config->is_configured;

    $self->exit("module-start is not properly configured")
      unless $self->config->is_configured;

    my ($action, $arg_map) = $self->parse_options(@args);
    my $handler = "handle_$action";
    $self->exit("No support for action '$action'")
      unless $self->can($handler);
#     unless ($module_name && $flavor) {
#         $self->exit($self->usage(), -noExitMsg);
#     }

    $self->$handler($arg_map);
    exit 0;
}

# Start a new module or project from a flavor of template
sub handle_start {
    my ($self, $args) = @_;
    $self->exit("No target module name specified for action 'start'")
      unless $args->{target};
    $self->exit("No project flavor specified for action 'start'")
      unless $args->{flavor};
    my $flavor = $args->{flavor};
    my $base = $self->config->base_dir;
    $self->exit("Invalid flavor '$flavor' specified")
      unless -d "$base/templates/$flavor";

    require Module::Start::Flavor;
    my $module_start_flavor = Module::Start::Flavor->new;
    $module_start_flavor->start_module($args);

    $self->exit(sprintf("%s successfully started",
        $module_start_flavor->config->module_dist_name),
        -noExitMsg,
    );
}

# Create the initial module-start user environment
sub setup_site_configuration {
    my $self = shift;

    print "You don't appear to have module-start configured.\n";
    unless ($self->q("Would you like to do that now?", 'y')) {
        $self->exit("Try running 'module-start -setup'");
    }

    $self->prompt_for_author();
    $self->prompt_for_email();
    $self->config->write_config($self->files->{config});

    require Module::Start::Flavor::Basic;
    Module::Start::Flavor::Basic->new->install_files;

    $self->config->is_configured(1);
}

# Ask user for their full name
sub prompt_for_author {
    my $self = shift;
    my $author = $self->p("What is your full name?");
    $self->config->author_full_name($author);
}

# Ask user for email address
sub prompt_for_email {
    my $self = shift;
    my $email = $self->p("What is your email address?");
    $self->config->author_email_address($email);
}

# Parse command line input
sub parse_options {
    my ($self, @args) = @_;
    my ($target, $flavor) = @args;
    # XXX add more action support here later.
    my $action = 'start';
    my $arg_map = {
        flavor => $flavor,
        target => $target,
    };
    return ($action, $arg_map);
}

1;

__DATA__

=head1 NAME

Module::Start - The Simple/Flexible Way to Create New Modules

=head1 SYNOPSIS

From the command line:

    > # start a Catalyst plugin
    > module-start Catalyst::Model::Funky catalyst
    You don't appear to have module-start configured.
    Would you like to do that now? [Yn] y
    What is your full name? Jimmy James
    What is your email address? jj@example.com
    Can I configure module-start in /home/jj/.module-start? [Yn] y
    Creating /home/jj/.module-start
    Changing to directory /home/jj/.module-start
    Creating ./config
    Installing Default Flavor
    Creating ./templates/basic
    *Error* No flavor 'catalyst' found in /home/jj/.module-start/templates/
    Please install or create a 'catalyst' flavor and try again
    Exiting...
    > cpan Module::Start::Flavor::Catalyst
    ... (cpan installs Module::Start::Flavor::Catalyst) ...
    > module-start -install Module::Start::Flavor::Catalyst
    Installing Flavor 'catalyst'
    Changing to directory /home/jj/.module-start
    Creating ./templates/catalyst
    Module::Start::Flavor::Catalyst successfully installed
    > module-start Catalyst::Model::Funky catalyst
    Creating module distribution Catalyst-Model-Funky
    Changing to directory Catalyst-Model-Funky
    Using 'catalyst' flavor templates
    Creating Makefile.PL
    Creating Changes
    Creating lib/Catalyst/Model/Funky.pm
    Creating t/00_load.t
    Creating README
    Creating MANIFEST
    Catalyst-Model-Funky successfully started

later...

    > cd Catalyst-Model-Funky
    > module-start Catalyst::Model::Funky::Boss catalyst
    Using 'catalyst' flavor templates
    Creating lib/Catalyst/Model/Funkier.pm

=head1 DESCRIPTION

If you are like me, when you think of a new idea, you want to get
started asap. If you are even more like me, your projects come in all
sorts of flavors. In other words, different types of projects need
different types of starting files. Within Perl, you have pure perl
modules, XS modules, Inline modules, Kwiki modules, Catalyst modules,
Jifty modules, Plagger modules, and on and on. You also might have JSAN
modules, Ruby modules, Python modules and PHP modules to write.

Module::Start creates a new module distribution (or any other imaginable
set of project files) in a simple straightforward way. All the
boilerplate files come from a set of templates.

=head1 CONFIGURATION

All the configuration info is either stored in F<~/.module-start/config>,
inferred from your environment, or prompted for.

C<module-start> will automatically configure itself the first time you
run it. If you want to reconfigure it later, run:

    module-start -setup

You are encouraged to edit the contents of the C<module-start> base
directory. To change basic configure information, edit the C<config>
file. To change or edit template flavors, edit the content of the
C<template> directory. Each subdirectory defines a new flavor. You can
set the default flavor in the C<config> file.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See [http://www.perl.com/perl/misc/Artistic.html]

_____[ config ]_________________________________________________________________
author_full_name: [% author_full_name %]
author_email_address: [% author_email_address %]
