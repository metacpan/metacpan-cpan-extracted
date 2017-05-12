use Test::More tests => 18;
use Taint::Util ();

sub unimport
{
    undef *$_ for qw(taint untaint tainted);
}

ok(!defined &taint,   'taint unexported');
ok(!defined &untaint, 'untaint unexported');
ok(!defined &tainted, 'tainted unexported');

Taint::Util->import;
ok(defined &taint,   'taint exported');
ok(defined &untaint, 'untaint exported');
ok(defined &tainted, 'tainted exported');

unimport();
ok(!(defined &taint), 'taint unexported');
ok(!(defined &untaint), 'untaint unexported');
ok(!(defined &tainted), 'tainted unexported');

unimport();
Taint::Util->import(qw(taint));
ok(defined &taint, 'taint exported');
ok(!(defined &untaint), 'untaint unexported');
ok(!(defined &tainted), 'tainted unexported');

unimport();
Taint::Util->import(qw(taint untaint));
ok(defined &taint, 'taint exported');
ok(defined &untaint, 'untaint exported');
ok(!(defined &tainted), 'tainted unexported');

unimport();
Taint::Util->import(qw(taint untaint tainted));
ok(defined &taint, 'taint exported');
ok(defined &untaint, 'untaint exported');
ok(defined &tainted, 'tainted unexported');
