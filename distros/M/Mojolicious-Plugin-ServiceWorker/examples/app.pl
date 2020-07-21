use Mojolicious::Lite;

plugin 'ServiceWorker' => {
  debug => 1,
};

get '/' => 'index';

app->start;

__DATA__

@@ index.html.ep
<div>Welcome.</div>
<script>
%= include 'serviceworker-install'
</script>
