#!/usr/bin/env perl
use lib '../lib';
use Mojolicious::Lite;

plugin 'AssetPack' => {pipes => ['ElmLang']};
app->asset->store->paths(['../t/assets']);

# Process 05-http.elm
app->asset->process('main.js' => '05-http.elm');

# Set up the mojo lite application and start it
get '/' => 'index';
app->start;

__DATA__
@@ index.html.ep
<!DOCTYPE HTML>
<html>
<head>
<title>Test</title>
<style>
    html,head,body { padding:0; margin:0; }
    body { font-family: calibri, helvetica, arial, sans-serif; }
</style>
%= asset 'main.js';
</head>
<body>
<script type="text/javascript">
    Elm.Main.fullscreen()
</script>
</body>
</html>