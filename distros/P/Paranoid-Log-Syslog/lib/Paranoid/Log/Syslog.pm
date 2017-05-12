# Paranoid::Log::Syslog -- Log Facility Syslog for paranoid programs
#
# (c) 2005 - 2015, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/Log/Syslog.pm, 2.00 2016/05/13 19:51:02 acorliss Exp $
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

package Paranoid::Log::Syslog;

use 5.006;

use strict;
use warnings;
use vars qw($VERSION);
use Paranoid;
use Paranoid::Debug qw(:all);
use Unix::Syslog qw(:macros :subs);
use Carp;

($VERSION) = ( q$Revision: 2.00 $ =~ /(\d+(?:\.\d+)+)/sm );

my @p2lmap = ( LOG_DEBUG, LOG_INFO, LOG_NOTICE, LOG_WARNING,
    LOG_ERR, LOG_CRIT, LOG_ALERT, LOG_EMERG,
    );

#####################################################################
#
# Module code follows
#
#####################################################################

{

    my %loggers = ();

    sub _logger {
        my $name    = shift;
        my %options = @_;

        unless ( exists $loggers{$name} ) {

            # Set a default ident
            unless ( defined $options{ident} and length $options{ident} ) {
                ( $options{ident} ) = ( $0 =~ m#([^/]+)$#s );
            }

            # Set a default facility
            $options{facility} = 'user' unless defined $options{facility};
            $options{facility} = _transFacility( $options{facility} );

            # Set a default syslog mode options
            $options{sysopt} = LOG_CONS | LOG_PID;

            # Set PID
            $options{pid} = $$;

            # Save the options
            $loggers{$name} = {%options};
        }

        return %{ $loggers{$name} };
    }

    sub _delLogger {
        my $name = shift;

        delete $loggers{$name};

        return 1;
    }

    my $lastLogger;

    sub _lastLogger : lvalue {
        $lastLogger;
    }

}

sub init {

    # Purpose:  Exists purely for compliance.
    # Returns:  True (1)
    # Usage:    init();

    return 1;
}

sub _transFacility {

    # Purpose:  Translates the string log facilities into the syslog constants
    # Returns:  Constant scalar value
    # Usage:    $facility = _transFacility($facilityName);

    my $f     = lc shift;
    my %trans = (
        authpriv => LOG_AUTHPRIV,
        auth     => LOG_AUTHPRIV,
        cron     => LOG_CRON,
        daemon   => LOG_DAEMON,
        ftp      => LOG_FTP,
        kern     => LOG_KERN,
        local0   => LOG_LOCAL0,
        local1   => LOG_LOCAL1,
        local2   => LOG_LOCAL2,
        local3   => LOG_LOCAL3,
        local4   => LOG_LOCAL4,
        local5   => LOG_LOCAL5,
        local6   => LOG_LOCAL6,
        local7   => LOG_LOCAL7,
        lpr      => LOG_LPR,
        mail     => LOG_MAIL,
        news     => LOG_NEWS,
        syslog   => LOG_SYSLOG,
        user     => LOG_USER,
        uucp     => LOG_UUCP,
        );

    return exists $trans{$f} ? $trans{$f} : undef;
}

sub addLogger {

    # Purpose:  Exists purely for compliance.
    # Returns:  True (1)
    # Usage:    init();

    my %record = @_;

    _logger( $record{name}, %{ $record{options} } );

    return 1;
}

sub delLogger {

    # Purpose:  Exists purely for compliance.
    # Returns:  True (1)
    # Usage:    init();

    my $name = shift;

    return _delLogger($name);
}

sub logMsg {

    # Purpose:  Logs the passed message to the named file
    # Returns:  Return value of print()
    # Usage:    logMsg(%recordd);

    my %record  = @_;
    my %options = _logger( $record{name} );
    my $llogger = _lastLogger();
    my $rv;

    pdebug( 'entering w/%s', PDLEVEL1, %record );
    pIn();

    if ( defined $record{message} and length $record{message} ) {

        # Check for children processes
        if ( $options{pid} != $$ ) {
            closelog();
            $llogger = _lastLogger() = undef;
            _delLogger( $record{name} );
            _logger( $record{name}, %options );
        }

        # Close the syslog connection and reconfigure if
        # this is a different logger
        if ( defined $llogger and $llogger ne $record{name} ) {
            closelog();
            $llogger = _lastLogger() = undef;
        }

        # Open a new connection
        unless ( defined $llogger ) {
            openlog( $options{ident}, $options{sysopt}, $options{facility} );
            _lastLogger() = $record{name};
        }

        # Logg the message
        syslog( $p2lmap[ $record{severity} ], '%s', $record{message} );
        $rv = 1;

    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::Log::Syslog - Log Facility Syslog

=head1 VERSION

$Id: lib/Paranoid/Log/Syslog.pm, 2.00 2016/05/13 19:51:02 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Log;
  
  startLogger( 'syslog_local1', 'Syslog', PL_WARN, PL_EQ,
    { facility => 'local1', ident => 'myproc' });

=head1 DESCRIPTION

This module implements UNIX syslog support for logging purposes.  The options
hash is entirely optional.  The facility defaults to B<user> if omitted, and
ident defaults to the process name.

This module does support the use of multiple syslog loggers, with each being
able to set their own facility and ident.

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

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Unix::Syslog>

=back

=head1 BUGS AND LIMITATIONS

None.

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2015, Arthur Corliss (corliss@digitalmages.com)

