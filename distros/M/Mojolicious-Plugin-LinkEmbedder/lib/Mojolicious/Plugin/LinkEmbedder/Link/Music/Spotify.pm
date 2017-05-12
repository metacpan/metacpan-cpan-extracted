package Mojolicious::Plugin::LinkEmbedder::Link::Music::Spotify;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Music';

has media_id => sub {
  my $self = shift;
  my $path = $self->url->path;

  return join ':', spotify => "$path" if $self->url->scheme eq 'spotify';
  return join ':', spotify => @$path  if @$path == 2;
  return '';
};

sub provider_name {'Spotify'}

sub pretty_url {
  my $self     = shift;
  my $url      = Mojo::URL->new('https://open.spotify.com');
  my $media_id = $self->media_id;

  $media_id =~ s!^spotify!!;
  $url->path(join '/', split ':', $media_id);
  $url;
}

sub to_embed {
  my $self     = shift;
  my $media_id = $self->media_id or return $self->SUPER::to_embed;
  my %args     = @_;

  $args{width}  ||= 300;
  $args{height} ||= 80;
  $args{view}   ||= 'coverart';
  $args{theme}  ||= 'white';

  $self->_iframe(
    src    => "https://embed.spotify.com/?uri=$media_id&theme=$args{theme}&view=$args{view}",
    class  => 'link-embedder music-spotify',
    width  => $args{width},
    height => $args{height}
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Music::Spotify - Spotify link

=head1 DESCRIPTION

L<https://developer.spotify.com/technologies/widgets/spotify-play-button/>

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Music>.

=head1 ATTRIBUTES

=head2 media_id

Returns a normalized spotify link.

=head2 provider_name

Returns "Spotify".

=head1 METHODS

=head2 pretty_url

Returns a L<https://open.spotify.com> link with L</media_id>.

=head2 to_embed

Returns the HTML code for an iframe embedding this movie.

=head1 AUTHOR

Marcus Ramberg

=cut
