package Mojolicious::Plugin::CascadingConfig;
use Mojo::Base 'Mojolicious::Plugin::Config';

our $VERSION = '0.01';

sub register {
    my ($self, $app, $plugin_conf) = @_;
    die 'Modes must be a non-empty array reference if provided'
        if defined $plugin_conf->{modes} and (not ref $plugin_conf->{modes} eq 'ARRAY' or not @{$plugin_conf->{modes}});

    # Override
    $app->defaults(config => $app->config);
    return $app->config if $app->config->{config_override};

    my @modes = @{$plugin_conf->{modes} || ['production', 'development']};
    my $moniker = $app->moniker;
    my $app_mode = $app->mode;
    my $config = {};
    for my $mode (@modes) {
        $config = $self->_load_and_merge_mode_config($app, $mode, $moniker, $plugin_conf, $config, 1);

        if ($mode eq $app_mode) {
            return $app->config($config)->config;
        }
    }

    $config = $self->_load_and_merge_mode_config($app, $app->mode, $moniker, $plugin_conf, $config, undef);
    return $app->config($config)->config;
}

sub _load_and_merge_mode_config {
    my ($self, $app, $mode, $moniker, $plugin_conf, $config, $require) = @_;

    my $filename = $mode eq 'production' ? "$moniker.conf" : "$moniker.$mode.conf";
    my $file = $app->home->child($filename);

    if (not -e $file) {
        if ($require) {
            die qq{Configuration file "$file" missing, maybe you need to create it?};
        } else {
            return $config;
        }
    }

    my $mode_config = $self->load($file, $plugin_conf, $app);
    return {%$config, %$mode_config};
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::CascadingConfig - Perl-ish configuration plugin that loads and merges config files in order

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojolicious-Plugin-CascadingConfig"><img src="https://travis-ci.org/srchulo/Mojolicious-Plugin-CascadingConfig.svg?branch=master"></a>

=head1 SYNOPSIS

  # myapp.conf for production mode
  {
      # Just a value
      foo => 'bar',

      # Nested data structures are fine too
      baz => ['♥'],

      # You have full access to the application
      music_dir => app->home->child('music'),
  }

  # myapp.development.conf for development mode
  {
      foo => 'not_bar',
  }

  # myapp.staging.conf for staging mode
  {
      baz => ['♫'],
  }


  # Mojolicious in production mode
  my $config = $app->plugin('CascadingConfig');
  say $config->{foo}; # says 'bar'
  say $config->{baz}; # says '♥'

  # Mojolicious::Lite
  my $config = plugin 'Config';
  say $config->{foo}; # says 'bar'

  # foo.html.ep
  %= $config->{foo} # evaluates to 'bar'

  # The configuration is available application-wide
  my $config = app->config;
  say $config->{foo}; # says 'bar'


  # Mojolicious in development mode
  say $config->{foo}; # says 'not_bar'
  say $config->{baz}; # says '♥'


  # Mojolicious in staging mode
  say $config->{foo}; # says 'not_bar';
  say $config->{baz}; # says '♫'

=head1 DESCRIPTION

L<Mojolicious::Plugin::CascadingConfig> is a Perl-ish configuration plugin that loads and merges config files in order, based on L<Mojolicious::Plugin::Config>.

This plugin will load configs in the order specified by L</modes> (ending with the current app L<mode|Mojolicious/mode> if it is not listed in L</modes>), with each new config adding to
the previous config and overwriting any config key/value pairs that existed before. Once the config file is read for the mode matching L<mode|Mojolicious/mode>, the config will be returned.
A file must be found for each mode specified in L</modes>.

Config filenames are expected to be in the form of "L<$moniker|Mojolicious/moniker>.$mode.conf". C<production> is a special mode where the form should be "L<$moniker|Mojolicious/moniker>.conf".

The application object can be accessed via C<$app> or the C<app> function in the config.
L<strict>, L<warnings>, L<utf8> and Perl 5.10 L<features|feature> are
automatically enabled.

If the configuration value C<config_override> has been set in
L<Mojolicious/"config"> when this plugin is loaded, it will not do anything.

=head1 OPTIONS

=head2 modes

  # Mojolicious::Lite

  # ['production', 'development'] is the default.
  # If staging is the current active mode for the app, the config for staging is not required since
  # it is not explicitly listed in modes.
  plugin CascadingConfig => {modes => ['production', 'development']};


  # Here a staging config file is required because it is listed in modes.
  plugin CascadingConfig => {modes => ['production', 'development', 'staging']};

Modes in the order that their config files should be loaded and merged. Any config file that is reached for a mode in L</modes> must exist. In addition to the modes listed,
the current app L<mode|Mojolicious/mode> will be loaded if a config file for it is present once all config files have been loaded for each mode in L</modes>. The config file for
the current app L<mode|Mojolicious/mode> is optional I<only if it is not in> L</modes>.

The default is C<['production', 'development']>.

=head1 METHODS

=head2 register

  my $config = $plugin->register($app);
  my $config = $plugin->register($app, {modes => ['prod', 'dev', 'stage', 'qa']});

Register plugin in L<Mojolicious> application and merge configuration.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious::Plugin::Config>

=item *

L<Mojolicious>

=item *

L<Mojolicious::Guides>

=item *

L<https://mojolicious.org>

=back

=cut
