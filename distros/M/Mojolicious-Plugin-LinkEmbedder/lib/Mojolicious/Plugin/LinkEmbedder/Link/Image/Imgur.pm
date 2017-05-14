package Mojolicious::Plugin::LinkEmbedder::Link::Image::Imgur;

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Image::Imgur - imgur.com image

=head1 DESCRIPTION

This class inherits from L<Mojolicious::Plugin::LinkEmbedder::Link::Image>.

=cut

use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Image';

=head1 ATTRIBUTES

=head2 media_id

Extracts the media_id from the url directly

=head2 media_url

URL to the image itself, extracted from the retrieved page

=head2 media_title

The title of the image, extracted from the retrieved page

=head2 provider_name

=cut

has media_id => sub { shift->url->path->[0] };
sub provider_name {'Imgur'}
has [qw( media_url media_title )];

=head1 METHODS

=head2 learn

Gets the file imformation from the page meta information

=cut

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
      my $dom = $tx->res->dom;
      $self->media_url(Mojo::URL->new(($dom->at('meta[property="og:image"]') || {})->{content}));
      $self->media_title(($dom->at('meta[property="og:title"]') || {})->{content});
      $self->$cb;
    },
  );
  $delay->wait unless $delay->ioloop->is_running;
}

=head2 to_embed

Returns an img tag.

=cut

sub to_embed {
  my $self = shift;

  $self->tag(
    img => src => $self->media_url,
    alt => $self->media_title || $self->media_url,
    title => $self->media_title
  );
}

=head1 AUTHOR

Joel Berger - C<jberger@cpan.org>

=cut

1;
