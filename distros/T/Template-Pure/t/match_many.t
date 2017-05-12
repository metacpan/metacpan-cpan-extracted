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
        <div>La la la la la....</div>
      </section>
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    'title,
     #article h1' => 'meta.title',
  ],    
);

ok my $data = +{
  meta => {
    title => 'Travel Poetry',
    created_on => '1/1/2000',
  },
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

#warn $string;

is $dom->find('title')->[0]->content, 'Travel Poetry';
is $dom->find('#article h1')->[0]->content, 'Travel Poetry';

done_testing; 
