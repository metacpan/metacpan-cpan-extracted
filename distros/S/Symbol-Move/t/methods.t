use strict;
use warnings;

use Test::More;
use Symbol::Methods;

BEGIN {
    package AAA;

    use vars qw/$aaai/;
    sub aaa { 'aaa' }
    our $aaa = 'aaa';
    our @aaa = ('a', 'a', 'a');
    our %aaa = (a => 'a');

    package BBB;

    sub bbb { 'bbb' }
    our $bbb = 'bbb';
    our @bbb = ('b', 'b', 'b');
    our %bbb = (b => 'b');

    package CCC;

    sub ccc { 'ccc' }
    our $ccc = 'ccc';
    our @ccc = ('c', 'c', 'c');
    our %ccc = (c => 'c');
}

ok(AAA->symbol::exists('&aaa'), 'AAA has &aaa');
ok(AAA->symbol::exists('$aaa'), 'AAA has $aaa');
ok(AAA->symbol::exists('@aaa'), 'AAA has @aaa');
ok(AAA->symbol::exists('%aaa'), 'AAA has %aaa');
ok(AAA->symbol::exists('$aaai'), 'AAA has $aaai (imported var test)');

ok(!AAA->symbol::exists('&bbb'), 'AAA does not have &bbb');
ok(!AAA->symbol::exists('$bbb'), 'AAA does not have $bbb');
ok(!AAA->symbol::exists('@bbb'), 'AAA does not have @bbb');
ok(!AAA->symbol::exists('%bbb'), 'AAA does not have %bbb');

ok(BBB->symbol::exists('&bbb'), 'BBB has &bbb');
ok(BBB->symbol::exists('$bbb'), 'BBB has $bbb');
ok(BBB->symbol::exists('@bbb'), 'BBB has @bbb');
ok(BBB->symbol::exists('%bbb'), 'BBB has %bbb');

ok(!BBB->symbol::exists('&aaa'), 'BBB does not have &aaa');
ok(!BBB->symbol::exists('$aaa'), 'BBB does not have $aaa');
ok(!BBB->symbol::exists('@aaa'), 'BBB does not have @aaa');
ok(!BBB->symbol::exists('%aaa'), 'BBB does not have %aaa');

is(AAA->symbol::fetch('&aaa'), \&AAA::aaa, "fetched the subref 'AAA::aaa'");
is(AAA->symbol::fetch('$aaa'), \$AAA::aaa, "fetched the scalarref 'AAA::aaa'");
is(AAA->symbol::fetch('@aaa'), \@AAA::aaa, "fetched the arrayref 'AAA::aaa'");
is(AAA->symbol::fetch('%aaa'), \%AAA::aaa, "fetched the hashref 'AAA::aaa'");

ok(my $ref = CCC->symbol::fetch('ccc'), "got ref");
ok(CCC->symbol::exists('ccc'), "removed the symbol");
is(CCC->symbol::delete('ccc'), $ref, "got expected ref");
ok(!CCC->symbol::exists('ccc'), "removed the symbol");

ok($ref = CCC->symbol::fetch('%ccc'), "got ref");
ok(CCC->symbol::exists('%ccc'), "removed the symbol");
is(CCC->symbol::delete('%ccc'), $ref, "got expected ref");
ok(!CCC->symbol::exists('%ccc'), "removed the symbol");

ok($ref = CCC->symbol::fetch('@ccc'), "got ref");
ok(CCC->symbol::exists('@ccc'), "removed the symbol");
is(CCC->symbol::delete('@ccc'), $ref, "got expected ref");
ok(!CCC->symbol::exists('@ccc'), "removed the symbol");

ok($ref = CCC->symbol::fetch('$ccc'), "got ref");
ok(CCC->symbol::exists('$ccc'), "removed the symbol");
is(CCC->symbol::delete('$ccc'), $ref, "got expected ref");
ok(!CCC->symbol::exists('$ccc'), "removed the symbol");

{
    # Need to turn off strict so we can use strings, otherwise the parser
    # auto-vivifies the symbols.
    no strict 'refs';

    AAA->symbol::alias('aaa', 'aaa2');
    is(\&AAA::aaa, \&{'AAA::aaa2'}, "aliased the sub");

    AAA->symbol::alias('$aaa', '$aaa2');
    is(\$AAA::aaa, \${'AAA::aaa2'}, "aliased the scalar");

    AAA->symbol::alias('$aaa', 'aaa2x');
    is(\$AAA::aaa, \${'AAA::aaa2x'}, "aliased the scalar, no sigil on second name");

    AAA->symbol::alias('%aaa', '%aaa2');
    is(\%AAA::aaa, \%{'AAA::aaa2'}, "aliased the hash");

    AAA->symbol::alias('@aaa', '@aaa2');
    is(\@AAA::aaa, \@{'AAA::aaa2'}, "aliased the array");

    ok(!eval { AAA->symbol::alias('$aaa', '&aaa5'); }, "dies");
    like($@, qr/Origin and Destination symbols must be the same type, got 'SCALAR' and 'CODE'/, "got useful error");

    ok(!eval { AAA->symbol::alias('$aaa', '$aaa2'); }, "dies");
    like($@, qr/Symbol \$AAA::aaa2 already exists/, "got useful error");

    ok(!eval { AAA->symbol::alias('$aaa6', '$aaa2'); }, "dies");
    like($@, qr/Symbol \$AAA::aaa6 does not exist/, "got useful error");

    AAA->symbol::move('aaa2', 'aaa3');
    is(\&AAA::aaa, \&{'AAA::aaa3'}, "moved the sub");
    ok(!AAA->symbol::exists('aaa2'), "removed symbol");

    AAA->symbol::move('$aaa2', '$aaa3');
    is(\$AAA::aaa, \${'AAA::aaa3'}, "moved the scalar");
    ok(!AAA->symbol::exists('$aaa2'), "removed symbol");

    AAA->symbol::move('%aaa2', '%aaa3');
    is(\%AAA::aaa, \%{'AAA::aaa3'}, "moved the hash");
    ok(!AAA->symbol::exists('%aaa2'), "removed symbol");

    AAA->symbol::move('@aaa2', '@aaa3');
    is(\@AAA::aaa, \@{'AAA::aaa3'}, "moved the array");
    ok(!AAA->symbol::exists('@aaa2'), "removed symbol");

    ok(!eval { AAA->symbol::move('$aaa', '&aaa5'); }, "dies");
    like($@, qr/Origin and Destination symbols must be the same type, got 'SCALAR' and 'CODE'/, "got useful error");

    ok(!eval { AAA->symbol::move('$aaa', '$aaa3'); }, "dies");
    like($@, qr/Symbol \$AAA::aaa3 already exists/, "got useful error");

    ok(!eval { AAA->symbol::move('$aaa6', '$aaa3'); }, "dies");
    like($@, qr/Symbol \$AAA::aaa6 does not exist/, "got useful error");
}

done_testing;
