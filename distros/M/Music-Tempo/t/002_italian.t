# -*- perl -*-

# t/002_italian.t - check to and from italian names

use Test::Simple tests => 4;
use Music::Tempo;

ok(bpm_to_italian(50) eq 'Largo');
ok(italian_to_bpm('Largo') == 50);
ok(bpm_to_italian(180) eq 'Presto');
ok(italian_to_bpm('Presto') == 171);



