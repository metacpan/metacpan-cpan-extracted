use lib './blib/lib';
local $/;
warn "\nfoo\n";
eval "use Test::More tests => 1;";
close STDOUT;

use_ok(POE::Session::Irssi);
Irssi::command('^quit');
