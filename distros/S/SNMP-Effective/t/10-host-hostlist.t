use warnings;
use strict;
use lib qw(lib);
use Test::More;
use SNMP::Effective::HostList;
use SNMP::Effective::Host;

plan tests => 19;

my $list = SNMP::Effective::HostList->new;

{
    my $host = SNMP::Effective::Host->new(address => 'bar');
    is($list->length, 0, 'no hosts in hostlist');
    ok(!$list->get_host('foo'), 'foo is not in hostlist');
    ok($list->add_host(address => 'foo'), 'add foo to hostlist');
    isa_ok($list->get_host('foo'), qw/SNMP::Effective::Host/);
    ok($list->add_host($host), 'add foo to hostlist');
    is($list->length, 2, 'length is now two');
    ok($list->add_host($host), 'try to add foo to hostlist again');
    is($list->length, 2, 'length is still two, since it was the same host');
    isa_ok($list->shift, qw/SNMP::Effective::Host/);
}

{
    my $cb = sub {};
    my $pre_cb = sub {};
    my $post_cb = sub {};
    my $arg = { foo => 123 };
    $list->shift; # zero left...
    $list->add_host(
        address => 'foo',
        callback => $cb,
        arg => $arg,
        pre_collect_callback => $pre_cb,
        post_collect_callback => $post_cb,
    );

    my $host = $list->shift;
    is($host->callback, $cb, 'correct callback got added to host');
    is_deeply(scalar $host->arg, $arg, 'correct arg got added to host');

    $host->arg({ bar => 42 });
    is_deeply(scalar $host->arg, { foo => 123, bar => 42 }, 'added "bar" to host arg');

    my $tmp = 12123213132213;
    $host->address($tmp);
    $host->session(\$tmp);
    $host->varlist([$tmp]);

    is("$host", $tmp, '"$host" is overloaded to ->address');
    is($$host, $tmp, '$$host is overloaded to ->session');
    is_deeply([@$host], [$tmp], '@$host is overloaded to ->varlist');
    is($host->pre_collect_callback, $pre_cb, 'pre_collect_callback holds code');
    is($host->post_collect_callback, $post_cb, 'post_collect_callback holds code');
}

TODO: {
    local $TODO = 'this is simply not tested';
    my $host = SNMP::Effective::Host->new(address => 'bar');
    is($host->data, {}, 'need to check input/output to data()');
    is($host->clear_data, undef, 'clear_data() does not need to return anything');
}
