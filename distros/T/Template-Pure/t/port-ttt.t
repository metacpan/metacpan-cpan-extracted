use Test::Most;
use Template::Pure;

ok my $board_template = qq[
  <table border="1">
    <tr id="t">
      <td id="tl">TL</td>
      <td id="tc">TC</td>
      <td id="tr">TR</td>
    </tr>
    <tr id="m">
      <td id="ml">ML</td>
      <td id="mc">MC</td>
      <td id="mr">MR</td>
    </tr>
    <tr id="b">
      <td id="bl">BL</td>
      <td id="bc">BC</td>
      <td id="br">BR</td>
    </tr>
  </table>
];

ok my $board = Template::Pure->new(
  template=>$board_template,
  directives=> [
    '#tl' => 'tl',
    '#tc' => 'tc',
    '#tr' => 'tr',
    '#ml' => 'ml',
    '#mc' => 'mc',
    '#mr' => 'mr',
    '#bl' => 'bl',
    '#bc' => 'bc',
    '#br' => 'br',
  ]
);

ok my $status_template = qq[
<dl id='game'>
  <dt>Status</dt>
  <dd id='status'>Tie</dd>
  <dt>Pending Move</dt>
  <dd id='current-move'>N/a</dd>
  <dt>Who's Turn</dt>
  <dd id='whos-turn'>N/a</dd>
  <dt id="board">Current Layout</dt>
</dl>
];

ok my $status = Template::Pure->new(
  template=>$status_template,
  directives=> [
    '#status' => 'status',
    '#current-move' => 'current-move',
    '#whos-turn' => 'whos-turn',
    '^#board+' => {
      board => $board,
    }
  ]
);

ok my $html_template = qq[
<!doctype html>
<html lang="en">
  <head>
    <title>Default Title</title>
    <meta charset="utf-8" />
      <meta name="description" content="Tic Tac Toe API">
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  </head>
  <body>
    <h1>Content goes here!</h1>
  </body>
</html>
];

ok my $html = Template::Pure->new(
  template=>$html_template,
  directives=> [
    'title' => 'title',
    'body' => 'body',
  ]
);

ok my $new_game_template = qq[
<html>
  <head>
    <title>New Game</title>
  </head>
  <body>
    <h1>Information</h1>
      <dl>
        <dt>Time of Request</dt>
        <dd id='time'>Jan 1</dd>
        <dt>Requested Move</dt>
        <dd id='moves'>2</dd>
      </dl>
    <h1>Links</h1>
    <p>Your <a id='new_game_url'>new game</a></p>
    <h1 id='game'>Current Game Status</h1>
  </body>
</html>
];

ok my $new_game = Template::Pure->new(
  template=>$new_game_template,
  directives=> [
    'html' => [
      {
        title => \'title',
        body => \'body',
      },
      '^.' => $html,
    ],
    'dl' => {
      information => [
        '#time' => 'time',
        '#moves' => 'moves',
      ],
    },
    'a#new_game_url@href' => 'new_url',
    '^#game+' => {
      status => $status,
    },
  ]
);



ok my $out = $new_game->render(
  {
    new_url => 'https://localhost/new',
    information =>  {
      time => scalar(localtime),
      moves => 4,
    },
    status => {
      status => 'incomplete',
      'current-move' => '4',
      'whos-turn' => 'X',
      'board' => {
        tl => 'X', tc => 'X', tr => 'X',
        ml => 'X', mc => 'X', mr => 'X',
        bl => 'X', bc => 'X', br => 'X',
      },
    }
  }
);

ok my $dom = Mojo::DOM58->new($out);

is $dom->at('title')->content, 'New Game';
is $dom->at('#moves')->content, 4;
is $dom->at('#whos-turn')->content, 'X';
is $dom->at('#new_game_url')->attr('href'), 'https://localhost/new';
is $dom->at('#status')->content, 'incomplete';
is $dom->at('#tl')->content, 'X';
is $dom->at('#tc')->content, 'X';
is $dom->at('#tr')->content, 'X';
is $dom->at('#ml')->content, 'X';
is $dom->at('#mc')->content, 'X';
is $dom->at('#mr')->content, 'X';
is $dom->at('#bl')->content, 'X';
is $dom->at('#bc')->content, 'X';
is $dom->at('#br')->content, 'X';

done_testing;
