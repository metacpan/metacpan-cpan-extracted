#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: lib/Systemd/Daemon.pm
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
# --------------------------------------------------------------------------------------------------

#pod =for test_synopsis my ( $cond, $percent, $pid );
#pod
#pod =head1 SYNOPSIS
#pod
#pod B<Note>: The module is in experimental state, interface may be changed in the future.
#pod
#pod Perlish functions:
#pod
#pod     use Systemd::Daemon qw{ -soft notify };
#pod
#pod     notify( RELOADING => 1 );
#pod     while ( $cond ) {
#pod         notify( STATUS => "Loading, $percent\% done" );
#pod         ...;
#pod     };
#pod
#pod     notify( READY => 1, STATUS => "Ready" );
#pod     ...;
#pod
#pod     notify( STOPPING => 1 );
#pod     ...;
#pod
#pod Low-level bare C functions:
#pod
#pod     use Systemd::Daemon qw{ -hard -sd };
#pod
#pod     sd_notify( 0, "READY=1\nSTATUS=Ready\n" );
#pod     sd_pid_notify( $pid, 0, "READY=1\nSTATUS=Ready\n" );
#pod     if ( sd_booted() > 0 ) { ... };
#pod
#pod =cut

#pod =head1 DESCRIPTION
#pod
#pod C<Systemd-Daemon> distribution includes two implementations of sd-daemon API: XS and Stub. The
#pod first contains actual bindings to libsystemd shared library, the second is a library of stubs,
#pod which do nothing but immediately return error code.
#pod
#pod C<Systemd::Daemon> serves as interface to underlying implementations. It can work in two modes:
#pod hard and soft. In both modes, C<Systemd::Daemon> loads XS implementation first. In case of any
#pod trouble (e. g. libsystemd shared library is not found) C<Systemd::Daemon> either re-throws
#pod exception (in hard mode) or falls back to use stubs (in soft mode).
#pod
#pod In other words, in hard mode you will get actual bindings or exception, while in soft mode you will
#pod get either actual binding or stubs (exception is possible if loading stubs also failed, but it
#pod should not occur in normal conditions).
#pod
#pod Desired mode is specified as import pseudo-tag C<-hard> or C<-soft>:
#pod
#pod     use Systemd::Daemon qw{ -hard };
#pod
#pod =cut

package Systemd::Daemon;

use strict;
use warnings;

# ABSTRACT: Write systemd-aware daemons in Perl
our $VERSION = '0.07'; # VERSION

use parent 'Exporter::Tiny';

use Carp qw{ croak };
use Try::Tiny;
use Systemd::Daemon::Stub;

our @CARP_NOT = qw{ Try::Tiny };

# --------------------------------------------------------------------------------------------------

#pod =head1 FUNCTIONS
#pod
#pod The module re-exports (by explicit request) all the functions from underlying implementation,
#pod see L<Systemd::Daemon::XS/"FUNCTIONS">.
#pod
#pod Additionally, the module defines following functions:
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

#pod =func notify
#pod
#pod     $int = notify( VAR => VALUE, … );
#pod
#pod C<notify> is Perl wrapper for C functions C<sd_notify> and C<sd_pid_notify>, so read
#pod L<sd_notify(3)|http://www.freedesktop.org/software/systemd/man/sd_notify.html> first.
#pod
#pod C functions accept status as one string of newline-separated variable assignments, e. g.:
#pod
#pod     sd_notify( 0, "RELOADING=1\nSTATUS=50% done\n" );
#pod
#pod Unlike to C functions, C<notify> accepts each variable separately as Perl "named arguments", e. g.:
#pod
#pod     notify( RELOADING => 1, STATUS => '50% done' );
#pod
#pod C<unset_environment> and C<pid> parameters can be specified as named arguments C<unset> and C<pid>
#pod respectively, e. g.:
#pod
#pod     notify( pid => $pid, unset => 1, ... );
#pod
#pod If C<pid> value is defined, C<notify> calls C<sd_pid_notify>, otherwise C<sd_notify> is called.
#pod C<unset> is defaulted to zero.
#pod
#pod L<sd_notify(3)|http://www.freedesktop.org/software/systemd/man/sd_notify.html> describes some
#pod "well-known" variable assignments, for example, C<RELOADING=1>. Systemd's reaction on assignment
#pod C<RELOADING=2> is not defined. In my experiments with systemd v217 any value but C<1> does not have
#pod any effect. To make C<notify> more Perlish, C<READY>, C<RELOADING>, C<STOPPING>, C<WATCHDOG>, and
#pod C<FDSTORE> arguments are normalized: if its value is false (e. g. undef, zero or empty string), the
#pod respective variable is not passed to underlying C function at all; if its value is true (not
#pod false), the respective variable is set to C<1>.
#pod
#pod C<notify> returns result of underlying C<sd_notify> (or C<sd_pid_notify>). It should be negative
#pod integer in case of error, zero if C<$ENV{ NOTIFY_SOCKET }> is not set (and so, C<systemd> cannot be
#pod notified), and some positive value in case of success. However, L<sd_notify(3)> recommends to
#pod ignore return value.
#pod
#pod =cut

