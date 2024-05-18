use v5.26;
use warnings;

use Test2::V0;

use Mojolicious::Lite;

my $book = {
  id          => 4,
  created_at  => '2024-05-05T05:05:05',
  updated_at  => undef,
  author      => bless({id => 7, firstname => 'Michael', lastname => "Crichton"}, 'Model::Author'),
  sneakySnake => "true",
};

plugin('Data::Transfigure');

isnt(app->transfig->output->transfigure($book), $book, 'changed output');
isnt(app->transfig->input->transfigure($book),  $book, 'changed input');

plugin('Data::Transfigure' => {bare => 1});

is(app->transfig->output->transfigure($book), $book, 'unchanged output');
is(app->transfig->input->transfigure($book),  $book, 'unchanged input');

done_testing;
