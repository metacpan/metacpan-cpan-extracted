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
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    'head title' => 'meta.title',
    '#article' => [
      'h2' => 'header',
    ],
  ],    
);

ok my $data = +{
  meta => {
    title => 'Travel Poetry',
    created_on => '1/1/2000',
  },
  header => 'Fire',
};

eval {
  $pure->render($data);
  fail "If you see this then we didn't produce the expected exception";
  1;
} || do {
  like $@, qr/Match specification 'h2' produces no nodes/;
};

done_testing(4);
