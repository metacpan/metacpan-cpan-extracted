#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: lib/Systemd/Daemon/XS.pm
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

#pod =for test_synopsis my ( $pid );
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Systemd::Daemon::XS qw{ :all };
#pod
#pod     sd_notify( 0, "READY=1\nSTATUS=Ready\n" );
#pod     sd_pid_notify( $pid, 0, "RELOADING=1" );
#pod     if ( sd_booted() ) {
#pod         ...;
#pod     };
#pod     ...;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides Perl bindings to the part of F<libsystemd> shared library declared in
#pod <F<systemd/sd-daemon.h>> header.
#pod
#pod =cut

package Systemd::Daemon::XS;

use strict;
use warnings;
use parent 'Exporter::Tiny';

# ABSTRACT: Perl bindings to libsystemd.
our $VERSION = '0.07'; # VERSION

## no critic ( ProhibitImplicitNewlines )
use Systemd::Daemon::XS::Inline
    C => '
        int sd_booted();
        int sd_is_fifo( int fd, const char * path );
        int sd_is_mq( int fd, const char * path );
        int sd_is_socket( int fd, int family, int type, int listening );
        int sd_is_socket_inet( int fd, int family, int type, int listening, U16 port );
        int sd_is_socket_unix( int fd, int family, int type, int listening, const char * path, size_t length );
        int sd_is_special( int fd, const char * path );
        int sd_listen_fds( int unset_environment );
        int sd_notify( int unset_environment, const char * state );
        // int sd_notifyf( int unset_environment, const char * format, ... );
        int sd_pid_notify( int pid, int unset_environment, const char * state );
        // int sd_pid_notify_with_fds( int pid, int unset_environment, const char * state, const int * fds, unsigned n_fds );
        // int sd_pid_notifyf( int pid, int unset_environment, const char * format, ... );
        // int sd_watchdog_enabled( int unset_environment, uint64_t * usec );
    ',
    libs      => '-lsystemd',
    autowrap  => 1,
    clean_after_build => 1,
        #   TODO: Is this comment still valid?
        #   `clean_after_build => 0` causes `make install` to fail, see
        #       https://github.com/ingydotnet/inline-pm/issues/53
        #   `clean_after_build => 1` causes errors when building RPM: rpmbuild
        #   tries to extract debug information from files which were wiped out.
    ;

#pod =pod
#pod
#pod =func sd_listen_fds
#pod
#pod     int sd_listen_fds( int unset_environment );
#pod
#pod
#pod See L<sd_listen_fds(3)|http://www.freedesktop.org/software/systemd/man/sd_listen_fds.html>.
#pod
#pod =func sd_notify
#pod
#pod =func sd_notifyf
#pod
#pod =func sd_pid_notify
#pod
#pod =func sd_pid_notify_with_fds
#pod
#pod =func sd_pid_notifyf
#pod
#pod     int sd_notify( int unset_environment, const char * state );
#pod     // int sd_notifyf( int unset_environment, const char * format, ... );
#pod     int sd_pid_notify( pid_t pid, int unset_environment, const char * state );
#pod     // int sd_pid_notify_with_fds( pid_t pid, int unset_environment, const char * state, const int * fds, unsigned n_fds );
#pod     // int sd_pid_notifyf( int pid, int unset_environment, const char * format, ... );
#pod
#pod
#pod See L<sd_notify(3)|http://www.freedesktop.org/software/systemd/man/sd_notify.html> for details.
#pod
#pod The binding for C<sd_pid_notify_with_fds> function is not yet implemented.
#pod
#pod The bindings for C<sd_notifyf> and C<sd_pid_notifyf> will not be implemented likely. These
#pod C<printf>-like functions accept format string and variable argument list. They are quite convenient
#pod in C, but in Perl they do not have much value — they may be easily replaced either by string
#pod interpolation and/or by using C<sprintf> function, e. g.:
#pod
#pod     sd_notify( 0, "STATUS=Done $percent\%.\n" );
#pod     sd_notify( 0, sprintf( "STATUS=Done %03d\%.\n", $percent ) );
#pod
#pod Also, it can be reimplemented in Perl:
#pod
#pod     sub sd_notifyf($$@) {
#pod         return sd_notify( shift( @_ ), sprintf( @_ ) );
#pod     }
#pod
#pod Such implementation is not included into C<Systemd::Daemon::XS> because it is not a binding to
#pod C<libsystemd>.
#pod
#pod =func sd_booted
#pod
#pod     int sd_booted();
#pod
#pod
#pod See L<sd_booted(3)|http://www.freedesktop.org/software/systemd/man/sd_booted.html>.
#pod
#pod =func sd_is_fifo
#pod
#pod =func sd_is_mq
#pod
#pod =func sd_is_socket
#pod
#pod =func sd_is_socket_inet
#pod
#pod =func sd_is_socket_unix
#pod
#pod =func sd_is_special
#pod
#pod     int sd_is_fifo( int fd, const char * path );
#pod     int sd_is_mq( int fd, const char * path );
#pod     int sd_is_socket( int fd, int family, int type, int listening );
#pod     int sd_is_socket_inet( int fd, int family, int type, int listening, uint16_t port );
#pod     int sd_is_socket_unix( int fd, int family, int type, int listening, const char * path, size_t length );
#pod     int sd_is_special( int fd, const char * path );
#pod
#pod
#pod See L<sd_is_fifo(3)|http://www.freedesktop.org/software/systemd/man/sd_is_fifo.html>.
#pod
#pod =func sd_watchdog_enabled
#pod
#pod     // int sd_watchdog_enabled( int unset_environment, uint64_t * usec );
#pod
#pod
#pod See L<sd_watchdog_enabled(3)|http://www.freedesktop.org/software/systemd/man/sd_watchdog_enabled.html>.
#pod
#pod The binding for C<sd_watchdog_enabled> function is not yet implemented.
#pod
#pod =cut

