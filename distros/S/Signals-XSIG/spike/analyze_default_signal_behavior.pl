# analyze_default_signal_behavior.pl: see what each signal does
# to a Perl program when the "DEFAULT" signal handler is set on 
# that program. The results can be appended to the
# lib/Signals/XSIG/Default.pm  file.

use IO::Handle;
use POSIX ':sys_wait_h';
use Config;
use strict;
use warnings;
$| = 1;

my $WNOHANG = &WNOHANG;
if (@ARGV < 2) {
    print STDERR qq[
This program will experimentally determine the default behavior 
of each signal on your system. The data collected will be
helpful in creating an appropriate  Signals/XSIG/Default.pm  
file.
];

}

my (@IGNORE, @SUSPEND, @TERMINATE, @UNKNOWN);
my $num_simultaneous = shift @ARGV || 4;
@IGNORE = ('__WARN__','__DIE__');

my @sigs = (sort keys %SIG, 'ZERO');
@sigs = @ARGV if @ARGV > 0;
my $abort_status;
if ($^O eq 'MSWin32') {
    $abort_status = 3;
}

if (@ARGV < 2) {
    printf STDERR "There are %d signals to analyze.\n", scalar @sigs;
    print STDERR "This may take a few minutes.\n\n";
}

# figure out the exit status of a program that calls POSIX::abort()
sub abort_status {
    use POSIX ();
    if (!defined $abort_status) {
	if (fork() == 0) {
	    POSIX::abort();
	    exit 0;
	}
	wait;
	$abort_status = $? || -9E9;
    }
    return $abort_status;
}

sub analysis_file {
    my ($signal) = @_;
    "siganal$signal.txt";
}

sub analyze_default_behavior_for_signal {
    my ($sig, $i, $analysis_file, $analysis_script) = @_;

    $analysis_file ||= analysis_file($sig);
    $analysis_script ||= "siganal$i.pl";
    unlink $analysis_file, $analysis_script;

    open my $cfh, '>', $analysis_script;
    print $cfh qq[

open(F, '>>', '$analysis_file');
print F "# analysis of $sig $analysis_file\\n";
close F;
\$SIG{'$sig'} = 'DEFAULT';
my \$n = sleep 2;
my \$msg = "CHILD \$n / 4\n";
open(F, '>>', '$analysis_file');
print F \$msg;
close F;
exit 0;

];
    close $cfh;
    
    my $status = 'unknown';
    my ($pid, $r, $nk);
    print STDERR "WNOHANG: $WNOHANG\n";
    
    if ($^O eq 'MSWin32') {
	%SIG = ();
	$pid = system(1, $^X, $analysis_script);
	print STDERR "sys1 pid($sig) = $pid\n";
    } else {
	$pid = fork();
	if ($pid == 0) {
	    %SIG = ();
	    exec $^X, $analysis_script;
	    die;
	}
    }

    $? = $^E = 0;
    $r = waitpid $pid, $WNOHANG;
    $status = $? if $r == $pid;   print STDERR "WNOHANG: \$r=$r \$?=$? $^E\n";
    sleep 2;
    $r = waitpid $pid, $WNOHANG;
    $status = $? if $r == $pid;   print STDERR "WNOHANG: \$r=$r \$?=$? $^E\n";
    $nk = kill $sig, $pid;     print STDERR "\$pid=$pid ; \$nk sig = $nk\n";
    sleep 2;
    $r = waitpid $pid, $WNOHANG;
    $status = $? if $r == $pid;   print STDERR "WNOHANG: \$r=$r \$?=$? $^E\n";
    sleep 5;
    $nk = kill 'CONT', $pid;      print STDERR "\$nk cont = $nk\n";
    sleep 2;
    $r = waitpid $pid, $WNOHANG;  print STDERR "WNOHANG: \$r=$r \$?=$? $^E\n";
    $status = $? if $r == $pid;
    $nk = kill 'KILL', $pid;      print STDERR "\$nk kill = $nk\n";
    $r = waitpid $pid, 0;
    $status = $? if $r == $pid;   print STDERR "wait: \$r=$r \$?=$? $^E\n";
    my $msg = "Status: $status\n";
    open my $fh, '>>', $analysis_file;
    print $fh $msg;
    close $fh;
    print STDERR "Completed analysis of $sig  status=$status\n";
    
    unlink $analysis_script;
    return $analysis_file;
}

