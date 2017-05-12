use strictures 1;
use Test::More;

eval {
    package MooLvalueBroken;
    use Moo;
    use MooX::LvalueAttribute;

    has one => (
                is => 'ro',
                lvalue => 1,
               );
};

like $@, qr/lvalue was set but no accessor nor reader/, "can't set an lvalue on a ro attribute";

{
    package MooLvalue;
    use Moo;
    use MooX::LvalueAttribute;

    has two => (
                is => 'rw',
                lvalue => 1,
               );

    has three => (
                is => 'rw',
                lvalue => 1,
               );

    has four => (
                is => 'rw',
               );

    1;
}

my $lvalue = MooLvalue->new(one => 5, two => 6);
is $lvalue->two, 6, "normal getter works";
$lvalue->two(43);
is $lvalue->two, 43, "normal setter still works";

$lvalue->two = 42;
is $lvalue->two, 42, "lvalue set works";
is $lvalue->_lv_two(), 42, "underlying getter works";

$lvalue->three = 3;
is $lvalue->three, 3, "lvalue set works for a second attribute";
is $lvalue->_lv_three(), 3, "underlying getter works for a second attribute";

eval { $lvalue->four = 4; };
like $@, qr/Can't modify non-lvalue subroutine|Modification of a read-only value attempted/, "an attribute without lvalue";

my $lvalue2 = MooLvalue->new(two => 7);
is $lvalue2->two, 7, "different instances have different values";

my $lvalue3 = MooLvalue->new(two => 'foo');
is $lvalue3->two, 'foo', "not numerical values getter works";
$lvalue3->two = 'bar';
is $lvalue3->two, 'bar', "not numerical values setter works";

done_testing;
