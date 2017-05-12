package System::Info::BSD;

use strict;
use warnings;

use base "System::Info::Base";

our $VERSION = "0.050";

=head1 NAME

System::Info::BSD - Object for specific BSD info.

=head1 DESCRIPTION

=head2 $si->prepare_sysinfo()

Use os-specific tools to find out more about the system.

=cut

sub prepare_sysinfo {
    my $self = shift;
    $self->SUPER::prepare_sysinfo;

    my $sysctl = __get_sysctl ();

    my $cpu = $sysctl->{model};

    if (exists $sysctl->{cpuspeed}) {
	$cpu .= sprintf " (%.0f MHz)", $sysctl->{cpuspeed};
	}
    elsif (exists $sysctl->{cpufrequency}) {
	$cpu .= sprintf " (%.0f MHz)", $sysctl->{cpufrequency}/1_000_000;
	}

    $self->{__cpu_type}  = $sysctl->{machine} if $sysctl->{machine};
    $self->{__cpu}       = $cpu               if $cpu;
    $self->{__cpu_count} = $sysctl->{ncpu};

    return $self;
    } # prepare_sysinfo

sub __get_sysctl {
    my %sysctl;

    my $sysctl_cmd = -x "/sbin/sysctl" ? "/sbin/sysctl" : "sysctl";

    my %extra  = (cpufrequency => undef, cpuspeed => undef);
    my @e_args = map {
	m/^hw\.(\w+)\s*[:=]/; $1
	} grep m/^hw\.(\w+)/ && exists $extra{$1} => `$sysctl_cmd -a hw`;

    foreach my $name (qw( model machine ncpu ), @e_args) {
	chomp ($sysctl{$name} = `$sysctl_cmd hw.$name`);
	$sysctl{$name} =~ s/^hw\.$name\s*[:=]\s*//;
	}
    $sysctl{machine} and $sysctl{machine} =~ s/Power Macintosh/macppc/;

    return \%sysctl;
    } # __get_sysctl

1;

__END__

=head1 COPYRIGHT AND LICENSE

(c) 2016-2017, Abe Timmerman & H.Merijn Brand, All rights reserved.

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
