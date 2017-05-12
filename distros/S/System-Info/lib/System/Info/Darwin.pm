package System::Info::Darwin;

use strict;
use warnings;

use base "System::Info::BSD";

our $VERSION = "0.050";

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

    my $model = $system_profiler->{"Machine Name"} ||
		$system_profiler->{"Machine Model"};

    my $ncpu = $system_profiler->{"Number Of CPUs"};
    $system_profiler->{"Total Number Of Cores"} and
	$ncpu .= " [$system_profiler->{'Total Number Of Cores'} cores]";

    $self->{__cpu_type}  = $system_profiler->{"CPU Type"}
	if $system_profiler->{"CPU Type"};
    $self->{__cpu}       = "$model ($system_profiler->{'CPU Speed'})";
    $self->{__cpu_count} = $ncpu;

    return $self;
    } # prepare_sysinfo

sub __get_system_profiler {
    my $system_profiler_output = do {
	local $^W = 0;
	`/usr/sbin/system_profiler -detailLevel mini SPHardwareDataType`;
	} or return;

    my %system_profiler;
    $system_profiler{$1} = $2
	while $system_profiler_output =~ m/^\s*([\w ]+):\s+(.+)$/gm;

    # convert newer output from Intel core duo
    my %keymap = (
	"Processor Name"        => "CPU Type",
	"Processor Speed"       => "CPU Speed",
	"Model Name"            => "Machine Name",
	"Model Identifier"      => "Machine Model",
	"Number Of Processors"  => "Number Of CPUs",
	"Number of Processors"  => "Number Of CPUs",
	"Total Number of Cores" => "Total Number Of Cores",
	);
    for my $newkey (keys %keymap) {
	my $oldkey = $keymap{$newkey};
	if (exists $system_profiler{$newkey}) {
	    $system_profiler{$oldkey} = delete $system_profiler{$newkey};
	    }
	}

    $system_profiler{"CPU Type"} ||= "Unknown";
    $system_profiler{"CPU Type"}   =~ s/PowerPC\s*(\w+).*/macppc$1/;
    $system_profiler{"CPU Speed"}  =~
	s/(0(?:\.\d+)?)\s*GHz/sprintf "%d MHz", $1 * 1000/e;

    return \%system_profiler;
    } # __get_system_profiler

1;

__END__

=head1 COPYRIGHT AND LICENSE

(c) 2016-2017, Abe Timmerman & H.Merijn Brand All rights reserved.

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
