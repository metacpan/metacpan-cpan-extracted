package Mojolicious::Plugin::LinkEmbedder::Link::Text;

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Text - Text URL

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link>.

=head2 Example styling

  .link-embedder .text-paste{background: #eee;border: 1px solid #ccc;}
  .link-embedder .text-paste .paste-meta{border-bottom: 1px solid #ccc;padding: 4px;}
  .link-embedder .text-paste pre{padding: 4px;margin:0;max-height: 240px;overflow:auto;}

=cut

use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link';
use Mojo::Util ();

=head1 METHODS

=head2 raw_url

=cut

sub raw_url { shift->url->clone }

=head2 to_embed

Returns the HTML code for a script tag that writes the gist.

=cut

sub to_embed {
  return $_[0]->SUPER::to_embed unless $_[0]->{text};

  my $self     = shift;
  my $media_id = $self->media_id;
  my $text     = $self->{text};

  return <<"  HTML";
<div class="link-embedder text-paste">
  <div class="paste-meta">
    <span>Hosted by</span>
    <a href="http://@{[$self->url->host_port]}">@{[$self->provider_name]}</a>
    <span>-</span>
    <a href="@{[$self->raw_url]}" target="_blank">View raw</a>
  </div>
  <pre>$text</pre>
</div>
  HTML
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
