package Mojolicious::Plugin::GoogleFontProxy;

# ABSTRACT: a small proxy that can be useful when you use Google fonts in your website

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.03';

our $CSS_URL_FORMAT    = 'https://fonts.googleapis.com/css%s?family=%s';
our $FONT_URL_FORMAT   = 'https://fonts.gstatic.com/s/%s';
our $USER_AGENT_STRING = '';

sub register {
    my ($self, $app, $config) = @_;

    if ( !$config->{no_types} ) {
        $app->types->type( 'woff2' => 'font/woff2' );
        $app->types->type( 'woff'  => 'font/woff' );
        $app->types->type( 'ttf'   => 'font/ttf' );
        $app->types->type( 'otf'   => 'font/opentype' );
    }

    $app->hook(
        after_render => sub {
            my ($c, $content, $format) = @_;

            return if !$format;
            return if $format ne 'html' && $format ne 'css';

            $$content =~ s{
                https://fonts.googleapis.com/css
                    (?<version>[0-9]?)
                    \?family=(?<file>.*?)
                    (?<suffix>['"])
            }{$c->url_for(
                'google-proxy-css',
                version => $+{version} || 0,
                file    => $+{file},
              ) . $+{suffix};
            }xge;
        }
    );

    $app->routes->get( '/google/css/:version/*file' )->to( cb => sub {
        my $c = shift;

        $c->render_later;

        my $version   = $c->param('version') || '';
        my $url       = sprintf $CSS_URL_FORMAT, $version, $c->param('file');
        my $ua_string = $USER_AGENT_STRING || $c->tx->req->headers->user_agent;

        $c->ua->get( $url => { 'User-Agent' => $ua_string } => sub {
            my ($ua, $tx) = @_;

            my $body = $tx->res->body;
            $body    =~ s{
                https?://fonts\.gstatic\.com/s/(.*?)\) \s* format\('(.*?)'\)
            }{$c->url_for('google-proxy-font', file => $1, fformat => $2) . ") format('$2')"}xmseg;

            return $c->render( data => $body, format => 'css' );
        });
    })->name( 'google-proxy-css' );

    $app->routes->get( '/google/font/:fformat/*file' )->to( cb => sub {
        my $c = shift;

        $c->render_later;

        my $url = sprintf $FONT_URL_FORMAT, $c->param('file');

        $c->ua->get( $url => sub {
            my ($ua, $tx) = @_;

            my $body = $tx->res->body;

            return $c->render( data => $body, format => $c->param('fformat') );
        });
    })->name( 'google-proxy-font' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::GoogleFontProxy - a small proxy that can be useful when you use Google fonts in your website

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('GoogleFontProxy');

  # Mojolicious::Lite
  plugin 'GoogleFontProxy';

=head1 DESCRIPTION

L<Mojolicious::Plugin::GoogleFontProxy> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::GoogleFontProxy> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head2 HOOKS INSTALLED

This plugin adds one C<after_render> hook to rewrite all links related to Google webfonts to use the
proxy routes.

=head2 ROUTES INSTALLED

=over 4

=item * C</google/font/*file>

=back

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
