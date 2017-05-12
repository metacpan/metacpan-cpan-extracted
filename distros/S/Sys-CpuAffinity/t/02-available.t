use Sys::CpuAffinity;
use Test::More tests => 1;
use strict;
use warnings;

# output the relevant configuration of this system.
# when test t/10-exercise.t doesn't pass,
# this information is helpful in discovering why

print STDERR "\n\nSystem configuration\n====================\n";

print STDERR "\$^O = $^O; \$] = $]\n";
print STDERR "\$ENV{AUTOMATED_TESTING} = ",$ENV{AUTOMATED_TESTING}||'',"\n";


my @xs = grep { eval "defined &Sys::CpuAffinity::$_" }
         grep { /^xs/ } keys %Sys::CpuAffinity::;
if (@xs) {
    print STDERR "Defined XS functions:\n\t";
    print STDERR join "\n\t", sort @xs;
    print STDERR "\n\n";
}

foreach my $module (qw(Win32::API Win32::Process 
                       BSD::Process::Affinity Math::BigInt)) {
    my $avail = Sys::CpuAffinity::_configModule($module);
    if ($avail) {
	no warnings 'uninitialized';
	$avail .= " v" . eval "\$$module" . "::VERSION";
    }
    print STDERR "module $module: ", ($avail || "not"), " available\n";
}

foreach my $externalProgram (qw(bindprocessor dmesg sysctl psrinfo hinv
				hwprefs lsdev system_profiler prtconf 
				taskset pbind cpuset)) {

    my $path = Sys::CpuAffinity::_configExternalProgram($externalProgram);
    if ($path) {
	print STDERR "$externalProgram available at: $path\n";
    } else {
	print STDERR "$externalProgram: not found\n";
    }
}
print STDERR "\n";

# RT#118730 now appears to be an issue with Math::BigInt?
# Let's perform some sanity checks.
print STDERR "Math::BigInt sanity checks\n";
print STDERR "==========================\n";
if ($INC{"Math/BigInt.pm"}) {
    print STDERR "Version $Math::BigInt::VERSION\n";
    my $TWO = Math::BigInt->new(2);

    my $y1 = Math::BigInt->new("18446744073709551616");
    my $z1 = Math::BigInt->new("18446744073709551615");

    my $y2 = $TWO ** 64;
    my $z2 = Math::BigInt->new(0);
    $z2 |= $TWO ** $_ for 0 .. 63;

    my $y3 = $TWO;
    $y3->bpow(64);
    my $z3 = Math::BigInt->new(0);
    for (0 .. 63) {
        my $x3 = Math::BigInt->new(2);
        $x3->bpow($_);
        $z3 += $x3;
    }

    my $checkA1 = ($y1 - 1 == $z1);
    my $checkB1 = ($y1 == $z1 + 1);

    my $checkA2 = ($y2 - 1 == $z2);
    my $checkB2 = ($y2 == $z2 + 1);

    my $checkA3 = ($y3 - 1 == $z3);
    my $checkB3 = ($y3 == $z3 + 1);

    print STDERR "    Check 1: $checkA1/$checkB1\n";
    print STDERR "    Check 2: $checkA2/$checkB2\n";
    print STDERR "    Check 3: $checkA3/$checkB3\n";
    no warnings 'uninitialized';
    if ($checkA1 + $checkA2 + $checkA3 +
        $checkB1 + $checkB2 + $checkB3 != 6) {
        print STDERR "Issue found\n";
        print STDERR "  \$y1=$y1, \$z1=$z1\n";
        print STDERR "  \$y2=$y2, \$z2=$z2\n";
        print STDERR "  \$y3=$y3, \$z3=$z3\n";
    } else {
        print STDERR "No issue found\n";
    }
} else {
    print STDERR "Math::BigInt is not available\n";
}
print STDERR "\n";


ok(1);
