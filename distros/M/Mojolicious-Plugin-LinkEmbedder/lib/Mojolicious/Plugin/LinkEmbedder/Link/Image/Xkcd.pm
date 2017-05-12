package Mojolicious::Plugin::LinkEmbedder::Link::Image::Xkcd;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Image';

has media_id => sub { shift->url->path->[0] };
sub provider_name {'Xkcd'}
has [qw( media_hover_text media_url media_title )];

sub learn {
  my ($self, $c, $cb) = @_;
  my $ua    = $self->{ua};
  my $delay = Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $ua->get($self->url, $delay->begin);
    },
    sub {
      my ($ua, $tx) = @_;
      my $link = $tx->res->dom->at('#comic img') || {};
      $self->media_url(Mojo::URL->new($link->{src})) if $link->{src};
      $self->media_title($link->{alt} || $link->{title} || $self->url);
      $self->media_hover_text($link->{title} || $self->media_title);
      $self->$cb;
    },
  );
  $delay->wait unless $delay->ioloop->is_running;
}

sub to_embed {
  my $self = shift;

  $self->tag(img => src => $self->media_url, alt => $self->media_title, title => $self->media_hover_text);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Image::Xkcd - xkcd.com image/comic

=head1 DESCRIPTION

This class inherits from L<Mojolicious::Plugin::LinkEmbedder::Link::Image>.

=head1 ATTRIBUTES

=head2 media_hover_text

The secret part of xkcd jokes

=head2 media_id

Extracts the media_id from the url directly

=head2 media_url

URL to the image itself, extracted from the retrieved page

=head2 media_title

The title of the image, extracted from the retrieved page

=head2 provider_name

=head1 METHODS

=head2 learn

Gets the file imformation from the page meta information

=head2 to_embed

Returns an img tag.

=head1 AUTHOR

Joel Berger - C<jberger@cpan.org>

=cut
