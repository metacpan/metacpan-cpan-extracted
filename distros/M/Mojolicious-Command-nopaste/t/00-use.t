use Mojo::Base -strict;
use Test::More;

sub test_require {
  my $module = shift;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  ok eval "require $module; 1", "load $module";
}

test_require 'Mojolicious::Command::nopaste';
test_require 'Mojolicious::Command::nopaste::Service';

my @services = qw/debian fpaste gist mathbin pastie shadowcat sprunge ubuntu/;

test_require "Mojolicious::Command::nopaste::Service::$_" foreach @services;

done_testing;

