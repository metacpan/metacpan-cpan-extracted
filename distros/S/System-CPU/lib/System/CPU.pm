package System::CPU;

use 5.006;
use strict;
use warnings;

use List::Util qw(sum);

our $VERSION = '1.03';

=head1 NAME

System::CPU - Cross-platform CPU information / topology

=head1 SYNOPSIS

 use System::CPU;

 # Number of logical cores. E.g. on SMT systems these will be Hyper-Threads
 my $logical_cpu = System::CPU::get_ncpu();

 # On some platforms you can also get the number of processors and physical cores
 my ($phys_processors, $phys_cpu, $logical_cpu) = System::CPU::get_cpu();

 # Model name of the CPU
 my $name = System::CPU::get_name();

 # CPU Architecture
 my $arch = System::CPU::get_arch();

 # Get all the above in a hash
 my $hash = System::CPU::get_hash();

=head1 DESCRIPTION

A pure Perl module with no dependencies to get basic CPU information on any platform.
The data you can get differs depending on platform, but for many systems running
Linux/BSD/MacOS you can get extra nuance like number of threads vs cores etc.

It was created for L<Benchmark::DKbench> with the C<get_ncpu> function modeled
after the one on L<MCE::Util>. In fact, some code was copied from that function as
it had the most reliable way to consistently get the logical cpus of the system.

=head1 FUNCTIONS

=head2 get_cpu

Returns as detailed CPU topology as the platform allows. A list of three values
will be returned, with the first and the second possibly C<undef>:

 my ($phys_processors, $phys_cpu, $logical_cpu) = System::CPU::get_cpu();

For many Linux, MacOS, BSD systems the number of physical processors (sockets),
as well as the number of physical CPU cores and logical CPUs (CPU threads) will
be returned.

For the systems where the extra information is not available (i.e. all other OSes
and some Linux/MacOS/BSD setups), the first two values will be C<undef>.

=head2 get_ncpu

 my $logical_cpus = System::CPU::get_ncpu();

This function behaves very similar to C<MCE::Util::get_ncpu> - in fact code is borrowed
from it. The number of logical CPUs will be returned, this is the number of hyper-threads
for SMT systems and the number of cores for most others.

=head2 get_name

 my $cpu_name = System::CPU::get_name(raw => $raw?);

Returns the CPU model name. By default it will remove some extra spaces and Intel's
(TM) and (R), but you can pass in the C<raw> argument to avoid this cleanup.

=head2 get_arch

 my $arch = System::CPU::get_arch();

Will return the CPU architecture as reported by the system. There is no standarized
form, e.g. Linux will report aarch64 on a system where Darwin would report arm64
etc.

=head2 get_hash

 my $hash = System::CPU::get_hash(%opt?);

Will return all the information the module can access in a hash. Accepts the options
of the other functions. Example hash output:

 {
    arch           => 'arm64',
    logical_cores  => 10,
    name           => 'Apple M2 Pro',
    physical_cores => 10,
    processors     => 1
 }

=head1 CAVEATS

Since text output from user commands is parsed for most platforms, only the English
language locales are supported.

=head1 NOTES

I did try to use existing solutions before writing my own. L<Sys::Info> has issues
installing on modern Linux systems (I tried submitting a PR, but the author seems
unresponsive).

L<System::Info> is the most promising, however, it returns a simple "core" count which
seems to inconsistently be either physical cores or threads depending on the platform.
The author got back to me, so I will try to sort that out, as that module is more
generic than System::CPU.

There are also several platform-specific modules, most requiring a compiler too
(e.g. L<Unix::Processors>, L<Sys::Info>, various C<*::Sysinfo>).

In the end, I wanted to get the CPU topology where possible - number of processors/sockets,
cores, threads separately, something that wasn't readily available.

I intend to support all systems possible with this simple pure Perl module. If you
have access to a system that is not supported or where the module cannot currently
give you the correct output, feel free to contact me about extending support.

Currently supported systems:

Linux/Android, BSD/MacOS, Win32/Cygwin, AIX, Solaris, IRIX, HP-UX, Haiku, GNU
and variants of those.

=cut

