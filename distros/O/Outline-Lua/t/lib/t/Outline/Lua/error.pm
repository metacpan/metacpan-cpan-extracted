package t::Outline::Lua::lua_to_perl;

use strict;
use warnings;

use Test::Class;
use Test::More 'no_plan';
use base qw( Test::Class );

use Outline::Lua;
use Data::Dumper;

my $result;

sub setup : Test( setup ) {
  my $self = shift;

  $Data::Dumper::Useqq = 1;

  $self->{lua} = Outline::Lua::new;
}

sub t01_error : Tests {
  my $self = shift;
  my $lua  = $self->{lua};

  my $lua_code = <<'EOLUA';

a

EOLUA
  ok( ! eval {$lua->run($lua_code)} );
  ok( $@ );
  
}

1;

__END__

