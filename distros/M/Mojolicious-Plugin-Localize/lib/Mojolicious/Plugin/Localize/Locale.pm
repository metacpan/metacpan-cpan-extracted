package Mojolicious::Plugin::Localize::Locale;
use Mojo::Base 'Mojolicious::Plugin';
use I18N::LangTags qw/implicate_supers/;
use I18N::LangTags::Detect;
use List::MoreUtils 'uniq';

# Register plugin
sub register {
  my ($self, $mojo) = @_;

  # Establish helpers
  $mojo->helper(
    'localize.locale' => sub {
      my $c = shift;

      # Delete preference
      if (@_ != 0) {
        delete $c->stash->{'localize.preference'};
      };

      # Already requested from stash
      if ($c->stash('localize.locale')) {

        # Return cached values
        return $c->stash('localize.locale') if @_ == 0;

        # Prepend override values
        $c->stash('localize.locale' => my $lang = [
          uniq(implicate_supers(map {lc} @_), @{ $c->stash('localize.locale')})
        ]);

        return $lang;
      };

      # Get languages from request headers
      my @langs = implicate_supers(
        I18N::LangTags::Detect->http_accept_langs(
          $c->req->headers->accept_language
        ));

      # Prepend override values
      unshift(@langs, implicate_supers(map {lc} @_)) if @_ > 0;

      # Return lang stash
      $c->stash('localize.locale' => my $lang = [ uniq(@langs) ]);
      return $lang;
    }
  );
};


1;


=pod

=head1 NAME

Mojolicious::Plugin::Localize::Locale - Localize Based on Requested Locales


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

Copyright (C) 2014-2017, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
