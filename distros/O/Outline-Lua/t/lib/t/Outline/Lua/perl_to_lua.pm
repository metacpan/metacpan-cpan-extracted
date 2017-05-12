package t::Outline::Lua::perl_to_lua;

use strict;
use warnings;

use Data::Dumper;
use Test::Class;
use Test::More 'no_plan';
use base qw( Test::Class );

use Outline::Lua;

my $return_type;
my $return_val;

sub print_type {
  undef $return_type;
  $return_type = [@_];
}

sub print_val {
  undef $return_val;
  $return_val = [@_];
}

sub local_print_type {
  return [@_];
}

# These are here until I implement funcref registration.
sub test_nothing {
  print_type;
  print_val;
  return;
}

sub test_hashref {
  +{
    test1 => 'one',
    test2 => 'two',
  };
}

sub test_arrayref {
  [
    1..10
  ];
}

sub test_string {
  "foo";
}

sub test_number {
  10
}

sub test_multivar {
  1..10;
}

sub test_undef {
  undef;
}

sub test_true {
  $Outline::Lua::TRUE;
}

sub test_false {
  $Outline::Lua::FALSE;
}

sub run {
  my $self = shift;
  my $func = shift;
  my $code = shift;

  $self->{lua}->register_perl_func(
    perl_func => __PACKAGE__ . '::' . $func,
  );
  $self->{lua}->run($code);
}

sub setup : Test( setup ) {
  my $self = shift;

  $self->{lua} = Outline::Lua::new;

  $self->{lua}->register_perl_func(
    perl_func => __PACKAGE__ . '::print_val',
  );
  $self->{lua}->register_perl_func(
    perl_func => __PACKAGE__ . '::print_type',
  );
}

sub t01_nothing : Tests {
  my $self = shift;
  
  $self->run('test_nothing', 'test_nothing()');

  is_deeply($return_type, [], "Nothing returned");
  is_deeply($return_val, [], "Nothing printed");
}

sub t02_array_ref : Tests {
  my $self = shift;

  $self->run('test_arrayref', <<EOLUA);
foo = test_arrayref()
print_type(type(foo))
print_val(foo)
EOLUA

  is_deeply($return_type, ['table'], "Table created");

  my $actual_val = local_print_type(test_arrayref());
  is_deeply($return_val, $actual_val, "Looks right");
}

sub t03_hash_ref : Tests {
  my $self = shift;

  $self->run('test_hashref', <<EOLUA);
foo = test_hashref();
print_type(type(foo));
print_val(foo)

EOLUA

  is_deeply($return_type, ['table'], "Table created");

  my $actual_val = local_print_type(test_hashref());
  is_deeply($return_val, $actual_val, "Looks right");
}

sub t04_string : Tests {
  my $self = shift;

  $self->run('test_string', <<EOLUA);
foo = test_string()
print_type(type(foo))
print_val(foo)

EOLUA
  
  is_deeply($return_type, ['string'], "String created"); 

  my $actual_val = local_print_type(test_string());
  is_deeply($return_val, $actual_val, "Looks right");
}

sub t05_number : Tests {
  my $self = shift;

  $self->run('test_number', <<EOLUA);
foo = test_number()
print_type(type(foo))
print_val(foo)

EOLUA

  is_deeply($return_type, ['number'], "Number created"); 

  my $actual_val = local_print_type(test_number());
  is_deeply($return_val, $actual_val, "Looks right");
}

sub t06_multivar : Tests {
  my $self = shift;

  $self->run('test_multivar', <<EOLUA);
a,b,c,d,e,f,g,h,i,j = test_multivar()
print_type(type(a), type(b), type(c), type(d), type(e), type(f), type(g), type(h), type(i), type(j))
print_val(a,b,c,d,e,f,g,h,i,j)

EOLUA

  is_deeply($return_type, [("number") x 10], "Ten numbers created.");

  my $actual_val = local_print_type(test_multivar());
  is_deeply($return_val, $actual_val, "Look OK") or diag Dumper($return_val);
}

sub t07_boolean : Tests {
  my $self = shift;

  $self->run('test_true', <<EOLUA);
t = test_true()
print_type(type(t))
print_val(t)
EOLUA

  is_deeply($return_type, ['boolean'], "Boolean created");
  my $actual_val = local_print_type(test_true());
  is_deeply($return_val, $actual_val);

  $self->run('test_false', <<EOLUA);
f = test_false()
print_type(type(f))
print_val(f)
EOLUA

  is_deeply($return_type, ['boolean'], "Boolean created");
  $actual_val = local_print_type(test_false());
  is_deeply($return_val, $actual_val);
}

1;

__END__

