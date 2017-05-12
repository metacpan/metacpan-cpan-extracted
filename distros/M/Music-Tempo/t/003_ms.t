# -*- perl -*-

# t/003_ms.t - check BPM/ms calculations are OK

use Test::Simple tests => 4;
use Music::Tempo;

ok(bpm_to_ms(120) == 500);
ok(bpm_to_ms(120,8) == 250);
ok(ms_to_bpm(1000) == 60);
ok(ms_to_bpm(1000,8) == 30);

