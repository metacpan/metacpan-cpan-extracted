package Mojolicious::Plugin::LinkEmbedder::Link::Video::Ted;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML';

has media_id => sub {
  my $self     = shift;
  my $media_id = $self->url->path->[-1];

  $media_id =~ s!\.html$!!;
  $media_id;
};

sub provider_name {'Ted'}

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

sub to_embed {
  my $self     = shift;
  my $media_id = $self->media_id or return $self->SUPER::to_embed;
  my %args     = @_;

  $self->_iframe(
    src    => "//embed.ted.com/talks/$media_id.html",
    class  => 'link-embedder video-ted',
    width  => $args{width} || 560,
    height => $args{height} || 315
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Video::Ted - ted.com video

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