sub notify(@) {
    my ( %args ) = @_;
    my $pid   = delete( $args{ pid   } );
    my $unset = delete( $args{ unset } ) ? 1 : 0;
    foreach my $k ( qw{ READY RELOADING STOPPING WATCHDOG FDSTORE } ) {
        delete( $args{ $k } ) and $args{ $k } = 1;
    }; # foreach
    my $state = join( '', map( { "$_=$args{ $_ }\n" } keys( %args ) ) );
    my $rc;
    if ( defined( $pid ) ) {
        $rc = sd_pid_notify( $pid, $unset, $state );
    } else {
        $rc = sd_notify( $unset, $state );
    }; # if
    return $rc;
}; # sub notify

# --------------------------------------------------------------------------------------------------

#pod =head1 CONSTANTS
#pod
#pod The module re-exports (by explicit request) all the constants from underlying implementation, see
#pod L<Systemd::Daemon::XS/"CONSTANTS">.
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

my $loaded;
sub _load($) {
    my ( $hard ) = @_;
    if ( not defined( $loaded ) ) {
        # Try to load XS module first.
        try {
            require Systemd::Daemon::XS;
            $loaded = 'Systemd::Daemon::XS';
        } catch {
            # If loading XS module failed, report the error…
            $_ =~ s{ \s at \s .+? \s line \s \d+\.\n\z}{}x;
            if ( $hard ) {
                # Croak in case of hard mode.
                croak $_;
            } else {
                carp $_;
            };
            $loaded = 'Systemd::Daemon::Stub';
        };
        $loaded->import( ':all' );
    };
    # Return the name of loaded module.
    return $loaded;
};

sub _exporter_validate_opts {   ## no critic ( ProhibitUnusedPrivateSubroutines )
    my ( $class, $opts ) = @_;
    if ( $opts->{ hard } and $opts->{ soft } ) {
        croak "$class: options hard and soft are mutually exclusive";
    };
    if ( $opts->{ hard } and defined( $loaded ) and $loaded ne 'Systemd::Daemon::XS' ) {
        croak "$class: Already loaded in soft mode";
    };
    _load( not $opts->{ soft } );
    return;
};

#pod =head1 EXPORT
#pod
#pod The module exports nothing by default. You have to specify symbols to import explicitly:
#pod
#pod     # Import function sd_listen_fds and constant $SD_LISTEN_FDS_START:
#pod     use Systemd::Daemon qw{ sd_listen_fds $SD_LISTEN_FDS_START };
#pod
#pod or use tags to import groups of related symbols:
#pod
#pod     # The same as as above:
#pod     use Systemd::Daemon qw{ :sd_listen };
#pod
#pod Either colon (C<:>) or dash (C<->) can be used as tag prefix:
#pod
#pod     # Ditto:
#pod     use Systemd::Daemon qw{ -sd_listen };
#pod
#pod The module uses L<Exporter::Tiny> to export symbols, so all advanced import features like renaming
#pod symbols, importing to another package, to a hash, by regexp, etc, can be used:
#pod
#pod     use Systemd::Daemon '$SD_ERR' => { -as => 'ERR' }, '$SD_DEBUG' => { -as => 'DBG' };
#pod     use Systemd::Daemon qw{ -all !notify };
#pod
#pod See L<Exporter::Tiny/"TIPS AND TRICKS IMPORTING FROM EXPORTER::TINY">.
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
$EXPORT_TAGS{ sd } = [ @{ $EXPORT_TAGS{ all } } ];
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

push( @EXPORT_OK, 'notify' );

#pod =head1 BUGS
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod *   L<systemd|https://wiki.freedesktop.org/www/Software/systemd/>
#pod *   L<daemon|http://www.freedesktop.org/software/systemd/man/daemon.html>
#pod *   L<sd-daemon|http://www.freedesktop.org/software/systemd/man/sd-daemon.html>
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

Systemd::Daemon - Write systemd-aware daemons in Perl

=head1 VERSION

Version 0.07, released on 2015-11-12 13:35 UTC.

=head1 SYNOPSIS

B<Note>: The module is in experimental state, interface may be changed in the future.

Perlish functions:

    use Systemd::Daemon qw{ -soft notify };

    notify( RELOADING => 1 );
    while ( $cond ) {
        notify( STATUS => "Loading, $percent\% done" );
        ...;
    };

    notify( READY => 1, STATUS => "Ready" );
    ...;

    notify( STOPPING => 1 );
    ...;

