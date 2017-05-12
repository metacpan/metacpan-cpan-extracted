use strict;
use Test::More tests => 5;

use_ok('Sys::Signals::Block') or exit 1;

use POSIX qw(SIGHUP SIGUSR1);

Sys::Signals::Block->import(SIGHUP, SIGUSR1);

my $usr1 = 0;
my $hup  = 0;

$SIG{USR1} = sub { $usr1++ };
$SIG{HUP}  = sub { $hup++ };

Sys::Signals::Block->block;

kill SIGHUP, $$;
kill SIGUSR1, $$;

ok !$hup, 'SIGHUP was blocked';
ok !$usr1, 'SIGUSR1 was blocked';

Sys::Signals::Block->unblock;
ok $hup, 'SIGHUP was delivered';
ok $usr1, 'SIGUSR1 was delivered';