#pod =head1 CONSTANTS
#pod
#pod Constants described below are not traditional 0-ary functions created by C<constant> pragma, but
#pod immutable variables created by C<Readonly> module, so you have to use sigils but can interpolate
#pod constants to strings.
#pod
#pod =const $SD_ALERT
#pod
#pod =const $SD_CRIT
#pod
#pod =const $SD_DEBUG
#pod
#pod =const $SD_EMERG
#pod
#pod =const $SD_ERR
#pod
#pod =const $SD_INFO
#pod
#pod =const $SD_NOTICE
#pod
#pod =const $SD_WARNING
#pod
#pod
#pod See L<sd-daemon(3)|http://www.freedesktop.org/software/systemd/man/sd-daemon.html>.
#pod
#pod =const $SD_LISTEN_FDS_START
#pod
#pod
#pod See L<sd_listen_fds(3)|http://www.freedesktop.org/software/systemd/man/sd_listen_fds.html>.
#pod
#pod =cut

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


#pod =head1 EXPORT
#pod
#pod The module exports nothing by default. You have to specify symbols to import explicitly:
#pod
#pod     # Import function sd_listen_fds and constant $SD_LISTEN_FDS_START:
#pod     use Systemd::Daemon::XS qw{ sd_listen_fds $SD_LISTEN_FDS_START };
#pod
#pod or use tags to import groups of related symbols:
#pod
#pod     # The same as as above:
#pod     use Systemd::Daemon::XS qw{ :sd_listen };
#pod
#pod Either colon (C<:>) or dash (C<->) can be used as tag prefix:
#pod
#pod     # Ditto:
#pod     use Systemd::Daemon::XS qw{ -sd_listen };
#pod
#pod The module uses L<Exporter::Tiny> to export symbols, so all advanced import features like renaming
#pod symbols, importing to another package, to a hash, by regexp, etc, can be used:
#pod
#pod     use Systemd::Daemon::XS '$SD_ERR' => { -as => 'ERR' }, '$SD_DEBUG' => { -as => 'DBG' };
#pod     use Systemd::Daemon::XS qw{ -all !sd_notify };
#pod
#pod See L<tips and tricks|Exporter::Tiny/"TIPS AND TRICKS IMPORTING FROM EXPORTER::TINY">.
#pod
#pod =head2 Tags
#pod
#pod The module defines following export tags (C<all> tag is not listed):
#pod
#pod =for :list
#pod = sd_booted
#pod sd_booted.
#pod = sd_is
#pod sd_is_fifo, sd_is_mq, sd_is_socket, sd_is_socket_inet, sd_is_socket_unix, sd_is_special.
#pod = sd_listen
#pod $SD_LISTEN_FDS_START, sd_listen_fds.
#pod = sd_log
#pod $SD_ALERT, $SD_CRIT, $SD_DEBUG, $SD_EMERG, $SD_ERR, $SD_INFO, $SD_NOTICE, $SD_WARNING.
#pod = sd_notify
#pod sd_notify, sd_pid_notify.
#pod = sd
#pod All above.
#pod
#pod
#pod =cut

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


