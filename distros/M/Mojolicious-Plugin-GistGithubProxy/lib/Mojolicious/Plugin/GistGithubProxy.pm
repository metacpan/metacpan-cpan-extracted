package Mojolicious::Plugin::GistGithubProxy;

# ABSTRACT: Mojolicious::Plugin::GistGithubProxy - a small proxy that can be useful when you embed gists in your website

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';

our $GIST_URL_FORMAT = 'https://gist.github.com/%s/%s.js?file=%s';

sub register {
    my ($self, $app, $config) = @_;

    $app->hook(
        after_render => sub {
            my ($c, $content, $format) = @_;

            return if !$format;
            return if $format ne 'html';

            $$content =~ s{
                https://gist\.github\.com/(.*?)/(.*?)\.js\?file=(.*?)"
            }{$c->url_for( 'github-proxy-gist', user => $1, id => $2, file => $3 ) . '"';}xge;
        }
    );

    $app->routes->get( '/github/gist-assets/:id' )->to( cb => sub {
        my $c = shift;

        $c->render_later;

        my $url = sprintf q~https://assets-cdn.github.com/assets/gist-embed-%s.css~, $c->param('id');
        $c->ua->get( $url => sub {
            my ($ua, $tx) = @_;

            my $body = $tx->res->body;
            return $c->render( data => $body, format => 'css' );
        });
    })->name( 'github-proxy-gist-asset' );

    $app->routes->get( '/github/gist/:user/:id/*file', $config )->to( cb => sub {
        my $c = shift;

        $c->render_later;

        my $url = sprintf $GIST_URL_FORMAT, $c->param('user'), $c->param('id'), $c->param('file');

        $c->ua->get( $url => sub {
            my ($ua, $tx) = @_;

            my $body = $tx->res->body;
            $body    =~ s{
                https://assets-cdn.github.com/assets/gist-embed-(.*?)\.css
            }{$c->url_for('github-proxy-gist-asset', id => $1)}xmse;

            return $c->render( data => $body, format => 'js' );
        });
    })->name( 'github-proxy-gist' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::GistGithubProxy - Mojolicious::Plugin::GistGithubProxy - a small proxy that can be useful when you embed gists in your website

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('GistGithubProxy');

  # Mojolicious::Lite
  plugin 'GistGithubProxy';

  # a default for the github user
  # useful when you usually embed gists from one person
  plugin 'GistGithubProxy' => { user => 'reneeb' };

=head1 DESCRIPTION

L<Mojolicious::Plugin::GistGithubProxy> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::GistGithubProxy> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head2 HOOKS INSTALLED

This plugin adds one C<after_render> hook to rewrite all links to I<gist.github.com> to use the
proxy routes.

=head2 ROUTES INSTALLED

=over 4

=item * C</github/gist/:user/:id/*file>

=item * C</github/gist/assets/:id>

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
