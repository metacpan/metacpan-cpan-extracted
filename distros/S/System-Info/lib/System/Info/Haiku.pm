package System::Info::Haiku;

use strict;
use warnings;

use base "System::Info::Base";

our $VERSION = "0.050";

=head1 NAME

System::Info::Haiku - Object for specific Haiku info.

=head1 DESCRIPTION

=head2 $si->prepare_sysinfo

Use os-specific tools to find out more about the system.

=cut

sub prepare_sysinfo {
    my $self = shift;
    $self->SUPER::prepare_sysinfo;

    eval { local $^W = 0; require Haiku::SysInfo };
    $@ and return $self;

    my $hsi = Haiku::SysInfo->new;
    (my $cbs = $hsi->cpu_brand_string) =~ s/^\s+//;
    $self->{__cpu_type}  = sprintf "0x%x", $hsi->cpu_type;
    $self->{__cpu}       = $cbs;
    $self->{__cpu_count} = $hsi->cpu_count;

    $self->{__os}        = join " - " => $hsi->kernel_name, $hsi->kernel_version;
    return $self;
    } # prepare_sysinfo

1;

__END__

=head1 COPYRIGHT AND LICENSE

(c) 2016-2019, Abe Timmerman & H.Merijn Brand, All rights reserved.

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