#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod *   L<sd_listen_fds(3)|http://www.freedesktop.org/software/systemd/man/sd_listen_fds.html>
#pod *   L<sd_notify(3)|http://www.freedesktop.org/software/systemd/man/sd_notify.html>
#pod *   L<sd_booted(3)|http://www.freedesktop.org/software/systemd/man/sd_booted.html>
#pod *   L<sd_is_fifo(3)|http://www.freedesktop.org/software/systemd/man/sd_is_fifo.html>
#pod *   L<sd_watchdog_enabled(3)|http://www.freedesktop.org/software/systemd/man/sd_watchdog_enabled.html>
#pod *   L<Exporter::Tiny>
#pod *   L<Readonly>
#pod
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

Systemd::Daemon::XS - Perl bindings to libsystemd.

=head1 VERSION

Version 0.07, released on 2015-11-12 13:35 UTC.

=head1 SYNOPSIS

    use Systemd::Daemon::XS qw{ :all };

    sd_notify( 0, "READY=1\nSTATUS=Ready\n" );
    sd_pid_notify( $pid, 0, "RELOADING=1" );
    if ( sd_booted() ) {
        ...;
    };
    ...;

=head1 DESCRIPTION

This module provides Perl bindings to the part of F<libsystemd> shared library declared in
<F<systemd/sd-daemon.h>> header.

=head1 EXPORT

The module exports nothing by default. You have to specify symbols to import explicitly:

    # Import function sd_listen_fds and constant $SD_LISTEN_FDS_START:
    use Systemd::Daemon::XS qw{ sd_listen_fds $SD_LISTEN_FDS_START };

or use tags to import groups of related symbols:

    # The same as as above:
    use Systemd::Daemon::XS qw{ :sd_listen };

Either colon (C<:>) or dash (C<->) can be used as tag prefix:

    # Ditto:
    use Systemd::Daemon::XS qw{ -sd_listen };

The module uses L<Exporter::Tiny> to export symbols, so all advanced import features like renaming
symbols, importing to another package, to a hash, by regexp, etc, can be used:

    use Systemd::Daemon::XS '$SD_ERR' => { -as => 'ERR' }, '$SD_DEBUG' => { -as => 'DBG' };
    use Systemd::Daemon::XS qw{ -all !sd_notify };

See L<tips and tricks|Exporter::Tiny/"TIPS AND TRICKS IMPORTING FROM EXPORTER::TINY">.

=head2 Tags

The module defines following export tags (C<all> tag is not listed):

=over 4

=item sd_booted

sd_booted.

=item sd_is

sd_is_fifo, sd_is_mq, sd_is_socket, sd_is_socket_inet, sd_is_socket_unix, sd_is_special.

=item sd_listen

$SD_LISTEN_FDS_START, sd_listen_fds.

=item sd_log

$SD_ALERT, $SD_CRIT, $SD_DEBUG, $SD_EMERG, $SD_ERR, $SD_INFO, $SD_NOTICE, $SD_WARNING.

=item sd_notify

sd_notify, sd_pid_notify.

=item sd

All above.

=back

=head1 CONSTANTS

Constants described below are not traditional 0-ary functions created by C<constant> pragma, but
immutable variables created by C<Readonly> module, so you have to use sigils but can interpolate
constants to strings.

=head2 $SD_ALERT

=head2 $SD_CRIT

=head2 $SD_DEBUG

=head2 $SD_EMERG

