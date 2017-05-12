package t::Outline::Lua::register_func;

use strict;
use warnings;

use Test::Class;
use Test::More 'no_plan';
use base qw( Test::Class );

use Outline::Lua;

my $test_str = "Hello, Lua!\n";
my $test_buff;
my $test_stdout;

sub setup : Test( setup ) {
  my $self = shift;

  close $test_stdout if $test_stdout;
  open  $test_stdout, '>', \$test_buff;

  $| = 1;
}

sub test_sub {
  print $test_stdout $test_str;
}

sub t01_default_name : Test( 1 ) {
  my $self = shift;
  my $lua  = Outline::Lua::new;

  $lua->register_perl_func(
    perl_func => 't::Outline::Lua::register_func::test_sub'
  );
  $lua->run('test_sub()');

  is($test_buff, $test_str, "Test registered as test_sub");
}

sub t02_specify_name : Test( 1 ) {
  my $self = shift;
  my $lua  = Outline::Lua::new;

  $lua->register_perl_func(
    perl_func => 't::Outline::Lua::register_func::test_sub',
    lua_name  => 'testfunc',
  );
  $lua->run('testfunc()');

  is($test_buff, $test_str, "Test registered as testfunc");
}

1;

__END__

