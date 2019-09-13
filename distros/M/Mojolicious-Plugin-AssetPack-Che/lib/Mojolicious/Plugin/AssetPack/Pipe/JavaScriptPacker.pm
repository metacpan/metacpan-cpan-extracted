package Mojolicious::Plugin::AssetPack::Pipe::JavaScriptPacker;
use Mojo::Base 'Mojolicious::Plugin::AssetPack::Pipe';
use Mojolicious::Plugin::AssetPack::Util qw(diag load_module DEBUG);
use JavaScript::Packer;

my $packer = JavaScript::Packer->init();

has config => sub {
  my $self = shift;
  my $config = $self->assetpack->config || $self->assetpack->config({});
  $config->{JavaScriptPacker} ||= {};
};
has minify_opts => sub { { %{shift->config->{minify_opts} ||= {}}, } };#

sub process {
  my ($self, $assets) = @_;
  my $store = $self->assetpack->store;
  
  return unless $self->assetpack->minify;
  
  my $file;
  return $assets->each(
    sub {
      my ($asset, $index) = @_;
      my $attrs = $asset->TO_JSON;
      $attrs->{key}      = 'js-min';
      $attrs->{minified} = 1;
      
      return if $asset->format ne 'js' || $asset->minified;
      return $asset->content($file)->minified(1)
        if $file = $store->load($attrs);
      return unless length(my $content = $asset->content);
      DEBUG && diag "Minify javascript=[%s] with checksum=[%s] and minify_opts=[@{[ %{$self->minify_opts} ]}]", $asset->url, $asset->checksum, ;
      $packer->minify(\$content, $self->minify_opts);
      $asset->content($store->save(\$content, $attrs))->minified(1);
    }
  );
}

1;