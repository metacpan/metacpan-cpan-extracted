# Paranoid::Log -- Log support for paranoid programs
#
# $Id: lib/Paranoid/Log.pm, 2.08 2020/12/31 12:10:06 acorliss Exp $
#
# This software is free software.  Similar to Perl, you can redistribute it
# and/or modify it under the terms of either:
#
#   a)     the GNU General Public License
#          <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
#          Free Software Foundation <http://www.fsf.org/>; either version 1
#          <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
#          <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
#   b)     the Artistic License 2.0
#          <https://opensource.org/licenses/Artistic-2.0>,
#
# subject to the following additional term:  No trademark rights to
# "Paranoid" have been or are conveyed under any of the above licenses.
# However, "Paranoid" may be used fairly to describe this unmodified
# software, in good faith, but not as a trademark.
#
# (c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
# (tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Log;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Paranoid::Debug qw(:all);
use Paranoid::Module;
use Paranoid::Input;

($VERSION) = ( q$Revision: 2.08 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT = qw(
    PL_DEBUG     PL_INFO      PL_NOTICE    PL_WARN
    PL_ERR       PL_CRIT      PL_ALERT     PL_EMERG
    PL_EQ        PL_NE        PL_GE        PL_LE
    startLogger stopLogger plog plverbosity
    );
@EXPORT_OK = (@EXPORT);
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

use constant PL_DEBUG  => 0;
use constant PL_INFO   => 1;
use constant PL_NOTICE => 2;
use constant PL_WARN   => 3;
use constant PL_ERR    => 4;
use constant PL_CRIT   => 5;
use constant PL_ALERT  => 6;
use constant PL_EMERG  => 7;

use constant PL_EQ => '=';
use constant PL_NE => '!';
use constant PL_GE => '+';
use constant PL_LE => '-';

use constant PL_LREF => 0;
use constant PL_AREF => 1;
use constant PL_DREF => 2;

our @_scopes = ( PL_EQ, PL_NE, PL_GE, PL_LE );
our @_levels = (
    PL_DEBUG, PL_INFO, PL_NOTICE, PL_WARN,
    PL_ERR,   PL_CRIT, PL_ALERT,  PL_EMERG,
    );

#####################################################################
#
# Module code follows
#
#####################################################################

{

    my %loaded = ();    # module => loaded (boolean)
    my %msubs  = ();    # module => log sub ref
    my @dist;           # modules to distribute to by log level

    # This has consists of the name/array key/value pairs.  Each associated
    # array consists of the following entries:
    #        [ $sref, $level, $scope, \%mopts ].
    my %loggers = ();

    sub _loadModule {

        # Purpose:  Loads the requested module if it hasn't been already.
        #           Attempts to first load the module as a name relative to
        #           Paranoid::Log, otherwise by itself.
        # Returns:  True (1) if load was successful,
        #           False (0) if there are any errors
        # Usage:    $rv = _loadModule($module);

        my $module = shift;
        my $mname  = $module;
        my ( $sref, $aref, $dref, $rv );

        pdebug( 'entering w/(%s)', PDLEVEL2, $module );
        pIn();

        # Was module already loaded (or a load attempted)?
        if ( exists $loaded{$module} ) {

            # Yep, so return module status
            $rv = $loaded{$module};

        } else {

            # Nope, so let's try to load it.
            #
            # Is the module name taint-safe?
            if ( detaint( $mname, 'filename' ) ) {

                # Yep, so try to load relative to Paranoid::Log
                $rv =
                      $mname eq 'Stderr' ? 1
                    : $mname eq 'Stdout' ? 1
                    : $mname eq 'PDebug' ? 1
                    : loadModule( "Paranoid::Log::$mname", '' )
                    && eval "Paranoid::Log::${mname}::init();"
                    && eval "\$sref = \\&Paranoid::Log::${mname}::logMsg;"
                    && eval "\$aref = \\&Paranoid::Log::${mname}::addLogger;"
                    && eval "\$dref = \\&Paranoid::Log::${mname}::delLogger;"
                    ? 1
                    : 0;

                # If that failed, try to load it directly
                unless ($rv) {
                    $rv =
                           loadModule( $mname, '' )
                        && eval "${mname}::init();"
                        && eval "\$sref = \\&${mname}::logMsg;"
                        && eval "\$aref = \\&${mname}::addLogger;"
                        && eval "\$dref = \\&${mname}::delLogger;"
                        ? 1
                        : 0;
                }

                # Cache & report the results
                $loaded{$module} = $rv;
                $msubs{$module} = [ $sref, $aref, $dref ];
                if ($rv) {
                    pdebug( 'successfully loaded log module for %s',
                        PDLEVEL3, $module );
                } else {
                    Paranoid::ERROR =
                        pdebug( 'failed to load log module for %s',
                        PDLEVEL1, $module );
                }

            } else {

                # Module name failed detainting -- report
                Paranoid::ERROR =
                    pdebug( 'failed to detaint module name', PDLEVEL1 );
                $rv = 0;
            }
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

        return $rv;
    }

    sub _updateDist {

        # Purpose:  Registers logging handles at the appropriate log levels
        # Returns:  Boolean
        # Usage:    $rv = _updateDist();

        my ( $logger, $level, $scope );

        # Purge @dist and reinitialize
        foreach ( PL_DEBUG .. PL_EMERG ) { $dist[$_] = [] }

        # Set up the distribution list
        foreach $logger ( keys %loggers ) {
            ( $level, $scope ) = @{ $loggers{$logger} }{qw(severity scope)};
            if ( $scope eq PL_EQ ) {
                push @{ $dist[$level] }, $logger;
            } elsif ( $scope eq PL_GE ) {
                foreach ( $level .. PL_EMERG ) {
                    push @{ $dist[$_] }, $logger;
                }
            } elsif ( $scope eq PL_LE ) {
                foreach ( PL_DEBUG .. $level ) {
                    push @{ $dist[$_] }, $logger;
                }
            } else {
                foreach ( PL_DEBUG .. PL_EMERG ) {
                    push @{ $dist[$_] }, $logger if $level != $_;
                }
            }
        }

        # Report distribution list
        foreach $level ( PL_DEBUG .. PL_EMERG ) {
            pdebug( '%s: %s', PDLEVEL3, $level, @{ $dist[$level] } );
        }

        return 1;
    }

    sub startLogger {

      # Purpose:  Adds a named logger to our loggers hash.
      # Returns:  True (1) if successful,
      #           False (0) if there are any errors
      # Usage:    $rv = startLogger($name, $mech, $level, $scope, { %mopts });

        my $name  = shift;
        my $mech  = shift;
        my $level = shift;
        my $scope = shift;
        my $mopts = shift;
        my $rv    = 1;

        pdebug( 'entering w/(%s)(%s)(%s)(%s)(%s)',
            PDLEVEL3, $name, $mech, $level, $scope, $mopts );
        pIn();

        # Set defaults for optional arguments that were left undefined
        $level = PL_NOTICE unless defined $level;
        $scope = PL_GE     unless defined $scope;

        # This is totally unnecessary, but we'll set PDebug to reflect
        # how it actually operations in case anyone is looking at the
        # distribution map
        $level = PL_DEBUG if $mech eq 'PDebug';

        # Make sure this is a valid named logger
        unless ( defined $name and length $name ) {
            Paranoid::ERROR =
                pdebug( 'invalid log name specified: %s', PDLEVEL1, $name );
            $rv = 0;
        }

        # Validate log level
        unless ( scalar grep { $_ == $level } @_levels ) {
            Paranoid::ERROR =
                pdebug( 'invalid log level specified: %s', PDLEVEL1, $level );
            $rv = 0;
        }

        # Validate scope
        unless ( scalar grep { $_ eq $scope } @_scopes ) {
            Paranoid::ERROR =
                pdebug( 'invalid log scope specified: %s', PDLEVEL1, $scope );
            $rv = 0;
        }

        # Make sure the module can be loaded if the log level was valid
        $rv = _loadModule($mech) if $rv;

        # Make sure the log entry is uniqe
        if ($rv) {
            if ( exists $loggers{$name} ) {
                Paranoid::ERROR = pdebug( 'a logger for %s already exists',
                    PDLEVEL1, $name );
                $rv = 0;
            } else {
                $mopts = {}
                    unless defined $mopts and ref $mopts eq 'HASH';
                $loggers{$name} = {
                    name      => $name,
                    mechanism => $mech,
                    severity  => $level,
                    scope     => $scope,
                    options   => {%$mopts} };
                $rv =
                      $mech eq 'Stderr' ? 1
                    : $mech eq 'Stdout' ? 1
                    : $mech eq 'PDebug' ? 1
                    :   &{ $msubs{$mech}[PL_AREF] }( %{ $loggers{$name} } );
                if ($rv) {
                    _updateDist();
                } else {
                    delete $loggers{$name};
                }
            }
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

        return $rv;
    }

    sub stopLogger {

        # Purpose:  Deletes a named logger from the hash.
        # Returns:  True (1)
        # Usage:    _delLogger($name);

        my $name = shift;
        my $rv   = 1;

        pdebug( 'deleting %s logger', PDLEVEL3, $name );
        if ( exists $loggers{$name} ) {
            unless ( $loggers{$name}{mechanism} eq 'Stderr'
                or $loggers{$name}{mechanism} eq 'Stdout'
                or $loggers{$name}{mechanism} eq 'PDebug' ) {
                $rv =
                    &{ $msubs{ $loggers{$name}{mechanism} }[PL_DREF] }(
                    %{ $loggers{$name} } );
            }
            if ($rv) {
                delete $loggers{$name};
                _updateDist();
            }
        }

        return $rv;
    }

    sub plog {

       # Purpose:  Logs the message to all facilities registered at that level
       # Returns:  True (1) if the message was succesfully logged,
       #           False (0) if there are any errors
       # Usage:    $rv = plog($severity, $message);
       # Usage:    $rv = plog($severity, $message, @pdebugvals);

        my $level   = shift;
        my $message = shift;
        my @margs   = @_;
        my $rv      = 1;
        my %record  = (
            severity => $level,
            message  => $message,
            );
        my ( $logger, $sref, $plevel );

        pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $level, $message );
        pIn();

        # Validate level and message
        $rv = 0
            unless defined $message
                and scalar grep { $_ == $level } @_levels;

        if ($rv) {

            # Trim leading/trailing whitespace and line terminators
            $message =~ s/^[\s\r\n]+//s;
            $message =~ s/[\s\r\n]+$//s;

            # First, if PDebug was enabled, we'll preprocess messages through
            # pdebug. *Every* message gets passed since pdebug has its own
            # mechanism to decide what to display
            if ( grep { $loggers{$_}{mechanism} eq 'PDebug' } keys %loggers )
            {

                # Paranoid::Debug uses an escalating scale of verbosity while
                # this module uses an escalating scale of severity.  We can
                # equate them in an inverse relationship, but we'll also need
                # to increment the output value since pdebug equates 0 as
                # disabled.
                #
                # Finally, we'll also make it a negative number to
                # signal pdebug to dive deeper into the call stack to find the
                # true originator of the message.  Otherwise, it would report
                # plog as the originator, which is less than helpful.
                $plevel = ( ( $level ^ 7 ) + 1 ) * -1;

                # Send it to pdebug, but save the output
                $message = pdebug( $message, $plevel, @margs );

                # Substitute the processed output if we had any substitution
                # values passed at all
                $record{message} = $message if scalar @margs;

            }

            # Iterate over the @dist level
            if ( defined $dist[$level] ) {

                # Iterate over each logger
                foreach $logger ( @{ $dist[$level] } ) {
                    next if $loggers{$logger}{mechanism} eq 'PDebug';

                    if ( $loggers{$logger}{mechanism} eq 'Stderr' ) {

                        # Special handling for STDERR
                        $rv = pderror($message);

                    } elsif ( $loggers{$logger}{mechanism} eq 'Stdout' ) {

                        # Special handling for STDOUT
                        $rv = print STDOUT "$message\n";

                    } else {

                        # Get the sub ref for the logger
                        $sref =
                            $msubs{ $loggers{$logger}{mechanism} }[PL_LREF];
                        $rv =
                            defined $sref
                            ? &$sref( %{ $loggers{$logger} }, %record )
                            : 0;
                    }
                }
            }

        } else {

            # Report error
            Paranoid::ERROR = pdebug( 'invalid log level(%s) or message(%s)',
                PDLEVEL1, $level, $message );
            $rv = 0;
        }

        pOut();
        pdebug( 'leaving w / rv : %s', PDLEVEL1, $rv );

        return $rv;
    }
}

sub plverbosity {

    # Purpose:  Sets Stdout/Stderr verbosity according to passed leve.
    #           Supports levels 1 - 3, with 4 being the most verbose
    # Returns:  Boolean
    # Usage:    $rv = plverbosity($level);

    my $level  = shift;
    my $max    = 3;
    my $outidx = PL_NOTICE;
    my $erridx = PL_CRIT;
    my $rv     = 1;

    pdebug( 'entering w/(%s)', PDLEVEL3, $level );
    pIn();

    # Make sure a positive integer was passed
    $rv = 0 unless $level > -1;

    # Cap $level
    $level = $max if $level > $max;

    # First, stop any current logging
    foreach ( 0 .. 7 ) {
        stopLogger( $_ < 3 ? "Stdout$_" : "Stderr$_" );
    }

    # Always enable PL_EMERG/PL_ALERT
    if ($level) {
        startLogger( "Stderr6", 'Stderr', PL_ALERT, PL_EQ );
        startLogger( "Stderr7", 'Stderr', PL_EMERG, PL_EQ );
    }

    # Enable what's been asked
    while ( $rv and $level ) {

        # Start the levels
        startLogger( "Stdout$outidx", 'Stdout', $outidx, PL_EQ );
        startLogger( "Stderr$erridx", 'Stderr', $erridx, PL_EQ );

        # Decrement the counters
        $outidx--;
        $erridx--;
        $level--;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::Log - Log Functions

=head1 VERSION

$Id: lib/Paranoid/Log.pm, 2.08 2020/12/31 12:10:06 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Log;

  $rv = startLogger($name, $mechanism, PL_WARN, PL_GE, { %options });
  $rv = stopLogger($name);

  $rv = plog($severity, $message);

=head1 DESCRIPTION

B<Paranoid::Log> provides a logging and message distribution framework that's
modeled heavily on I<syslog>.  It follows I<syslog> in that it allows one to
log messages at various levels of severity and have those messages distributed
across multiple log mechanisms automatically.  Within the L<Paranoid>
distribution itself it supports logging to files, STDERR, and named buffers.
Additional modules exist on CPAN to allow for distribution to e-mail, syslog,
and more.  It is also relatively trivial to write your own log mechanism to
work with this framework.

=head1 IMPORT LISTS

This module exports the following symbols by default:

    PL_DEBUG PL_INFO PL_NOTICE PL_WARN PL_ERR PL_CRIT
    PL_ALERT PL_EMERG PL_EQ PL_NE PL_GE PL_LE
    startLogger stopLogger plog plverbosity

The following specialized import lists also exist:

    List        Members
    --------------------------------------------------------
    all         @defaults

=head1 LOGGING MECHANISMS

Each logging mechanism is implemented as separate module consisting of
non-exported functions that conform to a a consistent API.  Each
mechanism module must have the following functions:

  Function        Description
  ------------------------------------------------------
  init            Called when module first loaded
  addLogger       Add a named instance of the mechanism
  delLogger       Removes a named instance of the mechanism
  logMsg          Logs the passed message

The B<init> function is only called once -- the first time the module is
used and accessed.  No arguments are passed, and if unnecessary for a
particular mechanism it can simply return a boolean true.

The B<logMsg> function is used to actually pass a log message to the 
mechanism.  It is called with a record hash based on the following template:

        my %record  = (
            name      => $name,
            mechanism => $name,
            msgtime   => time,
            severity  => $level,
            scope     => $scope,
            message   => $message,
            options   => {},
            );

The options key will be a hash reference to any logger-specific options,
should the mechanism require one.

The B<addLogger> function is called whenever a logger is started.  It is
called with the logger record above, minus a message and msgtime.

The B<delLogger> function is called whenevever a logger is stopped.  It is
called with the logger record above, minus a message and msgtime.

Please see the source for L<Paranoid::Logger::File> for a simple example of a
mechanism module.

=head1 SUBROUTINES/METHODS

=head2 startLogger

  $rv = startLogger($name, $mechanism, PL_WARN, PL_GE, { %options });

This function enables the specified logging mechanism at the specified levels.
Each mechanism (or permutation of) is associated with an arbitrary name.
This name can be used to bypass log distribution and log only in the named
mechanism.

If you have your own custom mechanism that complies with the Paranoid::Log
calling conventions you can pass this the name of the module (for example,
MyLog::Foo).

Log levels are modeled after syslog:

  log level       description
  =====================================================
  PL_EMERG        system is unusable
  PL_ALERT        action must be taken immediately
  PL_CRIT         critical conditions
  PL_ERR          error conditions
  PL_WARN         warning conditions
  PL_NOTICE       normal but significant conditions
  PL_INFO         informational
  PL_DEBUG        debug-level messages

If omitted level defaults to I<PL_NOTICE>.

Scope is defined with the following characters:

  character       definition
  =====================================================
  PL_EQ           log only messages at this severity
  PL_GE           log only messages at this severity
                    or higher
  PL_LE           log only messages at this severity
                    or lower
  PL_NE           log at all levels but this severity

If omitted scope defaults to I<PL_GE>.

Only the first two arguments are mandatory.  What you put into the %options, 
and whether you need it at all, will depend on the mechanism you're using.  The
facilities provided directly by B<Paranoid> are as follows:

  mechanism        arguments
  =====================================================
  Stdout           none
  Stderr           none
  Buffer           bufferSize (optional)
  File             file, mode (optional), perm (optional),
                   syslog (optional)
  PDebug           none

=head2 stopLogger

  $rv = stopLogger($name);

Removes the specified logging mechanism from the configuration and
re-initializes the distribution processor.

=head2 plog

  $rv = plog($severity, $message);

  # If the PDebug mechanism is enabled
  $rv = plog($severity, $message, @substitutions);

This call logs the passed message to all facilities enabled at the specified
log level.  If you have B<PDebug> enabled as a mechanism this function can
also provide an equivalent L<sprintf> functionality using the additional
arguments, and that processed output will be shared with all other mechanisms
that are enabled.

B<NOTE:> I<PDebug> support is meant to be a convenience to unify both normal
logging and the L<Paranoid::Debug::pdebug> B<STDERR> tracing mechanism.  That
said, note than enabling it means that B<all> log messages are passed to
L<pdebug>, since it has its own mechanism for deciding what gets sent to
B<STDERR> or not.

I<PDebug> support may not make sense for if your logging and debug output
can't be neatly lined up with the syslog-styled severities.

=head2 plverbosity

    $rv = plverbosity($level);
 
This function provides a simpler way to enable B<Stdout>/B<Stderr> logging to
the appropriate level, if you consider B<PL_DEBUG> to B<PL_NOTICE> to be
normal operation messages appropriate for B<STDOUT> messages, and B<PL_WARN>
through B<PL_EMERG> to be error messages appropriate for B<STDERR>.

This is primarily a convenience function for those simple, non-interactive
programs/functions that need support varying levels of verbosity for the
console.  From that perspective, it will be assumed that all user
notifications would be simple one-line messages.

B<NOTE:> I<PL_EMERG> and I<PL_ALERT> are always enabled if you use this
function.  Any error messages that should always be printed to the console
regardless of verbosity settings should be sent to one of those two levels.
The remaining levels (I<PL_WARN> through I<PL_CRIT>) will be optionally
enabled, just like I<PL_DEBUG>> through I<PL_NOTICE>.

=head1 DEPENDENCIES

=over

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Input>

=item o

L<Paranoid::Module>

=back

=head1 EXAMPLES

The following example provides the following behavior:  debug messages go to a
file, notice & above messages go to syslog, and critical and higher messages
also go to console and e-mail.

  # Set up the logging facilities
  startLogger("debug-log", "File", PL_DEBUG, PL_GE,
    { file => '/var/log/myapp-debug.log' });
  startLogger("console-err", "Stderr", PL_CRIT, PL_GE);

  # This goes only to the debug log
  plog(PL_DEBUG, "Starting application");

  # Again, only the debug log
  plog(PL_NOTICE, "Uh, something happened...");

  # This goes to STDERR and the debug log
  plog(PL_EMERG, "Ack! <choke... silence>");

=head1 SEE ALSO

=over

=item o

L<Paranoid::Log::Buffer>

=item o

L<Paranoid::Log::File>

=back

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is free software.  Similar to Perl, you can redistribute it
and/or modify it under the terms of either:

  a)     the GNU General Public License
         <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
         Free Software Foundation <http://www.fsf.org/>; either version 1
         <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
         <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
  b)     the Artistic License 2.0
         <https://opensource.org/licenses/Artistic-2.0>,

subject to the following additional term:  No trademark rights to
"Paranoid" have been or are conveyed under any of the above licenses.
However, "Paranoid" may be used fairly to describe this unmodified
software, in good faith, but not as a trademark.

(c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
(tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)

