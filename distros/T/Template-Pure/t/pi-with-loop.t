use Test::Most;
use Template::Pure;

ok my $base_html = q[
  <html>
    <head>
      <title>PI With Loop</title>
    </head>
    <body>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Age</th>
          </tr>
        </thead>
        <tbody>
          <?pure-include src='include' rows='rows'?>      
        </tbody>
      </table>
    </body>
  </html>
];

ok my $include_html = q[
  <tr class='rows'>
    <td class='id'>$id</td>
    <td class='name'>$name</td>
    <td class='age'>$age</td>
  </tr> 
];

ok my $include = Template::Pure->new(
  template=>$include_html,
  directives=> [
    '.rows' => {
      'row<-rows' => [
        '.id' => 'row.id',
        '.name' => 'row.name',
        '.age' => 'row.age'
      ],
    },
  ]);

ok my $base = Template::Pure->new(
  template=>$base_html,
  directives=> []
);

ok my $string = $base->render({
  include => $include,
  rows => [
    {id=>1,name=>'john',age=>44},
    {id=>2,name=>'james',age=>54},
    {id=>3,name=>'sue',age=>24},
  ],
});

ok my $dom = Mojo::DOM58->new($string);

is $dom->find('.rows')->[0]->at('.id')->content, '1';
is $dom->find('.rows')->[0]->at('.name')->content, 'john';
is $dom->find('.rows')->[0]->at('.age')->content, '44';

is $dom->find('.rows')->[1]->at('.id')->content, '2';
is $dom->find('.rows')->[1]->at('.name')->content, 'james';
is $dom->find('.rows')->[1]->at('.age')->content, '54';

is $dom->find('.rows')->[2]->at('.id')->content, '3';
is $dom->find('.rows')->[2]->at('.name')->content, 'sue';
is $dom->find('.rows')->[2]->at('.age')->content, '24';

done_testing; 
