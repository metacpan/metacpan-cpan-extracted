use Test::Most;
use Template::Pure;
use Mojo::DOM58;

my $html = qq[
  <html>
    <section id="one">
    <ol>
      <li>Things to Do...</li>
    </ol>
    <ul>
      <li>One</li>
    </ul>
    </section>
    <section id="two">
    <ol>
      <li>(p1)</li>
    </ol>
    <ul>
      <li>Item:</li>
    </ul>
    </section>
    <section id="object">
    <ol>
      <li>Things to Do...</li>
    </ol>
    </section>
  </html>
];

my $pure = Template::Pure->new(
  template => $html,
  directives => [
    '#one' => [
      'ol li' => {
        'task<-tasks' => 'task',
      },
      'ul li' => {
        'task<-tasks' => sub {
          my ($pure, $dom, $data) = @_;
          $pure->data_at_path($data, 'task');
        }
      },
    ],
    '#two' => [
      'ol li+' => {
        'task<-tasks' => 'task',
      },
      '+ul li' => {
        'task<-tasks' => sub {
          my ($pure, $dom, $data) = @_;
          $pure->data_at_path($data, 'task');
        }
      },
    ],
    '#object' => [
      'ol li' => {
        'task<-tasks' => Template::Pure->new(
          template => q[<p><span class='content'>content</span><span class='task'>task</span></p>],
          directives => [
            '.content'=>'content',
            '.task'=>'task',
          ],
        ),
      },
    ],
  ]);

my %data = (
  tasks => [
    'Walk Dogs',
    'Buy Milk',
  ],
);

ok my $string = $pure->render(\%data);
ok my $dom = Mojo::DOM58->new($string);

is $dom->find('#one ol li')->[0]->content, 'Walk Dogs';
is $dom->find('#one ol li')->[1]->content, 'Buy Milk';
ok !$dom->find('#one ol li')->[3];

is $dom->find('#one ul li')->[0]->content, 'Walk Dogs';
is $dom->find('#one ul li')->[1]->content, 'Buy Milk';
ok !$dom->find('#one ul li')->[3];

is $dom->find('#two ol li')->[0]->content, 'Walk Dogs(p1)';
is $dom->find('#two ol li')->[1]->content, 'Buy Milk(p1)';
ok !$dom->find('#two ol li')->[3];

is $dom->find('#two ul li')->[0]->content, 'Item:Walk Dogs';
is $dom->find('#two ul li')->[1]->content, 'Item:Buy Milk';
ok !$dom->find('#two ul li')->[3];

is $dom->find('#object .content')->[0]->content, 'Things to Do...';
is $dom->find('#object .content')->[1]->content, 'Things to Do...';
is $dom->find('#object .task')->[0]->content, 'Walk Dogs';
is $dom->find('#object .task')->[1]->content, 'Buy Milk';

{
  my $pure = Template::Pure->new(
    template => q[
      <ol>
        <li>Items</li>
      </ol>
    ],
    directives => [
      '^ol li' => {
        'task<-tasks' => Template::Pure->new(
          template => q[<span></span>],
          directives => [
            'span' => 'task',
            '.' => [
              { inner => \'^span', content => 'content' },
              '.' => 'content',
              'li+' => 'inner',
            ],
          ],
        ),
      }
    ]);

  ok my $string = $pure->render(\%data);
  ok my $dom = Mojo::DOM58->new($string);

  is $dom->find('ol li span')->[0]->content, 'Walk Dogs';
  is $dom->find('ol li span')->[1]->content, 'Buy Milk';
}

done_testing; 
