package System::Info::Darwin;

use strict;
use warnings;

use base "System::Info::BSD";

our $VERSION = "0.056";

=head1 NAME

System::Info::Darwin - Object for specific Darwin info.

=head1 DESCRIPTION

=head2 $si->prepare_sysinfo

Use os-specific tools to find out more about the system.

=cut

sub prepare_sysinfo {
    my $self = shift;
    $self->System::Info::Base::prepare_sysinfo ();

    $self->{__os} .= " (Mac OS X)";

    my $scl = __get_sysctl ();

    my $system_profiler = __get_system_profiler () or
	return $self->SUPER::prepare_sysinfo ();

    $self->{__system_profiler} = $system_profiler;
    if (my $kv = $system_profiler->{"system version"}) {
	$self->{__os} =~ s{\)$}{ - $kv)};
	}

    # This is physical processors (sockets) which os not returned anywhere for Apple Silicon (implied 1)
    my $ncpu = $system_profiler->{"number of cpus"} || 1;
    $system_profiler->{"total number of cores"} and
	$ncpu .= " [$system_profiler->{'total number of cores'} cores]";

	# Confusingly, System::Info uses "cpu_type" for architecture and Apple uses
	# "CPU Type" as the CPU model name. They are not the same thing.
    $self->{__cpu}       = $system_profiler->{chip} ||
	$system_profiler->{"cpu type"};
    $self->{__cpu} .= " ($system_profiler->{'cpu speed'})"
	if $system_profiler->{"cpu speed"};
    $self->{__cpu_type}  = $system_profiler->{arch};
    $self->{__cpu_count} = $ncpu;
    # _ncore reports hyperthreads for other platforms, so it would be
    # hw.logicalcpu (or hw.logicalcpu_max which is the same unless the system
    # has disabled cores).
    # Alternative hw.ncpu is deprecated, keeping for ancient systems.
    $self->{_ncore}      = $scl->{"hw.logicalcpu"}  || $scl->{"hw.ncpu"};
    $self->{_phys_core}  = $scl->{"hw.physicalcpu"} || $scl->{"hw.ncpu"};

    my $osv = do {
	local $^W = 0;
	`sw_vers -productVersion 2>/dev/null`;
	} || "";
    chomp ($self->{__osvers} = $osv);

    $self->{__memsize} = $scl->{"hw.memsize"};

    return $self;
    } # prepare_sysinfo

# System::Info::BSD.pm only uses hw
sub __get_sysctl {
    my $sysctl_cmd = -x "/sbin/sysctl" ? "/sbin/sysctl" : "sysctl";
    chomp (my @sysctl = do {
	local $^W = 0;
	`$sysctl_cmd -a 2>/dev/null`;
	});
    my %sysctl = map { split m/\s*[:=]\s*/, $_, 2 } grep m/[:=]/ => @sysctl;
    return \%sysctl;
    } # __get_sysctl

sub __get_system_profiler {
    my $system_profiler_output = do {
	local $^W = 0;
	`/usr/sbin/system_profiler -detailLevel mini SPHardwareDataType SPSoftwareDataType 2>&1`;
	} or return;

    # From RT#97441
    # In Yosemite the system_profiler started emitting these warnings:
    # 2015-07-24 06:54:06.842 system_profiler[59780:1318389] platformPluginDictionary: Can\'t get X86PlatformPlugin, return value 0
    # They seem to be harmless, but annoying.
    # Clean them out, but then warn about others from system_profiler.
    $system_profiler_output =~ s/^\d{4}-\d\d-\d\d .+ system_profiler\[.+?\] platformPluginDictionary: Can't get X86PlatformPlugin, return value 0$//mg;
    warn "Unexpected warning from system_profiler:\n$1\n"
	while $system_profiler_output =~ /^(.+system_profiler.+)/mg;

    my %system_profiler;
    $system_profiler{lc $1} = $2
	while $system_profiler_output =~ m/^\s*([\w ]+):\s+(.+)$/gm;

    # convert newer output from Intel core duo
    my %keymap = (
	"processor name"	=> "cpu type",
	"processor speed"	=> "cpu speed",
	"model name"		=> "machine name",
	"model identifier"	=> "machine model",
	"number of processors"	=> "number of cpus",
	"total number of cores"	=> "total number of cores",
	);
    for my $newkey (keys %keymap) {
	my $oldkey = $keymap{$newkey};
	exists $system_profiler{$newkey} and
	    $system_profiler{$oldkey} = delete $system_profiler{$newkey};
	}

    chomp ($system_profiler{"cpu type"} ||= `uname -m`);
    $system_profiler{"cpu speed"} ||= 0; # Mac M1 does not show CPU speed
    $system_profiler{"cpu speed"}   =~
	s/(0(?:\.\d+)?)\s*GHz/sprintf "%d MHz", $1 * 1000/e;
    $system_profiler{"cpu type"}  ||= "Unknown";
    $system_profiler{"cpu type"}   =~ s/\s*\([\d.]+\)//
	if $system_profiler{"cpu speed"};
    chomp ($system_profiler{arch} ||= `uname -m`);
    $system_profiler{arch}        ||= "Unknown";
    return \%system_profiler;
    } # __get_system_profiler

1;

__END__

$ uname -a
Darwin grannysmith.local 16.5.0 Darwin Kernel Version 16.5.0: Fri Mar  3 16:52:33 PST 2017; root:xnu-3789.51.2~3/RELEASE_X86_64 x86_64

$ uname -m
x86_64
$ uname -n
grannysmith.local
$ uname -p
i386
$ uname -r
16.5.0
$ uname -s
Darwin
$ uname -v
Darwin Kernel Version 16.5.0: Fri Mar  3 16:52:33 PST 2017; root:xnu-3789.51.2~3/RELEASE_X86_64

=head1 SEE ALSO

Mac::OSVersion

=head1 COPYRIGHT AND LICENSE

(c) 2016-2025, Abe Timmerman & H.Merijn Brand, All rights reserved.

With contributions from Jarkko Hietaniemi, Campo Weijerman, Alan Burlison,
Allen Smith, Alain Barbet, Dominic Dunlop, Rich Rauenzahn, David Cantrell.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
