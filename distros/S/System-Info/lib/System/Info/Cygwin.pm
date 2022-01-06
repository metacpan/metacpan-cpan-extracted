package System::Info::Cygwin;

use strict;
use warnings;

use base "System::Info::Linux";

use POSIX ();

our $VERSION = "0.050";

=head1 NAME

System::Info::Cygwin - Object for specific Cygwin info.

=head1 DESCRIPTION

=head2 $si->prepare_sysinfo()

Use os-specific tools to find out more about the system.

=cut

sub prepare_sysinfo {
    my $self = shift;
    $self->SUPER::prepare_sysinfo;

    return $self;
    } # prepare_sysinfo

=head2 $si->prepare_os

Use os-specific tools to find out more about the operating system.

=cut

sub prepare_os {
    my $self = shift;

    my @uname = POSIX::uname ();

    $self->{__osname} = $uname[0];
    $self->{__osvers} = $uname[2];
    my $os = join " - " => @uname[0,2];
    $os =~ s/(\S+)/\L$1/;
    $self->{__os} = $os;
    } # prepare_os

1;

__END__

=head1 COPYRIGHT AND LICENSE

(c) 2016-2022, Abe Timmerman & H.Merijn Brand, All rights reserved.

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
