package t::Outline::Lua::register_func;

use strict;
use warnings;

use Data::Dumper;

use Test::Class;
use Test::More 'no_plan';
use base qw( Test::Class );

use Outline::Lua;

my $test;

sub test {
  $test = [ @_ ];
}

sub setup : Test( setup ) {
  my $self  = shift;

  $self->{lua} = Outline::Lua::new;
  $self->{lua}->register_perl_func(perl_func => 't::Outline::Lua::register_func::test'); 
}

sub t01_all : Test(7) {
  my $self  = shift;

  my %register = ( 
    str   => 'string',
    t     => $Outline::Lua::TRUE,
    f     => $Outline::Lua::FALSE,
    fl    => 0.01,
    int   => 10,
    arr   => [ 1..5 ],
    hash  => { 'a' .. 'h' },
  );
  $self->{lua}->register_vars( %register );

  for (keys %register) {
    my $code = <<EOLUA;

    test( $_ )

EOLUA

    $self->{lua}->run( $code );

    is_deeply( $test, [ $register{$_} ], "$_ is $register{$_}" );
  }
}

# sub t02_numbers : Tests {
#   my $self  = shift;
# 
#   $self->{lua}->register_vars( num => 10, f => 0.01 );
#   my $code = <<EOLUA;
# 
#   test( num )
# 
# EOLUA
#   $self->{lua}->run( $code );
# 
#   is_deeply( $test, 10 );
# 
#   my $code = <<EOLUA;
# 
#   test( f )
# 
# EOLUA
# 
#   $self->{lua}->run( $code );
#   is_deeply( $test, 0.01 );
# }
# 
# sub t03_boolean : Tests {
#   my $self  = shift;
# 
#   $self->{lua}->register_vars( 
#     t => $Outline::Lua::TRUE, 
#     f => $Outline::Lua::FALSE,
#   );
#   my $code = <<EOLUA;
# 
#   test( t )
# 
# EOLUA
#   $self->{lua}->run( $code );
# 
#   is_deeply( $test, $Outline::Lua::TRUE );
# 
#   my $code = <<EOLUA;
# 
#   test( f )
# 
# EOLUA
# 
#   $self->{lua}->run( $code );
#   is_deeply( $test, $Outline::Lua::FALSE );
# }
# 
1;

__END__

