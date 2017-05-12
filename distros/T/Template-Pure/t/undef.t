use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $html = q[
  <html>
    <head>
      <title>Page Title</title>
    </head>
    <body>
      <h1>Article Title</h1>
      <ol>
        <li>stuff</li>
      </ol>
      <div id="end">End Stuff</div>
      <div id="append_prepend">vvv</div>
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    'title' => 'settings.maybe:defaults.title',
    'body h1' => 'title',
    'body div#end' => 'optional:foot',
    '#append_prepend+' => 'nothing',
    '+#append_prepend' => 'nothing',
    '#append_prepend' => [
      '.+' => 'nothing',
      '+.' => 'nothing',
    ],
    'ol li' => {
      'person<-people' => [
        '.' => '={person} ={i.index}',
      ],
    },
  ],    
);

ok my $data = +{
  settings => {
    foo => 'bar',
    defaults => undef,
  },
  title => undef,
  people => undef,
  nothing => undef,
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

ok !$dom->at('title');
ok !$dom->at('ol li');
ok !$dom->at('body div#end');
ok $dom->at('#append_prepend')->content, 'vvv';

done_testing; 
