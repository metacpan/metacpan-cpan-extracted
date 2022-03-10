# Paranoid::BerkeleyDB::Db -- BerkeleyDB Db Wrapper
#
# (c) 2005 - 2022, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/BerkeleyDB/Db.pm, 2.06 2022/03/08 22:26:06 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Dbironment definitions
#
#####################################################################

package Paranoid::BerkeleyDB::Db;

use strict;
use warnings;
use vars qw($VERSION);
use Paranoid;
use Paranoid::Debug qw(:all);
use Paranoid::Input qw(detaint);
use Paranoid::IO;
use Paranoid::IO::Lockfile;
use Paranoid::Filesystem;
use Class::EHierarchy qw(:all);
use BerkeleyDB;
use Cwd qw(getcwd realpath);
use Carp;

($VERSION) = ( q$Revision: 2.06 $ =~ /(\d+(?:\.\d+)+)/sm );

use vars qw(@ISA @_properties @_methods);

@_properties = ( [ CEH_PRIV | CEH_SCALAR, 'filename' ], );

@ISA = qw(Class::EHierarchy);

#####################################################################
#
# module code follows
#
#####################################################################

{

    my %dbh;    # Object handles
    my %dbp;    # Parameters used for handles
    my %dbc;    # Reference count
    my %pid;    # Object handle create PID

    sub _openDb {

        # Purpose:  Opens a new database or returns a cached reference
        # Returns:  Reference to BerkeleyDB::Db object
        # Usage:    $env = _openDb(%params);

        my $obj    = shift;
        my %params = @_;
        my ( $db, $fn, $fnp, $env, $rv );

        subPreamble(PDLEVEL2, '%', %params);

        # Validate filename
        $rv = defined $params{'-Filename'};
        if ( $rv and $rv = detaint( $params{'-Filename'}, 'filename', $fn ) )
        {

            # Create the path
            ($fnp) = ( $fn =~ m#^(.*/)#s );
            if ( defined $fnp and length $fnp and pmkdir($fnp) ) {
                unless ( pmkdir($fnp) ) {
                    carp pdebug(
                        'failed to create/access the requisite directory',
                        PDLEVEL1 );
                    $rv = 0;
                }
            } else {
                $fnp = './';
            }

            # TODO: Get path from Env

            # Make canonical and save
            $params{'-Filename'} = $fn = realpath($fn);
            pdebug( 'canonical filename: %s', PDLEVEL3, $fn );

        } else {
            carp pdebug( 'invalid filename specified: %s',
                PDLEVEL1, $params{'-Filename'} );
            $rv = 0;
        }

        if ($rv) {
            if ( exists $dbh{$fn} ) {
                pdebug( 'database already exists', PDLEVEL3 );

                if ( $pid{$fn} == $$ ) {
                    pdebug( 'using cached reference', PDLEVEL3 );

                    # Increment reference count
                    $dbc{$fn}++;
                    $db = $dbh{$fn};

                } else {

                    # Expect bad things from here, particularly since
                    # BerkeleyDB will close the shared file handles for
                    # the parent process as well...
                    croak pdebug(
                        'cached ref created under different pid (%s)',
                        PDLEVEL1, $pid{$fn} );

                }

            } else {

                pdebug( 'opening a new database', PDLEVEL3 );

                # Add default flags if they're omitted
                $params{'-Mode'}  = 0666 & ~umask;
                $params{'-Flags'} = DB_CREATE
                    unless exists $params{'-Flags'};

                # Validate/set the Env
                unless (exists $params{'-Env'}
                    and defined $params{'-Env'}
                    and $params{'-Env'}->isa('Paranoid::BerkeleyDB::Env') ) {

                    # It doesn't appear we were called with a valid Env, so
                    # we'll delete any references to it and try to muscle
                    # ahead
                    delete $params{'-Env'};

                }

                pdebug( 'final parameters: %s', PDLEVEL4, %params );

                # Create the database
                if ( pexclock( "$fn.lock", $params{'-Mode'} ) ) {
                    $db = BerkeleyDB::Btree->new(
                        %params, (
                            exists $params{'-Env'}
                            ? ( '-Env' => $params{'-Env'}->env )
                            : () ) );
                    punlock("$fn.lock");
                }

                if ( defined $db ) {

                    # Remove the Env from %params to avoid circular references
                    delete $params{'-Env'};

                    # Store the metadata
                    $dbp{$fn} = {%params};
                    $dbh{$fn} = $db;
                    $pid{$fn} = $$;
                    $dbc{$fn} = 1;

                } else {
                    Paranoid::ERROR =
                        pdebug( 'failed to open database: %s %s',
                        PDLEVEL1, $!, $BerkeleyDB::Error );
                }
            }
        }

        $obj->set( 'filename', $fn ) if defined $db;

        subPostamble(PDLEVEL2, '$', $db);

        return $db;
    }

    sub _closeDb {

        # Purpose:  Closes db or decrements counter
        # Returns:  Boolean
        # Usage:    $rv = _closeDb($filename);

        my $fn = shift;

        subPreamble(PDLEVEL2, '$', $fn);

        if ( defined $fn and exists $dbh{$fn} ) {
            if ( $dbc{$fn} == 1 ) {
                pdebug( 'closing out database %s', PDLEVEL4, $dbh{$fn} );
                {
                    no warnings;
                    $dbh{$fn}->db_sync;
                    $dbh{$fn}->db_close;
                }
                delete $dbh{$fn};
                delete $dbp{$fn};
                delete $dbc{$fn};
                delete $pid{$fn};
            } else {
                pdebug( 'decrementing ref count for %s', PDLEVEL4,
                    $dbh{$fn} );
                $dbc{$fn}--;
            }
        }

        subPostamble(PDLEVEL2, '$', 1);

        return 1;
    }

    sub filename {

        # Purpose:  Returns canonical filename
        # Returns:  String
        # Usage:    $fn = $obj->filename;

        my $obj = shift;
        my $rv;

        subPreamble(PDLEVEL1);

        if ( !$obj->isStale ) {

            $rv = $obj->get('filename');

            croak pdebug( 'object opened under a different pid (%s)',
                PDLEVEL1, $pid{$rv} )
                if defined $rv and $pid{$rv} != $$;

        } else {
            carp pdebug( 'filename method called on stale object', PDLEVEL1 );
        }

        subPostamble(PDLEVEL1, '$', $rv);

        return $rv;
    }

    sub params {

        # Purpose:  Returns parameter hash
        # Returns:  Hash
        # Usage:    %params = $obj->params;

        my $obj = shift;
        my ( $fn, %rv );

        subPreamble(PDLEVEL1);

        if ( !$obj->isStale ) {
            $fn = $obj->filename;
            %rv = %{ $dbp{$fn} };

            croak pdebug( 'object opened under a different pid (%s)',
                PDLEVEL1, $pid{$fn} )
                if $pid{$fn} != $$;

        } else {
            carp pdebug( 'params method called on stale object', PDLEVEL1 );
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL1, %rv );
        subPostamble(PDLEVEL1, '%', %rv);

        return %rv;
    }

    sub refc {

        # Purpose:  Returns reference count for underlying database
        # Returns:  Integer
        # Usage:    $ount = $obj->refc;

        my $obj = shift;
        my ( $fn, $rv );

        subPreamble(PDLEVEL1);

        if ( !$obj->isStale ) {
            $fn = $obj->filename;
            $rv = $dbc{$fn};

            croak pdebug( 'object opened under a different pid (%s)',
                PDLEVEL1, $pid{$fn} )
                if $pid{$fn} != $$;

        } else {
            carp pdebug( 'refc method called on stale object', PDLEVEL1 );
        }

        subPostamble(PDLEVEL1, '$', $rv);

        return $rv;
    }

    sub dbh {

        # Purpose:  Returns a reference to db
        # Returns:  Ref
        # Usage:    $dbh = $obj->dbh;

        my $obj = shift;
        my ( $fn, $rv );

        subPreamble(PDLEVEL1);

        if ( !$obj->isStale ) {
            $fn = $obj->filename;
            $rv = $dbh{$fn};

            croak pdebug( 'object opened under a different pid (%s)',
                PDLEVEL1, $pid{$fn} )
                if $pid{$fn} != $$;

        } else {
            pdebug( 'dbh method called on stale object', PDLEVEL1 );
        }

        subPostamble(PDLEVEL1, '$', $rv);

        return $rv;
    }
}

sub _initialize {
    my $obj    = shift;
    my %params = @_;
    my ( $db, $env, $rv );

    subPreamble(PDLEVEL1);

    if ( exists $params{'-Filename'} ) {
        $db = _openDb( $obj, %params );

        if ( defined $db ) {

            # Adopt the database
            $env = $params{'-Env'};
            $env->adopt($obj)
                if defined $env
                    and $env->isa('Paranoid::BerkeleyDB::Env');
            delete $params{'-Env'};

            $rv = 1;
        }

    } else {
        Paranoid::ERROR =
            pdebug( 'caller didn\'t specify -Filename', PDLEVEL1 );
    }

    subPostamble(PDLEVEL1, '$', $rv);

    return $rv;
}

sub _deconstruct {
    my $obj = shift;
    my ( $env, $db, $rv );

    subPreamble(PDLEVEL1);

    # Close database
    $rv = _closeDb( $obj->filename ) if !$obj->isStale;

    subPostamble(PDLEVEL1, '$', $rv);

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::BerkeleyDB::Db -- BerkeleyDB Db Wrapper

=head1 VERSION

$Id: lib/Paranoid/BerkeleyDB/Db.pm, 2.06 2022/03/08 22:26:06 acorliss Exp $

=head1 SYNOPSIS

  $db = Paranoid::BerkeleyDB::Db->new(
    -Env       => $env,
    -Filename => './dbdir/data.db',
    );

  $fn     = $db->filename;
  %params = $db->params;
  $count  = $db->refc;
  $bdb    = $db->dbh;

=head1 DESCRIPTION

This module provides an OO-based wrapper for the L<BerkeleyDB::Btree(3)> 
class with the standard B<Paranoid(3)> API integration.  This module can be
sued with or without a CDS environment and supports all of the standard
parameters that B<BerkeleyDB::Btree(3)> does.

If you're using the L<Paranoid::BerkeleyDB(3)> API this object is 
created for you automatically.  There is probably no value in using this 
module directly unless you need to tune L<BerkeleyDB::Btree>'s defaults.

Note that you can't have the same db open at the same time with different
options.  Which ever options were used for the first call is what's in effect
since subsequent calls to open the database will simply return cached
references.

=head1 SUBROUTINES/METHODS

=head2 new

  $db = Paranoid::BerkeleyDB::Db->new(
    -Env       => $env,
    -Filename => './dbdir/data.db',
    );

The only required argument is B<-Filename>.  For a complete list of all 
available options please see the L<BerkeleyDB(3)> man page.

By default the following settings are applied unless overridden:

    Parameter   Value
    ---------------------------------------------------
    -Flags      DB_CREATE
    -Mode       0666 &~ umask

If you decided to pass a custom BerkeleyDB environment it needs to be done via
L<Paranoid::BerkeleyDB::Env> or it will be ignored.

=head2 filename

    $fn = $db->filename;

This method returns the canonical path to the specified db file.

=head2 params

    %params = $db->params;

This method returns the assembled parameters hash used to open the BerkeleyDB
object, minus the environment reference (if passed).

=head2 refc

    $count = $db->refc;

This method returns the current number of references to the underlying
database object.  That count is essentially the number of objects all using
the same database.

=head2 dbh

  $db = $db->dbh;

This returns a handle to the current L<BerkeleyDB::Btree(3)> object.

=head2 DESTROY

A DESTROY method is provided which should sync and close an open database, as
well as release any locks.

=head1 DEPENDENCIES

=over

=item o

L<BerkeleyDB>

=item o

L<Carp>

=item o

L<Cwd>

=item o

L<Class::EHierarchy>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Filesystem>

=item o

L<Paranoid::Input>

=item o

L<Paranoid::IO>

=item o

L<Paranoid::IO::Lockfile>

=back

=head1 BUGS AND LIMITATIONS

L<BerkeleyDB(3)> does not support forking, and neither does this module.  This
module will croak if any methods are called on objects created under a
different PID.  Because of the nature of BerkeleyDB's file handle usage this
will likely wreak some havoc in the parent process, so note that it is
imperative that you're checking child exit values.

=head1 SEE ALSO

    L<BerkeleyDB(3)>

=head1 HISTORY

02/12/2016  Complete rewrite
03/21/2017  Ported to new Class::EHierarchy API

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2022, Arthur Corliss (corliss@digitalmages.com)

