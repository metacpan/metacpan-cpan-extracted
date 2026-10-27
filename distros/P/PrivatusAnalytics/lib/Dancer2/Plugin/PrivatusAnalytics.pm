package Dancer2::Plugin::PrivatusAnalytics;

use 5.020;
use strict;
use warnings;

use Dancer2::Plugin;
use Encode                        ();
use PrivatusAnalytics             ();
use PrivatusAnalytics::Attributes qw(event_data event_attrs click_data click_attr);

our $VERSION = '1.0.0';

has privatus => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_privatus',
);

plugin_keywords qw(
  privatus_analytics privatus_analytics_tag privatus_event privatus_event_data
  privatus_click privatus_click_data
);

sub _build_privatus {
    my ($plugin) = @_;
    my %settings = %{ $plugin->config || {} };
    $settings{environment} //= _environment($plugin);
    return PrivatusAnalytics->new(%settings);
}

# The app environment. `set environment => ...` changes the config, so read that first.
sub _environment {
    my ($plugin) = @_;
    return $plugin->app->config->{environment} // $plugin->app->environment;
}

sub BUILD {
    my ($plugin) = @_;

    # Template helpers, so [% privatus_analytics_tag() %] works in Template Toolkit.
    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template_render',
            code => sub {
                my ($tokens) = @_;
                $tokens->{privatus_analytics_tag} = sub { $plugin->privatus_analytics_tag(@_) };
                $tokens->{privatus_event}         = sub { $plugin->privatus_event(@_) };
                $tokens->{privatus_click}         = sub { $plugin->privatus_click(@_) };
                return;
            },
        )
    );

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after',
            code => sub { $plugin->_inject(@_) },
        )
    );
    return;
}

sub privatus_analytics {
    my ($plugin) = @_;
    return $plugin->privatus;
}

sub privatus_analytics_tag {
    my ( $plugin, @args ) = @_;
    my %options = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
    my $request = $plugin->app->request;
    $options{request} //= $request;
    $options{nonce}   //= $plugin->_nonce($request);
    return $plugin->privatus->tag(%options);
}

sub privatus_event {
    my ( $plugin, @args ) = @_;
    return event_attrs(@args);
}

sub privatus_event_data {
    my ( $plugin, @args ) = @_;
    return event_data(@args);
}

sub privatus_click {
    my ( $plugin, $name ) = @_;
    $plugin->_warn_click($name);
    return click_attr($name);
}

sub privatus_click_data {
    my ( $plugin, $name ) = @_;
    $plugin->_warn_click($name);
    return click_data($name);
}

# The nonce setting (a string, or a code ref that gets the request), or else the
# csp_nonce var.
sub _nonce {
    my ( $plugin, $request ) = @_;
    my $nonce = $plugin->privatus->nonce;
    $nonce = $nonce->($request) if ref $nonce eq 'CODE';
    return $nonce if defined $nonce;
    return $request ? $request->var('csp_nonce') : undef;
}

sub _warn_click {
    my ( $plugin, $name ) = @_;
    return if PrivatusAnalytics::Attributes::valid_click_name($name);
    return if _environment($plugin) eq 'production';
    $plugin->app->log(
        warning => sprintf '[privatus-analytics] click map name "%s" is not valid. Use letters, '
          . 'digits and _ . : - only, at most 100 characters. Nothing was printed.',
        $name // ''
    );
    return;
}

sub _inject {
    my ( $plugin, $response ) = @_;
    return unless $response && $response->can('content');
    my $request = $plugin->app->request;
    return
      unless $plugin->privatus->wants_inject(
        status           => $response->status,
        content_type     => scalar $response->header('Content-Type'),
        content_encoding => scalar $response->header('Content-Encoding'),
        requested_with   => $request ? scalar $request->header('X-Requested-With') : undef,
      );

    my $html = $response->content;
    return unless defined $html;
    return if index( $html, PrivatusAnalytics::MARKER ) >= 0 || $html !~ m{</head>}i;

    # Setting content encodes it again, so work on characters.
    if ( $response->is_encoded ) {
        my $charset = $response->headers->content_type_charset || 'UTF-8';
        $html = Encode::decode( $charset, $html );
    }
    $response->headers->remove_header('Content-Length');
    $response->content( PrivatusAnalytics::inject_tag( $html, $plugin->privatus_analytics_tag ) );
    return;
}

1;

__END__

=encoding utf8

=head1 NAME

Dancer2::Plugin::PrivatusAnalytics - add Privatus Analytics to a Dancer2 app

=head1 SYNOPSIS

  # config.yml
  plugins:
    PrivatusAnalytics:
      site_id: pa_YOURSITEID
      auto_inject: 1

  # MyApp.pm
  use Dancer2;
  use Dancer2::Plugin::PrivatusAnalytics;

  # In a Template Toolkit layout
  <head>
    [% privatus_analytics_tag() %]
  </head>
  <button [% privatus_event('Report exported', { format => 'csv' }) %]>Export</button>
  <a href="/pricing" [% privatus_click('pricing.cta') %]>See plans</a>

=head1 DESCRIPTION

Adds the cookieless Privatus Analytics script to a L<Dancer2> app. It only
prints HTML. It never sends anything from your server and sets no cookies.

The plugin takes every setting of L<PrivatusAnalytics> from
C<plugins: PrivatusAnalytics:> in your config. The tag is on when the
environment is C<production>, or when you set C<enabled>.

=head1 KEYWORDS

=over 4

=item privatus_analytics_tag(%options)

The script tag HTML. Takes any setting as an override, plus C<props>. Also
available in templates. The C<nonce> setting may be a code ref that gets the
request. Without one, the C<csp_nonce> var is used.

=item privatus_event($name, \%props)

Event attributes as HTML. Also available in templates.

=item privatus_event_data($name, \%props)

The same attributes as a list of pairs.

=item privatus_click($name)

The click map attribute as HTML. Also available in templates. Prints nothing
(and logs a warning outside production) when the name is not valid.

=item privatus_click_data($name)

The click map attribute as a list of pairs.

=item privatus_analytics

The L<PrivatusAnalytics> settings object.

=back

=head1 AUTO INJECT

With C<auto_inject: 1>, an C<after> hook adds the tag just before
C<< </head> >> in HTML responses with status 200. It skips Ajax requests,
encoded responses, pages without a C<< <head> >> and pages that already load
C</js/pa.js>.

=head1 SEE ALSO

L<PrivatusAnalytics>, L<https://privatusanalytics.com/docs>

=head1 LICENSE

MIT. Copyright (c) 2026 Two Phase LLC.

=cut
