package Mojolicious::Plugin::Localize::Preference;
use Mojo::Base 'Mojolicious::Plugin';

# Register plugin
sub register {


  # Probably add as a core helper!
  # Establish helpers
  $mojo->helper(
    'localize.preference' => sub {
      my $c = shift;

      my $l = $c->localize;
      my $d = $l->dictionary;
      my $locale = $l->locale;

      my @pref = _get_pref_keys($c, $d->{'_'}, $stash);
      
      # Check all locales
      foreach (@$locale) {
        return $_ if exists $d->{$_};
      };

      # Return default
      return $
    }
  );
};

1;

=pod

=head1 NAME

Mojolicious::Plugin::Localize::Preference - Get the preferred key on a dictionary level


=head1 SYNOPSIS

  # Register plugin with a dictionary in Mojolicious::Lite
  plugin Localize => {
    dict => {
      welcome => {
        '_' => sub { $_->locale },
        -en => 'Welcome!',
        de => 'Willkommen!',
        fr => 'Bonjour!'
      }
    }
  };

  # Optionally create language depending routes
  under '/:lang' => { lang => '' } => sub {
    my $c = shift;

    # Prefer the chosen language
    $c->localize->locale($c->stash('lang')) if $c->stash('lang');
    return 1;
  };

  # Set language depending routes
  get '/' => sub {
    shift->render('<%= loc "welcome" %>');
  };


=head1 DESCRIPTION

L<Mojolicious::Plugin::Localize::Locale> detects preferred languages
of a user agent's request to be used as preferred keys in dictionaries for
L<Mojolicious::Plugin::Localize>.


=head1 METHODS

L<Mojolicious::Plugin::Localize::Locale> inherits all methods
from L<Mojolicious::Plugin> and implements the following
new ones.


=head2 register

  # Mojolicious
  $mojo->plugin('Localize::Locale');

  # Mojolicious::Lite
  plugin 'Localize::Locale';

Called when registering the plugin.
The plugin is registered by L<Mojolicious::Plugin::Localize> by default.


=head1 HELPERS

=head2 localize->locale

  # Return the requested languages
  my $lang = $c->localize->locale;
  # $lang = ['en-us', 'en']

  # Set a preferred language
  $lang = $c->localize->locale('de-DE');
  # $lang = ['de-de', 'de', 'en-us', 'en']

Returns an array reference of locales the user preferred based on
the request headers. If language notations following
L<RFC 3066|http://www.ietf.org/rfc/rfc3066.txt>
are passed, these will be preferred over detected languages
(e.g. based on the URL path, TLD, GeoIP, or user preferences coming from a database).

All short names will be lower cased and specific languages will be followed
by the short name of their super languages.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Localize


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2018, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut

