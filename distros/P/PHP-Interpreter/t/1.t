#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 6;

BEGIN {
    use_ok 'PHP::Interpreter' or die;
}
# weird hack for include path
chdir('t');
ok my $p = new PHP::Interpreter(), "Create new PHP interpreter";
ok $p->include('test.inc'), 'Add test.inc';
ok my $a1 = $p->call('ident', 1), "Including a PHP file and executing a function off it";
is $a1, 1, 'We should get the proper value from the ident() function';
eval {
    $p->include('nonexistent.inc');
};
is $@, "Error including nonexistent.inc\n", 'Failed includes should die';
