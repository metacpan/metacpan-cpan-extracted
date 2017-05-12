#!/usr/bin/perl -w

use strict;

use Net::DRI::Data::Contact;

use Test::More tests => 13;

can_ok('Net::DRI::Data::Contact',qw/new id validate name org street city sp pc cc email voice fax loid roid srid auth disclose/);

my $s=Net::DRI::Data::Contact->new();
isa_ok($s,'Net::DRI::Data::Contact');


$s->name('Test');
is(scalar($s->name()),'Test','Scalar access (simple set)');
my @d=$s->name();
is_deeply(\@d,['Test'],'List access (simple set)');

$s->name('Test1','Test2');
is(scalar($s->name()),'Test1','Scalar access (double set)');
@d=$s->name();
is_deeply(\@d,['Test1','Test2'],'List access (double set)');


$s->street(['A1','A2']);
is_deeply(scalar($s->street()),['A1','A2'],'street() Scalar access (simple set)');
@d=$s->street();
is_deeply(\@d,[['A1','A2']],'street() List access (simple set)');

$s->street(['A1','A2'],['B1','B2']);
is_deeply(scalar($s->street()),['A1','A2'],'street() Scalar access (double set)');
@d=$s->street();
is_deeply(\@d,[['A1','A2'],['B1','B2']],'street() List access (double set)');


$s=Net::DRI::Data::Contact->new();
$s->org('Something é');
$s->loc2int();
is_deeply([$s->org()],['Something é','Something ?'],'loc2int()');
$s->int2loc();
is_deeply([$s->org()],['Something ?','Something ?'],'int2loc()');

TODO: {
        local $TODO="tests on validate()";
        ok(0);
}

exit 0;
