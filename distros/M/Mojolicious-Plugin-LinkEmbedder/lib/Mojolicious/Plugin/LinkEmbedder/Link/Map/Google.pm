package Mojolicious::Plugin::LinkEmbedder::Link::Map::Google;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link';

has media_id => sub { shift->url->query->param('v') || '' };
sub provider_name {'Google'}

sub learn {
  my ($self, $c, $cb) = @_;

  return $self->SUPER::learn($c, $cb) unless $self->media_id;
  $self->$cb;
  $self;
}

sub pretty_url {
  my $self  = shift;
  my $url   = $self->url->clone;
  my $query = $url->query;

  $url;
}

sub to_embed {
  my $self     = shift;
  my $media_id = $self->media_id or return $self->SUPER::to_embed;
  my $query    = Mojo::Parameters->new;
  my %args     = @_;

#<iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2000.0879317946715!2d10.775201!3d59.91408799999999!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x46416e590a57d99b%3A0x9995766dff5b9442!2sPostkontoret!5e0!3m2!1sen!2sno!4v1433605201155" width="600" height="450" frameborder="0" style="border:0"></iframe>
  $self->_iframe(
    src    => "//www.youtube.com/embed/$media_id?$query",
    class  => 'link-embedder video-youtube',
    width  => $args{width},
    height => $args{height}
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Map::Google - maps.google.com link

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link>.

=head1 ATTRIBUTES

=head2 media_id

=head2 provider_name

"Google".

=head1 METHODS

=head2 learn

=head2 pretty_url

Returns L</url> without "eurl", "mode" and "search" query params.

=head2 to_embed

Returns the HTML code for an iframe embedding this movie.

=head1 SEE ALSO

L<Mojolicious::Plugin::LinkEmbedder>.

=cut
