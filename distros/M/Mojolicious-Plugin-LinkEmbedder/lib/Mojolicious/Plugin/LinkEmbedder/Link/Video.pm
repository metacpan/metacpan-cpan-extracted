package Mojolicious::Plugin::LinkEmbedder::Link::Video;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link';

sub to_embed {
  my $self = shift;
  my $url  = $self->url;
  my $type = $url->path =~ /\.(\w+)$/ ? $1 : 'unknown';
  my %args = @_;
  my @extra;

  $type = $self->_types->type($type) || "unknown/$type";
  $args{height} ||= $self->DEFAULT_VIDEO_HEIGHT;
  $args{width}  ||= $self->DEFAULT_VIDEO_WIDTH;

  local $" = ' ';
  push @extra, 'autoplay' if $args{autoplay};
  unshift @extra, '' if @extra;

  return $self->tag(
    video  => width => $args{width},
    height => $args{height},
    class  => 'link-embedder',
    @extra,
    preload  => 'metadata',
    controls => undef,
    sub {
      return join('',
        $self->tag(source => src   => $url,    type => $type),
        $self->tag(p      => class => 'alert', 'Your browser does not support the video tag.'));
    }
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Video - Video URL

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link>.

=head1 METHODS

=head2 to_embed

TODO. (It returns a video tag for now)

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
