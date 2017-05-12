use strict;
use warnings;
use Test::More;
use Test::Deep qw(cmp_deeply bag);

our @R_list = qw(foo bar);
our @C_list = qw(xyzzy plugh y2);
our @I_list = qw(a b c);

{
  package The_Role;
  use Moose::Role;
  use t::Context::List;
  use t::Context::Scalar;
  use t::Context::Sensitive;

  add_list   { @R_list };
  add_scalar { @R_list };
  add_either { @R_list };
}

{
  package The_Class;
  use Moose;
  use t::Context::List;
  use t::Context::Scalar;
  use t::Context::Sensitive;

  with 'The_Role';

  sub instance_list   { @I_list }
  sub instance_scalar { @I_list }
  sub instance_either { @I_list }

  add_list   { @C_list };
  add_scalar { @C_list };
  add_either { @C_list };
}

my $obj = The_Class->new;

isa_ok($obj, 'The_Class', "our test object");

my $list_bag = bag(\@C_list, \@I_list, \@R_list);
my $want_L   = [ results => $list_bag ];
my $want_S    = bag(map { scalar @$_ } (\@R_list, \@C_list, \@I_list));

my $list_in_L = [ $obj->gather_lists ];
my $list_in_S = $obj->gather_lists;

cmp_deeply($list_in_L, $want_L,   "gather_lists in list context");
cmp_deeply($list_in_S, $list_bag, "gather_lists in scalar context")
  or note explain $list_in_S;

my $scalar_in_L = [ $obj->gather_scalars ];
my $scalar_in_S = $obj->gather_scalars;

cmp_deeply($scalar_in_L, [ results => $want_S ], 'gather_scalars in list');
cmp_deeply($scalar_in_S, $want_S, "gather_scalars in scalar context");

my $either_in_L = [ $obj->gather_either ];
my $either_in_S = $obj->gather_either;

cmp_deeply($either_in_L,  $want_L,   "gather_either in list context");
cmp_deeply($either_in_S, $want_S, "gather_either in scalar context");

done_testing;
