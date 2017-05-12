#!perl -w

use strict;
use Test::More tests => 1;

diag( "WARNING: ignore all warnings from this test ;-)\n" );
require Config;

diag( "osname: $^O" );
my $ccname = $Config::Config{ccname};
   $ccname = 'gcc' if($Config::Config{gccversion});
   $ccname = '(unknown compiler)' unless $ccname;
my $ccversion = ($ccname eq 'gcc') ?
                $Config::Config{gccversion} :
                $Config::Config{ccversion};
   $ccversion = '(unknown version)' unless $ccversion;
diag( "perl cc: $ccname $ccversion" );
diag( "perl version: ". $Config::Config{version} );
eval {
	require POSIX;
}; if($@) {
	diag( "can't load POSIX: uname(), EPERM, and ESRCH details unavailable");
} else {
	diag( "POSIX::uname: ".join(" - ", POSIX::uname()) );
  diag( "EPERM: ".POSIX->EPERM." ".
        "ESRCH: ".POSIX->ESRCH      );
}

diag( "tested by a " .
         (defined($ENV{AUTOMATED_TESTING}) && $ENV{AUTOMATED_TESTING} ?
         "smoker" : 
         "person" ));

#now gather some info - kill a bunch of processes with the "can i kill 
#you" signal, and store those results in a hash, then, as tersely as 
#possible, tell me what the results were
my %results;
for my $pid (0..100, $$) {
	my $out = kill 0, $pid;
	my $key = (0+$!).':'."$!";
	push @{$results{$key}}, $pid;
}
my @skeys = sort {
	my ($an, $as) = split /:/, $a;
	my ($bn, $bs) = split /:/, $b;
	($an <=> $bn) || ($as cmp $bs)
} keys %results;
foreach my $key (@skeys) {
	my ($errnum, $errstr) = split /:/, $key;
	diag( "errno $errnum ($errstr) was the result on these pids: ".
	      join(', ', @{$results{$key}}) );
#	diag( "pid: $pid, out: $out, err: $! (".(0+$!).")\n" );
}

ok("printed diagnostics");

