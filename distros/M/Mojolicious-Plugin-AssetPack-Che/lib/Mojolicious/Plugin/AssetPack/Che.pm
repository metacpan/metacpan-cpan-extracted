package Mojolicious::Plugin::AssetPack::Che;
use Mojo::Base 'Mojolicious::Plugin::AssetPack';
use Mojolicious::Plugin::AssetPack::Util qw( checksum );
use Mojo::URL;


has [qw(app config)];
has revision => sub { my $app = shift->app; $app->config('revision') // $app->config('version') // $app->config('версия') // ''; };

sub register {
  my ($self, $app, $config) = @_;
  $self->config($config);
  $self->app($app);
  Scalar::Util::weaken($self->{app});
  $self->SUPER::register($app, $config);
  
  # Patch the asset route
  $self->route;
  $app->routes->find('assetpack')->pattern->defaults->{cb} = $self->serve_cb();
  
  my $process = $config->{process};
  $self->process(ref eq 'ARRAY' ? @$_ : $_) #($_->[0], map Mojo::URL->new($_), @$_[1..$#$_])
    for ref $process eq 'HASH' ? map([$_=> ref $process->{$_} eq 'ARRAY' ? @{$process->{$_}} : $process->{$_}], keys %$process) : ref $process eq 'ARRAY' ? @$process : ();
  
  return $self;
}

sub process {# redefine for nested topics
  my ($self, $topic, @input) = @_;
  utf8::encode($topic);
 
  $self->route unless $self->{route_added}++;
  return $self->_process_from_def($topic) unless @input;
 
  # TODO: The idea with blessed($_) is that maybe the user can pass inn
  # Mojolicious::Plugin::AssetPack::Sprites object, with images to generate
  # CSS from?
  my $assets = Mojo::Collection->new;
  for my $url (@input) {
    utf8::encode($url);
    if (my $nested = $self->processed($url)) {
      push @$assets, @$nested;
      next;
    }
    my $asset = Scalar::Util::blessed($url) ? $url : $self->store->asset($url);
    die qq(Could not find input asset "$url".) unless Scalar::Util::blessed($asset);
    push @$assets, $asset;
  }
 
  return $self->tap(sub { $_->{input}{$topic} = $assets }) if $self->{lazy};
  return $self->_process($topic => $assets);
}

sub serve_cb {
  my $self= shift;
  return sub {
    my $c = shift;
    my $checksum = $c->stash('checksum');
    my $topic_checksum = checksum Mojo::Util::encode 'UTF-8', $c->stash('topic').$self->revision;
    my $topic_checksum_gzip = checksum Mojo::Util::encode 'UTF-8', $c->stash('topic').$self->revision.'.gzip';
    if ((my $asset = $self->{by_checksum}{$topic_checksum_gzip}) && ($c->req->headers->accept_encoding // '') =~ /gzip/i) {# 
      #~ warn "serve_cb", $c->dumper($asset);
      #~ my $cfconfig=$self->config->{CombineFile} || {};
      #~ $self->app->log->debug($c->dumper($asset));
      #~ my $checksum_gzip = checksum(Mojo::Util::encode 'UTF-8', $asset->url.$self->revision.'.gzip');#
      #~ $asset = $self->{by_checksum}{$checksum_gzip}
      $c->res->headers->content_encoding('gzip');
      $self->store->serve_asset($c, $asset);
      return $c->rendered;
    } elsif ($asset = $self->{by_checksum}{$checksum} || $self->{by_checksum}{$topic_checksum}) {
      $self->store->serve_asset($c, $asset);
      return $c->rendered;
      
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

Can pipe HTML files with L<Mojolicious::Plugin::AssetPack::Pipe::HTML>.

Can pipe CSS, JS, JSON, HTML with L<Mojolicious::Plugin::AssetPack::Pipe::CombineFile> into disk cache. This pipe can also gzip and cache gzipped assets.

Since version 1.28.

=head1 VERSION

Version 2.023 (test on base Mojolicious::Plugin::AssetPack v2.02)

=cut

our $VERSION = '2.023';


=head1 SYNOPSIS

See parent module L<Mojolicious::Plugin::AssetPack> for full documentation.

On register the plugin  C<config> can contain additional optional argument B<process>:

  $app->plugin('AssetPack::Che',
    pipes => [qw(Sass Css JavaScript HTML CombineFile)],
    CombineFile => { gzip => {min_size => 1000},}, # pipe options
    HTML => {minify_opts=>{remove_newlines => 1,}},# pipe based on HTML::Packer
    process => [
      ['foo.js'=>qw(path/to/foo1.js path/to/foo2.js)],
      ['foo.html'=>qw(path/to/foo1.html path/to/foo2.html)],
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

Copyright 2016-2018 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=cut

1; # End of Mojolicious::Plugin::AssetPack::Che

