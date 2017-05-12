# Paranoid::BerkeleyDB::Env -- BerkeleyDB CDS Env
#
# (c) 2005 - 2015, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/BerkeleyDB/Env.pm, 2.03 2017/02/06 02:49:24 acorliss Exp $
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

package Paranoid::BerkeleyDB::Env;

use strict;
use warnings;
use vars qw($VERSION);
use Fcntl qw(:DEFAULT :flock :mode :seek);
use Paranoid;
use Paranoid::Debug qw(:all);
use Paranoid::Input qw(detaint);
use Paranoid::Filesystem;
use Paranoid::IO;
use Paranoid::IO::Lockfile;
use Class::EHierarchy qw(:all);
use BerkeleyDB;
use Cwd qw(realpath);
use Carp;

($VERSION) = ( q$Revision: 2.03 $ =~ /(\d+(?:\.\d+)+)/sm );

use vars qw(@ISA @_properties);

@_properties = ( [ CEH_PRIV | CEH_SCALAR, 'home' ] );

@ISA = qw(Class::EHierarchy);

#####################################################################
#
# module code follows
#
#####################################################################

{

    my %dbe;    # Object handles
    my %dbp;    # Parameters used for handles
    my %dbc;    # Reference count
    my %pid;    # Object handle create PID

    sub _openDbe {

        # Purpose:  Opens a new environment or returns a cached reference
        # Returns:  Reference to BerkeleyDB::Env object
        # Usage:    $env = _openDbe(%params);

        my $obj    = shift;
        my %params = @_;
        my ( $env, $home, $rv, $fh );

        pdebug( 'entering w/%s', PDLEVEL2, %params );
        pIn();

        # Validate home
        $rv = defined $params{'-Home'};
        if ( $rv and $rv = detaint( $params{'-Home'}, 'filename', $home ) ) {

            # Create the path
            if ( pmkdir($home) ) {

                # Make canonical and save
                $params{'-Home'} = $home = realpath($home);
                pdebug( 'canonical home path: %s', PDLEVEL3, $home );

            } else {
                carp pdebug(
                    'failed to create/access the requisite directory',
                    PDLEVEL1 );
                $rv = 0;
            }

        } else {
            carp pdebug( 'invalid home specified: %s',
                PDLEVEL1, $params{'-Home'} );
            $rv = 0;
        }

        if ($rv) {
            if ( exists $dbe{$home} ) {
                pdebug( 'environment already exists', PDLEVEL3 );

                if ( $pid{$home} == $$ ) {
                    pdebug( 'using cached reference', PDLEVEL3 );

                    # Increment reference count
                    $dbc{$home}++;
                    $env = $dbe{$home};

                } else {

                    # Expect bad things from here, particularly since
                    # BerkeleyDB will close the shared file handles for
                    # the parent process as well...
                    croak pdebug(
                        'cached ref created under different pid (%s)',
                        PDLEVEL1, $pid{$home} );
                }

            } else {

                pdebug( 'opening a new environment', PDLEVEL3 );

                # Create an error log
                $params{'-ErrFile'} = "$home/db_err.log"
                    unless exists $params{'-ErrFile'};
                $fh =
                    popen( $params{'-ErrFile'},
                    O_WRONLY | O_CREAT | O_APPEND );
                $params{'-ErrFile'} = $fh if defined $fh;

                # Add default flags if they're omitted
                $params{'-Mode'}  = 0666 & ~umask;
                $params{'-Flags'} = DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL
                    unless exists $params{'-Flags'};
                $params{'-Verbose'} = 1;
                pdebug( 'final parameters: %s', PDLEVEL4, %params );

                # Create the environment
                if ( pexclock( "$home/env.lock", $params{'-Mode'} ) ) {
                    $env = BerkeleyDB::Env->new(%params);
                    punlock("$home/env.lock");
                }

                if ( defined $env ) {
                    $dbe{$home} = $env;
                    $dbp{$home} = {%params};
                    $pid{$home} = $$;
                    $dbc{$home} = 1;
                } else {
                    Paranoid::ERROR =
                        pdebug( 'failed to open environment: %s',
                        PDLEVEL1, $BerkeleyDB::Error );
                }
            }
        }

        $obj->set( 'home', $home ) if defined $env;

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL2, $env );

        return $env;
    }

    sub _closeDbe {

        # Purpose:  Closes env or decrements counter
        # Returns:  Boolean
        # Usage:    $rv = _closeDbe($home);

        my $home = shift;

        pdebug( 'entering w/%s', PDLEVEL2, $home );
        pIn();

        if ( defined $home and exists $dbe{$home} ) {
            if ( $dbc{$home} == 1 ) {
                pdebug( 'closing out environment', PDLEVEL4 );
                delete $dbe{$home};
                delete $dbp{$home};
                delete $dbc{$home};
                delete $pid{$home};
            } else {
                pdebug( 'decrementing ref count', PDLEVEL4 );
                $dbc{$home}--;
            }
        }

        pOut();
        pdebug( 'leaving w/rv: 1', PDLEVEL2 );

        return 1;
    }

    sub home {

        # Purpose:  Returns canonical home path
        # Returns:  String
        # Usage:    $home = $obj->home;

        my $obj = shift;
        my $rv;

        pdebug( 'entering', PDLEVEL1 );
        pIn();

        if ( !$obj->isStale ) {

            $rv = $obj->get('home');

            croak pdebug( 'object opened under a different pid (%s)',
                PDLEVEL1, $pid{$rv} )
                if defined $rv and $pid{$rv} != $$;

        } else {
            carp pdebug( 'home method called on stale object', PDLEVEL1 );
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

        return $rv;
    }

    sub params {

        # Purpose:  Returns parameter hash
        # Returns:  Hash
        # Usage:    %params = $obj->params;

        my $obj = shift;
        my ( $home, %rv );

        pdebug( 'entering', PDLEVEL1 );
        pIn();

        if ( !$obj->isStale ) {
            $home = $obj->home;
            %rv   = %{ $dbp{$home} };

            croak pdebug( 'object opened under a different pid (%s)',
                PDLEVEL1, $pid{$home} )
                if $pid{$home} != $$;

        } else {
            carp pdebug( 'params method called on stale object', PDLEVEL1 );
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL1, %rv );

        return %rv;
    }

    sub refc {

        # Purpose:  Returns reference count for underlying environment
        # Returns:  Integer
        # Usage:    $count = $obj->refc;

        my $obj = shift;
        my ( $home, $rv );

        pdebug( 'entering', PDLEVEL1 );
        pIn();

        if ( !$obj->isStale ) {
            $home = $obj->home;
            $rv   = $dbc{$home};

            croak pdebug( 'object opened under a different pid (%s)',
                PDLEVEL1, $pid{$home} )
                if $pid{$home} != $$;

        } else {
            carp pdebug( 'refc method called on stale object', PDLEVEL1 );
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

        return $rv;
    }

    sub env {

        # Purpose:  Returns a reference to the env
        # Returns:  Ref
        # Usage:    $env = $obj->env;

        my $obj = shift;
        my ( $home, $rv );

        pdebug( 'entering', PDLEVEL1 );
        pIn();

        if ( !$obj->isStale ) {
            $home = $obj->home;
            $rv   = $dbe{$home};

            croak pdebug( 'object opened under a different pid (%s)',
                PDLEVEL1, $pid{$home} )
                if $pid{$home} != $$;
        } else {
            pdebug( 'env method called on a stale object', PDLEVEL1 );
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

        return $rv;
    }
}

sub _initialize {
    my $obj    = shift;
    my %params = @_;
    my $rv;

    # Make sure minimal parameters are preset
    pdebug( 'entering', PDLEVEL1 );
    pIn();

    if ( exists $params{'-Home'} ) {
        $rv = 1 if defined _openDbe( $obj, %params );
    } else {
        Paranoid::ERROR = pdebug( 'caller didn\'t specify -Home', PDLEVEL1 );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub _deconstruct {
    my $obj = shift;
    my $rv;

    pdebug( 'entering', PDLEVEL1 );
    pIn();

    # Close the environment
    $rv = _closeDbe( $obj->home ) if !$obj->isStale;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::BerkeleyDB::Env -- BerkeleyDB CDS Env Object

=head1 VERSION

$Id: lib/Paranoid/BerkeleyDB/Env.pm, 2.03 2017/02/06 02:49:24 acorliss Exp $

=head1 SYNOPSIS

  $db = Paranoid::BerkeleyDB::Env->new(-Home => './dbdir');

  $home   = $dbe->home;
  %params = $dbe->params;
  $count  = $dbe->refc;
  $env    = $dbe->env;
  @dbs    = $dbe->dbs;

=head1 DESCRIPTION

This module provides an OO-based wrapper for the L<BerkeleyDB::Env(3)> 
class with the standard B<Paranoid(3)> API integration.  This class 
supports all of the standard parameters that B<BerkeleyDB::Env(3)> does.

If you're using the L<Paranoid::BerkeleyDB(3)> API this object is 
created for you automatically.  There is probably no value in using this 
module directly unless you need to tune L<BerkeleyDB::Btree>'s defaults.

While this class places no restrictions on the use of any available
L<BerkeleyDB::Env(3)> options it does automatically deploy some defaults 
options oriented towards CDS access.  These can be overridden, but if you're 
focused on CDS this will simplify their use.

=head1 SUBROUTINES/METHODS

=head2 new

  $db = Paranoid::BerkeleyDB::Env->new(-Home => './dbdir');

The only required argument is B<-Home>.  For a complete list of all available
options please see the L<BerkeleyDB(3)> man page.

By default the following settings are applied unless overridden:

    Parameter   Value
    ---------------------------------------------------
    -Flags      DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL
    -ErrFile    {-Home}/db_err.log
    -Verbose    1

=head2 home

    $home = $dbe->home;

This method returns the canonical path to the environment's home directory.

=head2 params

    %params = $dbe->params;

This method returns the assembled parameters hash used to open the
BerkeleyDB::Env object.

=head2 refc

    $count = $dbe->refc;

This method returns the current number of references to the underlying
environment object.  That count is essentially the number of objects all using
the same environment.

=head2 env

  $env = $dbe->env;

This returns a handle to the current L<BerkeleyDB::Env(3)> object.

=head2 DESTROY

A DESTROY method is provided which should sync and close an open database, as
well as release any locks.

=head1 DEPENDENCIES

=over

=item o

L<BerkeleyDB>

=item o

L<Class::EHierarchy>

=item o

L<Fcntl>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Input>

=item o

L<Paranoid::IO>

=item o

L<Paranoid::IO::Lockfile>

=back

=head1 BUGS AND LIMITATIONS

Race conditions, particularly on environment creation/opens, are worked 
around by the use of external lock files and B<flock> advisory file locks.  
Lockfiles are not used during normal operations on the environment.

While CDS allows for safe concurrent use of database files, it makes no
allowances for recovery from stale locks.  If a process exits badly and fails
to release a write lock (which causes all other process operations to block
indefinitely) you have to intervene manually.  The brute force intervention
would mean killing all accessing processes and deleting the environment files
(files in the same directory call __db.*).  Those will be recreated by the
next process to access them.

Berkeley DB provides a handy CLI utility called L<db_stat(1)>.  It can provide
some statistics on your shared database environment via invocation like so:

  db_stat -m -h .

The last argument, of course, is the directory in which the environment was
created.  The example above would work fine if your working directory was that
directory.

You can also show all existing locks via:

    db_stat -N -Co -h .

=head1 SEE ALSO

    L<BerkeleyDB(3)>

=head1 HISTORY

02/12/2016  Complete rewrite

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2016, Arthur Corliss (corliss@digitalmages.com)

