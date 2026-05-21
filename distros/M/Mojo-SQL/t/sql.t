use Mojo::Base -strict, -signatures;

use Test::More;

use Mojo::SQL qw(sql sql_unsafe);
use Mojo::SQL::Statement;

subtest 'Statement' => sub {
  is_deeply(Mojo::SQL::Statement->new->parse('SELECT 1')->to_query,  {text => 'SELECT 1',  values => []}, 'static');
  is_deeply(Mojo::SQL::Statement->new->parse('SELECT 1;')->to_query, {text => 'SELECT 1;', values => []}, 'semicolon');
  is_deeply(
    Mojo::SQL::Statement->new->parse('SELECT ?;', 1)->to_query,
    {text => 'SELECT $1;', values => [1]},
    'one placeholder'
  );
  is_deeply(
    Mojo::SQL::Statement->new->parse('SELECT ?, ?, ?;', 1, '2', [3])->to_query,
    {text => 'SELECT $1, $2, $3;', values => [1, '2', [3]]},
    'three placeholders'
  );
  is_deeply(
    Mojo::SQL::Statement->new->parse('SELECT ??, ?;', 1)->to_query,
    {text => 'SELECT ?, $1;', values => [1]},
    'escaped question mark'
  );

  my $partial = Mojo::SQL::Statement->new->parse('AND two = ? AND three = ?', 'Two', 3);
  is_deeply(Mojo::SQL::Statement->new->parse('SELECT * FROM foo WHERE one = ? ?', 'One', $partial)->to_query,
    {text => 'SELECT * FROM foo WHERE one = $1 AND two = $2 AND three = $3', values => ['One', 'Two', 3]}, 'composed');
  is_deeply(
    Mojo::SQL::Statement->new->parse('SELECT * FROM foo WHERE one = ? ? ? AND four = ?', 'One', $partial, $partial, 4)
      ->to_query,
    {
      text => 'SELECT * FROM foo WHERE one = $1 AND two = $2 AND three = $3 AND two = $4 AND three = $5 AND four = $6',
      values => ['One', 'Two', 3, 'Two', 3, 4]
    },
    'composed twice'
  );

  my $empty = Mojo::SQL::Statement->new->parse('');
  is_deeply(
    Mojo::SQL::Statement->new->parse('SELECT 1 ?', $empty)->to_query,
    {text => 'SELECT 1 ', values => []},
    'empty partial'
  );

  subtest 'From unsafe string' => sub {
    my $unsafe = Mojo::SQL::Statement->new->parse_unsafe(q{FROM bar WHERE ? = '?'}, 'baz', 'yada');
    is_deeply(
      Mojo::SQL::Statement->new->parse('SELECT * ? ORDER BY id', $unsafe)->to_query,
      {text => q{SELECT * FROM bar WHERE baz = 'yada' ORDER BY id}, values => []},
      'unsafe spliced in'
    );

    $unsafe = Mojo::SQL::Statement->new->parse_unsafe('FROM ?? WHERE id = ?', 23);
    is_deeply(
      Mojo::SQL::Statement->new->parse('SELECT * ?', $unsafe)->to_query,
      {text => 'SELECT * FROM ? WHERE id = 23', values => []},
      'escaped question mark'
    );
  };

  subtest 'to_list' => sub {
    my @list = Mojo::SQL::Statement->new->parse('SELECT 1')->to_list;
    is_deeply(\@list, ['SELECT 1'], 'static');

    @list = Mojo::SQL::Statement->new->parse('SELECT ?;', 1)->to_list;
    is_deeply(\@list, ['SELECT $1;', 1], 'one placeholder');

    @list = Mojo::SQL::Statement->new->parse('SELECT ?, ?, ?;', 1, '2', [3])->to_list;
    is_deeply(\@list, ['SELECT $1, $2, $3;', 1, '2', [3]], 'three placeholders');

    my $partial = Mojo::SQL::Statement->new->parse('AND two = ? AND three = ?', 'Two', 3);
    @list = Mojo::SQL::Statement->new->parse('SELECT * FROM foo WHERE one = ? ?', 'One', $partial)->to_list;
    is_deeply(\@list, ['SELECT * FROM foo WHERE one = $1 AND two = $2 AND three = $3', 'One', 'Two', 3], 'composed');

    my $empty = Mojo::SQL::Statement->new->parse('');
    @list = Mojo::SQL::Statement->new->parse('SELECT 1 ?', $empty)->to_list;
    is_deeply(\@list, ['SELECT 1 '], 'empty partial');

    @list = Mojo::SQL::Statement->new->parse('SELECT ?, ?, ?;', 1, '2', [3])->to_list({placeholder => '?'});
    is_deeply(\@list, ['SELECT ?, ?, ?;', 1, '2', [3]], 'custom placeholder');
  };

  subtest 'to_array' => sub {
    my $array = Mojo::SQL::Statement->new->parse('SELECT 1')->to_array;
    is_deeply($array, ['SELECT 1'], 'static');

    $array = Mojo::SQL::Statement->new->parse('SELECT ?;', 1)->to_array;
    is_deeply($array, ['SELECT $1;', 1], 'one placeholder');

    $array = Mojo::SQL::Statement->new->parse('SELECT ?, ?, ?;', 1, '2', [3])->to_array;
    is_deeply($array, ['SELECT $1, $2, $3;', 1, '2', [3]], 'three placeholders');

    my $partial = Mojo::SQL::Statement->new->parse('AND two = ? AND three = ?', 'Two', 3);
    $array = Mojo::SQL::Statement->new->parse('SELECT * FROM foo WHERE one = ? ?', 'One', $partial)->to_array;
    is_deeply($array, ['SELECT * FROM foo WHERE one = $1 AND two = $2 AND three = $3', 'One', 'Two', 3], 'composed');

    my $empty = Mojo::SQL::Statement->new->parse('');
    $array = Mojo::SQL::Statement->new->parse('SELECT 1 ?', $empty)->to_array;
    is_deeply($array, ['SELECT 1 '], 'empty partial');

    $array = Mojo::SQL::Statement->new->parse('SELECT ?, ?, ?;', 1, '2', [3])->to_array({placeholder => '?'});
    is_deeply($array, ['SELECT ?, ?, ?;', 1, '2', [3]], 'custom placeholder');
  };
};

