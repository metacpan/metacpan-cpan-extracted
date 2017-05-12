#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: lib/Systemd/Daemon/Stub.pm
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Systemd-Daemon.
#
#   perl-Systemd-Daemon is free software: you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation, either version
#   3 of the License, or (at your option) any later version.
#
#   perl-Systemd-Daemon is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Systemd-Daemon. If not, see <http://www.gnu.org/licenses/>.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#pod =head1 DESCRIPTION
#pod
#pod The module defines the same functions as C<Systemd::Daemon::XS>, but these functions do nothing
#pod useful, they are just stubs returning error code (negated POSIX::ENOSYS value). Constants are
#pod defined to their proper values, though.
#pod
#pod The module is not intended to be used directly. Use C<Systemd::Daemon> instead — the latter loads
#pod real functions from C<Systemd::Daemon::XS>, and falls back to stubs if real functions are not
#pod available.
#pod
#pod =for Pod::Coverage sd_booted sd_is_fifo sd_is_mq sd_is_socket sd_is_socket_inet sd_is_socket_unix sd_is_special $SD_LISTEN_FDS_START sd_listen_fds $SD_ALERT $SD_CRIT $SD_DEBUG $SD_EMERG $SD_ERR $SD_INFO $SD_NOTICE $SD_WARNING sd_notify sd_pid_notify
#pod
#pod =cut

package Systemd::Daemon::Stub;

use strict;
use warnings;
use parent 'Exporter::Tiny';

# ABSTRACT: Stubs for Systemd::Daemon
our $VERSION = '0.07'; # VERSION

use POSIX qw{};

use Readonly;
our $SD_LISTEN_FDS_START; Readonly $SD_LISTEN_FDS_START => 3;
our $SD_ALERT; Readonly $SD_ALERT => '<1>';
our $SD_CRIT; Readonly $SD_CRIT => '<2>';
our $SD_DEBUG; Readonly $SD_DEBUG => '<7>';
our $SD_EMERG; Readonly $SD_EMERG => '<0>';
our $SD_ERR; Readonly $SD_ERR => '<3>';
our $SD_INFO; Readonly $SD_INFO => '<6>';
our $SD_NOTICE; Readonly $SD_NOTICE => '<5>';
our $SD_WARNING; Readonly $SD_WARNING => '<4>';

sub sd_booted() { return - POSIX::ENOSYS };
sub sd_is_fifo($$) { return - POSIX::ENOSYS };
sub sd_is_mq($$) { return - POSIX::ENOSYS };
sub sd_is_socket($$$$) { return - POSIX::ENOSYS };
sub sd_is_socket_inet($$$$$) { return - POSIX::ENOSYS };
sub sd_is_socket_unix($$$$$$) { return - POSIX::ENOSYS };
sub sd_is_special($$) { return - POSIX::ENOSYS };
sub sd_listen_fds($) { return - POSIX::ENOSYS };
sub sd_notify($$) { return - POSIX::ENOSYS };
sub sd_pid_notify($$$) { return - POSIX::ENOSYS };

our ( @EXPORT_OK, %EXPORT_TAGS );
$EXPORT_TAGS{ all } = \@EXPORT_OK;
$EXPORT_TAGS{ sd_booted } = [ qw{ sd_booted } ];
$EXPORT_TAGS{ sd_is } = [ qw{ sd_is_fifo sd_is_mq sd_is_socket sd_is_socket_inet sd_is_socket_unix sd_is_special } ];
$EXPORT_TAGS{ sd_listen } = [ qw{ $SD_LISTEN_FDS_START sd_listen_fds } ];
$EXPORT_TAGS{ sd_log } = [ qw{ $SD_ALERT $SD_CRIT $SD_DEBUG $SD_EMERG $SD_ERR $SD_INFO $SD_NOTICE $SD_WARNING } ];
$EXPORT_TAGS{ sd_notify } = [ qw{ sd_notify sd_pid_notify } ];
$EXPORT_TAGS{ sd_watchdog } = [ qw{  } ];
@EXPORT_OK = map( { @{ $EXPORT_TAGS{ $_ } } } keys( %EXPORT_TAGS ) );
## no critic ( ProhibitUnusedPrivateSubroutines )
sub _exporter_expand_sub { ## no critic ( RequireArgUnpacking )
    my $class = shift( @_ );
    my ( $name, undef, undef, $permitted ) = @_;
    if ( substr( $name, 0, 1 ) eq '$' and $name =~ $permitted ) {
        $name = substr( $name, 1 );
        no strict 'refs'; ## no critic( ProhibitNoStrict )
        return $name => \${ $name };
    } else {
        return $class->SUPER::_exporter_expand_sub( @_ );
    };
};


#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

1;

# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Systemd::Daemon::Stub - Stubs for Systemd::Daemon

=head1 VERSION

Version 0.07, released on 2015-11-12 13:35 UTC.

=head1 DESCRIPTION

The module defines the same functions as C<Systemd::Daemon::XS>, but these functions do nothing
useful, they are just stubs returning error code (negated POSIX::ENOSYS value). Constants are
defined to their proper values, though.

The module is not intended to be used directly. Use C<Systemd::Daemon> instead — the latter loads
real functions from C<Systemd::Daemon::XS>, and falls back to stubs if real functions are not
available.

=for Pod::Coverage sd_booted sd_is_fifo sd_is_mq sd_is_socket sd_is_socket_inet sd_is_socket_unix sd_is_special $SD_LISTEN_FDS_START sd_listen_fds $SD_ALERT $SD_CRIT $SD_DEBUG $SD_EMERG $SD_ERR $SD_INFO $SD_NOTICE $SD_WARNING sd_notify sd_pid_notify

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
