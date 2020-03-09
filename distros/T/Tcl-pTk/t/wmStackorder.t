use warnings;
use strict;

use Tcl::pTk;
#use Tk; # verified against Perl/Tk for compatibility

use Test::More tests => 10;

my $mw = MainWindow->new;
#my $mw_f = $mw->Frame(-height => 200, -width => 200)->pack;

my $t = $mw->Toplevel;
#my $t_f = $t->Frame(-height => 200, -width => 200)->pack;

$mw->idletasks;
print "# Lowering \$mw below \$t\n";
$mw->lower($t);
is($t->stackorder('isabove', $mw), 1, '[wm stackorder $t isabove $mw] == 1');
is($t->stackorder('isbelow', $mw), 0, '[wm stackorder $t isbelow $mw] == 0');
is($mw->stackorder('isabove', $t), 0, '[wm stackorder $mw isabove $t] == 0');
is($mw->stackorder('isbelow', $t), 1, '[wm stackorder $mw isbelow $t] == 1');
is_deeply([$mw->stackorder], [$mw->PathName, $t->PathName], '[wm stackorder $mw] eq "$mw $t"');
print "# Raising \$mw above \$t\n";
$mw->raise($t);
is($t->stackorder('isabove', $mw), 0, '[wm stackorder $t isabove $mw] == 0');
is($t->stackorder('isbelow', $mw), 1, '[wm stackorder $t isbelow $mw] == 1');
is($mw->stackorder('isabove', $t), 1, '[wm stackorder $mw isabove $t] == 1');
is($mw->stackorder('isbelow', $t), 0, '[wm stackorder $mw isbelow $t] == 0');
is_deeply([$mw->stackorder], [$t->PathName, $mw->PathName], '[wm stackorder $mw] eq "$t $mw"');

$mw->idletasks;
(@ARGV) ? MainLoop : $mw->destroy;
