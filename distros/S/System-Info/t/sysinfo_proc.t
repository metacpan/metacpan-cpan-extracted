#!/usr/bin/perl

use strict;
use warnings;
no  warnings "redefine";
use 5.008003;

use Test::More tests => 12;
use Test::Warnings;

BEGIN {
    # redefine the CORE functions to mimic themselfs at compile-time
    # so we can re-redefine them at run-time

    our $tux = 0; # Counter for unique GLOBrefs
    *CORE::GLOBAL::open = sub (*;$@) {
	my ($handle, $second, @args) = @_;
	my ($pkg) = caller;
	if (defined $handle && !ref $handle) {
	    no strict "refs";
	    $handle = \*{ "$pkg\:\:$handle" };
	    }
	elsif (!defined $handle) {    # undefined scalar, provide GLOBref
	    $_[0] = $handle = do {
		no strict "refs";
		\*{ sprintf "%s::TUX%06d", $pkg, $tux++ };
		};
	    }
	CORE::open ($handle, $second, @args);
	};

    *CORE::GLOBAL::close = sub (*) {
	my ($handle) = @_;
	unless (ref $handle) {
	    my ($pkg) = caller;
	    no strict "refs";
	    $handle = *{ "$pkg\:\:$handle" };
	    }
	CORE::close ($handle);
	};
    }

my %files;

use System::Info::Linux;
use System::Info::Generic;
my $this_system = System::Info::Generic->new;

