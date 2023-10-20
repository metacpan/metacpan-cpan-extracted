use Test2::Tools::Exception qw/dies lives/;
use Test2::V0;

our $cmd_mock;
our $mockfile;

require System::CPU; # Runtime to set $cmd_mock

BEGIN {
    eval "use Test::MockFile qw(nostrict);";
    $mockfile = $@ ? 0 : 1;

    *CORE::GLOBAL::readpipe = sub {
        my $cmd   = shift;
        my $match = join "|", keys %$cmd_mock;
        my $out   = $cmd =~ /($match)/ ? $cmd_mock->{$1} : "";
        return $out unless wantarray;
        return unless $out;
        my @split = split /\n/, $out;
        $split[$_] .= "\n" for 0 .. $#split;
        return @split;
    };
}

my $all_tests = get_tests();
my %function  = (
    get_cpu  => \&System::CPU::get_cpu,
    get_name => \&System::CPU::get_name,
    get_arch => \&System::CPU::get_arch,
);

foreach my $func (sort keys %function) {
    my $tests = $all_tests->{$func};
    subtest $func => sub {
        run_test($_, $function{$func}, $func) for @{$tests};
    };
}

subtest "get_hash" => sub {
    local $^O = "darwin";
    $cmd_mock = {
        profiler     => 'Hardware',
        logicalcpu   => 10,
        physicalcpu  => 10,
        brand_string => "Apple M2 Pro",
        uname        => "arm64"
    };
    is(
        System::CPU::get_hash(),
        {
            name           => 'Apple M2 Pro',
            physical_cores => 10,
            processors     => 1,
            arch           => 'arm64',
            logical_cores  => 10
        },
        "get_hash"
    );
};

subtest "raw" => sub {
    local $^O = "haiku";
    $cmd_mock = {sysinfo => 'CPU #0: "Intel(R) Core(TM)2 Duo CPU     T9600  @ 2.80GHz"'};
    is(System::CPU::get_name(raw=>1), "Intel(R) Core(TM)2 Duo CPU     T9600  @ 2.80GHz", "get_name raw");
};

subtest "vms" => sub {
    like(
        dies {
            local $^O = 'vms';
            $function{$_}->();
        },
        qr/not recognized/,
        "$_: Unsupported system."
    ) for sort keys %function;
};

subtest "_uname_m" => sub {
    $cmd_mock = {"uname -p" => 'arm'};
    is(System::CPU::_uname_m(), "arm", "uname -p fallback");
    $cmd_mock = {"uname -x" => 'arm'};
    is(System::CPU::_uname_m(), "", "No uname -p fallback");
};

done_testing;

sub run_test {
    my ($test, $func, $name) = @_;

    return ok(1, "Skip without Mockfile")
        if (!$mockfile || $^O eq 'freebsd') # FreeBSD has issues with Test::MockFile
        && ($test->[1] eq 'file' || scalar @$test > 4);

    local $^O = $test->[0];

    my $mock;
    use Data::Dumper;
    $mock = Test::MockFile->file(@{$test->[4]}) if scalar @$test > 4;
    $mock = Test::MockFile->file(@{$test->[2]}) if $test->[1] eq 'file';
    $cmd_mock = $test->[1] eq 'cmd' ? $test->[2] : {nullcmd => 0};
    local $ENV{$test->[2]->[0]} = $test->[2]->[1] if $test->[1] eq 'env';
    is([$func->()], $test->[3], "$name $^O");
    is(System::CPU::get_ncpu(), $test->[3]->[2], "get_ncpu $^O") if $name eq 'get_cpu';
}

