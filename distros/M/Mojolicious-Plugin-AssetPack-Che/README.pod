package Mojolicious::Plugin::AssetPack::Che;
use Mojo::Base 'Mojolicious::Plugin::AssetPack';
use Mojolicious::Plugin::AssetPack::Util qw( DEBUG diag checksum );#
use Mojo::URL;

has [qw(config app)] => undef,  weak=>1;
has revision => sub { my $app = shift->app; $app->config('revision') // $app->config('version') // $app->config('версия') // ''; };

sub register {
  my ($self, $app, $config) = @_;
  $self->config($config);
  $self->app($app);
  #~ Scalar::Util::weaken($self->{app});
  Mojo::File->new($app->home->rel_file('assets'), 'cache')->remove_tree({keep_root => 1});
  $self->SUPER::register($app, $config);
  
  # Patch the asset route
  $self->route;
  $app->routes->find('assetpack')->pattern->defaults->{cb} = $self->serve_cb();
  
  $self->store->_types->type(html => ['text/html;charset=UTF-8']);# Restore deleted Jan
  $self->store->default_headers($config->{default_headers})
    if $config->{default_headers};
  
  my $process = $config->{process};
  $self->process(ref eq 'ARRAY' ? @$_ : $_) #($_->[0], map Mojo::URL->new($_), @$_[1..$#$_])
    for ref $process eq 'HASH' ? map([$_=> ref $process->{$_} eq 'ARRAY' ? @{$process->{$_}} : $process->{$_}], keys %$process) : ref $process eq 'ARRAY' ? @$process : ();
  
  return $self;
}

# redefine for nested topics
sub process {
  my ($self, $topic, @input) = @_;
  utf8::encode($topic);
 
  $self->route unless $self->{route_added}++;
  return $self->_process_from_def($topic) unless @input;
 
  my $assets = Mojo::Collection->new;
  for my $url (@input) {
    utf8::encode($url);
    if (my $nested = $self->processed($url)) {
      push @$assets, @$nested;
      next;
    }
    my $asset = Scalar::Util::blessed($url) ? $url : $self->store->asset($url);
    die qq(Could not find input asset "$url" .) unless Scalar::Util::blessed($asset);
    push @$assets, $asset;
  }
 
  return $self->tap(sub { $_->{input}{$topic} = $assets }) if $self->{lazy};
  return $self->_process($topic => $assets);
}

#!!! me frozen at parent version 2.02
sub processed { $_[0]->{by_topic}{$_[1]} }

sub serve_cb {
  my $self= shift;
  return sub {
    my $c = shift;
    my $checksum = $c->stash('checksum');
    if (($c->req->headers->accept_encoding // '') =~ /gzip/i && (my $asset = $self->{by_checksum}{$checksum})) {
      my $checksum_gzip = checksum($asset->url.$self->revision.'.gzip');
      $asset = $self->{by_checksum}{$checksum_gzip}
        and $c->res->headers->content_encoding('gzip')
        and (DEBUG ?  diag("Sent GZIPed topic [%s]", $asset->url) : 1)#$self->minify ? $self->app->log->info('') : 
        and $self->store->serve_asset($c, $asset)
        and return $c->rendered;
    }
    Mojolicious::Plugin::AssetPack::_serve($c, @_);
  };
   
}


=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::AssetPack::Che

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::AssetPack::Che - Child of Mojolicious::Plugin::AssetPack for little bit code.

=head1 DESCRIPTION

Can process assets during register plugin.

Can nested assets.

Can pipe HTML files with L<Mojolicious::Plugin::AssetPack::Pipe::HTML>.

Can compile Vue templates L<Mojolicious::Plugin::AssetPack::Pipe::VueTemplateCompiler>.

Can pipe CSS, JS, JSON, HTML with L<Mojolicious::Plugin::AssetPack::Pipe::CombineFile> into disk cache. This pipe can also gzip and cache gzipped assets.

Since parent version 1.28.

=head1 VERSION

Version 2.106 (test on base Mojolicious::Plugin::AssetPack v2.10)

=cut

our $VERSION = '2.106';


=head1 SYNOPSIS

See parent module L<Mojolicious::Plugin::AssetPack> for full documentation.

On register the plugin  C<config> can contain additional optional argument B<process>:

  $app->plugin('AssetPack::Che',
    pipes => [qw(Sass Css JavaScriptPacker HTML CombineFile)],
    CombineFile => { gzip => {min_size => 1000},}, # pipe options
    HTML => {minify_opts=>{remove_newlines => 1,}},# pipe based on HTML::Packer
    JavaScriptPacker => {minify_opts=>{}},# pipe based on JavaScript::Packer
    process => [
      ['foo.js' => qw(path/to/foo1.js path/to/foo2.js)],
      ['bar.js' => qw(foo.js path/to/bar1.js path/to/bar2.js)], # nested topic
      ['foo.html' => qw(path/to/foo1.html path/to/foo2.html)],
      ...
    ],
  );


=head1 SEE ALSO

L<Mojolicious::Plugin::AssetPack>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-AssetPack-Che/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016-2020 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=cut

1; # End of Mojolicious::Plugin::AssetPack::Che

