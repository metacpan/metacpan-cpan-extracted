package Mojolicious::Plugin::LinkEmbedder::Link::Video::Vimeo;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML';

has media_id => sub {
  my $self     = shift;
  my $media_id = $self->url->path->[-1];

  $media_id =~ s!\.html$!!;
  $media_id;
};

sub provider_name {'Vimeo'}

sub learn {
  my ($self, $c, $cb) = @_;

  return $self->SUPER::learn($c, $cb) unless $self->media_id;
  $self->$cb;
  $self;
}

sub to_embed {
  my $self     = shift;
  my $media_id = $self->media_id or return $self->SUPER::to_embed;
  my $src      = Mojo::URL->new('//player.vimeo.com/video/86404451?portrait=0&amp;color=ffffff');
  my %args     = @_;

  $self->_iframe(
    src    => "//player.vimeo.com/video/$media_id?portrait=0&color=ffffff",
    class  => 'link-embedder video-vimeo',
    width  => $args{width} || 500,
    height => $args{height} || 281
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Video::Vimeo - vimeo.com video

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML>.

=head1 ATTRIBUTES

=head2 media_id

Returns the the digit from the url L</url>.

=head2 provider_name

=head1 METHODS

=head2 learn

=head2 to_embed

Returns the HTML code for an iframe embedding this movie.

=head1 AUTHOR

Marcus Ramberg

=cut
