use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $html = q[
  <html>
    <head>
      <title>Page Title</title>
    </head>
    <body>
      <p class="foo">aaa</a>
      <p class="bar">bbb</a>
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    'p' => Mojo::DOM58->new("<a href='localhost:foo'>Foo!</a>"),
  ]);

ok my $data = +{
  title => 'A Shadow Over Innsmouth',
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

is $dom->find('p')->[0]->content, '<a href="localhost:foo">Foo!</a>';
is $dom->find('p')->[1]->content, '<a href="localhost:foo">Foo!</a>';

done_testing; 
