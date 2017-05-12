use lib qw(lib ../lib);
use Test::More tests => 3;
use Su;

# Suppress load error for test convinience.
$Su::Process::SUPPRESS_LOAD_ERROR = 1;

package Test120;

my $model = {};

sub process {
  return "proc";
}

package main;
my $su = Su->new();

my $ret = $su->resolve(
  {
    proc  => 'Test120',
    model => { key1 => { 'nestkey1' => ['value'] } },
  },
  'arg1', 'arg2'
);

is( 'proc', $ret );

# Error occurs because proc field not exist.
eval {
  $ret = $su->resolve(
    {
      incorrect => 'Test120',
      model     => { key1 => { 'nestkey1' => ['value'] } },
    },
    'arg1', 'arg2'
  );
};    ## end eval

ok(1) if $@ and $@ =~ /proc not set in the passed definition./;

# Incorrect model field name.
eval {
  $ret = $su->resolve(
    {
      proc     => 'Test120',
      ng_model => { key1 => { 'nestkey1' => ['value'] } },
    },
    'arg1', 'arg2'
  );
};    ## end eval

# ok because model is not required.
is( 'proc', $ret );

