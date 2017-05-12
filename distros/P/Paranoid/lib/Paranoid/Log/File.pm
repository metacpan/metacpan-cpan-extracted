# Paranoid::Log::File -- File Log support for paranoid programs
#
# (c) 2005 - 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/Log/File.pm, 2.05 2017/02/06 01:48:57 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Log::File;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION);
use Paranoid::Debug qw(:all);
use Paranoid::Filesystem;
use Paranoid::Input;
use Paranoid::IO;
use Fcntl qw(:DEFAULT :flock :mode :seek);

($VERSION) = ( q$Revision: 2.05 $ =~ /(\d+(?:\.\d+)+)/sm );

#####################################################################
#
# Module code follows
#
#####################################################################

{

    my $hostname;
    my $pname;

    sub _getHostname {

        # Purpose:  Returns the hostname, defaulting to localhost if
        #           /bin/hostname is unusable
        # Returns:  Hostname
        # Usage:    $hostname = _getHostname();

        my $fd;

        # Return cached result
        return $hostname if defined $hostname;

        # Get the current hostname
        if ( -x '/bin/hostname' ) {
            if ( open $fd, '-|', '/bin/hostname' ) {
                chomp( $hostname = <$fd> );
                close $fd;
            }
        }

        # Do a little sanitizing...
        if (defined $hostname and length $hostname) {
            $hostname =~ s/\..*$//so;
        } else {
            $hostname = 'localhost';
        }

        return $hostname;
    }

    sub _timestamp {

        # Purpose:  Returns a syslog-stype timestamp string for the current or
        #           passed time
        # Returns:  String
        # Usage:    $timestamp = ptimestamp();
        # Usage:    $timestamp = ptimestamp($epoch);

        my $utime  = shift;
        my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
        my @ctime;

        @ctime = defined $utime ? ( localtime $utime ) : (localtime);

        return sprintf
            '%s %2d %02d:%02d:%02d',
            $months[ $ctime[4] ],
            @ctime[ 3, 2, 1, 0 ];
    }

    sub init {
        _getHostname();
        ($pname) = ( $0 =~ m#^(?:.+/)?([^/]+)$#s );
        return 1;
    }

    sub addLogger {

        # Purpose:  Opens a handle the requested file
        # Returns:  Boolean
        # Usage:    $rv = addLogger(%record);

        my %record = @_;
        my ( $mode, $perm, $rv );

        pdebug( 'entering w/%s', PDLEVEL1, %record );
        pIn();

        # Get mode and permissions
        $mode =
            exists $record{options}{mode}
            ? $record{options}{mode}
            : O_CREAT | O_APPEND | O_WRONLY;
        $perm = $record{options}{perm} if exists $record{options}{perm};
        pdebug( 'perm: %s mode: %s', PDLEVEL1, $perm, $mode );
        if ( defined $record{options}{file}
            and length $record{options}{file} ) {
            $rv = defined popen( $record{options}{file}, $mode, $perm );
        } else {
            Paranoid::ERROR =
                pdebug( 'invalid file name specified in options: %s',
                PDLEVEL1, $record{options}{file} );
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

        return $rv;
    }

    sub delLogger {

        # Purpose:  Closes the requested file
        # Returns:  Return value of close
        # Usage:    $rv = delLogger(%record);

        my %record = @_;

        return pclose( $record{options}{file} );
    }

    sub logMsg {

        # Purpose:  Logs the passed message to the named file
        # Returns:  Return value of print()
        # Usage:    $rv = logMsg(%record);

        my %record = @_;
        my ( $fh, $message, $rv );

        pdebug( 'entering w/%s', PDLEVEL1, %record );
        pIn();

        # Get the message and make sure it's terminated by a single newline
        $message = $record{message};
        $message =~ s/\n*$/\n/so;

        if ( $record{options}{syslog} ) {
            $message =~ s/\n//so;
            $message = sprintf "%s %s %s[%d]: %s\n",
                _timestamp( $record{msgtime} ), $hostname, $pname, $$,
                substr $message, 0, 2048;
        }

        $rv = pappend( $record{options}{file}, $message );

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

        return $rv;
    }
}

1;

__END__

=head1 NAME

Paranoid::Log::File - File Logging Functions

=head1 VERSION

$Id: lib/Paranoid/Log/File.pm, 2.05 2017/02/06 01:48:57 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Log;
  
  startLogger('events', 'File', PL_DEBUG, PL_GE, 
    { 
      file   => '/var/log/events.log',
      mode   => O_TRUNC | O_CREAT | O_RDWR,
      perm   => 0600,
      syslog => 1,
    });

=head1 DESCRIPTION

This provides a mechanism to log to log files.  It will log arbitrarily long
text, but also provides a syslog mode which limits log lines to 2048 and
precedes text with the standard syslog preamble (date/time, host, process
name/PID).

The only mandatory option is the I<file> key/value pair.  This module
leverages L<Paranoid::IO>'s I<popen>.

I<mode> defaults to O_CREAT | O_APPEND | O_WRONLY.'

I<perm> defaults to 0666 (umask still applies).

I<syslog> defaults to false.  Enabling it causes every line to be formatted
akin to syslog, along with the 2048 byte limit on messages.

=head1 OPTIONS

The options recognized for use in the options hash are as follows:

    Option      Value       Description
    -----------------------------------------------------
    file        string      file name of log file
    mode        integer     file mode to open with
    perm        integer     file permissions of newly 
                            created log files
    syslog      boolean     enable syslog-style format

=head1 SUBROUTINES/METHODS

B<NOTE>:  Given that this module is not intended to be used directly nothing
is exported.

=head2 init

=head2 logMsg

=head2 addLogger

=head2 delLogger

=head1 DEPENDENCIES

=over

=item o

L<Fcntl>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Filesystem>

=item o

L<Paranoid::Input>

=item o

L<Paranoid::IO>

=back

=head1 SEE ALSO

=over

=item o

L<Paranoid::Log>

=back

=head1 BUGS AND LIMITATIONS

This isn't a high performance module when dealing with a high logging rate
with high concurrency.  This is due to the advisory locking requirement and
the seeks to the end of the file with every message.  This facility is
intended as a kind of lowest-common denominator for programs that need some
kind of logging capability.

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2017, Arthur Corliss (corliss@digitalmages.com)