=head2 $SD_ERR

=head2 $SD_INFO

=head2 $SD_NOTICE

=head2 $SD_WARNING

See L<sd-daemon(3)|http://www.freedesktop.org/software/systemd/man/sd-daemon.html>.

=head2 $SD_LISTEN_FDS_START

See L<sd_listen_fds(3)|http://www.freedesktop.org/software/systemd/man/sd_listen_fds.html>.

=head1 FUNCTIONS

=head2 sd_listen_fds

    int sd_listen_fds( int unset_environment );

See L<sd_listen_fds(3)|http://www.freedesktop.org/software/systemd/man/sd_listen_fds.html>.

=head2 sd_notify

=head2 sd_notifyf

=head2 sd_pid_notify

=head2 sd_pid_notify_with_fds

=head2 sd_pid_notifyf

    int sd_notify( int unset_environment, const char * state );
    // int sd_notifyf( int unset_environment, const char * format, ... );
    int sd_pid_notify( pid_t pid, int unset_environment, const char * state );
    // int sd_pid_notify_with_fds( pid_t pid, int unset_environment, const char * state, const int * fds, unsigned n_fds );
    // int sd_pid_notifyf( int pid, int unset_environment, const char * format, ... );

See L<sd_notify(3)|http://www.freedesktop.org/software/systemd/man/sd_notify.html> for details.

The binding for C<sd_pid_notify_with_fds> function is not yet implemented.

The bindings for C<sd_notifyf> and C<sd_pid_notifyf> will not be implemented likely. These
C<printf>-like functions accept format string and variable argument list. They are quite convenient
in C, but in Perl they do not have much value — they may be easily replaced either by string
interpolation and/or by using C<sprintf> function, e. g.:

    sd_notify( 0, "STATUS=Done $percent\%.\n" );
    sd_notify( 0, sprintf( "STATUS=Done %03d\%.\n", $percent ) );

Also, it can be reimplemented in Perl:

    sub sd_notifyf($$@) {
        return sd_notify( shift( @_ ), sprintf( @_ ) );
    }

Such implementation is not included into C<Systemd::Daemon::XS> because it is not a binding to
C<libsystemd>.

=head2 sd_booted

    int sd_booted();

See L<sd_booted(3)|http://www.freedesktop.org/software/systemd/man/sd_booted.html>.

=head2 sd_is_fifo

=head2 sd_is_mq

=head2 sd_is_socket

=head2 sd_is_socket_inet

=head2 sd_is_socket_unix

=head2 sd_is_special

    int sd_is_fifo( int fd, const char * path );
    int sd_is_mq( int fd, const char * path );
    int sd_is_socket( int fd, int family, int type, int listening );
    int sd_is_socket_inet( int fd, int family, int type, int listening, uint16_t port );
    int sd_is_socket_unix( int fd, int family, int type, int listening, const char * path, size_t length );
    int sd_is_special( int fd, const char * path );

See L<sd_is_fifo(3)|http://www.freedesktop.org/software/systemd/man/sd_is_fifo.html>.

=head2 sd_watchdog_enabled

    // int sd_watchdog_enabled( int unset_environment, uint64_t * usec );

See L<sd_watchdog_enabled(3)|http://www.freedesktop.org/software/systemd/man/sd_watchdog_enabled.html>.

The binding for C<sd_watchdog_enabled> function is not yet implemented.

=for test_synopsis my ( $pid );

=head1 SEE ALSO

=over 4

=item *

L<sd_listen_fds(3)|http://www.freedesktop.org/software/systemd/man/sd_listen_fds.html>

=item *

L<sd_notify(3)|http://www.freedesktop.org/software/systemd/man/sd_notify.html>

=item *

L<sd_booted(3)|http://www.freedesktop.org/software/systemd/man/sd_booted.html>

=item *

L<sd_is_fifo(3)|http://www.freedesktop.org/software/systemd/man/sd_is_fifo.html>

=item *

L<sd_watchdog_enabled(3)|http://www.freedesktop.org/software/systemd/man/sd_watchdog_enabled.html>

=item *

L<Exporter::Tiny>

=item *

L<Readonly>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
