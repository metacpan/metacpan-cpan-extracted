use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $html = q[
  <html>
    <head>
      <title>Page Title</title>
    </head>
    <body>
      <ul>
        <li><span>stuff</span>extra stuff</li>
      </ul>
      <ol>
        <li>
          stuff
        </li>
      </ol>
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    'ul li' => {
      'person<-people' => [
        'span' => 'person',
      ],
    },
    'ol li' => {
      'person<-people' => [
        '.' => '={person |
          upper | 
          repeat(6) | 
          truncate(={/settings.length}) } ={i.index}',
      ],
      'order_by' => sub {
        my ($pure, $data, $a, $b) = @_;
        return $b cmp $a;
      },
      'grep' => 'callbacks.grep',
    },
  ],    
);

ok my $data = +{
  settings => {
    length => 10,
  },
  people => [qw/john jack jane/],
  callbacks => {
    'grep' => sub {
      return $_[1] =~m/ja/;
    },
  }
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

is $dom->find('ul li')->[0]->content, '<span>john</span>extra stuff';
is $dom->find('ul li')->[1]->content, '<span>jack</span>extra stuff';
is $dom->find('ul li')->[2]->content, '<span>jane</span>extra stuff';
ok !$dom->find('ul li')->[3];

is $dom->find('ol li')->[0]->content, 'JANEJANEJA 1';
is $dom->find('ol li')->[1]->content, 'JACKJACKJA 2';
ok !$dom->find('ol li')->[3];

#warn $string; 

done_testing; 