{   our $CPU_TYPE = "Generic";
    # redefine the CORE functions only locally
    local $^W; # no warnings "redefine";
    local *CORE::GLOBAL::open = sub (*;$@) {
	local $^W = 1;

	my ($handle, $second, @args) = @_;
	my ($pkg) = caller;
	if (defined $handle && !ref $handle) {
	    no strict "refs";
	    $handle = \*{"$pkg\:\:$handle"};
	    }
	elsif (!defined $handle) {    # undefined scalar, provide GLOBref
	    $_[0] = $handle = do {
		no strict "refs";
		\*{ sprintf "%s::TUX%06d", $pkg, our $tux++ };
		};
	    }

	if ($second eq "<" && $args[0] eq "/proc/cpuinfo") {
	    shift @args;

	    my $fn = $::CPU_TYPE;

	    # we can do this fully qualified filehandle as we only use GLOBs
	    # to keep up with 5.005xx
	    no strict "refs";
	    tie *$handle, "ReadProc", $files{$fn};
	    }
	else {
	    CORE::open ($handle, $second, @args);
	    }
	};
    local *CORE::GLOBAL::close = sub (*) {
	my ($pkg) = caller;
	no strict "refs";
	tied $_[0] and untie *{ "$pkg\:\:$_[0]" };
	};

    *System::Info::Base::get_cpu_type = sub {
	my $self = shift;
	return $self->{__cpu_type} = $::CPU_TYPE;
	};
    $^W = 1;

    $CPU_TYPE = "i386";
    my $i386 = System::Info::Linux->new;
    $this_system->{_os} = $i386->_os;

    is_deeply $i386->old_dump, {
	_host     => $this_system->host,
	_os       => $this_system->os,
	_cpu_type => $CPU_TYPE,
	_cpu      => "AMD Athlon(tm) 64 Processor 3200+ (AuthenticAMD 1000MHz)",
	_ncpu     => 1,
	}, "Read /proc/cpuinfo for i386";
#

    $CPU_TYPE = "ppc";
    my $ppc = System::Info::Linux->new;

    is_deeply $ppc->old_dump, {
	_host     => $this_system->host,
	_os       => $this_system->os,
	_cpu_type => $CPU_TYPE,
	_cpu      => "7400, altivec supported PowerMac G4 (400.000000MHz)",
	_ncpu     => 1,
	}, "Read /proc/cpuinfo for ppc";

    $CPU_TYPE = "i386_2";

    my $i386_2 = System::Info::Linux->new;

    is_deeply $i386_2->old_dump, {
	_host     => $this_system->host,
	_os       => $this_system->os,
	_cpu_type => $CPU_TYPE,
	_cpu      => "Intel(R) Core(TM)2 CPU T5600 @ 1.83GHz (GenuineIntel 1000MHz)",
	_ncpu     => "1 [2 cores]",
	}, "Read /proc/cpuinfo for duo i386";

    $CPU_TYPE = "arm_v6l";

    my $arm_v6 = System::Info::Linux->new;

    is_deeply $arm_v6->old_dump, {
	_host     => $this_system->host,
	_os       => $this_system->os,
	_cpu_type => $CPU_TYPE,
	_cpu      => "ARMv6-compatible processor rev 7 (v6l) (700 MHz)",
	_ncpu     => 1,
	}, "Read /proc/cpuinfo for ARM v6";

    $CPU_TYPE = "arm_v6l2";

    my $arm_v62 = System::Info::Linux->new;

    is_deeply $arm_v62->old_dump, {
	_host     => $this_system->host,
	_os       => $this_system->os,
	_cpu_type => $CPU_TYPE,
	_cpu      => "ARMv6-compatible processor rev 7 (v6l) (700 MHz)",
	_ncpu     => 1,
	}, "Read /proc/cpuinfo for ARM v6";

    $CPU_TYPE = "arm_v7";

    my $arm_v7 = System::Info::Linux->new;

    is_deeply $arm_v7->old_dump, {
	_host     => $this_system->host,
	_os       => $this_system->os,
	_cpu_type => $CPU_TYPE,
	_cpu      => "ARMv7 Processor rev 2 (v7l) (300 MHz)",
	_ncpu     => 1,
	}, "Read /proc/cpuinfo for ARM v7";

    $CPU_TYPE = "i386_16";
    my $i386_16 = System::Info::Linux->new;

    is_deeply $i386_16->old_dump, {
	_host     => $this_system->host,
	_os       => $this_system->os,
	_cpu_type => $CPU_TYPE,
	_cpu      => "Intel(R) Xeon(R) CPU L5520 @ 2.27GHz (GenuineIntel 2268MHz)",
	_ncpu     => "2 [16 cores]",
	}, "Read /proc/cpuinfo for i386/16";

    $CPU_TYPE = "macabre";
    my $macabre = System::Info::Linux->new;

    is_deeply $macabre->old_dump, {
	_host     => $this_system->host,
	_os       => $this_system->os,
	_cpu_type => $CPU_TYPE,
	_cpu      => "Intel(R) Xeon(R) CPU E5-1603 0 @ 2.80GHz (GenuineIntel 2800MHz)",
	_ncpu     => "1 [4 cores]",
	}, "Read /proc/cpuinfo for macabre";

    $CPU_TYPE = "vogon";
    my $vogon = System::Info::Linux->new;

    is_deeply $vogon->old_dump, {
	_host     => $this_system->host,
	_os       => $this_system->os,
	_cpu_type => $CPU_TYPE,
	_cpu      => "Quad-Core AMD Opteron(tm) Processor 8356 (AuthenticAMD 1200MHz)",
	_ncpu     => "4 [16 cores]",
	}, "Read /proc/cpuinfo for vogon";

    $CPU_TYPE = "s390x_sles11_sp2";
    my $s390xsles11sp2 = System::Info::Linux->new;

    is_deeply $s390xsles11sp2->old_dump, {
	_host     => $this_system->host,
	_os       => $this_system->os,
	_cpu_type => $CPU_TYPE,
	_cpu      => "IBM/S390 (1300 MHz)",
	_ncpu     => "3",
	}, "Read /proc/cpuinfo for s390x SLES 11-SP2";

    $CPU_TYPE = "s390x_fedora";
    my $s390xfedora = System::Info::Linux->new;

    is_deeply $s390xfedora->old_dump, {
	_host     => $this_system->host,
	_os       => $this_system->os,
	_cpu_type => $CPU_TYPE,
	_cpu      => "IBM/S390 (2900 MHz)",
	_ncpu     => "2",
	}, "Read /proc/cpuinfo for s390x Fedora";
    }

