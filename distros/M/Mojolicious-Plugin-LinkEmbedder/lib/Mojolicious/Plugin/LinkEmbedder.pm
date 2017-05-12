package Mojolicious::Plugin::LinkEmbedder;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON;
use Mojo::UserAgent;
use Mojolicious::Plugin::LinkEmbedder::Link;
use constant DEBUG => $ENV{MOJO_LINKEMBEDDER_DEBUG} || 0;

our $VERSION = '0.24';

has _ua => sub { Mojo::UserAgent->new(max_redirects => 3) };

sub embed_link {
  my ($self, $c, $url, $cb) = @_;

  $url = Mojo::URL->new($url || '') unless ref $url;

  if ($url =~ m!\.(?:jpg|png|gif)\b!i) {
    return $c if $self->_new_link_object(image => $c, {url => $url}, $cb);
  }
  if ($url =~ m!\.(?:mpg|mpeg|mov|mp4|ogv)\b!i) {
    return $c if $self->_new_link_object(video => $c, {url => $url}, $cb);
  }
  if ($url =~ m!^spotify:\w+!i) {
    return $c if $self->_new_link_object('open.spotify' => $c, {url => $url}, $cb);
  }
  if (!$url or !$url->host) {
    return $c->tap(
      $cb,
      Mojolicious::Plugin::LinkEmbedder::Link->new(
        url   => Mojo::URL->new,
        error => {message => 'Invalid input', code => 400,}
      )
    );
  }

  return $c->delay(
    sub {
      my ($delay) = @_;
      $self->_ua->head($url => $delay->begin);
    },
    sub {
      my ($delay, $tx) = @_;
      $self->_learn($c, $tx, $cb);
    }
  );
}

sub _learn {
  my ($self, $c, $tx, $cb) = @_;
  my $ct   = $tx->res->headers->content_type || '';
  my $etag = $tx->res->headers->etag;
  my $url  = $tx->req->url;

  if ($etag and $etag eq ($c->req->headers->etag // '')) {
    return $c->$cb(Mojolicious::Plugin::LinkEmbedder::Link->new(_tx => $tx, etag => $etag));
  }
  if (my $err = $tx->error) {
    return $c->$cb(Mojolicious::Plugin::LinkEmbedder::Link->new(_tx => $tx, error => $err));
  }
  if (my $type = lc $url->host) {
    $type =~ s/^(?:www|my)\.//;
    $type =~ s/\.\w+$//;
    return if $self->_new_link_object($type => $c, {_tx => $tx}, $cb);
  }

  return if $ct =~ m!^image/!     and $self->_new_link_object(image => $c, {url => $url, _tx => $tx}, $cb);
  return if $ct =~ m!^video/!     and $self->_new_link_object(video => $c, {url => $url, _tx => $tx}, $cb);
  return if $ct =~ m!^text/plain! and $self->_new_link_object(text  => $c, {url => $url, _tx => $tx}, $cb);

  if ($ct =~ m!^text/html!) {
    return if $self->_new_link_object(html => $c, {_tx => $tx}, $cb);
  }

  warn "[LINK] New from $ct: Mojolicious::Plugin::LinkEmbedder::Link ($url)\n" if DEBUG;
  $c->$cb(Mojolicious::Plugin::LinkEmbedder::Link->new(_tx => $tx));
}

sub _new_link_object {
  my ($self, $type, $c, $args, $cb) = @_;
  my $class = $self->{classes}{$type} or return;

  warn "[LINK] New from $type: $class\n" if DEBUG;
  eval "require $class;1" or die "Could not require $class: $@";
  local $args->{ua} = $self->_ua;
  my $link = $class->new($args);

  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $link->learn($c, $delay->begin);
    },
    sub {
      my ($delay) = @_;
      do { local $link->{_tx}; local $link->{ua}; warn Data::Dumper::Dumper($link); } if DEBUG and 0;
      $c->$cb($link);
    },
  );

  return $class;
}

sub register {
  my ($self, $app, $config) = @_;

  $self->{classes} = {
    'appear'         => 'Mojolicious::Plugin::LinkEmbedder::Link::Video::AppearIn',
    '2play'          => 'Mojolicious::Plugin::LinkEmbedder::Link::Game::_2play',
    'beta.dbtv'      => 'Mojolicious::Plugin::LinkEmbedder::Link::Video::Dbtv',
    'dbtv'           => 'Mojolicious::Plugin::LinkEmbedder::Link::Video::Dbtv',
    'collegehumor'   => 'Mojolicious::Plugin::LinkEmbedder::Link::Video::Collegehumor',
    'gist.github'    => 'Mojolicious::Plugin::LinkEmbedder::Link::Text::GistGithub',
    'github'         => 'Mojolicious::Plugin::LinkEmbedder::Link::Text::Github',
    'html'           => 'Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML',
    'instagram'    => 'Mojolicious::Plugin::LinkEmbedder::Link::Image::Instagram',
    'image'          => 'Mojolicious::Plugin::LinkEmbedder::Link::Image',
    'imgur'          => 'Mojolicious::Plugin::LinkEmbedder::Link::Image::Imgur',
    'ix'             => 'Mojolicious::Plugin::LinkEmbedder::Link::Text::Ix',
    'metacpan'       => 'Mojolicious::Plugin::LinkEmbedder::Link::Text::Metacpan',
    'open.spotify'   => 'Mojolicious::Plugin::LinkEmbedder::Link::Music::Spotify',
    'paste.scsys.co' => 'Mojolicious::Plugin::LinkEmbedder::Link::Text::PasteScsysCoUk',
    'pastebin'       => 'Mojolicious::Plugin::LinkEmbedder::Link::Text::Pastebin',
    'pastie'         => 'Mojolicious::Plugin::LinkEmbedder::Link::Text::Pastie',
    'ted'            => 'Mojolicious::Plugin::LinkEmbedder::Link::Video::Ted',
    'text'           => 'Mojolicious::Plugin::LinkEmbedder::Link::Text',
    'twitter'        => 'Mojolicious::Plugin::LinkEmbedder::Link::Text::Twitter',
    'travis-ci'      => 'Mojolicious::Plugin::LinkEmbedder::Link::Text::Travis',
    'video'          => 'Mojolicious::Plugin::LinkEmbedder::Link::Video',
    'vimeo'          => 'Mojolicious::Plugin::LinkEmbedder::Link::Video::Vimeo',
    'youtube'        => 'Mojolicious::Plugin::LinkEmbedder::Link::Video::Youtube',
    'xkcd'           => 'Mojolicious::Plugin::LinkEmbedder::Link::Image::Xkcd',
  };

  $app->helper(
    embed_link => sub {
      return $self if @_ == 1;
      return $self->embed_link(@_);
    }
  );

  if (my $route = $config->{route}) {
    $self->_add_action($app, $route, $config);
  }
}

