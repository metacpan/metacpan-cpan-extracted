# t/001_load.t - check module loading
use Test::More;

my @classes = qw(
  Slovo::Plugin::Prodan
  Slovo::Model::Poruchki
  Slovo::Controller::Poruchki
  Slovo::Command::prodan
  Slovo::Command::prodan::products
);
use_ok($_) for @classes;

done_testing();

