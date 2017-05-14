package Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML;

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Text::HTML - HTML document

=head1 DESCRIPTION

This class inherits from L<Mojolicious::Plugin::LinkEmbedder::Link::Text>.

=cut

use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text';

=head1 ATTRIBUTES

=head2 audio

=head2 canon_url

Holds the content from "og:url" meta tag. Fallback to
L<Mojolicious::Plugin::LinkEmbedder::Link/url>.

=head2 description

Holds the content from "og:description" meta tag.

=head2 image

Holds the content from "og:image" or "og:image:url" meta tag.

=head2 title

Holds the content from "og:title" meta tag or the "title" tag.

=head2 type

Holds the content from "og:type" meta tag.

=head2 video

Holds the content from "og:video" meta tag.

=cut

has audio       => '';
has canon_url   => sub { shift->url };
has description => '';
has image       => '';
has title       => '';
has type        => '';
has video       => '';

=head1 METHODS

=head2 learn

=cut

sub learn {
  my ($self, $c, $cb) = @_;

  $self->ua->get(
    $self->url,
    sub {
      my ($ua, $tx) = @_;
      my $dom = $tx->success ? $tx->res->dom : undef;
      $self->_tx($tx)->_learn_from_dom($dom) if $dom;
      $self->$cb;
    },
  );

  $self;
}

=head2 to_embed

Returns data about the HTML page in a div tag.

=cut

sub to_embed {
  my $self = shift;

  if ($self->image) {
    return $self->tag(
      div => class => 'link-embedder text-html',
      sub {
        return join(
          '',
          $self->tag(
            div => class => 'link-embedder-media',
            sub { $self->tag(img => src => $self->image, alt => $self->title) }
          ),
          $self->tag(h3 => $self->title),
          $self->tag(p  => $self->description),
          $self->tag(
            div => class => 'link-embedder-link',
            sub {
              $self->tag(a => href => $self->canon_url, title => $self->canon_url, $self->canon_url);
            }
          )
        );
      }
    );
  }

  return $self->SUPER::to_embed(@_);
}

sub _learn_from_dom {
  my ($self, $dom) = @_;
  my $e;

  $self->audio($e->{content}) if $e = $dom->at('meta[property="og:audio"]');

  $self->description($e->{content} || $e->{value})
    if $e = $dom->at('meta[property="og:description"]') || $dom->at('meta[name="twitter:description"]');

  $self->image($e->{content} || $e->{value})
    if $e
    = $dom->at('meta[property="og:image"]')
    || $dom->at('meta[property="og:image:url"]')
    || $dom->at('meta[name="twitter:image"]');

  $self->title($e->{content} || $e->{value} || $e->text || '')
    if $e = $dom->at('meta[property="og:title"]') || $dom->at('meta[name="twitter:title"]') || $dom->at('title');

  $self->type($e->{content}) if $e = $dom->at('meta[property="og:type"]') || $dom->at('meta[name="twitter:card"]');
  $self->video($e->{content}) if $e = $dom->at('meta[property="og:video"]');
  $self->canon_url($e->{content} || $e->{value})
    if $e = $dom->at('meta[property="og:url"]') || $dom->at('meta[name="twitter:url"]');
  $self->media_id($self->canon_url) if $self->canon_url and !defined $self->{media_id};
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
