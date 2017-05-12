use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $html = qq[
  <html>
    <head>
      <title>Page Title</title>
    </head>
    <body>
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    'title' => 'meta.title',
    'body' => 'content',
  ]
);

ok $pure->{dom};
ok $pure->{directives};
ok $pure->{filters};

ok my $data = +{
  meta => {
    title=>'Doomed Poem',
    author=>'jnap',
  },
  content => q[
    Are you doomed to discover that you never recovered from the narcoleptic
    country in which you once stood? Where the fire's always burning, but
    there's never enough wood?
  ],
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

is $dom->at('title'), '<title>Doomed Poem</title>';
like $dom->at('body'), qr/Are you doomed to discover that/;

done_testing;
