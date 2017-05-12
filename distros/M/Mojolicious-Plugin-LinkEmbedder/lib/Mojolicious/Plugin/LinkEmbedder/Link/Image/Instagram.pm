package Mojolicious::Plugin::LinkEmbedder::Link::Image::Instagram;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Image';

sub learn {
  my ($self, $c, $cb) = @_;
  my $ua  = $self->{ua};
  my $url = Mojo::URL->new('https://api.instagram.com/oembed');

  $url->query(url => $self->url);

  my $delay = Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $ua->get($url, $delay->begin);
    },
    sub {
      my ($ua, $tx) = @_;
      my $json = $tx->res->json;

      $self->author_name($json->{author_name});
      $self->author_url($json->{author_url});
      $self->media_id($json->{media_id});
      $self->provider_url($json->{provider_url});
      $self->provider_name($json->{provider_name});
      $self->title($json->{title});
      $self->{html} = $json->{html};
      $self->$cb;
    },
  );
  $delay->wait unless $delay->ioloop->is_running;
}

sub to_embed { shift->{html} || '' }

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Image::Instagram - instagram.com image or video

=head1 DESCRIPTION

This class inherits from L<Mojolicious::Plugin::LinkEmbedder::Link::Image>.

=head1 METHODS

=head2 learn

Gets the file imformation from the page meta information

=head2 to_embed

Returns markup.

=head1 SEE ALSO

L<Mojolicious::Plugin::LinkEmbedder>.

=cut