sub get_tests {
    my $func = shift;
    return {get_cpu => [
['linux', 'file', ['/proc/cpuinfo', undef], [undef, undef, undef]],
['android', 'file', ['/proc/cpuinfo', 'processor  : 0
BogoMIPS    : 48.00
Features    : fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm ssbs sb paca pacg dcpodp flagm2 frint
CPU implementer : 0x00
CPU architecture: 8
CPU variant : 0x0
CPU part    : 0x000
CPU revision    : 0

processor   : 1
BogoMIPS    : 48.00
Features    : fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm ssbs sb paca pacg dcpodp flagm2 frint
CPU implementer : 0x00
CPU architecture: 8
CPU variant : 0x0
CPU part    : 0x000
CPU revision    : 0'], [undef, 2, 2]],
['linux', 'file', ['/proc/cpuinfo', 'processor   : 0
core id     : 0
cpu cores   : 2

processor   : 1
core id     : 2
cpu cores   : 2'],[undef, 2, 2]],
['linux', 'file', ['/proc/cpuinfo', 'processor   : 0
physical id : 0
core id     : 0
cpu cores   : 1

processor   : 1
physical id : 0
core id     : 0
cpu cores   : 1

processor   : 2
physical id : 1
core id     : 0
cpu cores   : 1

processor   : 3
physical id : 1
core id     : 0
cpu cores   : 1'],[2, 2, 4]],
['bsd', 'cmd', {sysctl => ""}, [undef, undef, undef]],
['bsd', 'cmd', {ncpu => 10, profiler => 'Hardware'}, [1, 10, 10]],
['darwin', 'cmd', {profiler => 'Hardware:

    Hardware Overview:

      Model Name: Mac Pro
      Model Identifier: MacPro5,1
      Processor Name: Quad-Core Intel Xeon
      Processor Speed: 2,26 GHz
      Number of Processors: 2
      Total Number of Cores: 8
      L2 Cache (per Core): 256 KB
      L3 Cache (per Processor): 8 MB
      Memory: 12 GB', logicalcpu => 16, physicalcpu => 8}, [2, 8, 16]],
['solaris', 'file', ['/usr/sbin/psrinfo', undef], [undef, undef, undef]],
['solaris', 'file', ['/usr/sbin/psrinfo', 1], [undef, undef, undef]],
['solaris', 'cmd', {'uname -X' => 'System = SunOS
Node = b-solaris11-amd64
Release = 5.11
KernelID = 11.0
Machine = i86pc
BusType = <unknown>
Serial = <unknown>
Users = <unknown>
OEM# = 0
Origin# = 1
NumCPU = 4'}, [undef, undef, 4], ['/usr/sbin/psrinfo', undef]],
['aix', 'cmd', {lparstat => ""}, [undef, undef, undef]],
['aix', 'cmd', {lsdev => 'proc0 Available 00-00 Processor
proc2 Available 00-02 Processor
proc4 Available 00-04 Processor
proc6 Available 00-06 Processor'}, [undef, undef, 4]],
['aix', 'cmd', {pmcycles => 'Cpu 0 runs at 1656 MHz
Cpu 1 runs at 1656 MHz'}, [undef, undef, 2]],
['aix', 'cmd', {lparstat => "Online Virtual CPUs : 1"}, [undef, undef, 1]],
['aix', 'cmd', {lparstat => "Online Virtual CPUs", pmcycles => 'Cpu 0 runs at 1656 MHz'}, [undef, undef, 1]],
['gnu', 'cmd', {none => ""}, [undef, undef, undef]],
['gnu', 'cmd', {nproc => 6}, [undef, undef, 6]],
['haiku', 'cmd', {none => ""}, [undef, undef, undef]],
['haiku', 'cmd', {sysinfo => 'CPU #0: "Intel(R) Core(TM)2 Duo CPU     T9600  @ 2.80GHz"'}, [undef, undef, 1]],
['irix', 'cmd', {none => ""}, [undef, undef, undef]],
['irix', 'cmd', {hinv => '12 200 MHZ IP19 Processors
CPU: MIPS R4400 Processor Chip Revision: 6.0
FPU: MIPS R4010 Floating Point Chip Revision: 0.0
Data cache size: 16 Kbytes
Instruction cache size: 16 Kbytes
Secondary unified instruction/data cache size: 4 Mbytes'}, [undef, undef, 12]],
['hp-ux', 'cmd', {none => ""}, [undef, undef, undef]],
['hp-ux', 'cmd', {ioscan => 'Class       I  H/W Path  Driver    S/W State   H/W Type     Description
========================================================================
processor   0  120       processor   CLAIMED     PROCESSOR    Processor
processor   1  121       processor   CLAIMED     PROCESSOR    Processor
processor   2  122       processor   CLAIMED     PROCESSOR    Processor
processor   3  123       processor   CLAIMED     PROCESSOR    Processor
processor   4  124       processor   CLAIMED     PROCESSOR    Processor
processor   5  125       processor   CLAIMED     PROCESSOR    Processor
processor   6  126       processor   CLAIMED     PROCESSOR    Processor
processor   7  127       processor   CLAIMED     PROCESSOR    Processor'}, [undef, undef, 8]],
['MSWin32', 'env', ["NUMBER_OF_PROCESSORS", undef], [undef, undef, undef]],
['cygwin', 'env', ["NUMBER_OF_PROCESSORS", 4], [undef, undef, 4]],
],
get_name => [['android', 'file', ['/proc/cpuinfo', undef], [""]],
['linux', 'file', ['/proc/cpuinfo', 'processor  : 0
BogoMIPS    : 48.00
Features    : fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm ssbs sb paca pacg dcpodp flagm2 frint
CPU implementer : 0x00
CPU architecture: 8
CPU variant : 0x0
CPU part    : 0x000
CPU revision    : 0'], [""]],
['linux', 'file', ['/proc/cpuinfo', 'processor       : 0
vendor_id       : GenuineIntel
cpu family      : 6
model           : 143
model name      : Intel(R) Xeon(R) Platinum 8481C CPU @ 2.70GHz
stepping        : 8
microcode       : 0xffffffff
cpu MHz         : 2699.998
cache size      : 107520 KB
physical id     : 0
siblings        : 4
core id         : 0
cpu cores       : 2
apicid          : 0
initial apicid  : 0'], ['Intel Xeon Platinum 8481C CPU @ 2.70GHz']],
['bsd', 'cmd', {sysctl => ""}, [""]],
['bsd', 'cmd', {model => "Intel(R) Core(TM) i7 CPU 870 @ 2.93GHz"}, ["Intel Core i7 CPU 870 @ 2.93GHz"]],
['darwin', 'cmd', {brand_string => "Apple M2 Pro"}, ["Apple M2 Pro"]],
['cygwin', 'env', ["PROCESSOR_IDENTIFIER", "Intel64 Family 6 Model 58 Stepping 9, GenuineIntel"], ["Intel64 Family 6 Model 58 Stepping 9, GenuineIntel"]],
['aix', 'cmd', {none => ""}, [""]],
['aix', 'cmd', {prtconf => "Processor Type: PowerPC_POWER4"}, ["PowerPC_POWER4"]],
['irix', 'cmd', {none => ""}, [""]],
['irix', 'cmd', {hinv => "12 200 MHZ IP19 Processors
CPU: MIPS R4400 Processor Chip Revision: 6.0
FPU: MIPS R4010 Floating Point Chip Revision: 0.0
Data cache size: 16 Kbytes"}, ["MIPS R4400 Processor Chip Revision: 6.0"]],
['solaris', 'cmd', {kstat => 'cpu_info:0:cpu_info0:brand      AMD Ryzen 5 PRO 4650U with Radeon Graphics
cpu_info:0:cpu_info0:chip_id    0
cpu_info:0:cpu_info0:clock_MHz  2094
cpu_info:0:cpu_info0:core_id    0
cpu_info:0:cpu_info0:cpu_type   i386
cpu_info:0:cpu_info0:family     23
cpu_info:0:cpu_info0:fpu_type   i387 compatible
cpu_info:0:cpu_info0:implementation     x86 (chipid 0x0 AuthenticAMD 860F01 family 23 model 96 step 1 clock 2100 MHz)
cpu_info:0:cpu_info0:max_ncpu_per_chip  2
cpu_info:0:cpu_info0:max_ncpu_per_core  1
cpu_info:0:cpu_info0:model      96
cpu_info:0:cpu_info0:ncore_per_chip     2
cpu_info:0:cpu_info0:ncpu_per_chip      2
cpu_info:0:cpu_info0:pg_id      1
cpu_info:0:cpu_info0:pkg_core_id        0
cpu_info:0:cpu_info0:vendor_id  AuthenticAMD
cpu_info:1:cpu_info1:brand      AMD Ryzen 5 PRO 4650U with Radeon Graphics
cpu_info:1:cpu_info1:chip_id    0
cpu_info:1:cpu_info1:class      misc
cpu_info:1:cpu_info1:clock_MHz  2094
cpu_info:1:cpu_info1:core_id    1
cpu_info:1:cpu_info1:cpu_type   i386
cpu_info:1:cpu_info1:family     23
cpu_info:1:cpu_info1:fpu_type   i387 compatible
cpu_info:1:cpu_info1:implementation     x86 (chipid 0x0 AuthenticAMD 860F01 family 23 model 96 step 1 clock 2100 MHz)
cpu_info:1:cpu_info1:max_ncpu_per_chip  2
cpu_info:1:cpu_info1:max_ncpu_per_core  1
cpu_info:1:cpu_info1:max_pwrcap 0
cpu_info:1:cpu_info1:model      96
cpu_info:1:cpu_info1:ncore_per_chip     2
cpu_info:1:cpu_info1:ncpu_per_chip      2
cpu_info:1:cpu_info1:pg_id      1
cpu_info:1:cpu_info1:pkg_core_id        1
cpu_info:1:cpu_info1:vendor_id  AuthenticAMD
'}, ["AMD Ryzen 5 PRO 4650U with Radeon Graphics"]],
['haiku', 'cmd', {sysinfo => 'CPU #0: "Intel(R) Core(TM)2 Duo CPU     T9600  @ 2.80GHz"
CPU #1: "Intel(R) Core(TM)2 Duo CPU     T9600  @ 2.80GHz"'}, ["Intel Core2 Duo CPU T9600 @ 2.80GHz"]],
['hp-ux', 'cmd', {machinfo => 'CPU info:
Number of CPUs = 8
Clock speed = 1598 MHz
Bus speed = 533 MT/s
CPUID registers
vendor information = "GenuineIntel"
processor serial number = 0x0000000000000000
processor version info = 0x0000000020000704
architecture revision: 0
processor family: 32 Intel(R) Itanium 2 9000 series
processor model: 0 Intel(R) Itanium 2 9000 series
processor revision: 7 Stepping C2
largest CPUID reg: 4'}, ["Intel Itanium 2 9000 series"]],
['hp-ux', 'cmd', {machinfo => 'CPU info:
   Intel(R) Itanium 2 9100 series processor (1.67 GHz, 18 MB)
   2 cores, 4 logical processors per socket
   666 MT/s bus, CPU version A1
          Active processor count:
          2 sockets
          4 cores (2 per socket)
          8 logical processors (4 per socket)
          LCPU attribute is enabled

Memory: 8160 MB (7.97 GB)'}, ["Intel Itanium 2 9100 series processor (1.67 GHz, 18 MB)"]]],
get_arch => [['linux', 'cmd', {uname => 'aarch64'}, ["aarch64"]],
['aix', 'cmd', {uname => 'x86_64'}, ["x86_64"]],
['cygwin', 'env', ["PROCESSOR_ARCHITECTURE", 'AMD64'], ["AMD64"]],
['haiku', 'cmd', {getarch => 'x86'}, ["x86"]],
]};
}
