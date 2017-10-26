package Mojolicious::Plugin::AssetPack::Pipe::CombineFile;
use Mojo::Base 'Mojolicious::Plugin::AssetPack::Pipe';
use Mojolicious::Plugin::AssetPack::Util qw(checksum diag DEBUG);
use IO::Compress::Gzip 'gzip';
 
has enabled => sub { shift->assetpack->minify };
has app => sub { shift->assetpack->app };
has config => sub { my $self = shift; my $config = $self->assetpack->config || $self->assetpack->config({}); $config->{CombineFile} ||= {}; };
has serve => sub { shift->assetpack->serve_cb };

sub new {
  my $self = shift->SUPER::new(@_);
  $self->app->routes->route('/assets/*topic')->via(qw(HEAD GET))
    ->name('assetpack by topic')->to(cb => $self->_cb_route_by_topic);
  $self;
}

sub process {
  my ($self, $assets) = @_;
  my $combine = Mojo::Collection->new;
  my @other;
  my $topic = $self->topic;
 
  #~ return unless $self->enabled;!!! below
 
  for my $asset (@$assets) {
    next
      if $asset->isa('Mojolicious::Plugin::AssetPack::Asset::Null');
    
    push @$combine, $asset
      and next
      if grep $asset->format eq $_, qw(css js json html);
    
    push @other, $asset;
    
  }
  
  my @process = ();
  
  if (@$combine) {
    my $format = $combine->[0]->format;
    #~ my $checksum = checksum $topic;
    my $checksum = checksum $topic.($self->app->config('version') // $self->app->config('версия') // '');#$combine->map('url')->join(':');
    
    #~ warn "Process CombineFile: ", $self->assetpack->app->dumper($combine), $checksum;
    
    #~ my $name = checksum $topic;
    return
      unless $self->enabled || $format ~~ ['html', 'json'];
    
    
    if ($format  eq 'html') {# enabled always
      #~ my $pre_name = $self->config->{html} && $self->config->{html}{pre_name};
      my $url_lines = $self->config->{url_lines};
      
      $combine->map( sub {
        my $url = $_->url;
        return # 
          unless $url_lines && exists $url_lines->{$url};# && !$url_lines->{$url};
        
        my $url_line = $url_lines->{$url};
        utf8::encode($url_line);
        $_->content(sprintf("%s\n%s", $url_line,  $_->content));

      } );
      
      $self->assetpack->store->_types->type(html => ['text/html;charset=UTF-8'])# Restore deleted Jan
        unless $self->assetpack->store->_types->type('html');
      
    } 
    my $content = $combine->map('content')->map(sub { /\n$/ ? $_ : "$_\n" })->join;
   
    DEBUG && diag 'Combining assets into "%s" with checksum[%s] and format[%s].', $topic, $checksum, $format;

    push @process,
      $self->assetpack->store->save(\$content, {key => "combine-file", url=>$topic, name=>$checksum, checksum=>$checksum, minified=>1, format=>$format,});
    
    if ($self->config->{gzip} && ($self->config->{gzip}{min_size} || 1000) < $content->size) {
      gzip \($content->to_string) => \(my $gzip), {-Level => 9};
      my $checksum_gzip = checksum($topic.($self->app->config('version') // $self->app->config('версия') // '').'.gzip');
      DEBUG && diag 'GZIP asset topic=[%s] with checksum=[%s] and format=[%s] and rate=[%s/%s].', $topic, $checksum, $format, $content->size, length($gzip);
      $self->assetpack->{by_checksum}{$checksum_gzip} = $self->assetpack->store->save(\$gzip, {key => "combine-file-gzip", url=>$topic.'.gzip', name=>$topic.'.gzip', checksum=>$checksum_gzip, minified=>1, format=>$format,});
      
    }
  }
  
  push @process, @other;# preserve assets such as images and font files
  @$assets = @process;
}

sub _cb_route_by_topic {
  my $self = shift;
  #~ my $assetpack  =$self->assetpack;
return sub {
  my $c  = shift;
  my $topic = $c->stash('topic');
  $c->stash('name'=>checksum $topic.($self->app->config('version') // $self->app->config('версия') // ''));
  $c->stash('checksum'=>checksum $topic.($self->app->config('version') // $self->app->config('версия') // ''));
  return $self->serve->($c);
  
   #~ my $assets = $assetpack->processed($topic)
    #~ or $c->render(text => "// The asset [$topic] does not exists (not processed) or not found\n", status => 404)
    #~ and return;

  #~ my $format = $assets->[0]->format;
  #~ my $checksum = checksum $topic;#assets->map('checksum')->join(':');
  
  #~ my $asset = $assetpack->store->load({key => "combine-file", url=>$topic, name=>$checksum, checksum => $checksum, minified=>1, format=>$format});#  $format eq 'html' ? 0 : 1
  
  #~ $assetpack->store->serve_asset($c, $asset)
    #~ and return $c->rendered
    #~ if $asset;
 
  #~ $c->render(text => "// No such asset [$topic]\n", status => 404);
};
}
 
1;

=pod

=encoding utf8

Доброго всем

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::AssetPack::Pipe::CombineFile - Store combined asset to cache file instead of memory.


=head1 SYNOPSIS

  $app->plugin('AssetPack::Che' => {
          pipes => [qw(Sass Css JavaScript CombineFile)],
          CombineFile => {html=>{names=>"@@@ ", url_lines=>{'templates/bar.html'=>'t/bar',},},},
          process => {
            'tmpl1.html'=>['templates/foo.html', 'templates/bar.html',],
            ...,
          },
        });

=head1 CONFIG

B<CombineFile> determine config for this pipe module. Hashref has keys for format extensions and also:

B<url_lines> - hashref maps url of asset to some line and place this line as first in content. If not defined thecontent will not change.


=head1 ROUTE

B</assets/*topic> will auto place.

Get combined asset by url

  <scheme>//<host>/assets/tmpl1.html

=head1 SEE ALSO

L<Mojolicious::Plugin::AssetPack::Che>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=cut