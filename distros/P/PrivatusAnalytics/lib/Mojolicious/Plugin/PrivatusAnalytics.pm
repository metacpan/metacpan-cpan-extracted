package Mojolicious::Plugin::PrivatusAnalytics;

use 5.020;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream              ();
use Mojo::Util                    qw(encode);
use PrivatusAnalytics             ();
use PrivatusAnalytics::Attributes qw(event_data click_data to_html);

our $VERSION = '1.0.0';

sub register {
    my ( $self, $app, $conf ) = @_;
    my %conf = ( %{ $app->config->{privatus_analytics} || {} }, %{ $conf || {} } );
    $conf{environment} //= $app->mode;
    my $pa = PrivatusAnalytics->new(%conf);

    $app->helper( privatus_analytics => sub { $pa } );

    $app->helper(
        privatus_analytics_tag => sub {
            my ( $c, @args ) = @_;
            my %options = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
            $options{request} //= $c;
            $options{nonce}   //= _nonce( $pa, $c );
            return Mojo::ByteStream->new( $pa->tag(%options) );
        }
    );

    $app->helper(
        privatus_event => sub {
            my ( $c, @args ) = @_;
            return Mojo::ByteStream->new( to_html( event_data(@args) ) );
        }
    );
    $app->helper(
        privatus_event_data => sub {
            my ( $c, @args ) = @_;
            return event_data(@args);
        }
    );
    $app->helper(
        privatus_click => sub {
            my ( $c, $name ) = @_;
            return Mojo::ByteStream->new( to_html( _click( $app, $name ) ) );
        }
    );
    $app->helper(
        privatus_click_data => sub {
            my ( $c, $name ) = @_;
            return _click( $app, $name );
        }
    );

    $app->hook(
        after_render => sub {
            my ( $c, $output, $format ) = @_;
            return unless ( $format // '' ) eq 'html' && defined ${$output};
            my $headers = $c->res->headers;
            return
              unless $pa->wants_inject(
                status           => $c->stash('status')    // 200,
                content_type     => $headers->content_type // 'text/html',
                content_encoding => $headers->content_encoding,
                requested_with   => $c->req->headers->header('X-Requested-With'),
              );
            return if index( ${$output}, PrivatusAnalytics::MARKER ) >= 0 || ${$output} !~ m{</head>}i;

            # The rendered output is already encoded, so the tag is encoded the same way.
            my $tag      = $c->privatus_analytics_tag->to_string;
            my $encoding = $app->renderer->encoding;
            $tag = encode( $encoding, $tag ) if $encoding && !utf8::is_utf8( ${$output} );
            ${$output} = PrivatusAnalytics::inject_tag( ${$output}, $tag );
        }
    );
    return $pa;
}

# The nonce: the plugin setting (a string, or a code ref that gets the controller),
# or else the csp_nonce stash value.
sub _nonce {
    my ( $pa, $c ) = @_;
    my $nonce = $pa->nonce;
    $nonce = $nonce->($c) if ref $nonce eq 'CODE';
    return $nonce // $c->stash('csp_nonce');
}

sub _click {
    my ( $app, $name ) = @_;
    my @data = click_data($name);
    if ( !@data && $app->mode ne 'production' ) {
        $app->log->warn(
            sprintf '[privatus-analytics] click map name "%s" is not valid. Use letters, '
              . 'digits and _ . : - only, at most 100 characters. Nothing was printed.',
            $name // ''
        );
    }
    return @data;
}

1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::PrivatusAnalytics - add Privatus Analytics to a Mojolicious app

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin(PrivatusAnalytics => { site_id => 'pa_YOURSITEID' });

  # Mojolicious::Lite
  plugin PrivatusAnalytics => { site_id => 'pa_YOURSITEID', auto_inject => 1 };

  # In a template
  <head>
    %= privatus_analytics_tag
  </head>
  <button <%= privatus_event 'Report exported', { format => 'csv' } %>>Export</button>
  <a href="/pricing" <%= privatus_click 'pricing.cta' %>>See plans</a>

=head1 DESCRIPTION

Adds the cookieless Privatus Analytics script to a L<Mojolicious> app. It only
prints HTML. It never sends anything from your server and sets no cookies.

The plugin takes every setting of L<PrivatusAnalytics>. Settings in the app
config under C<privatus_analytics> are read too. The tag is on when the app
mode is C<production>, or when you set C<enabled>.

=head1 HELPERS

=over 4

=item privatus_analytics_tag(%options)

The script tag, as a L<Mojo::ByteStream>. Takes any setting as an override,
plus C<props>. The C<nonce> setting may be a code ref that gets the
controller. Without one, the C<csp_nonce> stash value is used.

=item privatus_event($name, \%props)

Event attributes as safe HTML.

=item privatus_event_data($name, \%props)

The same attributes as a list of pairs, for the C<tag> and C<link_to> helpers:

  %= link_to Guide => '/guide', privatus_event_data('Guide opened')

=item privatus_click($name)

The click map attribute as safe HTML. Prints nothing (and logs a warning
outside production) when the name is not valid.

=item privatus_click_data($name)

The click map attribute as a list of pairs.

=item privatus_analytics

The L<PrivatusAnalytics> settings object.

=back

=head1 AUTO INJECT

With C<< auto_inject => 1 >>, an C<after_render> hook adds the tag just before
C<< </head> >> in HTML pages with status 200. It skips Ajax requests, pages
without a C<< <head> >> and pages that already load C</js/pa.js>.

=head1 SEE ALSO

L<PrivatusAnalytics>, L<https://privatusanalytics.com/docs>

=head1 LICENSE

MIT. Copyright (c) 2026 Two Phase LLC.

=cut
