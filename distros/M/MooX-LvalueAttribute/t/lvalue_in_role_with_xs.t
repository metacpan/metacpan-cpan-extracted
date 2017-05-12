use strictures 1;
use Test::More;

use Method::Generate::Accessor;

$Method::Generate::Accessor::CAN_HAZ_XS
  or plan( skip_all => 'Need Class::XSAccessor to run these tests' );

{
    package MyRole;
    use Moo::Role;
    use MooX::LvalueAttribute;

    has three => (
                  is => 'rw',
                  lvalue => 1,
                 );

    has two => (
                is => 'rw',
                lvalue => 1,
               );

}

{
    package MooLvalue;
    use Moo;

    with ('MyRole');


    has four => (
                  is => 'rw',
                  lvalue => 1,
                 );

}

{
    package MooNoLvalue;
    use Moo;

    has two => (
                is => 'rw',
                lvalue => 1,
               );

    has four => (
                is => 'rw',
                lvalue => 1,
               );

}


my $lvalue = MooLvalue->new(one => 5, two => 6, three => 3);
is $lvalue->two, 6, "normal getter works";
$lvalue->two(43);
is $lvalue->two, 43, "normal setter still works";

$lvalue->two = 42;
is $lvalue->two, 42, "lvalue set works, defined in a role";
is $lvalue->_lv_two(), 42, "underlying getter works";

$lvalue->three = 3;
is $lvalue->three, 3, "lvalue set works for a second attribute";
is $lvalue->_lv_three(), 3, "underlying getter works for a second attribute";

eval { $lvalue->_lv_four() };
like $@, qr/Can't locate object method "_lv_four"/, "this attr has no lvalue";

my $lvalue2 = MooLvalue->new(two => 7);
is $lvalue2->two, 7, "different instances have different values";

my $lvalue3 = MooNoLvalue->new(two => 7, four => 8);
eval { $lvalue3->_lv_two() };
like $@, qr/Can't locate object method "_lv_two"/, "a class without lvalue - first attribute";
eval { $lvalue3->_lv_four() };
like $@, qr/Can't locate object method "_lv_four"/, "a class without lvalue - second attribute";

done_testing;
