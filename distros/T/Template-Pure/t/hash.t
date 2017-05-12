use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $html = q[
  <html>
    <head>
      <title>Page Title</title>
    </head>
    <body>
      <dl>
        <dt>term</dt>
        <dd>data</dd>
      </dl>
      <p>Blah
      </p>
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    'dl' => {
      'meta' => [
        'dt' => 'property',
        'dd' => 'value',
      ],
      directives => [
        '.+' => 'value'
      ]
    },
    'p' => [
      { age => 'meta.value' },
      '.' => 'age',
    ]
  ]);

ok my $data = +{
  meta => {
    property => 'age',
    value => 17,
  }
};


ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

is $dom->at('dl dt')->content, 'age';
is $dom->at('dl dd')->content, '17';
is $dom->at('body p')->content, '17';

done_testing; 
