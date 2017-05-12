#!./perl -w

BEGIN {
    require Config; import Config;
    if (!$Config{'d_fork'}
        # open2/3 supported on win32 (but not Borland due to CRT bugs)
        && (($^O ne 'MSWin32' && $^O ne 'NetWare') || $Config{'cc'} =~ /^bcc/i))
      {
          print "1..0\n";
          exit 0;
      }
    # make warnings fatal
    $SIG{__WARN__} = sub { die @_ };
}

use strict;
use Test::More tests => 30;

use IO::Handle;
use POSIX::Open3;
use File::Spec;

my $perl = $^X;

sub cmd_line {
	if ($^O eq 'MSWin32' || $^O eq 'NetWare') {
		my $cmd = shift;
		$cmd =~ tr/\r\n//d;
		$cmd =~ s/"/\\"/g;
		return qq/"$cmd"/;
	}
	else {
		return $_[0];
	}
}

my ($pid, $reaped_pid);
STDOUT->autoflush;
STDERR->autoflush;

# basic
$pid = open3 'WRITE', 'READ', 'ERROR', $perl, '-e', cmd_line(<<'EOF');
    $| = 1;
    print scalar <STDIN>;
    print STDERR "hi error\n";
EOF
cmp_ok($pid, '!=', 0);
isnt((print WRITE "hi kid\n"), 0);
like(scalar <READ>, qr/^hi kid\r?\n$/);
like(scalar <ERROR>, qr/^hi error\r?\n$/);
is(close(WRITE), 1) or diag($!);
is(close(READ), 1) or diag($!);
is(close(ERROR), 1) or diag($!);
$reaped_pid = waitpid $pid, 0;
is($reaped_pid, $pid);
is($?, 0);

my $desc = "read and error together, both named";
$pid = open3 'WRITE', 'READ', 'READ', $perl, '-e', cmd_line(<<'EOF');
    $| = 1;
    print scalar <STDIN>;
    print STDERR scalar <STDIN>;
EOF
print WRITE "$desc\n";
my_is(scalar <READ>, "$desc\n");

print WRITE "$desc [again]\n";
my_is(scalar <READ>, "$desc [again]\n");
waitpid $pid, 0;

$desc = "read and error together, error empty";
$pid = open3 'WRITE', 'READ', '', $perl, '-e', cmd_line(<<'EOF');
    $| = 1;
    print scalar <STDIN>;
    print STDERR scalar <STDIN>;
EOF
print WRITE "$desc\n";
my_is(scalar <READ>, "$desc\n");

print WRITE "$desc [again]\n";
my_is(scalar <READ>, "$desc [again]\n");
waitpid $pid, 0;

is(pipe(PIPE_READ, PIPE_WRITE), 1);
$pid = open3 '<&PIPE_READ', 'READ', '',
		    $perl, '-e', cmd_line('print scalar <STDIN>');
close PIPE_READ;
print PIPE_WRITE "dup writer\n";
close PIPE_WRITE;
my_is(scalar <READ>, "dup writer\n");
waitpid $pid, 0;

my $TB = Test::Builder->new();
my $test = $TB->current_test;
# dup reader
$pid = open3 'WRITE', '>&STDOUT', 'ERROR',
		    $perl, '-e', cmd_line('print scalar <STDIN>');
++$test;
print WRITE "ok $test\n";
waitpid $pid, 0;

# dup error:  This particular case, duping stderr onto the existing
# stdout but putting stdout somewhere else, is a good case because it
# used not to work.
$pid = open3 'WRITE', 'READ', '>&STDOUT',
		    $perl, '-e', cmd_line('print STDERR scalar <STDIN>');
++$test;
print WRITE "ok $test\n";
waitpid $pid, 0;

# dup reader and error together, both named
$pid = open3 'WRITE', '>&STDOUT', '>&STDOUT', $perl, '-e', cmd_line(<<'EOF');
    $| = 1;
    print STDOUT scalar <STDIN>;
    print STDERR scalar <STDIN>;
EOF
++$test;
print WRITE "ok $test\n";
++$test;
print WRITE "ok $test\n";
waitpid $pid, 0;

# dup reader and error together, error empty
$pid = open3 'WRITE', '>&STDOUT', '', $perl, '-e', cmd_line(<<'EOF');
    $| = 1;
    print STDOUT scalar <STDIN>;
    print STDERR scalar <STDIN>;
EOF
++$test;
print WRITE "ok $test\n";
++$test;
print WRITE "ok $test\n";
waitpid $pid, 0;

# command line in single parameter variant of open3
# for understanding of Config{'sh'} test see exec description in camel book
my $cmd = 'print(scalar(<STDIN>))';
$cmd = $Config{'sh'} =~ /sh/ ? "'$cmd'" : cmd_line($cmd);
eval{$pid = open3 'WRITE', '>&STDOUT', 'ERROR', "$perl -e " . $cmd; };
if ($@) {
	print "error $@\n";
	++$test;
	print WRITE "not ok $test\n";
}
else {
	++$test;
	print WRITE "ok $test\n";
	waitpid $pid, 0;
}
$TB->current_test($test);

# RT 72016
eval{$pid = open3 'WRITE', 'READ', 'ERROR', '/non/existant/program'; };
if (POSIX::Open3::DO_SPAWN) {
    if ($@) {
	cmp_ok(waitpid($pid, 0), '>', 0);
    } else {
	pass();
    }
} else {
    isnt($@, '') or do {waitpid $pid, 0};
}

# RT 66224
SKIP: {
    skip "Under windows...", 7 if $^O eq "MSWin32";

    open(SAVE_STDOUT,">&",STDOUT) or die "save stdout failed";
    my $dev_null = File::Spec->devnull;

    # open(DEVNULL,'<', $dev_null) or die "open '$dev_null' failed: $!";

    # Now set STDOUT to a filehandle on a new descriptor
    open(FH1,'>', $dev_null) or die "open '$dev_null' failed: $!";
    *STDOUT = *FH1;

    open3(*PIPEIN, *PIPEOUT, undef, $perl, '-e', cmd_line(<<'EOF')) or die "open3 failed";
   print "stdout 1\n";
   print "stdout 2\n";
   print "stdout 3\n";
   print STDERR "stderr 1\n";
   print STDERR "stderr 2\n";
   print STDERR "stderr 3\n";
   $a = <STDIN>;
   print $a;
EOF

    print PIPEIN "stdin\n";
    for my $j (1..2) {
        for my $i (1..3) {
            $_ = <PIPEOUT> || "nothing more";
            chomp;
            like $_, qr/^std(out|err) $i/;
        }
    }
    $_ = <PIPEOUT> || "nothing more";
    chomp;
    like $_, qr/^stdin/;

    close(PIPEOUT) or die "close pipe failed";

    # And restore stdout
    open(STDOUT,">&",*SAVE_STDOUT) or die "restore stout failed";
}


sub my_is {
    my $l = shift;
    $l =~ s/\r//g;
    is ($l, shift @_);
}
