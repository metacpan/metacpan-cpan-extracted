package Mojolicious::Plugin::LinkEmbedder::Link::Video::Youtube;

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Video::Youtube - youtube.com link

=head1 DESCRIPTION

L<https://developers.google.com/youtube/player_parameters#Embedding_a_Player>

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML>.

=cut

use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML';

=head1 ATTRIBUTES

=head2 media_id

Returns the "v" query param value from L</url>.

=head2 provider_name

=cut

has media_id => sub { shift->url->query->param('v') || '' };
sub provider_name {'YouTube'}

=head1 METHODS

=head2 learn

=cut

sub learn {
  my ($self, $c, $cb) = @_;

  return $self->SUPER::learn($c, $cb) unless $self->media_id;
  $self->$cb;
  $self;
}

=head2 pretty_url

Returns L</url> without "eurl", "mode" and "search" query params.

=cut

sub pretty_url {
  my $self  = shift;
  my $url   = $self->url->clone;
  my $query = $url->query;

  $query->remove('eurl');
  $query->remove('mode');
  $query->remove('search');
  $url;
}

=head2 to_embed

Returns the HTML code for an iframe embedding this movie.

=cut

sub to_embed {
  my $self     = shift;
  my $media_id = $self->media_id or return $self->SUPER::to_embed;
  my $query    = Mojo::Parameters->new;
  my %args     = @_;

  $query->param(autoplay => 1) if $args{autoplay};

  $args{width}  ||= $self->DEFAULT_VIDEO_WIDTH;
  $args{height} ||= $self->DEFAULT_VIDEO_HEIGHT;

  $self->_iframe(
    src    => "//www.youtube.com/embed/$media_id?$query",
    class  => 'link-embedder video-youtube',
    width  => $args{width},
    height => $args{height}
  );
}

=head1 AUTHOR

Marcus Ramberg

=cut

1;
