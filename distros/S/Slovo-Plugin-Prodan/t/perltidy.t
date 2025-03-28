use Mojo::Base -strict, -signatures;
use Mojo::File 'path';
use Test::More;

eval { require Test::PerlTidy; } or do {
  plan(skip_all => 'Test::PerlTidy required to criticise code');
};

my $ROOT = path(__FILE__)->dirname->dirname->to_string;
Test::PerlTidy::run_tests(

  #debug      => 1,
  path       => $ROOT,
  exclude    => ['local/', 'blib/', 'data/', 'lib/perl5/', 'domove'],
  perltidyrc => "$ROOT/.perltidyrc"
);

