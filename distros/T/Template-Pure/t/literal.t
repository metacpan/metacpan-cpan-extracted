use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $html = q[
  <html>
    <head>
      <title>Page Title</title>
    </head>
    <body>
      <p id="literal_q">aaa</a>
      <p id="literal_qq">bbb</a>
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    title=>'title',
    '#literal_q' => "'literal data single quote'",
    '#literal_qq' => '"literal data double quote"',
  ]);

ok my $data = +{
  title => 'A Shadow Over Innsmouth',
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

#warn $string;

is $dom->at('title')->content, 'A Shadow Over Innsmouth';
is $dom->at('#literal_q')->content, 'literal data single quote';
is $dom->at('#literal_qq')->content, 'literal data double quote';

done_testing; 
