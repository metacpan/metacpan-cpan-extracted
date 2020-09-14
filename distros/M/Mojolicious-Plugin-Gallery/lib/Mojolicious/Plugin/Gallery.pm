package Mojolicious::Plugin::Gallery;

use strict;
use 5.008_005;
our $VERSION = '0.06';

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::File 'path';
use File::Basename;
use YAML::XS;
use DDP;

sub register {
  my ($self, $app) = @_;
  my $config = $app->config->{gallery};

  my $path = path $config->{main_path};
  my $galleries = [];

  my $items = $path->list({dir => 1});
  for my $gallery ($items->each) {
    my $meta_source = $gallery->list->first(qr/yml|yaml/);
    die 'meta is undef' unless $meta_source;
    my $meta = Load $meta_source->slurp;
    next unless $meta->{show};
    my $gallery_name = $gallery->basename;
    my $gallery_path = $gallery->to_string;
    my $photos_path  = sprintf '%s/large', $gallery->to_string;

    my $photos = path($photos_path)->list->grep(qr/jpg|png/);
    my $text = '';
    my $photo_items;
    for my $photo ($photos->each) {
      my $filename = $photo->basename;
      my $gallery_path_withot_public = $gallery_path;

      # some Workaround. Fix it
      $gallery_path_withot_public =~ s/public\///;
      say $gallery_path_withot_public;

      push @$photo_items, {
        large     => sprintf('/%s/large/%s', $gallery_path_withot_public, $filename),
        medium    => sprintf('/%s/medium/%s', $gallery_path_withot_public, $filename),
        thumbnail => sprintf('/%s/thumbnail/%s', $gallery_path_withot_public, $filename),
      };
    }

    my $gallery_url = sprintf 'photos/%s', $meta->{url} || $gallery_name;

    my $c = $app->build_controller;
    $app->routes->get($gallery_url)->to(cb => sub {
      my $c = shift;
      $c->render(template => 'gallery/item',
        page_title   => $meta->{title},
        photos       => $photo_items,
        meta         => $meta,
      );
    });

    push @$galleries, {
      meta   => $meta,
      url    => $gallery_url,
      photos => [ splice(@$photo_items, 0, 3) ],
    };
  }

  $app->routes->get('/gallery')->to(cb => sub {
    my $c = shift;
    $c->render(template => 'gallery/list',
      page_title   => 'Somoe Photos',
      galleries    => $galleries,
    );
  });

}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Gallery - Simple phot gallery for Mojolicious

=head1 SYNOPSIS

  use Mojolicious::Plugin::Gallery;

=head1 DESCRIPTION

Mojolicious::Plugin::Gallery is if you want simple gallery

Your steps
- Make dir in public/gallery
- Run ./cmd.pl resize
- Update info in public/gallery/<your album>/meta.yml
- Restart your app

=head1 AUTHOR

sklukin E<lt>sklukin@yandex.ruE<gt>

=head1 COPYRIGHT

Copyright 2020-2020 sklukin

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