Low-level bare C functions:

    use Systemd::Daemon qw{ -hard -sd };

    sd_notify( 0, "READY=1\nSTATUS=Ready\n" );
    sd_pid_notify( $pid, 0, "READY=1\nSTATUS=Ready\n" );
    if ( sd_booted() > 0 ) { ... };

=head1 DESCRIPTION

C<Systemd-Daemon> distribution includes two implementations of sd-daemon API: XS and Stub. The
first contains actual bindings to libsystemd shared library, the second is a library of stubs,
which do nothing but immediately return error code.

C<Systemd::Daemon> serves as interface to underlying implementations. It can work in two modes:
hard and soft. In both modes, C<Systemd::Daemon> loads XS implementation first. In case of any
trouble (e. g. libsystemd shared library is not found) C<Systemd::Daemon> either re-throws
exception (in hard mode) or falls back to use stubs (in soft mode).

In other words, in hard mode you will get actual bindings or exception, while in soft mode you will
get either actual binding or stubs (exception is possible if loading stubs also failed, but it
should not occur in normal conditions).

Desired mode is specified as import pseudo-tag C<-hard> or C<-soft>:

    use Systemd::Daemon qw{ -hard };

=head1 EXPORT

The module exports nothing by default. You have to specify symbols to import explicitly:

    # Import function sd_listen_fds and constant $SD_LISTEN_FDS_START:
    use Systemd::Daemon qw{ sd_listen_fds $SD_LISTEN_FDS_START };

or use tags to import groups of related symbols:

    # The same as as above:
    use Systemd::Daemon qw{ :sd_listen };

Either colon (C<:>) or dash (C<->) can be used as tag prefix:

    # Ditto:
    use Systemd::Daemon qw{ -sd_listen };

The module uses L<Exporter::Tiny> to export symbols, so all advanced import features like renaming
symbols, importing to another package, to a hash, by regexp, etc, can be used:

    use Systemd::Daemon '$SD_ERR' => { -as => 'ERR' }, '$SD_DEBUG' => { -as => 'DBG' };
    use Systemd::Daemon qw{ -all !notify };

See L<Exporter::Tiny/"TIPS AND TRICKS IMPORTING FROM EXPORTER::TINY">.

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

=head1 FUNCTIONS

The module re-exports (by explicit request) all the functions from underlying implementation,
see L<Systemd::Daemon::XS/"FUNCTIONS">.

Additionally, the module defines following functions:

=head2 notify

    $int = notify( VAR => VALUE, … );

C<notify> is Perl wrapper for C functions C<sd_notify> and C<sd_pid_notify>, so read
L<sd_notify(3)|http://www.freedesktop.org/software/systemd/man/sd_notify.html> first.

C functions accept status as one string of newline-separated variable assignments, e. g.:

    sd_notify( 0, "RELOADING=1\nSTATUS=50% done\n" );

Unlike to C functions, C<notify> accepts each variable separately as Perl "named arguments", e. g.:

    notify( RELOADING => 1, STATUS => '50% done' );

C<unset_environment> and C<pid> parameters can be specified as named arguments C<unset> and C<pid>
respectively, e. g.:

    notify( pid => $pid, unset => 1, ... );

If C<pid> value is defined, C<notify> calls C<sd_pid_notify>, otherwise C<sd_notify> is called.
C<unset> is defaulted to zero.

L<sd_notify(3)|http://www.freedesktop.org/software/systemd/man/sd_notify.html> describes some
"well-known" variable assignments, for example, C<RELOADING=1>. Systemd's reaction on assignment
C<RELOADING=2> is not defined. In my experiments with systemd v217 any value but C<1> does not have
any effect. To make C<notify> more Perlish, C<READY>, C<RELOADING>, C<STOPPING>, C<WATCHDOG>, and
C<FDSTORE> arguments are normalized: if its value is false (e. g. undef, zero or empty string), the
respective variable is not passed to underlying C function at all; if its value is true (not
false), the respective variable is set to C<1>.

C<notify> returns result of underlying C<sd_notify> (or C<sd_pid_notify>). It should be negative
integer in case of error, zero if C<$ENV{ NOTIFY_SOCKET }> is not set (and so, C<systemd> cannot be
notified), and some positive value in case of success. However, L<sd_notify(3)> recommends to
ignore return value.

=for test_synopsis my ( $cond, $percent, $pid );

=head1 CONSTANTS

The module re-exports (by explicit request) all the constants from underlying implementation, see
L<Systemd::Daemon::XS/"CONSTANTS">.

=head1 BUGS

=head1 SEE ALSO

=over 4

=item *

L<systemd|https://wiki.freedesktop.org/www/Software/systemd/>

=item *

L<daemon|http://www.freedesktop.org/software/systemd/man/daemon.html>

=item *

L<sd-daemon|http://www.freedesktop.org/software/systemd/man/sd-daemon.html>

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
