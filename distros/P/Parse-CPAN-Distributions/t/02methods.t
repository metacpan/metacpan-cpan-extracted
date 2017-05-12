#!/usr/bin/perl -w
use strict;

use Test::More  tests => 2*27;
use Parse::CPAN::Distributions;

my @files = (
    't/samples/find-ls',
    't/samples/find-ls.gz',
);

my @list;

for my $file (@files) {
    my $obj = Parse::CPAN::Distributions->new(file => $file);
    isa_ok($obj,'Parse::CPAN::Distributions');

    ok(!$obj->listed());
    ok( $obj->listed('Test-CPAN-Meta'));
    ok( $obj->listed('Test-CPAN-Meta','0.12'));
    ok(!$obj->listed('Test-CPAN-Meta','0.01'));
    ok(!$obj->listed('Test-CPAN-Meta','0.99'));
    ok(!$obj->listed('NonExistentModule'));

    @list = $obj->distributions_by('BARBIE');   is(scalar(@list),27);
    @list = $obj->distributions_by('EIBRAB');   is(scalar(@list),0);
    @list = $obj->distributions_by();           is(scalar(@list),0);

    is($obj->latest_version(),0);
    is($obj->latest_version('NonExistentModule'),0);
    is($obj->latest_version('CPAN-WWW-Testers-Generator'),'0.27');
    is($obj->latest_version('CPAN-WWW-Testers-Generator','BARBIE'),'0.27');
    is($obj->latest_version('CPAN-WWW-Testers-Generator','LBROCARD'),'0.22');

    @list = $obj->versions('CPAN-WWW-Testers-Generator');               is(scalar(@list),6);# print "\n#list=@list [$#list][".(scalar(@list))."]\n";
    @list = $obj->versions('CPAN-WWW-Testers-Generator','BARBIE');      is(scalar(@list),5);
    @list = $obj->versions('CPAN-WWW-Testers-Generator','LBROCARD');    is(scalar(@list),1);
    @list = $obj->versions('CPAN-WWW-Testers-Generator','EIBRAB');      is(scalar(@list),0);
    @list = $obj->versions('NonExistentModule');                        is(scalar(@list),0);
    @list = $obj->versions();                                           is(scalar(@list),0);

    is($obj->author_of(),undef);
    is($obj->author_of('NonExistentModule','0.01'),undef);
    is($obj->author_of('CPAN-WWW-Testers-Generator'),undef);
    is($obj->author_of('CPAN-WWW-Testers-Generator','0.01'),undef);
    is($obj->author_of('CPAN-WWW-Testers-Generator','0.27'),'BARBIE');
    is($obj->author_of('CPAN-WWW-Testers-Generator','0.22'),'LBROCARD');
}
