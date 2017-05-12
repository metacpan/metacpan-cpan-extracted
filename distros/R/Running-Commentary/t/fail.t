use 5.014;

use Test::Effects;

plan tests => 5;

use Running::Commentary;
run_with -nocolour;

effects_ok { run 'Default fail' => 'hhasjkhahsahjkds'; }
           {
                return => undef,
                stdout => qr/\ADefault fail...failed to execute/,
           };


use Running::Commentary fail => 'die';
effects_ok { run 'Default fail' => 'hhasjkhahsahjkds'; }
           {
                stdout => qr/\ADefault fail...failed to execute/,
                die => qr/\ADefault fail failed to execute/,
           };

my $fail_flag;
use Running::Commentary fail => \$fail_flag;
effects_ok { run 'Default fail' => 'hhasjkhahsahjkds'; }
           {
                return => undef,
                stdout => qr/\ADefault fail...failed to execute/,
           };
like "@$fail_flag", qr/\ADefault fail failed to execute/ => 'Correct error msg';

effects_ok { Running::Commentary->import(sub{}) }
           {
                die => qr/\ABad argument to 'use Running::Commentary' \(expected: 'fail' => \$fail_mode\)/,
           };





