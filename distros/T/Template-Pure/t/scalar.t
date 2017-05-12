use Test::Most;
use Template::Pure;
use Mojo::DOM58;

ok my $html = qq[
  <html>
    <head>
      <title>Page Title</title>
    </head>
    <body>
      <h1>Example</h1>
      <div id='content'>
        <p class="append">append:</p>
        <p class="prepend">:prepend</p>
        <p class="replace">append</p>
      </div>
      <div id='attribute'>
        <img src="append:" class="append" />
        <img src=":prepend" class="prepend" />
        <img src="replace" class="replace" />
      </div>
      <div id='node'>
        <p class="append">append:</p>
        <p class="prepend">:prepend</p>
        <p class="replace">append</p>
      </div>
      <div id='dom'>...
      </div>
      <ul id='bug'>
        <li>
          <form action="/task/">
          <ol>
            <li>..</li>
          </ol>
          </form>
        <li>
      </div>
    </body>
  </html>
];

ok my $pure = Template::Pure->new(
  template=>$html,
  directives=> [
    'title' => q[
      meta.title | 
      upper | 
      truncate(={settings.title_length},"...")
    ],
    '#content .append+' => 'content.append',
    '+#content .prepend' => 'content.prepend',
    '#content .replace' => 'content.replace',
    '#attribute .replace@src' => 'attribute.replace',
    '#attribute .append@src+' => 'attribute.append',
    '+#attribute .prepend@src' => 'attribute.prepend',
    '^#node .append+' => 'node.append',
    '^+#node .prepend' => 'node.prepend',
    '^#node .replace' => 'node.replace | encoded_string',
    'html|' => sub {
      my ($template, $dom, $data) = @_;
      $dom->find('div')->each(sub {
        $_->attr(class=>"added");
      });
    },
    'body h1' => [
      '.' => \'/title',
      '.@class+' => \'/body div#node@id',
      '^.' => sub {
        my ($template, $dom, $data) = @_;
        $dom->attr(foo=>'bar');
        return $template->encoded_string($dom);
      },
    ],
    'body div@foo' => sub {
      my ($template, $dom, $data) = @_;
      return 'bar';
    },
    'body' => [
      'div#dom' => \'^/title',
    ],
    '#bug > li' => {
      'task<-tasks' => [
        'form@action+' => 'task.id',
        'ol li' => {
          'in<-task.inner' => 'in',
        },
      ],
    },
  ]
);

ok $pure->{dom};
ok $pure->{directives};
ok $pure->{filters};

ok my $data = +{
  tasks => [
    {id=>1, inner=>[1,2,3]},
    {id=>2, inner=>[1,2,3]},
    {id=>3, inner=>[1,2,3]},
  ],
  meta => { title=>'doomed poem' },
  settings => { title_length => 6 },
  content => {
    replace => 'content-replace',
    append => 'content-append',
    prepend => 'content-prepend',
  },
  attribute => {
    replace => 'attr-replace',
    append => 'attr-append',
    prepend => 'attr-prepend',
  },
  node => {
    replace => '<p class="replace">node-replace</p>',
    append => 'node-append',
    prepend => 'node-prepend',
  }

};

ok my $string = $pure->render($data);
ok my $dom = Mojo::DOM58->new($string);

#warn $string;

is $dom->at('title')->content, 'DOO...';

{
  ok my $node = $dom->at('body h1');
  is $node->attr('class'), 'node';
  is $node->attr('foo'), 'bar';
  is $node->content, 'DOO...';
}

{
  ok my $node = $dom->at('#content');
  is $node->attr('class'), 'added';
  is $node->attr('foo'), 'bar';
  is $node->at('.append')->content, 'append:content-append';
  is $node->at('.prepend')->content, 'content-prepend:prepend';
  is $node->at('.replace')->content, 'content-replace';
}

{
  ok my $node = $dom->at('#attribute');
  is $node->attr('class'), 'added';
  is $node->attr('foo'), 'bar';
  is $node->at('.append')->attr('src'), 'append:attr-append';
  is $node->at('.prepend')->attr('src'), 'attr-prepend:prepend';
  is $node->at('.replace')->attr('src'), 'attr-replace';
}

{
  ok my $node = $dom->at('#node');
  is $node->attr('class'), 'added';
  is $node->attr('foo'), 'bar';
  is $node->at('.append'), '<p class="append">append:</p>';
  is $node->at('.prepend'), '<p class="prepend">:prepend</p>';
  is $node->at('.replace'), '<p class="replace">node-replace</p>';
}

{
  is $dom->at('#dom')->content, '<title>DOO...</title>';
}

{
  ok my $col = $dom->find('#bug > li');
  is $col->[0]->at('form')->attr('action'), '/task/1';
  is $col->[0]->find('ol li')->[0]->content, '1';
  is $col->[0]->find('ol li')->[1]->content, '2';
  is $col->[0]->find('ol li')->[2]->content, '3';
  ok ! $col->[0]->find('ol li')->[3];
  
  is $col->[1]->at('form')->attr('action'), '/task/2';
  is $col->[1]->find('ol li')->[0]->content, '1';
  is $col->[1]->find('ol li')->[1]->content, '2';
  is $col->[1]->find('ol li')->[2]->content, '3';
  ok ! $col->[1]->find('ol li')->[3];

  is $col->[2]->at('form')->attr('action'), '/task/3';
  is $col->[2]->find('ol li')->[0]->content, '1';
  is $col->[2]->find('ol li')->[1]->content, '2';
  is $col->[2]->find('ol li')->[2]->content, '3';
  ok ! $col->[2]->find('ol li')->[3];

  ok ! $col->[3];
}

done_testing;
