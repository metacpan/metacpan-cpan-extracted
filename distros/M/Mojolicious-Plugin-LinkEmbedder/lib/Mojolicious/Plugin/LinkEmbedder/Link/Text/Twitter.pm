package Mojolicious::Plugin::LinkEmbedder::Link::Text::Twitter;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text';

has media_id => sub {
  my $self = shift;
  my $path = $self->url->path;

  return $1 if $path =~ m!^/(\w+/status/\w+)/?$!;
  return $1 if $path =~ m!^/(\w+/status/\w+)/photo/\w+/?$!;
  return '';
};

sub provider_name {'Twitter'}

sub to_embed {
  my $self     = shift;
  my $media_id = $self->media_id or return $self->SUPER::to_embed;
  my %args     = @_;

  return $self->tag(
    div => class => 'link-embedder text-twitter',
    sub {
      join(
        '',
        $self->tag(
          blockquote => class => 'twitter-tweet',
          lang => $args{lang} || 'en',
          data => {conversation => $args{conversation} || 'none'},
          sub {
            $self->tag(a => href => "https://twitter.com/$media_id", "Loading $media_id...");
          }
        ),
        '<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>'
      );
    }
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Text::Twitter - twitter.com link

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Text>.

=head1 ATTRIBUTES

=head2 media_id

  $str = $self->media_id;

Example C<$str>: "/username/status/123456789".

=head2 provider_name

=head1 METHODS

=head2 to_embed

Returns the HTML code for javascript embedding this tweet.

=head1 AUTHOR

Jan Henning Thorsen

=cut
