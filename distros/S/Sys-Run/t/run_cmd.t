#!perl -w

use strict;
use warnings;

use File::Temp;
use File::Blarf;
use Sys::Run;
use Test::MockObject::Universal;
use Test::More tests => 30;

my $Logger = Test::MockObject::Universal::->new();
my $tempdir = File::Temp::tempdir( CLEANUP => 1 );
my $logfile = $tempdir.'/logfile';
my $outfile = $tempdir.'/outfile';
my $cmd = 'echo OK';

my $Run = Sys::Run::->new({
  'logger'  => $Logger,
});
# Test Logfile
ok($Run->run_cmd($cmd, { Logfile => $logfile, }, ));
my @content = File::Blarf::slurp($logfile);
ok(grep( {/CMD: echo OK/} @content));
ok(grep( {/OK/} @content));
ok(grep( {/CMD finished. Exit Code: 0/} @content));
@content = ();
unlink($logfile);
# Test DryRun
ok($Run->run_cmd($cmd, { Logfile => $logfile, DryRun => 1, }, ));
@content = File::Blarf::slurp($logfile);
ok(grep( {/CMD: echo OK/} @content));
ok(grep( {/CMD finished in DryRun mode. Faking exit code: 0/} @content));
@content = File::Blarf::slurp($outfile);
ok(!grep( {/OK/} @content));
# Test CaptureOutput
# - w/ Outfile
# - - w/Append
File::Blarf::blarf($outfile,'First line');
ok($Run->run_cmd($cmd, { CaptureOutput => 1, Outfile => $outfile, Append => 1, }, ));
@content = File::Blarf::slurp($outfile);
ok(grep( {/First line/} @content));
ok(grep( {/OK/} @content));
@content = ();
unlink($outfile);
# - - w/o Append
File::Blarf::blarf($outfile,'First line');
ok($Run->run_cmd($cmd, { CaptureOutput => 1, Outfile => $outfile, Append => 0, }, ));
@content = File::Blarf::slurp($outfile);
ok(grep( {!/First line/} @content));
ok(grep( {/OK/} @content));
@content = ();
unlink($outfile);
# - w/o Outfile
is($Run->run_cmd('echo -n OK', { CaptureOutput => 1, }, ),'OK');
is($Run->run_cmd($cmd, { CaptureOutput => 1, }, ),"OK\n");
is($Run->run_cmd($cmd, { CaptureOutput => 1, Chomp => 1, }, ),'OK');
# - w/ STDERR redirect
is($Run->run_cmd(q{perl -le'print STDERR DANCINGONERROR; print STDOUT DANCINGONOUT' 2>}.$outfile, { CaptureOutput => 1, Chomp => 1, }, ), 'DANCINGONOUT');
@content = File::Blarf::slurp($outfile);
ok(grep( {/DANCINGONERROR/} @content));
@content = ();
unlink($outfile);
# - w/o STDERR redirect
is($Run->run_cmd(q{perl -le'print STDERR DANCINGONERROR; print STDOUT DANCINGONOUT'}, { CaptureOutput => 1, Chomp => 1, }, ), "DANCINGONERROR\nDANCINGONOUT");
# - w/o CaptureOutput or Logfile
ok($Run->run_cmd(q{perl -le'print STDERR DANCINGONERROR; print STDOUT DANCINGONOUT'}, { CaptureOutput => 0, }, ));
# Test Timeout
my $t0 = time();
isnt($Run->run_cmd('sleep 60', { Timeout => 1, }, ), 1);
my $d0 = time() - $t0;
ok($d0 < 30);
# Test ReturnRV
# - w/ ReturnRV == 0 and exit 0
is($Run->run_cmd('true', { ReturnRV => 0, }, ), 1);
# - w/ ReturnRV == 0 and exit 1
isnt($Run->run_cmd('false', { ReturnRV => 0, }, ), 1);
# - w/ ReturnRV == 1 and exit 0
is($Run->run_cmd('true', { ReturnRV => 1, }, ), 0);
# - w/ ReturnRV == 1 and exit 1
is($Run->run_cmd('false', { ReturnRV => 1, }, ), 1);

# Test SSH Options
like($Run->_ssh_opts(), qr/oBatchMode=yes/, 'SSH Options contain ssh Batch Mode');
unlike($Run->_ssh_opts(), qr/oStrictHostKeyChecking=no/, 'SSH Options do not contain StrictHostKeyChecking=no');
$Run->ssh_hostkey_check(0);
like($Run->_ssh_opts(), qr/oStrictHostKeyChecking=no/, 'SSH Options do contain StrictHostKeyChecking=no');