sub analyze_sync {
    my ($sig, $i) = @_;
    analyze_default_behavior_for_signal($sig, 1);
    parse_analysis_file($sig, analysis_file($sig));
}

$::j=0;
print "[$^O]\n";
if ($^O eq 'MSWin32') {
    my $i = 0;
    for (@sigs) {
	analyze_sync($_, $i++);
    }
    @sigs = ();
}

while (@sigs) {
    # avoid fork() in MSWin32; it creates pseudo-processes
    $num_simultaneous = 1 if $^O eq 'MSWin32';
    my @sigz = splice @sigs, 0, $num_simultaneous;
    my $i = 0;
    foreach my $sig (@sigz) {
	if ($num_simultaneous == 1 || fork() == 0) {
	    analyze_default_behavior_for_signal($sig,$i);
	    exit 0 unless $num_simultaneous == 1;
	}
	$i++;
    }
    foreach (@sigz) {
	my $q = wait;
	print STDERR "WAIT: $_ => $q\n";
    }
    foreach my $sig (@sigz) {
	parse_analysis_file($sig,analysis_file($sig));
    }
}

sub parse_analysis_file {
    my ($sig,$file) = @_;
    open G, '<', $file;
    my @g = <G>;
    close G;

    my $i = ++$::j;
    my @sig_name = split ' ', $Config{sig_name};
    my @sig_num = split ' ', $Config{sig_num};
    my ($sig_no) = grep { $sig_name[$_] eq $sig } 0..$#sig_num;
    $sig_no ||= 9999;
    $sig_no = $sig_num[$sig_no];
    $sig_no ||= '';
    if ($g[0] =~ /^#/) {
	print STDERR "Analysis file:\n @g\n";
	shift @g;
    }

    my ($sleep_result, $sleep_benchmark) = $g[0] =~ /CHILD (\d+) \/ (\d+)/;
    if (defined($sleep_benchmark) && $sleep_result > $sleep_benchmark) {
	# the program completed but took longer than ~4 seconds.
	# This means it was suspended and then resumed several seconds later.
	push @SUSPEND, $sig;
	printf STDERR "%d. SIG", $i;
	printf "%-7s [%s] => %s\n", $sig, $sig_no, "SUSPEND";
    } else {
	my ($status) = $g[-1] =~ /Status: (\d+)/;
	if ($status eq "0") {
	    # The program completed normally in a regular amount of time.
	    # The signal was ignored or not received.
	    push @IGNORE, $sig;
	    printf STDERR "%d. SIG", $i;
	    printf "%-7s [%s] => %s\n", $sig, $sig_no, "IGNORE";
	} elsif ($status > 0) {
	    # The program did not complete normally.
	    # The signal terminated the program.
	    push @TERMINATE, $sig;
	    
	    printf STDERR "%d. SIG", $i;
	    if ($status == $sig_no << 8) {
		# exit status is divisible by 256. Like quitting with  exit()
		printf "%-7s [%s] => %s\n", $sig, $sig_no, "EXIT $sig_no";
	    } elsif (0 && $status == abort_status()) {
		# exit status same as abort status (see &abort_status).
		printf "%-7s [%s] => %s\n", $sig, $sig_no, "ABORT";
	    } else {
		# exit status not divisible by 256. Only way to do this
		# reliably is to actually raise the signal
		printf "%-7s [%s] => %s\n", $sig, $sig_no, "TERMINATE $status";
	    }
	} else {
	    push @UNKNOWN, $sig;
	    printf STDERR "%d. SIG", $i;
	    printf "%-7s [%s] => %d %s\n", $sig, $sig_no, $status, "UNKNOWN";
	}
    }
    unlink $file;
}
