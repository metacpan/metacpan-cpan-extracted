use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $master_html = q[
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

ok my $master = Template::Pure->new(
  template=>$master_html,
  directives=> [
    'title' => 'title',
    '^title+' => 'scripts',
    'body section#content' => 'content',
  ]);

ok my $page_html = q[
  <html>
    <head>
      <title>The Real Page</title>
      <script>
      function foo(bar) {
        return baz;
      }
      </script>
    </head>
    <body>
      <p>You are doomed to discover that you never
      recovered from the narcolyptic country in
      which you once stood; where the fire's always
      burning but there's never enough wood.</p>
    </body>
  </html>
];

ok my $page = Template::Pure->new(
  template=>$page_html,
  directives=> [
    'title' => 'meta.title',
    'html' => [
      {
        title => \'title',
        scripts => \'^head script',
        content => \'body',
      },
      '^.' => $master,
    ]
  ]);

ok my $data = +{
  meta => {
    title => 'Inner Stuff',
  },
};

ok my $string = $page->render($data);
ok my $dom = Mojo::DOM58->new($string);

is $dom->at('title')->content, 'Inner Stuff';
is $dom->at('#foot')->content, 'Here&#39;s the footer';
is $dom->find('link')->[0]->attr('href'), '/css/pure-min.css';
like $dom->at('body #content'), qr'<p>You are doomed to discover';
like $dom->find('script')->[0]->content, qr'function foo';

done_testing; 
