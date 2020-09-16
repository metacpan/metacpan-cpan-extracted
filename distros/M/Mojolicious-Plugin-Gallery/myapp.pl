#!/usr/bin/env perl

use lib 'lib';
use Mojolicious::Lite;

app->plugin(Config => { file => 'main.conf' });

app->plugin('Gallery');

get '/' => sub {
  my $c = shift;

  $c->render(template => 'index')
};

app->start;

__DATA__

@@ gallery_list.html.ep

% layout 'default';

<div class="wrapper">

  <div class="page">
    <div class="container">
      <h2>
        Фотоотчеты
      </h2>

      % for my $gal (@$galleries) {
        <h3>
          %= $gal->{meta}{title}
        </h3>
        <a href="<%= $gal->{url} %>">Смотреть все</a>
        <br>
        <br>
        % for my $photo (@{$gal->{photos}}) {
          <a class="gallery" href="<%= $photo->{large} %>" data-fancybox="group-<%= $gal->{url} %>">
            <img src="<%= $photo->{thumbnail} %>" class="gallery-item-image">
          <a/>
        % }
      % }
    </div>
  </div>

</div>

@@ gallery_item.html.ep

% layout 'default';

<div class="wrapper">

  %= include 'layouts/parts/header';

  <div class="page">
    <div class="container">
      <h2>
        %= $meta->{title}
      </h2>
      %= $meta->{description};
      <br>
      <br>
      <br>

      % for my $photo (@$photos) {
        <a class="gallery" href="<%= $photo->{large} %>" data-fancybox="group">
          <img src="<%= $photo->{thumbnail} %>" class="gallery-item-image">
        <a/>
      % }
    </div>
  </div>

</div>

@@ index.html.ep
% layout 'default';

<h1>Welcome to the Mojolicious Gallery!</h1>
<a href="/gallery">Gallery</a>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="ru">
<head>
  <title>Gallery</title>
  <link rel="stylesheet" href="/fancybox/dist/jquery.fancybox.min.css"></link>
  <script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"></script>
  <!--
  use fancy box https://fancyapps.com/fancybox/
  <script type="text/javascript" src="/fancybox/dist/jquery.fancybox.min.js"></script>
  -->
</head>
<body>
  <%= content %>
</body>
</html>
