# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More;
use warnings;
use strict;

for (qw /Synapse::CLI::Config Synapse::CLI::Config::Type Synapse::CLI::Config::Object/) {
    eval "use $_";
    my $ok = $@ ? 0 : 1;
    ok ($ok, "use $_");
}

$Synapse::CLI::Config::BASE_DIR        = "./t/data";
$Synapse::CLI::Config::BASE_DIR        = "./t/data";
$Synapse::CLI::Config::ALIAS->{type}   = 'Synapse::CLI::Config::Type';
$Synapse::CLI::Config::ALIAS->{object} = 'Synapse::CLI::Config::Object';
$Synapse::CLI::Config::ALIAS->{foo}    = 'Foo';


my $l = Synapse::CLI::Config::execute (qw /type object list/);
for (@{$l}) {
    Synapse::CLI::Config::execute ('object', $_, 'remove');
};
$l = Synapse::CLI::Config::execute ('type', 'object', 'list');
ok (@{$l} == 0, 'no object left');

my $c = Synapse::CLI::Config::execute (qw /type object count/);
ok ($c == 0, 'count()');

my $test = Synapse::CLI::Config::execute (qw /type object create test/, "This is a test");
is ($test->name(), 'test', 'name()');
is ($test->label(), 'This is a test', 'label()');

my $test2 = Synapse::CLI::Config::Object->new ('test');
is ($test2->name(), 'test', 'name()');
is ($test2->label(), 'This is a test', 'label()');

$test2 = Synapse::CLI::Config::execute (qw /object test copy-as test2/);
is ($test2->name(), 'test2', 'name()');
is ($test2->label(), 'This is a test', 'label()');

$test2 = Synapse::CLI::Config::execute (qw /object test rename-to test3/);
is ($test2->name(), 'test3', 'name()');

my $test3 = Synapse::CLI::Config::Object->new ('test3');
is ($test3->name(), 'test3', 'name()');
is ($test3->label(), 'This is a test', 'label()');

my $o = $test2;
$o->set ('foo', 'bar');
is ($o->{foo}, 'bar', 'set');

$o->del ('foo');
ok (!$o->{foo}, 'del');

$o->list_push ('list', 'foo');
$o->list_push ('list', 'bar');
$o->list_push ('list', 'baz');

is ($o->{list}->[0], 'foo', 'list_push#0');
is ($o->{list}->[1], 'bar', 'list_push#1');
is ($o->{list}->[2], 'baz', 'list_push#2');

$o->list_pop ('list');
is ($o->{list}->[0], 'foo', 'list_pop#0');
is ($o->{list}->[1], 'bar', 'list_pop#1');
ok (!$o->{list}->[2], 'list_pop#2');

$o->list_shift ('list');
is ($o->{list}->[0], 'bar', 'list_shift#0');
ok (!$o->{list}->[1], 'list_shift#1');

$o->list_unshift ('list', 'foo');
is ($o->{list}->[0], 'foo', 'list_unshift#0');
is ($o->{list}->[1], 'bar', 'list_unshift#1');
ok (!$o->{list}->[2], 'list_unshift#2');

$o->list_del ('list', 0);
is ($o->{list}->[0], 'bar', 'list_del#0');
ok (!$o->{list}->[1], 'list_del#1');

$o->list_add ('list', 0, 'foo');
is ($o->{list}->[0], 'foo', 'list_add#0');
is ($o->{list}->[1], 'bar', 'list_add#1');
ok (!$o->{list}->[2], 'list_add#2');

$o->set_add (qw /basket orange/);
$o->set_add (qw /basket kiwi/);
$o->set_add (qw /basket banana/);
$o->set_add (qw /basket kiwi/);
$o->set_add (qw /basket kiwi/);

$l = $o->set_list('basket');
ok ($l->[0], "banana");
ok ($l->[1], "kiwi");
ok ($l->[2], "orange");

Test::More::done_testing();

__END__
