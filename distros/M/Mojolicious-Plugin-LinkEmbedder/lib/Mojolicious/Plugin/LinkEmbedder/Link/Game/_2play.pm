package Mojolicious::Plugin::LinkEmbedder::Link::Game::_2play;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Game';

has media_id => sub { shift->url->path->[2] || '' };
sub provider_name {'2play'}
sub _js_embed_url {'http://video.nettavisen.no/javascripts/embed.js'}

sub to_embed {
  my $self = shift;
  my $media_id = $self->media_id or return $self->SUPER::to_embed;

  qq(<script src="@{[$self->_js_embed_url]}"></script><script>video_embed("$media_id",1)</script>);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Game::_2play - 2play.com link

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Game>.

=head1 ATTRIBUTES

=head2 media_id

Returns the second path segment from L</url>.

=head2 provider_name

=head1 METHODS

=head2 to_embed

Returns the HTML code for an iframe embedding this movie.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

Marcus Ramberg - C<mramberg@cpan.org>

=cut
