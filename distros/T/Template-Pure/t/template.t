use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $inner_html = q[
  <h1>Header</h1>
  <section id="content">...</p>
];

ok my $inner = Template::Pure->new(
  template=>$inner_html,
  directives=> [
    'h1' => 'meta.title',
    '#content' => 'content',
]);

ok my $inner_html_2 = q[
  <span>Inner</span>
];

ok my $inner_2 = Template::Pure->new(
  template=>$inner_html_2,
  directives=> [
    'span' => 'bar.baz',
]);



ok my $html = q[
  <html>
    <head>
      <title>Page Title</title>
    </head>
    <body>
      <p id="story">Some Stuff</p>
      <div>BAZ</div>
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    '^body p'=>$inner,
    '#story' => 'story',
    'div' => {
      foo => $inner_2,
    },
]);

ok my $data = +{
  meta => {
    title => 'Inner Stuff',
    date => '1/1/2020',
  },
  story => 'XX' x 10,
  foo => {
    bar => {
      baz => 1000,
    }
  }
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

is $dom->at('body section#content p#story ')->content, 'XXXXXXXXXXXXXXXXXXXX';
is $dom->at('body h1')->content, 'Inner Stuff';
is $dom->at('body div span')->content, '1000';

done_testing; 
