use Mojo::Base -strict;

use Mojo::Autobox;

use Test::More;

subtest 'collection method' => sub {
  my $c = [qw/a b c/]->collection;
  isa_ok $c, 'Mojo::Collection', 'right type';
  is $c->first, 'a', 'right behavior';
};

subtest 'c method' => sub {
  my $c = [qw/a b c/]->c;
  isa_ok $c, 'Mojo::Collection', 'right type';
  is $c->first, 'a', 'right behavior';
};

subtest 'json method' => sub {
  my $json = [qw/val1 val2/]->json;
  like $json, qr/\s*\[\s*"val1"\s*,\s*"val2"\s*\]/, 'correct json output'
};

subtest 'j method' => sub {
  my $json = [qw/val1 val2/]->j;
  like $json, qr/\s*\[\s*"val1"\s*,\s*"val2"\s*\]/, 'correct json output'
};

done_testing;

