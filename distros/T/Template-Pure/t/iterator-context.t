use Test::Most;
use Template::Pure;
use Mojo::DOM58;

my $html = qq[
  <ol>
    <li>
      <span class='priority'>high|medium|low</span>
      <span class='title'>title</span>
    </li>
  </ol>
];

my $pure = Template::Pure->new(
  template => $html,
  directives => [
    'ol li' => {
      '.<-tasks' => [
        '.priority' => 'priority',
        '.title' => 'title',
      ],
    },
  ]);

my %data = (
  tasks => [
    { priority => 'high', title => 'Walk Dogs'},
    { priority => 'medium', title => 'Buy Milk'},
  ],
);

ok my $string = $pure->render(\%data);
ok my $dom = Mojo::DOM58->new($string);

#warn $string;

is $dom->find('ol li')->[0]->at('.title')->content, 'Walk Dogs';
is $dom->find('ol li')->[0]->at('.priority')->content, 'high';
is $dom->find('ol li')->[1]->at('.title')->content, 'Buy Milk';
is $dom->find('ol li')->[1]->at('.priority')->content, 'medium';
ok !$dom->find('ol li')->[2];

done_testing; 
