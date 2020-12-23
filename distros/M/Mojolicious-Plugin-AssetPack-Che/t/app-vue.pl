use lib 'lib', '../lib';
use Mojolicious::Lite;

plugin 'AssetPack::Che' => {
  pipes => [qw(VueTemplateCompiler CombineFile)],#CombineFile
    CombineFile => {
      gzip => {min_size => 1000},
    },
  process => [
    ['js/dist/рендер.js?333'=>qw(js/App.vue.html js/файлы.vue.html), 'js/components/Шаблон №1.vue.html',],
    #~ 'main.js'=>[qw(.js js/component1.vue.js js/2.vue.js)]
    #js/dist/рендер.js
    ['main.js'=>qw(
        js/dist/рендер.js
        js/main.js
        js/App.js
        js/components/Hello.js
    )],
  ],
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
<title>Test the  VueTemplateCompiler pipe | AssetPack::Che</title>
</head>
<body>
<h1>Test the VueTemplateCompiler pipe</h1>
<div id=app></div>
%= asset 'main.js';
</body>
</html>
