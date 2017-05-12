use Test::Most;
use Template::Pure;

ok my $overlay_html = q[
  <html>
    <head>
      <title>Example Title</title>
      <link rel="stylesheet" href="/css/pure-min.css"/>
        <link rel="stylesheet" href="/css/grids-responsive-min.css"/>
          <link rel="stylesheet" href="/css/common.css"/>
      <script src="/js/3rd-party/angular.min.js"></script>
        <script src="/js/3rd-party/angular.resource.min.js"></script>
    </head>
    <body>
      <section id="content">...</section>
      <p id="foot">Here's the footer</p>
    </body>
  </html>
];

ok my $overlay = Template::Pure->new(
  template=>$overlay_html,
  directives=> [
    'title' => 'title',
    'head+' => 'scripts',
    'body section#content' => 'content',
  ]);

ok my $story_html = qq[
  <section>
    <h1>story title</h1>
    <p>By </p>
  </section>];

ok my $story = Template::Pure->new(
  template=>$story_html,
  directives=> [
    'h1' => 'title',
    '^p+' => 'content',
    'p+' => 'author',
    '#story+' => 'author',
  ]);

ok my $foot_html = qq[
  <span class="time">current time: </span>];

ok my $foot = Template::Pure->new(
  template=>$foot_html,
  directives=> [
    '.time+' => 'time',
  ]);

ok my $base_html = q[
  <?pure-overlay src='lib.overlay'
    title=\'title'
    scripts=\'^head script' 
    content=\'body'?>
  <html>
    <head>
      <title>Page Title: </title>
      <script>
      function foo(bar) {
        return baz;
      }
      </script>
    </head>
    <body>
      <?pure-wrapper src='lib.story' ctx='meta'?>
      <div id='story'>Example Story</div>
      <?pure-include src='lib.foot' ctx='meta'?>
      <?pure-include src='lib.foot' time='meta.time'?>
      <?pure-filter src='lib.filter' class='meta.class' ?>
      <a href="aaa">Hi</a>
    </body>
  </html>
];

ok my $base = Template::Pure->new(
  template=>$base_html,
  directives=> [
    'title+' => 'meta.title',
    '#story' => sub { 'XXX'x10 },
  ]
);

ok my $string = $base->render({
  meta => {
    title=>'My Title',
    author=>'jnap',
    time => scalar(localtime),
    class => 'blue',
  },
  class => 'red',
  lib => {
    foot => $foot,
    story => $story,
    overlay => $overlay,
    filter => sub {
      my $template = shift;
      return Template::Pure->new(
        template => $template,
        directives => [
        'a@class' => 'class',
        ]
      );
    },
  }
});

ok my $dom = Mojo::DOM58->new($string);

is $dom->at('title')->content, 'Page Title: My Title';
is $dom->at('section #story')->content, 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXjnap';
is $dom->at('section p')->content, 'By jnap';
is $dom->at('section h1')->content, 'My Title';
like $dom->find('.time')->[0]->content, qr'current time:';
like $dom->find('.time')->[0]->content, qr'current time:';
is $dom->at('#foot')->content, 'Here&#39;s the footer';
is $dom->find('link')->[0]->attr('href'), '/css/pure-min.css';
is $dom->find('script')->[0]->attr('src'), '/js/3rd-party/angular.min.js';
like $dom->find('script')->[2]->content, qr'function';
like $dom->find('script')->[2]->content, qr'return baz';
is $dom->find('a.blue')->[0]->attr('href'), 'aaa';

done_testing;
#warn $string;
