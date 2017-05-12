use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $wrapper_html = qq[
  <section>Example Wrapped Stuff</section>];

ok my $wrapper = Template::Pure->new(
  template=>$wrapper_html,
  directives=> [
    'section' => 'content',
  ]);

ok my $template = qq[
 <html>
    <head>
      <title>Title Goes Here!</title>
    </head>
    <body>
      <p>Hi Di Ho!</p>
    </body>
  </html>    
];

ok my @directives = (
  title => 'title | upper',
  body => 'info',
);

ok my $pure = Template::Pure->new(
  template => $template,
  directives => \@directives);

ok my $data = +{
  title => 'Scalar objects',
  info => $wrapper,
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

is $dom->at('body section p')->content, 'Hi Di Ho!';
is $dom->at('title')->content, 'SCALAR OBJECTS';

done_testing;
