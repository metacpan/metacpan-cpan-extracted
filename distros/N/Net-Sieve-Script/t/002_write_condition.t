use Test::More tests => 13;
use strict;

use lib qw(lib);

BEGIN {
    use_ok( 'Net::Sieve::Script::Rule' );
    use_ok( 'Net::Sieve::Script::Condition');
}

my $rule = Net::Sieve::Script::Rule->new(
#   test_list => 'anyof (header :contains "Subject" "[Test]",header :contains "Subject" "[Test2]")' ,
    );


ok ($rule->add_condition('header :contains "Subject" "[Test1]"'), "add rule condition by string");
ok ($rule->add_condition('header :contains "Subject" "[Test2]"'), "add rule condition by string");
#ok ($rule->add_condition('header :contains "Subject" "[Test3]"'), "add rule condition by string");

ok ( $rule->delete_condition(1), "delete condition 1") ;

ok ( $rule->add_condition('anyof (header :contains "Subject" "[Test2]",header :contains "Subject" "[Test3]")'), "add complex condition by string");

my $cond = Net::Sieve::Script::Condition->new('header');
$cond->match_type(':contains');
$cond->key_list('"[Test4]"');
$cond->header_list('"Subject"');
ok ( $rule->add_condition($cond), "add rule condition by object");

my $parent = $rule->add_condition('allof');
ok ( $parent, "add allof block");

ok ($rule->add_condition('header :contains "Subject" "[Test5]"',$parent), "add rule to parent block");
ok ($rule->add_condition('header :contains "Subject" "[Test6]"',$parent), "add rule to parent block");


is ( $rule->add_condition('anyof',3), 0, "test error on add condition");

ok ( $rule->delete_condition(12), "delete condition 12") ;
#print $rule->write_condition."\n\n";
is ( $rule->delete_condition(18), 0, "test error on delete");

#use Data::Dumper;
#print Dumper $rule->conditions;

#print $rule->write_condition."\n\n";
