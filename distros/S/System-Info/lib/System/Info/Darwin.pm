package System::Info::Darwin;

use strict;
use warnings;

use base "System::Info::BSD";

our $VERSION = "0.052";

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
    my $system_profiler = __get_system_profiler () or
	return $self->SUPER::prepare_sysinfo ();

    $self->{__system_profiler} = $system_profiler;
    if (my $kv = $system_profiler->{"system version"}) {
	$self->{__os} =~ s{\)$}{ - $kv)};
	}

    my $model = $system_profiler->{"machine name"} ||
		$system_profiler->{"machine model"};

    my $ncpu = $system_profiler->{"number of cpus"};
    $system_profiler->{"total number of cores"} and
	$ncpu .= " [$system_profiler->{'total number of cores'} cores]";

    $self->{__cpu_type}  = $system_profiler->{"cpu type"}
	if $system_profiler->{"cpu type"};
    $self->{__cpu}       = "$model ($system_profiler->{'cpu speed'})";
    $self->{__cpu_count} = $ncpu;

    return $self;
    } # prepare_sysinfo

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
	"number of processors"  => "number of cpus",
	"number of processors"  => "number of cpus",
	"total number of cores" => "total number of cores",
	);
    for my $newkey (keys %keymap) {
	my $oldkey = $keymap{$newkey};
	exists $system_profiler{$newkey} and
	    $system_profiler{$oldkey} = delete $system_profiler{$newkey};
	}

    chomp ($system_profiler{"cpu type"} ||= `uname -m`);
    $system_profiler{"cpu type"} ||= "Unknown";
    $system_profiler{"cpu type"}   =~ s/PowerPC\s*(\w+).*/macppc$1/;
    $system_profiler{"cpu speed"}  =~
	s/(0(?:\.\d+)?)\s*GHz/sprintf "%d MHz", $1 * 1000/e;

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


=head1 COPYRIGHT AND LICENSE

(c) 2016-2018, Abe Timmerman & H.Merijn Brand All rights reserved.

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
