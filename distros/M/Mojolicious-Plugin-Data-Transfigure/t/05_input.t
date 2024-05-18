use v5.26;
use warnings;

use Test2::V0;

use Mojolicious::Lite;

use Data::Transfigure;
use Data::Transfigure::Value;
use Test::Mojo;

use experimental qw(signatures);

plugin('Data::Transfigure');

my $t = Test::Mojo->new();

my @books =
  ({id => 1, the_title => "Jurassic Parka"}, {id => 2, the_title => "The Andromeda Straine"}, {id => 3, the_title => "Sphere"},);

patch(
  "/book/:id" => sub($c) {
    my $id     = $c->param('id');
    my ($book) = grep {$_->{id} == $id} @books;
    my $data   = $c->transfig->json;

    foreach my $k (keys($data->%*)) {$book->{$k} = $data->{$k}}

    $c->render(text => $book->{the_title});
  }
);

$t->patch_ok('/book/2', {Accept => '*/*'} => json => {theTitle => 'The Andromeda Strain'})->content_is('The Andromeda Strain');
is($books[1]->{the_title}, 'The Andromeda Strain', 'double-check that book 2 was modified');

my $transfigure = Data::Transfigure->bare();
$transfigure->add_transfigurators(
  Data::Transfigure::Value->new(
    value   => 'Jurassic Park',
    handler => sub($data) {
      "Jurassic Bark";
    }
  )
);

patch(
  "/books/:id" => sub($c) {
    my $id     = $c->param('id');
    my ($book) = grep {$_->{id} == $id} @books;
    my $data   = $c->transfig->json(transfigurator => $transfigure);

    foreach my $k (keys($data->%*)) {$book->{$k} = $data->{$k}}

    $c->render(text => $book->{the_title});
  }
);

$t->patch_ok('/books/1', {Accept => '*/*'} => json => {the_title => 'Jurassic Park'})->content_is('Jurassic Bark');
is($books[0]->{the_title}, 'Jurassic Bark', 'double-check that book 1 was modified');

done_testing;
