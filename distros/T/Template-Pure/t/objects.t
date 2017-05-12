use Test::Most;
use Template::Pure;
use Mojo::DOM58;

{
  package Local::Example;

  sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
  }

  sub TO_HTML {
    my ($self, $pure, $dom, $data) = @_;
    return $dom->attr('class');
  }
}

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
    'p' => Local::Example->new,
  ]);

ok my $data = +{
  title => 'A Shadow Over Innsmouth',
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

is $dom->find('p')->[0]->content, 'foo';
is $dom->find('p')->[1]->content, 'bar';

# count tests because the ones in the sub callback might not get
# run if there's trouble in the code.

done_testing; 
