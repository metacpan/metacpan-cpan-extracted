NAME
    Mojolicious::Plugin::INIConfig::Extended - Mojolicious Plugin to
    overload a Configuration

CAUTION
    This module is alpha release. the feature will be changed without
    warnings.

SYNOPSIS
      # myapp.ini
      [section]
      foo=bar
      music_dir=<%= app->home->rel_dir('music') %>

      # Mojolicious
      my $config = $self->plugin('INIConfig::Extended');

      # Mojolicious::Lite
      my $config = plugin 'INIConfig::Extended';

      # foo.html.ep
      %= $config->{section}{foo}

      # The configuration is available application wide
      my $config = app->config;

      # Everything can be customized with options
      my $config = plugin INIConfig::Extended => {file => '/etc/myapp.conf'};

      $self->plugin('INIConfig::Extended', {
         base_config => $self->app->config,
        config_files => \@config_files });

      If no $self->app->config already exists, you can provide an empty hashref {} instead 
      and this ought to work, but please see the KNOWN BUGS section below.

DESCRIPTION
    Mojolicious-Plugin-INIConfig-Extended provides configuration inheritance
    and overloading

    Mojolicious::Plugin::INIConfig is a INI configuration plugin that
    preprocesses its input with Mojo::Template.

    The application object can be accessed via $app or the "app" function.
    You can extend the normal config file "myapp.ini" with "mode" specific
    ones like "myapp.$mode.ini". A default configuration filename will be
    generated from the value of "moniker" in Mojolicious.

    This ::INIConfig::Extended module seeks to do for
    Mojolicious::Plugin::INIConfig, what my earlier cpan contribution,
    Config::Simple::Extended did for Config::Simple.

    The code here barely refactors the INIConfig plugin's ->register method
    to route to a new ->inherit method when appropriate. I copied over the
    test suite from ::INIConfig and ::INIConfig::Extended introduces no
    regression and may be used as a drop in replacement.

    v0.02 now records a default.config_files key in the returned configuration 
    hash which returns an array ref of files used to build the configuration.  

OPTIONS
    Mojolicious::Plugin::INIConfig::Extended inherits all options from
    Mojolicious::Plugin::INIConfig and supports the following new ones.

  base_config
      # Mojolicious::Lite
      plugin Config => { base_config => $app->cfg, file => 'conf.d/example.com/site_config.ini' };

    Overload a base configuration with key->value pairs from an additional
    configuration file.

  config_files
      # Mojolicious::Lite
      plugin Config => { config_files => [ qw{ conf.d/base_config.ini conf.d/example.com/site_config.ini ] };

    Build configuration from an ordered list of configuration files,
    subsequent ones overloading preceeding ones.

METHODS
    Mojolicious::Plugin::INIConfig::Extended inherits all methods from
    Mojolicious::Plugin::INIConfig and implements the following new ones.

  inherit
      $self->plugin('INIConfig::Extended', {
         base_config => $self->app->config,
        config_files => \@config_files });

    Overload a Config::Tiny configuration, return it as $app->cfg

DEVELOPER NOTES
    To package and publish this project to cpan

    PERL5LIB="$PWD/local/lib/perl5" perl -I /opt/local/milla/lib/perl5 /opt/local/milla/bin/dzil build
    PERL5LIB="$PWD/local/lib/perl5" perl -I /opt/local/milla/lib/perl5 /opt/local/milla/bin/dzil release 

BACKWARDS COMPATIBILITY POLICY
    At least for now, in its early stages of development, this module should
    be considered experimental. EXPERIMENTAL features may be changed without
    warnings.

KNOWN BUGS
    For the moment, as currently implemented, the ->inherit method, although
    it expects both a base_config (hash ref) and a config_files (array ref),
    and its design anticipates in the future processing that array of config
    files to overload the configuration; it currently only processes the
    first ini file in that array. All other config files will be ignored.

    Patches with tests are welcome in the form of a Pull Request. Or with
    patience I will soon enough encounter a use case which should make me
    return to this project and to complete the implementation of its
    original design. For the moment, though, this serves my immediate needs.
    For clues on how to invoke the ->inherit method to overcome this
    limitation please see `perldoc Config::Simple::Extended`.

BUGS
    Please tell me bugs if you find bug.

    "<hesco at yourmessagedelivered.com>"

    <http://github.com/yuki-kimoto/Mojolicious-Plugin-INIConfig>
    <http://github.com/hesco/Mojolicious-Plugin-INIConfig-Extended>

COPYRIGHT & LICENSE
    Copyright 2015-2024 Hugh Esco and YMD Partners LLC, all rights reserved.

    with appreciation to the original author for their work: 
    Copyright 2013 Yuki Kimoto, all rights reserved.

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

