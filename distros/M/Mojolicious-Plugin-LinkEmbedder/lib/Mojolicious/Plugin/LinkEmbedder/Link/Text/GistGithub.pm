package Mojolicious::Plugin::LinkEmbedder::Link::Text::GistGithub;
use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text';

my $ID = 0;

has media_id => sub {
  shift->url->path =~ m!^(/\w+/\w+)(?:\.js)?$! ? $1 : '';
};

sub provider_name {'Github'}

sub to_embed {
  my $self = shift;
  my $media_id = $self->media_id or return $self->SUPER::to_embed;

  $ID++;

  return $self->tag(
    div => (class => 'link-embedder text-gist-github', id => "link_embedder_text_gist_github_$ID"),
    sub {
      return <<"HERE";
<script>
window.link_embedder_text_gist_github_$ID=function(g){
document.getElementById('link_embedder_text_gist_github_$ID').innerHTML=g.div;
if(window.link_embedder_text_gist_github_styled++)return;
var s=document.createElement('link');s.rel='stylesheet';s.href=g.stylesheet;
document.getElementsByTagName('head')[0].appendChild(s);
};
</script>
<script src="https://gist.github.com$media_id.json?callback=link_embedder_text_gist_github_$ID"></script>
HERE
    },
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Text::GistGithub - gist.github.com link

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Text>.

=head1 OUTPUT HTML

This is an example output:

  <div class="link-embedder text-gist-github" id="link_embedder_text_gist_github_42">$gist</div>
  <script>
    window.link_embedder_text_gist_github_$ID = function(g) {
      delete window.linkembedder_textgistgithub42;
      document.getElementById('link_embedder_text_gist_github_42').innerHTML = g.div;
      if(window.link_embedder_text_gist_github_styled++) return;
      var s = document.createElement('link'); s.rel = 'stylesheet'; s.href = g.stylesheet;
      document.getElementsByTagName('head')[0].appendChild(s);
    };
  </script>
  <script src="https://gist.github.com/$media_id.json?callback=linkembedder_textgistgithub42"></script>

The number "42" is generated dynamically by this module.
C<$gist> is the raw text from the gist.

The GitHub stylesheet will not be included if the container document has
already increased C<window.link_embedder_text_gist_github_styled>.

=head1 ATTRIBUTES

=head2 media_id

  $str = $self->media_id;

Example C<$str>: "/username/123456789".

=head2 provider_name

=head1 METHODS

=head2 to_embed

Returns the HTML code for a script tag that writes the gist.

=head1 AUTHOR

Jan Henning Thorsen

=cut
