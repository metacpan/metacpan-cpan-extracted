use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Module::New::Loader;

subtest no_args => sub {
  my $loader = Module::New::Loader->new;

  local $@;
  my $instance = eval { $loader->load( 'Loader' ) };
  ok !$@, 'loaded successfully';
  warn $@ if $@;
  ok $instance->isa('Module::New::Loader'), 'and the loaded class is as expected';
};

subtest with_namespace => sub {
  my $loader = Module::New::Loader->new('Module::New::ForTest');

  local $@;
  my $instance = eval { $loader->load( Sample => 'File' ) };
  ok !$@, 'loaded successfully';
  warn $@ if $@;
  ok $instance->isa('Module::New::ForTest::Sample::File'), 'and the loaded class is as expected';
};

subtest fallback => sub {
  my $loader = Module::New::Loader->new('Module::New::NotFound');

  local $@;
  my $instance = eval { $loader->load( 'Loader' ) };
  ok !$@, 'loaded successfully';
  warn $@ if $@;
  ok $instance->isa('Module::New::Loader'), 'and the loaded class is as expected';
};

done_testing;