# Assign file contents
BEGIN {
    $files{i386} = <<'__EOINFO__';
processor       : 0
vendor_id       : AuthenticAMD
cpu family      : 15
model           : 47
model name      : AMD Athlon(tm) 64 Processor 3200+
stepping        : 2
cpu MHz         : 1000.000
cache size      : 512 KB
fdiv_bug        : no
hlt_bug         : no
f00f_bug        : no
coma_bug        : no
fpu             : yes
fpu_exception   : yes
cpuid level     : 1
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 syscall nx mmxext fxsr_opt lm 3dnowext 3dnow up pni lahf_lm ts fid vid ttp tm stc
bogomips        : 2012.54
__EOINFO__

    $files{ppc} = <<'__EOINFO__';
processor       : 0
cpu             : 7400, altivec supported
temperature     : 20-29 C (uncalibrated)
clock           : 400.000000MHz
revision        : 2.9 (pvr 000c 0209)
bogomips        : 49.66
timebase        : 24908033
machine         : PowerMac3,1
motherboard     : PowerMac3,1 MacRISC Power Macintosh
detected as     : 65 (PowerMac G4 AGP Graphics)
pmac flags      : 00000004
L2 cache        : 1024K unified
pmac-generation : NewWorld
__EOINFO__

    $files{"i386_2"} = <<'__EOINFO__';
processor	: 0
vendor_id	: GenuineIntel
cpu family	: 6
model		: 15
model name	: Intel(R) Core(TM)2 CPU         T5600  @ 1.83GHz
stepping	: 6
cpu MHz		: 1000.000
cache size	: 2048 KB
physical id	: 0
siblings	: 2
core id		: 0
cpu cores	: 2
fdiv_bug	: no
hlt_bug		: no
f00f_bug	: no
coma_bug	: no
fpu		: yes
fpu_exception	: yes
cpuid level	: 10
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe nx lm constant_tsc pni monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr lahf_lm
bogomips	: 3661.63
clflush size	: 64

processor	: 1
vendor_id	: GenuineIntel
cpu family	: 6
model		: 15
model name	: Intel(R) Core(TM)2 CPU         T5600  @ 1.83GHz
stepping	: 6
cpu MHz		: 1833.000
cache size	: 2048 KB
physical id	: 0
siblings	: 2
core id		: 1
cpu cores	: 2
fdiv_bug	: no
hlt_bug		: no
f00f_bug	: no
coma_bug	: no
fpu		: yes
fpu_exception	: yes
cpuid level	: 10
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe nx lm constant_tsc pni monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr lahf_lm
bogomips	: 3657.62
clflush size	: 64
__EOINFO__

    $files{arm_v6l} = <<'__EOINFO__'; # RaspberryPI, raspbian 8.0
Processor       : ARMv6-compatible processor rev 7 (v6l)
BogoMIPS        : 697.95
Features        : swp half thumb fastmult vfp edsp java tls 
CPU implementer : 0x41
CPU architecture: 7
CPU variant     : 0x0
CPU part        : 0xb76
CPU revision    : 7
Hardware        : BCM2708
Revision        : 000e
Serial          : 00000000dc08448c
__EOINFO__

    $files{arm_v6l2} = <<'__EOINFO__'; # RaspberryPI, raspbian 9.1
processor       : 0
model name      : ARMv6-compatible processor rev 7 (v6l)
BogoMIPS        : 697.95
Features        : half thumb fastmult vfp edsp java tls
CPU implementer : 0x41
CPU architecture: 7
CPU variant     : 0x0
CPU part        : 0xb76
CPU revision    : 7

Hardware        : BCM2835
Revision        : 000f
Serial          : 00000000c7982c01
__EOINFO__

    $files{arm_v7} = <<'__EOINFO__'; # Archos 101IT, Android 2.2
Processor      : ARMv7 Processor rev 2 (v7l)
BogoMIPS       : 298.32
Features       : swp half thumb fastmult vfp edsp neon vfpv3 
CPU implementer        : 0x41
CPU architecture: 7
CPU variant    : 0x3
CPU part       : 0xc08
CPU revision   : 2
Hardware       : Archos A101IT board
Board          : 0005
OMAP revision  : ES1.2
Revision       : 0000
Serial         : 0000000000000000
Boot           : 4.04.000000
__EOINFO__

    $files{"i386_16"} = <<'__EOINFO__';
processor	: 0
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 0
siblings	: 8
core id		: 0
cpu cores	: 4
apicid		: 0
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.48
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 1
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 0
siblings	: 8
core id		: 1
cpu cores	: 4
apicid		: 2
initial apicid	: 2
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.48
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 2
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 0
siblings	: 8
core id		: 2
cpu cores	: 4
apicid		: 4
initial apicid	: 4
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.48
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 3
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 0
siblings	: 8
core id		: 3
cpu cores	: 4
apicid		: 6
initial apicid	: 6
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.48
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 4
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 1
siblings	: 8
core id		: 0
cpu cores	: 4
apicid		: 16
initial apicid	: 16
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.35
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 5
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 1
siblings	: 8
core id		: 1
cpu cores	: 4
apicid		: 18
initial apicid	: 18
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.35
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 6
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 1
siblings	: 8
core id		: 2
cpu cores	: 4
apicid		: 20
initial apicid	: 20
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.35
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 7
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 1
siblings	: 8
core id		: 3
cpu cores	: 4
apicid		: 22
initial apicid	: 22
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.35
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 8
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 0
siblings	: 8
core id		: 0
cpu cores	: 4
apicid		: 1
initial apicid	: 1
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.48
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 9
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 0
siblings	: 8
core id		: 1
cpu cores	: 4
apicid		: 3
initial apicid	: 3
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.48
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 10
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 0
siblings	: 8
core id		: 2
cpu cores	: 4
apicid		: 5
initial apicid	: 5
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.48
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 11
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 0
siblings	: 8
core id		: 3
cpu cores	: 4
apicid		: 7
initial apicid	: 7
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.48
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 12
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 1
siblings	: 8
core id		: 0
cpu cores	: 4
apicid		: 17
initial apicid	: 17
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.35
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 13
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 1
siblings	: 8
core id		: 1
cpu cores	: 4
apicid		: 19
initial apicid	: 19
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.35
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 14
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 1
siblings	: 8
core id		: 2
cpu cores	: 4
apicid		: 21
initial apicid	: 21
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.35
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

processor	: 15
vendor_id	: GenuineIntel
cpu family	: 6
model		: 26
model name	: Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz
stepping	: 5
microcode	: 0x11
cpu MHz		: 2268.000
cache size	: 8192 KB
physical id	: 1
siblings	: 8
core id		: 3
cpu cores	: 4
apicid		: 23
initial apicid	: 23
fpu		: yes
fpu_exception	: yes
cpuid level	: 11
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 4533.35
clflush size	: 64
cache_alignment	: 64
address sizes	: 40 bits physical, 48 bits virtual
power management:

__EOINFO__

    $files{"macabre"} = <<'__EOINFO__';
processor	: 0
vendor_id	: GenuineIntel
cpu family	: 6
model		: 45
model name	: Intel(R) Xeon(R) CPU E5-1603 0 @ 2.80GHz
stepping	: 7
microcode	: 0x710
cpu MHz		: 2800.000
cache size	: 10240 KB
physical id	: 0
siblings	: 4
core id		: 0
cpu cores	: 4
apicid		: 0
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 13
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx lahf_lm arat epb xsaveopt pln pts dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 5586.32
clflush size	: 64
cache_alignment	: 64
address sizes	: 46 bits physical, 48 bits virtual
power management:

processor	: 1
vendor_id	: GenuineIntel
cpu family	: 6
model		: 45
model name	: Intel(R) Xeon(R) CPU E5-1603 0 @ 2.80GHz
stepping	: 7
microcode	: 0x710
cpu MHz		: 1200.000
cache size	: 10240 KB
physical id	: 0
siblings	: 4
core id		: 1
cpu cores	: 4
apicid		: 2
initial apicid	: 2
fpu		: yes
fpu_exception	: yes
cpuid level	: 13
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx lahf_lm arat epb xsaveopt pln pts dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 5586.38
clflush size	: 64
cache_alignment	: 64
address sizes	: 46 bits physical, 48 bits virtual
power management:

processor	: 2
vendor_id	: GenuineIntel
cpu family	: 6
model		: 45
model name	: Intel(R) Xeon(R) CPU E5-1603 0 @ 2.80GHz
stepping	: 7
microcode	: 0x710
cpu MHz		: 2400.000
cache size	: 10240 KB
physical id	: 0
siblings	: 4
core id		: 2
cpu cores	: 4
apicid		: 4
initial apicid	: 4
fpu		: yes
fpu_exception	: yes
cpuid level	: 13
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx lahf_lm arat epb xsaveopt pln pts dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 5586.37
clflush size	: 64
cache_alignment	: 64
address sizes	: 46 bits physical, 48 bits virtual
power management:

processor	: 3
vendor_id	: GenuineIntel
cpu family	: 6
model		: 45
model name	: Intel(R) Xeon(R) CPU E5-1603 0 @ 2.80GHz
stepping	: 7
microcode	: 0x710
cpu MHz		: 1200.000
cache size	: 10240 KB
physical id	: 0
siblings	: 4
core id		: 3
cpu cores	: 4
apicid		: 6
initial apicid	: 6
fpu		: yes
fpu_exception	: yes
cpuid level	: 13
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx lahf_lm arat epb xsaveopt pln pts dtherm tpr_shadow vnmi flexpriority ept vpid
bogomips	: 5586.38
clflush size	: 64
cache_alignment	: 64
address sizes	: 46 bits physical, 48 bits virtual
power management:

__EOINFO__

    $files{"vogon"} = <<'__EOINFO__';
processor	: 0
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 0
siblings	: 4
core id		: 0
cpu cores	: 4
apicid		: 4
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4599.67
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 1
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 0
siblings	: 4
core id		: 1
cpu cores	: 4
apicid		: 5
initial apicid	: 1
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4599.67
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 2
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 0
siblings	: 4
core id		: 2
cpu cores	: 4
apicid		: 6
initial apicid	: 2
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4599.67
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 3
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 2300.000
cache size	: 512 KB
physical id	: 0
siblings	: 4
core id		: 3
cpu cores	: 4
apicid		: 7
initial apicid	: 3
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4599.67
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 4
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 1
siblings	: 4
core id		: 0
cpu cores	: 4
apicid		: 8
initial apicid	: 4
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4601.26
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 5
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 1
siblings	: 4
core id		: 1
cpu cores	: 4
apicid		: 9
initial apicid	: 5
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4601.26
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 6
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 1
siblings	: 4
core id		: 2
cpu cores	: 4
apicid		: 10
initial apicid	: 6
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4601.26
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 7
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 1
siblings	: 4
core id		: 3
cpu cores	: 4
apicid		: 11
initial apicid	: 7
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4601.26
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 8
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 2
siblings	: 4
core id		: 0
cpu cores	: 4
apicid		: 12
initial apicid	: 8
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4602.26
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 9
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 2
siblings	: 4
core id		: 1
cpu cores	: 4
apicid		: 13
initial apicid	: 9
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4602.26
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 10
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 2
siblings	: 4
core id		: 2
cpu cores	: 4
apicid		: 14
initial apicid	: 10
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4602.26
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 11
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 2
siblings	: 4
core id		: 3
cpu cores	: 4
apicid		: 15
initial apicid	: 11
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4602.26
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 12
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 3
siblings	: 4
core id		: 0
cpu cores	: 4
apicid		: 16
initial apicid	: 12
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4602.30
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 13
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 3
siblings	: 4
core id		: 1
cpu cores	: 4
apicid		: 17
initial apicid	: 13
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4602.30
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 14
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 3
siblings	: 4
core id		: 2
cpu cores	: 4
apicid		: 18
initial apicid	: 14
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4602.30
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

processor	: 15
vendor_id	: AuthenticAMD
cpu family	: 16
model		: 2
model name	: Quad-Core AMD Opteron(tm) Processor 8356
stepping	: 3
cpu MHz		: 1200.000
cache size	: 512 KB
physical id	: 3
siblings	: 4
core id		: 3
cpu cores	: 4
apicid		: 19
initial apicid	: 15
fpu		: yes
fpu_exception	: yes
cpuid level	: 5
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm 3dnowext 3dnow constant_tsc rep_good nonstop_tsc extd_apicid pni monitor cx16 popcnt lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs npt lbrv svm_lock
bogomips	: 4602.30
TLB size	: 1024 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm stc 100mhzsteps hwpstate

__EOINFO__

    $files{"s390x_sles11_sp2"} = <<'__EOINFO__';
vendor_id       : IBM/S390
# processors    : 3
bogomips per cpu: 1258.00
features        : esan3 zarch stfle msa ldisp eimm dfp edat etf3eh highgprs
processor 0: version = 00,  identification = 002623,  machine = 2064
processor 1: version = 00,  identification = 102623,  machine = 2064
processor 2: version = 00,  identification = 202623,  machine = 2064
__EOINFO__

    $files{"s390x_fedora"} = <<'__EOINFO__';
vendor_id       : IBM/S390
# processors    : 2
bogomips per cpu: 2913.00
max thread id   : 0
features        : esan3 zarch stfle msa ldisp eimm dfp edat etf3eh highgprs te sie 
cache0          : level=1 type=Data scope=Private size=96K line_size=256 associativity=6
cache1          : level=1 type=Instruction scope=Private size=64K line_size=256 associativity=4
cache2          : level=2 type=Data scope=Private size=1024K line_size=256 associativity=8
cache3          : level=2 type=Instruction scope=Private size=1024K line_size=256 associativity=8
cache4          : level=3 type=Unified scope=Shared size=49152K line_size=256 associativity=12
cache5          : level=4 type=Unified scope=Shared size=393216K line_size=256 associativity=24
processor 0: version = FF,  identification = 35C047,  machine = 2827
processor 1: version = FF,  identification = 35C047,  machine = 2827
cpu number      : 0
cpu MHz dynamic : 5504
cpu MHz static  : 5504
cpu number      : 1
cpu MHz dynamic : 5504
cpu MHz static  : 5504
__EOINFO__
    }

package ReadProc;

sub TIEHANDLE {
    my $class = shift;
    my $data  = shift or die "No content for tied filehandle!";
    bless \$data, $class;
    }

sub READLINE {
    my $buffer = shift;
    length $$buffer or return;
    $$buffer =~ s/[ \t\r\xa0]+/ /g;
    $$buffer =~ s/ \n/\n/g;
    if (wantarray) {
	my @list = map "$_\n" => split m/\n/, $$buffer;
	$$buffer = "";
	return @list;
	}

    $$buffer =~ s/^(.*\n?)// and return $1;
    }

1;
