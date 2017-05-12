use Test::More tests => 17;
use strict;

use lib qw(lib);

BEGIN {
    use_ok( 'Net::Sieve::Script::Rule' );
    use_ok( 'Net::Sieve::Script::Action');
}

my $rule = Net::Sieve::Script::Rule->new(
        test_list => 'header :contains "Subject" "[Test]"' ,
        );

is( $rule->delete_action(0), 0, "test error delete action 0 ");
is( $rule->delete_action(1), 0, "test error delete action 1 ");
is( $rule->find_action(1), 0, "test error find action 1 ");

$rule->add_action('fileinto "Test1"');
isa_ok($rule->find_action(1),'Net::Sieve::Script::Action');
is( $rule->find_action(5), 0, "test error find action 5 ");

is ($rule->write_action,"    fileinto \"Test1\";\n",'add fileinto "Test1"');
$rule->add_action("stop");
is ($rule->write_action,"    fileinto \"Test1\";\n    stop;\n",'add stop');
 
ok( $rule->delete_action(2), "delete action 2 (stop)");
is( $rule->delete_action(5), 0, "test error delete action 5 ");

my $action = Net::Sieve::Script::Action->new("discard");
$rule->add_action($action);
is ($rule->write_action,"    fileinto \"Test1\";\n    discard;\n",'add Action object discard');
$rule->add_action("stop");

#print $rule->write_action."\n\n";

ok($rule->swap_actions(1,3),'swap actions');
is($rule->swap_actions(1,1), 0, "test swap_actions error");
is($rule->swap_actions(1,0), 0, "test swap_actions error");
is($rule->swap_actions(5,1), 0, "test swap_actions error");

$rule->add_action("keep; stop;");
isa_ok($rule->find_action(5),'Net::Sieve::Script::Action',"add list command 4 and 5, 5");
#print $rule->write_action;


