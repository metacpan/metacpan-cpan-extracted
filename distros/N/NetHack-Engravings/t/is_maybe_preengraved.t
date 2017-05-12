#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use NetHack::Engravings 'is_maybe_preengraved';

ok(is_maybe_preengraved('?d aera iur'));
ok(is_maybe_preengraved('Elbereth'));
ok(!is_maybe_preengraved('ElberethElbereth'));
ok(!is_maybe_preengraved('E gc e nEl|creth|l|e?eth'));
ok(is_maybe_preengraved('The?e ??? a|vay? |e?n s m???ir? ry?  c | ?b?u  m   c??'));
ok(is_maybe_preengraved('Hu ge? is ?  o??u??r? e?pc? c?cc ??? a |og?'));
ok(is_maybe_preengraved('? ?i c o  c?  ? r?rg  ?? ?   s  s | ?? i  ro?  r?h?n c?'));
ok(!is_maybe_preengraved('E      L ? ?   L? __  ELL      ?    |   F ?  EF-|? E  _  [|'));

done_testing;
