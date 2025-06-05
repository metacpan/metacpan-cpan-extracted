####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1,
#        XDR::Gen version 0.0.5 and LibVirt version v11.4.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.14;
use warnings;

package Protocol::Sys::Virt::UNIXSocket v11.4.0;

use parent qw(Exporter);

use Carp qw(croak);
use Log::Any qw($log);

our @EXPORT = qw( socket_path );

sub socket_path {
    my %args = @_;
    my $path = $args{prefix} // '';
    $path .= '/run/libvirt';

    my $driver;
    my $mode = $args{mode} // 'legacy';
    if ($mode eq 'direct' and ($args{hypervisor} // $args{driver})) {
        $path .= '/virt' . ($args{hypervisor} // $args{driver}) . 'd-sock';
    }
    else {
        $path .= '/libvirt-sock';
    }
    if ($args{readonly}) {
        $path .= '-ro';
    }

    return $path;
}

1;


__END__

=head1 NAME

Protocol::Sys::Virt::UNIXSocket - Helper routines for parsing LibVirt
 Unix sockets

=head1 VERSION

v11.4.0

=head1 SYNOPSIS

  use Protocol::Sys::Virt::UNIXSocket; # imports 'socket_path'

  my $path = socket_path();

=head1 DESCRIPTION

Helper functions for LibVirt Unix sockets.

=head1 FUNCTIONS

=head2 socket_path

  my $path = socket_path(type => 'system', mode => 'direct', readonly => 1);

Returns the path name of the socket with the given parameters. The following
parameters may be given:

=over 8

=item * type

=over 8

=item * C<system> (default)

=item * C<user>

=back

=item * mode

=over 8

=item * C<legacy> (default)

=item * C<direct>

In case the C<hypervisor> value is missing, the function
falls back to C<legacy> mode.

=back

=item * readonly

When passed with a non-zero value, returns the name
 of the read-only socket.

=item * prefix

Path to prepend to state directory name holding the sockets.

Eg., C<< prefix => '/var' >> causes sockets paths to be rooted at
C< /var/run/libvirt > instead of C< /run/libvirt >.

=item * hypervisor

Specifies the name of the hypervisor to connect to; uses
the same naming scheme as the protocol part of the URI.

Example values are C<qemu> and C<vbox>.

=item * driver

Alternative name for C<hypervisor>.

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT

See the LICENSE file in this distribution.