subtest 'Functions' => sub {
  is_deeply sql('SELECT 1')->to_query,     {text => 'SELECT 1',  values => []}, 'static';
  is_deeply sql('SELECT 1;')->to_query,    {text => 'SELECT 1;', values => []}, 'semicolon';
  is_deeply sql('SELECT ?;', 1)->to_query, {text => 'SELECT $1;', values => [1]}, 'one placeholder';
  is_deeply sql('SELECT ?, ?, ?;', 1, '2', [3])->to_query, {text => 'SELECT $1, $2, $3;', values => [1, '2', [3]]},
    'three placeholders';
  is_deeply sql('SELECT ??, ?;', 1)->to_query, {text => 'SELECT ?, $1;', values => [1]}, 'escaped question mark';

  my $partial = sql 'AND two = ? AND three = ?', 'Two', 3;
  is_deeply sql('SELECT * FROM foo WHERE one = ? ?', 'One', $partial)->to_query,
    {text => 'SELECT * FROM foo WHERE one = $1 AND two = $2 AND three = $3', values => ['One', 'Two', 3]}, 'composed';
  is_deeply sql('SELECT * FROM foo WHERE one = ? ? ? AND four = ?', 'One', $partial, $partial, 4)->to_query,
    {
    text   => 'SELECT * FROM foo WHERE one = $1 AND two = $2 AND three = $3 AND two = $4 AND three = $5 AND four = $6',
    values => ['One', 'Two', 3, 'Two', 3, 4]
    },
    'composed twice';

  my $empty = sql '';
  is_deeply sql('SELECT 1 ?', $empty)->to_query, {text => 'SELECT 1 ', values => []}, 'empty partial';

  subtest 'From unsafe string' => sub {
    my $unsafe = sql_unsafe q{FROM bar WHERE ? = '?'}, 'baz', 'yada';
    is_deeply sql('SELECT * ? ORDER BY id', $unsafe)->to_query,
      {text => q{SELECT * FROM bar WHERE baz = 'yada' ORDER BY id}, values => []}, 'unsafe spliced in';

    $unsafe = sql_unsafe 'FROM ?? WHERE id = ?', 23;
    is_deeply sql('SELECT * ?', $unsafe)->to_query, {text => 'SELECT * FROM ? WHERE id = 23', values => []},
      'escaped question mark';
  };
};

subtest 'Custom placeholder' => sub {
  is_deeply sql('SELECT 1')->to_query({placeholder => '?'}), {text => 'SELECT 1', values => []}, 'static';
  is_deeply sql('SELECT ?;', 1)->to_query({placeholder => '?'}), {text => 'SELECT ?;', values => [1]},
    'one placeholder';
  is_deeply sql('SELECT ?, ?, ?;', 1, '2', [3])->to_query({placeholder => '?'}),
    {text => 'SELECT ?, ?, ?;', values => [1, '2', [3]]}, 'three placeholders';

  my $partial = sql 'AND two = ? AND three = ?', 'Two', 3;
  is_deeply sql('SELECT * FROM foo WHERE one = ? ?', 'One', $partial)->to_query({placeholder => '?'}),
    {text => 'SELECT * FROM foo WHERE one = ? AND two = ? AND three = ?', values => ['One', 'Two', 3]}, 'composed';
  is_deeply sql('SELECT * FROM foo WHERE one = ? ? ? AND four = ?', 'One', $partial, $partial, 4)
    ->to_query({placeholder => '?'}),
    {
    text   => 'SELECT * FROM foo WHERE one = ? AND two = ? AND three = ? AND two = ? AND three = ? AND four = ?',
    values => ['One', 'Two', 3, 'Two', 3, 4]
    },
    'composed twice';
};

done_testing;
