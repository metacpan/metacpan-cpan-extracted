package Mojolicious::Plugin::LinkEmbedder::Link::Video::Dbtv;

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Video::Dbtv - dbtv.no video

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Video>.

=cut

use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Video';

=head1 ATTRIBUTES

=head2 media_id

Returns the the digit from the url L</url>.

=head2 provider_name

=cut

has media_id => sub {
  my $self = shift;
  my $url  = $self->url;

  $url->query->param('vid') || $url->path->[-1];
};

sub provider_name {'Dagbladet'}

=head1 METHODS

=head2 learn

=cut

sub learn {
  my ($self, $c, $cb) = @_;

  if ($self->media_id) {
    $self->$cb;
  }
  else {
    $self->SUPER::learn($c, $cb);
  }

  return $self;
}

=head2 pretty_url

Returns a pretty version of the L</url>.

=cut

sub pretty_url {
  my $self     = shift;
  my $media_id = $self->media_id or return $self->SUPER::to_embed;
  my $url      = $self->url->clone;

  $url->fragment(undef);
  $url->query(vid => $media_id);
  $url;
}

=head2 to_embed

Returns the HTML code for an iframe embedding this movie.

=cut

sub to_embed {
  my $self = shift;
  my $src  = Mojo::URL->new('http://beta.dbtv.no/player');
  my %args = @_;

  push @{$src->path}, $self->media_id;
  $src->query({autoplay => $args{autoplay} ? 'true' : 'false'});

  $self->_iframe(
    src    => $src,
    class  => 'link-embedder video-dbtv',
    width  => $args{width} || 980,
    height => $args{height} || 551
  );
}

=head1 AUTHOR

Marcus Ramberg

=cut

1;
