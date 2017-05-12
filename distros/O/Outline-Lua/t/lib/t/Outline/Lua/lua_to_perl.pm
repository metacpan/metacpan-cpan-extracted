package t::Outline::Lua::lua_to_perl;

use strict;
use warnings;

use Test::Class;
use Test::More 'no_plan';
use base qw( Test::Class );

use Outline::Lua;
use Data::Dumper;

my $result;

# These are here until I implement funcref registration.
sub _print {
  $result = \@_;
#  print Dumper \@_;
}

sub setup : Test( setup ) {
  my $self = shift;

  $Data::Dumper::Useqq = 1;

  $self->{lua} = Outline::Lua::new;

  $self->{lua}->register_perl_func(
    perl_func => __PACKAGE__ . '::_print',
    lua_name  => 'print',
  );
}

sub t01_nil : Test( 1 ) {
  my $self = shift;
  my $lua  = $self->{lua};

  my $lua_code = <<'EOLUA';
print( a )

EOLUA

  $lua->run( $lua_code );

  is_deeply( $result, [ undef ] );
}

sub t02_string : Tests {
  my $self = shift;
  my $lua  = $self->{lua};

  my $lua_code = <<'EOLUA';
a = "foo\n"
print( a )

EOLUA

  $lua->run( $lua_code );

  is_deeply( $result, [ "foo\n" ] );
}

sub t03_number : Test( 1 ) {
  my $self = shift;
  my $lua  = $self->{lua};

  my $lua_code = <<'EOLUA';
a = 10
b = 1.1
c = 0.1e-10
d = 0.1e10
print( a, b, c, d )

EOLUA

  $lua->run( $lua_code );

  is_deeply( $result, [ 10, 1.1, 1e-11, 1e9 ] );
}

sub t04_boolean : Test( 3 ) {
  my $self = shift;
  my $lua  = $self->{lua};

  my $lua_code = <<'EOLUA';
a = true
b = false
print( a, b )

EOLUA

  $lua->run( $lua_code );

  is_deeply( $result, [ $Outline::Lua::TRUE, $Outline::Lua::FALSE ] );
  ok( $result->[0] );
  ok( ! $result->[1] );
}

sub t05_hash : Test( 3 ) {
  my $self = shift;
  my $lua  = $self->{lua};

  my $lua_code = <<'EOLUA';
a = {}
a["foo"] = "one"
a["bar"] = "two"
print( a )

EOLUA

  $lua->run( $lua_code );

  is_deeply( $result, [ { foo => 'one', bar => 'two' } ] );
  
  TODO: {
    todo_skip "Not implemented: auto-arrayification", 2 if ! eval { $lua->auto_arrayify(1) };

    $lua_code = <<'EOLUA';
a = {}
a[1] = "one"
a[2] = "two"
print( a )

EOLUA

    $lua->run( $lua_code );
    is_deeply( $result, [[ qw( one two ) ]] );

    $lua->auto_arrayify(0);
    $lua_code = <<'EOLUA';
a = {}
a[1] = "one"
a[2] = "two"
print( a )

EOLUA

    $lua->run( $lua_code );
    is_deeply( $result, [ { qw( 1 one 2 two ) } ] );
  }
}
1;

__END__

