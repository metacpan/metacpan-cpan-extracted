use warnings;
use strict;
use lib qw(lib);
use Test::More;
use SNMP::Effective::VarList;
use SNMP::Effective::Dispatch;

plan tests => 11;

tie my @varlist, 'SNMP::Effective::VarList';

{
    eval { push @varlist, 'foo' };
    like($@, qr{A list of array}, 'failed to push foo to @varlist');
    eval { push @varlist, [1] };
    like($@, qr{Each array}, 'failed to push [1] to @varlist');
    eval { push @varlist, ['foo', 1] };
    like($@, qr{The first element}, 'failed to push [foo, 1] to @varlist');
}

{
    push @varlist, ['get', '1.2.3'];
    is($varlist[0]->[0], 'get', 'action "get" got pushed');
    isa_ok($varlist[0]->[1], 'SNMP::VarList');
    isa_ok($varlist[0]->[1][0], 'SNMP::Varbind');
    is($varlist[0]->[1][0][0], '1.2.3', '0->1->0->0 == 1.2.3');
}

{
    push @varlist, ['get', SNMP::Varbind->new(['2.3.4'])];
    is($varlist[1]->[1][0][0], '2.3.4', '1->1->0->0 == 2.3.4');
}

{
    is(push(@varlist, ['get', SNMP::VarList->new(['3.4.5'], ['4.5.6'])]), 3, 'three items total in list');
    is($varlist[2]->[1][0][0], '3.4.5', '2->1->0->0 == 3.4.5');
    is($varlist[2]->[1][1][0], '4.5.6', '2->1->0->1 == 4.5.6');
}
