
BEGIN {
  use Test::Most;
  use Template::Pure;
  plan skip_all => "Moo required, err $@" 
    unless eval "use Moo; 1";
}

{
  package Local::Template::Pure::Obj;

  use Moo;

  sub TO_HTML {
    my ($self, $pure, $dom, $data) = @_;
    return 'obj'x3;
  }

  package Local::Template::Pure::Custom;

  use Moo;
  extends 'Template::Pure';

  has 'version' => (is=>'ro', required=>1);

  sub time {
  my $self = shift;
    return sub {
    my ($self, $dom, $data) = @_;
    $dom->attr(foo=>'bar');
    return 'Mon Apr 11 10:49:42 2016';
    };
  }

  sub obj {
    my $self = shift;
    return sub {
    my ($self, $dom, $data) = @_;
    return Local::Template::Pure::Obj->new;
    };
  }

  sub array {
    my $self = shift;
    return [
      'title+' => 'self.version'
    ];
  }

}

ok my $html_template = qq[
  <html>
    <head>
      <title>Page Title</title>
    </head>
    <body>
      <div id='version'>Version</div>
      <div id='main'>Test Body</div>
      <div id='foot'>Footer</div>
      <div id='obj'>...</div>
    </body>
  </html>
];

ok my $pure = Local::Template::Pure::Custom->new(
  version => 100,
  template=>$html_template,
  directives=> [
    'title' => 'meta.title',
    '#version' => 'self.version',
    '#main' => 'story',
    '#foot' => 'self.time',
    '#obj' => 'self.obj',
    'head' => 'self.array',
  ]
);

ok my $data = +{
  meta => {
    title=>'A subclass',
    author=>'jnap',
  },
  story => 'XXX',
};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

is $dom->at('title'), '<title>A subclass100</title>';
is $dom->at('#version')->content, '100';
is $dom->at('#main')->content, 'XXX';
is $dom->at('#foot')->content, 'Mon Apr 11 10:49:42 2016';
is $dom->at('#obj')->content, 'objobjobj';
is $dom->at('#foot')->attr('foo'), 'bar';

#warn $string;

done_testing;
