use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $html = q[
  <html>
    <head>
      <title>Page Title</title>
    </head>
    <body>
      <section id="article">
        <h1>Header</h1>
        <div>Story</div>
      </section>
      <ul id="friendlist">
        <li>Friends</li>
      </ul>
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    'head title' => 'meta.title',
    '#article' => [
      'h1' => 'header',
      'div' => 'content',
    ],
    'ul li' => {
      'friend<-user.friends' => [
        '.' => '={friend}, #={i.index}',
      ],
    },
  ],    
);

ok my $data = +{
  meta => {
    title => 'Travel Poetry',
    created_on => '1/1/2000',
  },
  header => 'Fire',
  content => q[
    Are you doomed to discover that you never recovered from the narcoleptic
    country in which you once stood? Where the fire's always burning, but
    there's never enough wood?
  ],
  user => {
    name => 'jnap',
    friends => [qw/jack jane joe/],
  },
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

is $dom->find('title')->[0]->content, 'Travel Poetry';
is $dom->find('#article h1')->[0]->content, 'Fire';
like $dom->find('#article div')->[0]->content, qr'Are you doomed to discover';

is $dom->find('ul li')->[0]->content, 'jack, #1';
is $dom->find('ul li')->[1]->content, 'jane, #2';
is $dom->find('ul li')->[2]->content, 'joe, #3';

done_testing; 
