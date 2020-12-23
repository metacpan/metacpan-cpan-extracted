use lib 'lib', '../lib';
use Mojolicious::Lite;

plugin 'AssetPack::Che' => {
  pipes => [qw(Css CombineFile JavaScriptPacker)],#
  CombineFile => {
      gzip => {min_size => 1000},
    },
  process => {
    'main.css'=>['css/foo.css', 'css/bar.css',],
    'шаблон 1.html?1111'=>['templates/1.html', 'templates/2.html'],
  },
};

get '/' => sub {
  my $c   = shift;
  $c->render();
}=>'index';

app->start;

__DATA__
@@ index.html.ep
<html>
<head>
<title>Test the AssetPack::Che</title>
%= asset 'main.css';
</head>
<body>
<h1>Test the AssetPack::Che</h1>
</body>
</html>