sub get_hash {
    my %opt = @_;
    my ($proc, $phys, $log) = get_cpu(%opt);
    my $name = get_name(%opt);
    my $arch = get_arch(%opt);
    return {
        processors     => $proc,
        logical_cores  => $log,
        physical_cores => $phys,
        name           => $name,
        arch           => $arch,
    };
}

sub get_cpu {
    return _linux_cpu()   if $^O =~ /linux|android/i;
    return _bsd_cpu()     if $^O =~ /bsd|darwin|dragonfly/i;
    return _solaris_cpu() if $^O =~ /osf|solaris|sunos|svr5|sco/i;
    return _aix_cpu()     if $^O =~ /aix/i;
    return _gnu_cpu()     if $^O =~ /gnu/i;
    return _haiku_cpu()   if $^O =~ /haiku/i;
    return _hpux_cpu()    if $^O =~ /hp-?ux/i;
    return _irix_cpu()    if $^O =~ /irix/i;
    return (undef, undef, $ENV{NUMBER_OF_PROCESSORS})
        if $^O =~ /mswin|mingw|msys|cygwin/i;

    die "OS identifier '$^O' not recognized. Contact dkechag\@cpan.org to add support.";
}

sub get_ncpu {
    my $ncpu = get_cpu();
    return $ncpu;
}

sub get_name {
    my %opt = @_;
    my $name;
    if ($^O =~ /linux|android/i) {
        ($name) = _proc_cpuinfo();
    } elsif ($^O =~ /bsd|darwin|dragonfly/i) {
        chomp($name = `sysctl -n machdep.cpu.brand_string 2>/dev/null`);
        chomp($name = `sysctl -n hw.model 2>/dev/null`) unless $name;
    } elsif ($^O =~ /mswin|mingw|msys|cygwin/i) {
        $name = $ENV{PROCESSOR_IDENTIFIER};
    } elsif ($^O =~ /aix/i) {
        chomp(my $out = `prtconf | grep -i "Processor Type" 2>/dev/null`);
        $name = $1 if $out =~ /:\s*(.*)/;
    } elsif ($^O =~ /irix/i) {
        my @out = grep {/CPU:/i} `hinv 2>/dev/null`;
        $name = $1 if @out && $out[0] =~ /CPU:\s*(.*)/i;
    } elsif ($^O =~ /haiku/i) {
        my $out = `sysinfo -cpu 2>/dev/null | grep "^CPU #"`;
        $name = $1 if $out =~ /:\s*(?:")?(.*?)(?:")?\s*$/m;
    } elsif ($^O =~ /hp-?ux/i) {
        my $out = `machinfo`;
        if ($out =~ /processor model:\s*\d*\s*(.+?)$/im) {
            $name = $1;
        } elsif ($out =~ /\s*\d*\s*(.+(?:MHz|GHz).+)$/m) {
            $name = $1;
        }
    } elsif ($^O =~ /osf|solaris|sunos|svr5|sco/i) {
        my $out = `kstat -p cpu_info`;
        $name = $1 if $out =~ /:brand\s*(.*)$/m;
    } else {
        die "OS identifier '$^O' not recognized. Contact dkechag\@cpan.org to add support.";
    }

    unless ($opt{raw}) {
        $name =~ s/\s+/ /g         if $name;    # I don't like some systems giving excess whitespace.
        $name =~ s/\((?:R|TM)\)//g if $name;    # I don't like Intel's (R)s and (TM)s
    }
    return $name || "";
}


sub get_arch {
    return _uname_m() if $^O =~ /linux|android|bsd|darwin|dragonfly|gnu|osf|solaris|sunos|svr5|sco|hp-?ux/i;
    return _uname_p() if $^O =~ /aix|irix/i;
    return _getarch() if $^O =~ /haiku/i;
    return $ENV{PROCESSOR_ARCHITECTURE} if $^O =~ /mswin|mingw|msys|cygwin/i;

    die "OS identifier '$^O' not recognized. Contact dkechag\@cpan.org to add support.";
}

sub _solaris_cpu {
    my $ncpu;
    if (-x '/usr/sbin/psrinfo') {
        my $count = grep {/on-?line/} `psrinfo 2>/dev/null`;
        $ncpu = $count if $count;
    } else {
        my @output = grep {/^NumCPU = \d+/} `uname -X 2>/dev/null`;
        $ncpu = (split ' ', $output[0])[2] if @output;
    }
    return (undef, undef, $ncpu);
}

