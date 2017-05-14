package Mojolicious::Plugin::LinkEmbedder::Link::Video::Blip;

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Video::Blip - blip.tv link

=head1 DESCRIPTION

L<https://developers.google.com/youtube/player_parameters#Embedding_a_Player>

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML>.

=cut

use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML';

=head1 ATTRIBUTES

=head2 provider_name

=cut

sub provider_name {'Blip'}

=head1 METHODS

=head2 learn

Will fetch the L</url> and extract the L</media_id>.

=cut

sub learn {
  my ($self, $c, $cb) = @_;

  $self->{ua}->get(
    $self->url,
    sub {
      my ($ua, $tx) = @_;
      my $tag = $tx->res->dom->at('[data-analytics="embed"]');

      if ($tag and $tag->{'data-cliptext'}) {

# <iframe src="http://blip.tv/play/hJFxg5qyeAI.x?p=1" width="720" height="433" frameborder="0" allowfullscreen></iframe>
# <embed type="application/x-shockwave-flash" src="http://a.blip.tv/api.swf#hJFxg5qyeAI" style="display:none"></embed>
        $self->media_id($1) if $tag->{'data-cliptext'} =~ m!play/([^\?]+)!;
      }
      elsif ($tx->res->body =~ m!blip\.tv/play/([^\?]+)!) {

        # http://blip.tv/play/ab.c?p=1
        $self->media_id($1);
      }
      else {
        my $dom = $tx->res->dom;
        $self->_tx($tx)->_learn_from_dom($dom) if $dom;
      }

      $self->$cb;
    }
  );

  $self;
}

=head2 to_embed

Returns the HTML code for an iframe embedding this movie.

=cut

sub to_embed {
  my $self     = shift;
  my $media_id = $self->media_id or return $self->SUPER::to_embed;
  my %args     = @_;

  $self->tag(
    iframe => src => "http://blip.tv/play/$media_id?p=1",
    class  => 'link-embedder video-blip',
    width  => $args{width}  || 720,
    height => $args{height} || 433,
    frameborder           => 0,
    allowfullscreen       => undef,
    webkitAllowFullScreen => undef
  );
}

=head1 AUTHOR

Marcus Ramberg

=cut

1;
