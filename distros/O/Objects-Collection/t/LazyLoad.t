# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Object-Collection.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More 'no_plan';    #tests => 'noplan';

use Test::More tests =>8 ;
use Data::Dumper;

BEGIN {
    use_ok('Objects::Collection::LazyObject');
}

package test_for_lazy;
$test_for_lazy::is_load = 0;

sub new {
    my $class = shift;
    $test_for_lazy::is_load = 1;
    $class = ref $class if ref $class;
    my $self = bless( {}, $class );
}

sub set_flag {
    my $self = shift;
    $test_for_lazy::is_load = shift;
}

sub nop {};
package main;
our $test_var = 0;
ok $test_for_lazy::is_load == 0, "check flag before load";
my $obj = new test_for_lazy::;
ok $test_for_lazy::is_load == 1, "check flag after load";
$obj->set_flag(0);
ok $test_for_lazy::is_load == 0, "check obj->set_flag(0)";

isa_ok (( my $lazy = new Objects::Collection::LazyObject:: sub { new test_for_lazy:: } ),
  'Objects::Collection::LazyObject', "create lazy");
ok $test_for_lazy::is_load == 0, "check obj->set_flag(0)";
$lazy->nop;
ok $test_for_lazy::is_load == 1, "check create from lazy";
$lazy->set_flag(2);
ok $test_for_lazy::is_load == 2, "check lazy->set_flag(2)";

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

