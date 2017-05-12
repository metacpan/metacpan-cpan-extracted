#!/usr/bin/perl -w

use strict;

use Test::More tests => 21;

BEGIN
{
  use_ok('Rose::Conf');
}

our %CONF;
MyConf->import('%CONF');

is($CONF{'COLOR'}, 'blue', 'Hash get 1');
is($CONF{'SIZE'}, 'big', 'Hash get 2');

is(MyConf->param('COLOR'), 'blue', 'param() get 1');
is(MyConf->param('SIZE'), 'big', 'param() get 2');

$CONF{'COLOR'} = 'red';
MyConf->param(SIZE => 'small');

is($CONF{'COLOR'}, 'red', 'Hash get 3');
is($CONF{'SIZE'}, 'small', 'Hash get 4');

is(MyConf->param('COLOR'), 'red', 'param() get 3');
is(MyConf->param('SIZE'), 'small', 'param() get 4');

ok(MyConf->param_exists('COLOR'), 'param_exists() 1');
ok(MyConf->param_exists('SIZE'), 'param_exists() 2');

ok(!MyConf->param_exists('color'), 'param_exists() 3');
ok(!MyConf->param_exists('nonesuch'), 'param_exists() 4');

my $hash = MyConf->conf_hash;

is($hash->{'COLOR'}, 'red', 'conf_hash() get 1');
is($hash->{'SIZE'}, 'small', 'conf_hash() get 2');

eval { MyConf->param('foo') };
ok($@, 'Nonexistent param 1');

eval { MyConf->param('HASH')->param('x') };
ok($@, 'Nonexistent param 2');

is(MyConf->param('HASH')->param('b')->param('c'), 4, 'get nested param() 1');

$CONF{'HASH'}{'b'}{'c'} = 7;
is(MyConf->param('HASH')->param('b')->param('c'), 7, 'set nested param() 1');

ok(MyConf->param('HASH')->param_exists('b'), 'nested param_exists() 1');
ok(!MyConf->param('HASH')->param_exists('x'), 'nested param_exists() 2');

BEGIN
{
  package MyConf;

  use strict;
  our @ISA = qw(Rose::Conf);

  our %CONF =
  (
    COLOR => 'blue',
    SIZE  => 'big',
    
    HASH =>
    {
      a => 3,
      b =>
      {
        c => 4,
      }
    }
  );
}
