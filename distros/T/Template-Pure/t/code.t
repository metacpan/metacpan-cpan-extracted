use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $html = q[
  <html>
    <head>
      <title>Page Title</title>
    </head>
    <body>
      <p>foo</p>
      <p>baz</p>
      <div id="111"></div>
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    sub {
      my ($template, $dom, $data) = @_;
      $dom->at('#111')->content("coderef");
    },
    'p' => sub {
      my ($template, $dom, $data) = @_;
      Test::Most::is ref($template), 'Template::Pure';
      Test::Most::is "$dom", "<p>".$dom->content."</p>";
      return $template->data_at_path($data, $dom->content)
    }
  ]);

ok my $data = +{
  foo => 'foo is you',
  baz => 'baz is raz',
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

#warn $string;

is $dom->find('p')->[0]->content, 'foo is you';
is $dom->find('p')->[1]->content, 'baz is raz';
is $dom->at('#111')->content, 'coderef';

# count tests because the ones in the sub callback might not get
# run if there's trouble in the code.
#
done_testing(12);
