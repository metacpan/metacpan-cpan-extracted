use strict;
use warnings;
use Test::More;
use Module::New::License;

subtest perl => sub {
  my $license = Module::New::License->object('perl', {holder => 'me', year => '2013'});
  ok $license, 'found license';
};

subtest not_found => sub {
  eval { Module::New::License->object('not_found', {holder => 'me', year => '2013'}) };
  ok $@, 'not found license';
};

done_testing;
