#!/usr/bin/env perl
use Mojolicious::Lite;
use lib 'lib';

app->defaults(
  layout => 'default',
  urls   => [
    qw(
      http://beta.dbtv.no/3186954129001?vid%3D3186954129001%26ct%3Dtrendingnow%233186954129001
      http://blip.tv/the-cinema-snob/endless-love-by-the-cinema-snob-6723860
      http://catoverflow.com/cats/r4cIt4z.gif
      http://google.com
      http://imgur.com/2lXFJK0
      http://ix.io/hgz
      http://open.spotify.com/artist/6VKNnZIuu9YEOvLgxR6uhQ
      http://pastebin.com/uNvULndg
      http://paste.scsys.co.uk/470943
      http://pastie.org/10069695
      https://appear.in/your-room-name
      https://gist.github.com/jhthorsen
      https://gist.github.com/jhthorsen/3964764
      https://gravatar.com/avatar/806800a3aeddbad6af673dade958933b
      https://travis-ci.org/Nordaaker/convos/builds/47421379
      https://twitter.com/jhthorsen
      https://twitter.com/jhthorsen/status/434045220116643843
      https://twitter.com/mulligan/status/555050159189413888/
      https://twitter.com/mulligan/status/555050159189413888/photo/1
      https://vimeo.com/86404451
      http://techslides.com/demos/sample-videos/small.flv
      http://techslides.com/demos/sample-videos/small.mp4
      http://techslides.com/demos/sample-videos/small.ogv
      http://techslides.com/demos/sample-videos/small.webm
      http://www.collegehumor.com/video/6952147/jake-and-amir-road-trip-part-6-las-vegas
      http://www.ted.com/talks/ryan_holladay_to_hear_this_music_you_have_to_be_there_literally.html
      http://www.youtube.com/user/jsconfeu
      http://www.youtube.com/watch?v=4BMYH-AQyy0
      http://xkcd.com/927/
      spotify:track:5tv77MoS0TzE0sJ7RwTj34
      )
  ],
);
plugin LinkEmbedder => {route => '/embed'};
get '/' => 'links';
app->start;
__DATA__
@@ links.html.ep
<ul>
% for my $url (@{$c->app->defaults('urls')}) {
  <li><%= link_to $url, "/embed?url=$url" %></li>
% }
</ul>
@@ layouts/default.html.ep
<html>
<head>
  <title>Test embed code for <%= param('url') || 'missing ?url=' %></title>
  <script>
    // window.link_embedder_text_gist_github_styled = 1;
  </script>
  <style>
    iframe { width: 100%; border: 0; }
  </style>
</head>
<body>
%= content
</body>
</html>
