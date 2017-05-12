#!perl.exe -w
use strict;
use Win32::Job;
use Getopt::Std;

die "Usage: winjob.pl [-d] [-t timeout] statusdir command ...\n"
    unless ($ARGV[1]);

my %Opt;
getopts('dt:', \%Opt);

my $debug   = $Opt{d};
my $timeout = $Opt{t} ? int($Opt{t}) : 86400000;

my $dir = shift;
my @cmd = @ARGV;

warn "winjob.pl: \@cmd=(", join(',', @cmd), ")\n" if ($debug);

sub which {
    # Try to find "executable" in %PATH% if not qualified with full path
    # do it the DOS way, search '.' first -- no comment
    my $pgm = shift;

    my $fullpath = $pgm;
    
    if ($pgm !~ m|[/\\]|) {
	my @pathext = ('', split(';', $ENV{PATHEXT}));
	@pathext = ('', '.com', '.exe', '.bat', '.cmd') if (not $ENV{PATHEXT});
	push(@pathext, qw/.pl .py .php/);
	
	warn "winjob.pl: pathext=(", join(',', @pathext), ")\n" if ($debug);
	
        P: foreach my $p (('.', split(';', $ENV{PATH}))) {
	    warn "winjob.pl: Looking in $p\n" if (0 and $debug);
	    foreach my $ext (@pathext) {
		my $x = $p . "\\" . $pgm . $ext;
		warn "winjob.pl: testing $x\n" if (0 and $debug);
		if (-f $x) { # do not test -x for pl, -f will be good enough
		    $fullpath = $x;
		    last P;
		}
	    }
	}
    }
    return $fullpath;
}

my $run = $cmd[0];
if (not defined($cmd[1])) {
    ### no further args, so command is in one line
    ### try to find out the program to start
    if ($run =~ m/^\s*"([^"]+)"/) {
	# command given with quotation marks
	# '"C:\bla\blub bla\xyz.exe" arg1 arg2 ...'
	$run = $1;
    } elsif ($run =~ /^(\S+)\s*/) {
	# without quotation
	# 'C:\bla\blubb\xyz.exe arg1 arg2 ...'
	$run = $1;
    }
}

warn "winjob.pl: \$run = $run" if ($debug);
    
# so we indentified the command, try to find it in the path
my $fullpath = which($run);

warn "winjob.pl: \$fullpath = $fullpath" if ($debug);

# teach windows some unix magic...
open(X, $fullpath); # ignore errors...
my $magic;
my $interp;
read(X, $magic, 2); # do not read more than 2 chars at first
if ($magic eq '#!') {
    $interp = <X>;
    if ($interp =~ m/^\s*"([^"]+)"/) {
	$interp = $1;
    } elsif ($interp =~ m/^\s*(\S+)\s*/) {
	$interp = $1;
    }
    print "winjob.pl: magic! \$interp=$interp for $fullpath\n" if ($debug);
    # remove wrong path like /usr/bin/... or other
    if (not -x $interp) {
	# strip wrong path
	$interp =~ s|.*[/\\]+||;

	# Search %PATH%
	# Win32::Job should do that, but doesn't in my version
	$interp = which($interp);

	$interp = $^X if (not -f $interp and $interp =~ m/perl/);
	
	warn "winjob.pl: \$interp does not exist, I'll try with $interp\n"
	    if ($debug);
    }
}
close(X);

my $Arg = '';
if ($interp) {
    # run interpreter instead, use path of script as first arg
    $Arg      = '"' . $fullpath . '" ';
    $fullpath = $interp;
}

if (defined($cmd[1])) {
    $Arg .= '"' . join('" "', @cmd) . '"';
} else {
    $Arg .= $cmd[0];
}

warn "winjob.pl: \$fullpath = '$fullpath'\n  \$Arg = '$Arg'\n  \$dir='$dir'"
    if ($debug);

my $out; open($out, '>', $dir . '/STDOUT') or
    warn "$0: Cannot write $dir\\STDOUT: $!\n";
my $err; open($err, '>', $dir . '/STDERR') or
    warn "$0: Cannot write $dir\\STDERR: $!\n";

my $job = Win32::Job->new();
my $pid = $job->spawn($fullpath, $Arg, { stdin  => 'NUL',
		      stdout => $out, stderr => $err});

my $RC;
if (not $job or not $pid) {
    my $msg = "$0: Could not spawn job to run '$fullpath': $! ($^E)\n";
    print STDERR $msg;
    print $err $msg;
    open(FA, '>', $dir . "/fail"); print FA $msg; close(FA);
    $RC = 127;
} else {
    open(PID, '>', $dir . "/pid=$pid"); close(PID);
    open(STA, '>', $dir . "/start"); print STA time(), "\n"; close(STA);
    $job->run($timeout);
    $RC = $job->status()->{$pid}->{exitcode};
    $RC = 125 unless (defined $RC);
}

open(RC, '>', $dir . "/RC=$RC"); close(RC);
open(I, '>>', $dir . "/info");
print I "_endtime=", time(), "\n";
print I "_timed_out=1\n" if ($RC == 293);
close(I);
close($out);
close($err);

exit($RC);