sub _add_action {
  my ($self, $app, $route, $config) = @_;

  $config->{max_age} //= 60;
  $route = $app->routes->route($route) unless ref $route;

  $route->to(
    cb => sub {
      my $c             = shift;
      my $url           = $c->param('url');
      my $if_none_match = $c->req->headers->if_none_match;

      $c->delay(
        sub {
          my ($delay) = @_;
          $c->embed_link($url, $delay->begin);
        },
        sub {
          my ($delay, $link) = @_;
          my $err = $link->error;

          if ($err) {
            $c->res->code($err->{code} || 500);
            $c->respond_to(json => {json => $err}, any => {text => $err->{message} || 'Unknown error.'});
          }
          elsif ($if_none_match and $if_none_match eq $link->etag) {
            $c->res->code(304);
            $c->rendered;
          }
          else {
            $c->res->headers->etag($link->etag) if $link->etag;
            $c->res->headers->cache_control("max-age=$config->{max_age}") if !$link->etag and $config->{max_age};
            $c->respond_to(json => {json => $link}, any => {text => $link->to_embed});
          }
        }
      );
    }
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder - Convert a URL to embedded content

=head1 VERSION

0.24

=head1 DESCRIPTION

This module can transform a URL to an iframe, image or other embeddable
content.

=head1 SYNOPSIS

=head2 Simple version

  use Mojolicious::Lite;
  plugin LinkEmbedder => { route => '/embed' };

=head2 Full control

  plugin 'LinkEmbedder';

  get '/embed' => sub {
    my $c = shift;

    $c->delay(
      sub {
        my ($delay) = @_;
        $c->embed_link($c->param('url'), $delay->begin);
      },
      sub {
        my ($delay, $link) = @_;

        $c->respond_to(
          json => {
            json => {
              media_id => $link->media_id,
              url => $link->url->to_string,
            },
          },
          any => { text => $link->to_embed }
        );
      }
    );
  };

=head2 Example with caching

  plugin 'LinkEmbedder';

  get '/embed' => sub {
    my $c = shift;
    my $url = $c->param('url');
    my $cached;

    $c->delay(
      sub {
        my ($delay) = @_;
        return $delay->pass($cached) if $cached = $c->cache->get($url);
        return $c->embed_link($c->param('url'), $delay->begin);
      },
      sub {
        my ($delay, $link) = @_;

        $link = $link->TO_JSON if UNIVERSAL::can($link, 'TO_JSON');
        $c->cache->set($url => $link);

        $c->respond_to(
          json => {
            json => {
              media_id => $link->{media_id},
              url => $link->{url},
            },
          },
          any => { text => $link->{html} }
        );
      }
    );
  };

=head1 SUPPORTED LINKS

=over 4

=item * L<Mojolicious::Plugin::LinkEmbedder::Link>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Game::_2play>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Image>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Image::Imgur>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Image::Instagram>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Image::Xkcd>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Video>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Music::Spotify>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Video::AppearIn>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Video::Dbtv>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Video::Collegehumor>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Video::Dagbladet>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Video::Ted>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Video::Vimeo>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Video::Youtube>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Text>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Text::Github>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Text::GistGithub>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Text::Ix>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Text::Metacpan>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Text::Pastebin>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Text::Pastie>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Text::PasteScsysCoUk>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Text::Twitter>

=item * L<Mojolicious::Plugin::LinkEmbedder::Link::Text::Travis>

=back

=head1 METHODS

=head2 embed_link

See L</SYNOPSIS>.

=head2 register

  $app->plugin('LinkEmbedder' => \%config);

Will register the L</embed_link> helper which creates new objects from
L<Mojolicious::Plugin::LinkEmbedder::Default>. C<%config> is optional but can
contain:

=over 4

=item * route => $str|$obj

Use this if you want to have the default handler to do link embedding.
The default handler is shown in L</SYNOPSIS>. C<$str> is just a path,
while C<$obj> is a L<Mojolicious::Routes::Route> object.

=back

=head1 DISCLAIMER

This module might embed javascript from 3rd party services.

Any damage caused by either evil DNS takeover or malicious code inside
the javascript is not taken into account by this module.

If you are aware of any security risks, then please let us know.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

Joel Berger, jberger@cpan.org

Marcus Ramberg - C<mramberg@cpan.org>

=cut