sub _bsd_cpu {
    my $prof = `system_profiler -detailLevel mini SPHardwareDataType SPSoftwareDataType 2>/dev/null`;
    my $proc = $prof ? 1 : undef;
    $proc = $1 if $prof && $prof =~ /Number of (?:Processors|CPUs): (\d+)/i;
    chomp(my $cpus = `sysctl -n hw.logicalcpu 2>/dev/null`);
    chomp($cpus    = `sysctl -n hw.ncpu 2>/dev/null`) unless $cpus; # Old system fallback
    return ($proc, undef, undef) unless $cpus;
    chomp(my $cores = `sysctl -n hw.physicalcpu 2>/dev/null`);
    $cores ||= $cpus;
    return ($proc, $cores, $cpus);
}

sub _linux_cpu {
   my ($name, $phys, $cores, $cpus) = _proc_cpuinfo();
   return $phys, $cores, $cpus;
}

sub _aix_cpu {
    my $ncpu;
    my @output = `lparstat -i 2>/dev/null | grep "^Online Virtual CPUs"`;
    if (@output) {
        $output[0] =~ /(\d+)\n$/;
        $ncpu = $1 if $1;
    }
    if (!$ncpu) {
        @output = `pmcycles -m 2>/dev/null`;
        if (@output) {
            $ncpu = scalar @output;
        } else {
            @output = `lsdev -Cc processor -S Available 2>/dev/null`;
            $ncpu   = scalar @output if @output;
        }
    }
    return (undef, undef, $ncpu);
}

sub _haiku_cpu {
    my $ncpu;
    my @output = `sysinfo -cpu 2>/dev/null | grep "^CPU #"`;
    $ncpu = scalar @output if @output;
    return (undef, undef, $ncpu);;
}

sub _hpux_cpu {
    my $ncpu = grep { /^processor/ } `ioscan -fkC processor 2>/dev/null`;
    return (undef, undef, $ncpu || undef);
}

sub _irix_cpu {
    my $ncpu;
    my @out = grep {/\s+processors?$/i} `hinv -c processor 2>/dev/null`;
    $ncpu = (split ' ', $out[0])[0] if @out;
    return (undef, undef, $ncpu);;
}

sub _gnu_cpu {
    my $ncpu;
    chomp(my @output = `nproc --all 2>/dev/null`);
    $ncpu = $output[0] if @output;
    return (undef, undef, $ncpu);;
}

sub _proc_cpuinfo {
    my (@physical, @cores, $phys, $cpus, $name);
    if (-f '/proc/cpuinfo' && open my $fh, '<', '/proc/cpuinfo') {
        while (<$fh>) {
            $cpus++ if /^processor\s*:/i;
            push @physical, $1 if /^physical id\s*:\s*(\d+)/i;
            push @cores,    $1 if /^cpu cores\s*:\s*(\d+)/i;
            $name = $1 if /^model name\s*:\s*(.*)/i;
        }
        return $name, undef, $cores[0], $cpus if !@physical && @cores;
        @cores = (0) unless @cores;
        my %hash;
        $hash{$physical[$_]} = $_ < scalar(@cores) ? $cores[$_] : $cores[0]
            for 0 .. $#physical;
        my $phys  = keys %hash        || undef;
        my $cores = sum(values %hash) || $cpus;
        return $name, $phys, $cores, $cpus;
    }
    return;
}

sub _uname_m {
    chomp( my $arch = `uname -m 2>/dev/null` );
    return $arch || _uname_p();
}

sub _uname_p {
    chomp( my $arch = `uname -p 2>/dev/null` );
    return $arch;
}

sub _getarch {
    chomp( my $arch = `getarch 2>/dev/null` );
    return $arch;
}

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/dkechag/System-CPU/issues>.

You can also submit PRs with fixes/enhancements directly.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc System::CPU

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/dkechag/System-CPU>

=item * Search CPAN

L<https://metacpan.org/release/System-CPU>

=back

=head1 ACKNOWLEDGEMENTS

Some code borrowed from L<MCE>.

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Dimitrios Kechagias.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1; # End of System::CPU
