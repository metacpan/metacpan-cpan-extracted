package Mojolicious::Plugin::AssetPack::Pipe::CombineFile;
use Mojo::Base 'Mojolicious::Plugin::AssetPack::Pipe';
use Mojolicious::Plugin::AssetPack::Util qw(checksum diag DEBUG);
use IO::Compress::Gzip 'gzip';
 
has enabled => sub { shift->assetpack->minify };
has app => sub { shift->assetpack->app };
has config => sub { my $self = shift; my $config = $self->assetpack->config || $self->assetpack->config({}); $config->{CombineFile} ||= {}; };
has serve => sub { shift->assetpack->serve_cb };
has revision => sub { shift->assetpack->revision // '' };

sub new {
  my $self = shift->SUPER::new(@_);
  $self->app->routes->any('/assets/*topic')->methods(qw(HEAD GET))
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
    
    return
      unless $self->enabled || $format ~~ ['html', 'json'];
     
    my $content = $combine->map('content')->map(sub { /\n$/ ? $_ : "$_\n" })->join;
    my $checksum = checksum $topic.$self->revision;#
    
    DEBUG && diag 'Combining assets into "%s" with revision=[%s] checksum[%s] and format[%s].', $topic, $self->revision, $checksum, $format;
 
    push @process,
      $self->assetpack->store->save(\$content, {key => "combine-file", url=>$topic, name=>$checksum, checksum=>$checksum, minified=>1, format=>$format,});
     
    if ($self->config->{gzip} && ($self->config->{gzip}{min_size} || 1000) < $content->size) {
      gzip \($content->to_string) => \(my $gzip), {-Level => 9};
      my $checksum_gzip = checksum($topic.$self->revision.'.gzip');
      DEBUG && diag 'GZIP asset topic=[%s] with revision=[%s] checksum=[%s] and format=[%s] and rate=[%s/%s].', $topic, $self->revision, $checksum, $format, $content->size, length($gzip);
      $self->assetpack->{by_checksum}{$checksum_gzip} = $self->assetpack->store->save(\$gzip, {key => "combine-file-gzip", url=>$topic.'.gzip', name=>$topic.'.gzip', checksum=>$checksum_gzip, minified=>1, format=>$format,});
       
    }
  }
   
  push @process, @other;# preserve assets such as images and font files
  @$assets = @process;
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

Mojolicious::Plugin::AssetPack::Pipe::CombineFile - Store combined asset to cache file instead of memory.


=head1 SYNOPSIS

  $app->plugin('AssetPack::Che' => {
          pipes => [qw(Sass Css JavaScript CombineFile)],
          CombineFile => { gzip => {min_size => 1000},}, # pipe options
          process => {
            'foo.html'=>['templates/foo.html', 'templates/bar.html',],
            ...,
          },
        });

=head1 CONFIG

B<CombineFile> determine config for this pipe module. Hashref has keys for format extensions and also:

B<gzip> - options.


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

Copyright 2016-2018 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut