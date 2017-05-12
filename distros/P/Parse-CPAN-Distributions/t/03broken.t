#!/usr/bin/perl -w
use strict;

use Test::More  tests => 16;
use Parse::CPAN::Distributions;

my @list;

{
    my $obj = Parse::CPAN::Distributions->new(file => 't/samples/find-ls-test.txt');
    isa_ok($obj,'Parse::CPAN::Distributions');

    ok( $obj->listed('Test-FileA'));
    ok(!$obj->listed('Test-FileA','0.01'));
    ok( $obj->listed('Test-FileB'));
    ok(!$obj->listed('Test-FileB','0.01'));

    @list = $obj->distributions_by('BARBIE');   is(scalar(@list),2);
    @list = $obj->distributions_by('EIBRAB');   is(scalar(@list),0);

    is($obj->latest_version('Test-FileA'),'');
    is($obj->latest_version('Test-FileB'),'');

    @list = $obj->versions('Test-FileA');               is(scalar(@list),1);
    @list = $obj->versions('Test-FileA','BARBIE');      is(scalar(@list),1);
    @list = $obj->versions('Test-FileB');               is(scalar(@list),1);
    @list = $obj->versions('Test-FileB','BARBIE');      is(scalar(@list),1);

    is($obj->author_of('Test-FileA',''),'BARBIE');
    is($obj->author_of('Test-FileB',''),'BARBIE');
    is($obj->author_of('Test-FileB'),undef);
}
