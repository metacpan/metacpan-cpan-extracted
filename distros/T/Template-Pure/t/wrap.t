use Test::Most;
use Template::Pure;

ok my $wrapper_html = qq[
  <span>Example Wrapped Stuff</span>];

ok my $wrapper = Template::Pure->new(
  template=>$wrapper_html,
  directives=> [
    'span' => 'content',
  ]);

ok my $to_wrap_html = qq[
  <html>
    <head>
      <title>Page Title: </title>
    </head>
    <body>
      <div id="foo">foo</div>
      <div id="bar">bar</div>
    </body>
  </html>
];

ok my $to_wrap = Template::Pure->new(
  template=>$to_wrap_html,
  directives=> [
    'title+' => 'meta.title',
    'div' => $wrapper,
  ]
);

ok my $rendered_template = $to_wrap->render({
  meta => { title=>'My Title', author=>'jnap' },
});

ok my $dom = Mojo::DOM58->new($rendered_template);

is $dom->at('title')->content, 'Page Title: My Title';
is $dom->at('#foo span')->content, 'foo';
is $dom->at('#bar span')->content, 'bar';

done_testing;
