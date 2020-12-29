package Mojolicious::Plugin::AssetPack::Pipe::CombineFile;
use Mojo::Base 'Mojolicious::Plugin::AssetPack::Pipe';
use Mojolicious::Plugin::AssetPack::Util qw(checksum diag DEBUG);
use IO::Compress::Gzip 'gzip';
use Mojo::Util qw(url_unescape decode);
 
has enabled => sub { shift->assetpack->minify };
has app => sub { shift->assetpack->app };
has config => sub { my $self = shift; my $config = $self->assetpack->config || $self->assetpack->config({}); $config->{CombineFile} ||= {}; };
has serve => sub { shift->assetpack->serve_cb };
has revision => sub { shift->assetpack->revision // '' };


sub new {
  my $self = shift->SUPER::new(@_);
  $self->app->routes->any('/assets/*topic')
    ->methods(qw(HEAD GET))
    ->name('assetpack by topic')
    ->to(cb => $self->_cb_route_by_topic);
  $self;
}

sub process {
  my ($self, $assets) = @_;
  my $collect = Mojo::Collection->new;
  my $topicURL  = Mojo::URL->new($self->topic);
  my $topic = url_unescape($topicURL->path->to_string);#->charset('UTF-8')
  my $format = $topicURL->path->[-1] =~ /\.(\w+)$/ ? lc $1 : '';
  my $checksum = checksum $topic.$self->revision;#name=>decode('UTF-8', $topic)
  my $attrs = {key => "combine-file", url=>$topic, name=>decode('UTF-8', $topic), checksum=>$checksum, minified=>1, format=>$format,};# for store
  my $store = $self->assetpack->store;
  
  return
      unless $self->enabled || $format ~~ ['html', 'json'];
  
  DEBUG && diag "Process topic [%s]", $topic;
  #~ return unless $self->enabled;!!! below
  
  #~ diag "Load [%s]", $self->assetpack->app->dumper($store->load($attrs));
  
  my (@other, $content) = ();
  
  for my $asset (@$assets) {
    next
      if $asset->isa('Mojolicious::Plugin::AssetPack::Asset::Null');
     
    push @$collect, $asset
      and next
      if grep $asset->format eq $_, qw(css js json html);
     
    push @other, $asset;
     
  }
  
  # preserve assets such as images and font files
  @$assets = @other;
  
  if (@$collect) {
    #~ my $format = $collect->[0]->format;
    
    #~ return
      #~ unless $self->enabled || $format ~~ ['html', 'json'];
     
    $content = $collect->map('content')->map(sub { /\n$/ ? $_ : "$_\n" })->join;
    #~ my $checksum = checksum $topic.$self->revision;#
    
    DEBUG && diag 'Combined [%s] assets into "%s" with revision=[%s] checksum[%s] and format[%s].', scalar @$collect, $topic, $self->revision, $checksum, $format;
 
    #~ push @process, 
    Mojo::File::path($self->app->static->paths->[0], 'cache', $topic)->dirname->make_path;
    $store->save(\$content, $attrs);
    
    push @$assets,
      Mojolicious::Plugin::AssetPack::Asset->new(url => $topic)->checksum($checksum)->minified(1)
      ->content($content);
  }

  if ($content && $self->config->{gzip} && ($self->config->{gzip}{min_size} || 1000) < $content->size) {
    gzip \($content->to_string) => \(my $gzip), {-Level => 9};
    my $checksum_gzip = checksum $topic.$self->revision.'.gzip';
    DEBUG && diag 'GZIP combined topic=[%s] with revision=[%s] checksum=[%s] and format=[%s] and rate=[%s/%s].', $topic, $self->revision, $checksum, $format, $content->size, length($gzip);
    $self->assetpack->{by_checksum}{$checksum_gzip} = $store->save(\$gzip, {key => "combine-file-gzip", url=>$topic.'.gzip', name=>decode('UTF-8', $topic.'.gzip'), checksum=>$checksum_gzip, minified=>1, format=>$format,});# name=>decode('UTF-8', $topic.'.gzip')
    #~ push @$assets, 
      #~ Mojolicious::Plugin::AssetPack::Asset->new(url => $topic.'.gzip')->checksum($checksum_gzip)->minified(1)
      #~ ->content($gzip);
     
  }
}

sub _cb_route_by_topic {
  my $self = shift;
  
  return sub {
    my $c  = shift;
    my $topic = $c->stash('topic');
    utf8::encode($topic);
    #~ my $checksum = checksum Mojo::Util::encode('UTF-8', $topic.$self->revision);
    my $checksum = checksum $topic.$self->revision;
    #~ my $checksum = checksum $topic.($self->app->config('version') // $self->app->config('версия') // '');
    DEBUG && diag 'Routing combined topic=[%s] checksum=[%s]', $topic, $checksum;
    $c->stash('name'=>$checksum);
    $c->stash('checksum'=>$checksum);
    return $self->serve->($c);
  };
}
 
1;

=pod

=encoding utf8

Доброго всем

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::AssetPack::Pipe::CombineFile - Store combined and gzipped asset to cache file instead of memory.


=head1 SYNOPSIS

  $app->plugin('AssetPack::Che' => {
          pipes => [qw(Sass Css JavaScript CombineFile)],
          CombineFile => { gzip => {min_size => 1000},}, # pipe options
          process => [
            ['foo.html'=>qw(templates/foo.html templates/bar.html)],
            ...,
          ],
        });

=head1 CONFIG

B<CombineFile> determine config for this pipe module. Hashref keys:

B<gzip> - hashref options.


=head1 ROUTE

B</assets/*topic> will auto place.

Get combined asset by url

  <scheme>//<host>/assets/foo.html

=head1 SEE ALSO

L<Mojolicious::Plugin::AssetPack::Che>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-AssetPack-Che/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016-2020 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut