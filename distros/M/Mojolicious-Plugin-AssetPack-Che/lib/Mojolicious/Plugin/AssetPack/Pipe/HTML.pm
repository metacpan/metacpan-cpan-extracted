package Mojolicious::Plugin::AssetPack::Pipe::HTML;
use Mojo::Base 'Mojolicious::Plugin::AssetPack::Pipe';
use Mojolicious::Plugin::AssetPack::Util qw(diag load_module DEBUG);
use HTML::Packer;

has config => sub { my $self = shift; my $config = $self->assetpack->config || $self->assetpack->config({}); $config->{HTML} ||= {} };
has minify_opts => sub { {remove_comments => 1, remove_newlines => 0, no_compress_comment => 1, html5 => 1, %{shift->config->{minify_opts} ||= {}}, } };# do_javascript => 'clean', do_stylesheet => 'minify' ,

sub process {
  my ($self, $assets) = @_;
  my $store = $self->assetpack->store;
  
  return unless $self->assetpack->minify;
  
  my $file;
  return $assets->each(
    sub {
      my ($asset, $index) = @_;
      my $attrs = $asset->TO_JSON;
      $attrs->{key}      = 'html-min';
      $attrs->{minified} = 1;
      
      return
       if $asset->format ne 'html' || $asset->minified;

      ($file = $store->load($attrs)) && return $asset->content($file)->minified(1);
      length(my $content = $asset->content) || return;
      
      #~ load_module 'HTML::Packer'
        #~ || die qq(Could not load "HTML::Packer": $@);
      DEBUG && diag "Minify asset=[%s] with checksum=[%s] and minify_opts=[@{[ %{$self->minify_opts} ]}]", $asset->url, $asset->checksum, ;
      HTML::Packer::minify(\$content, $self->minify_opts);
      $asset->content($store->save(\$content, $attrs))->minified(1);
    }
  );
}
 
1;