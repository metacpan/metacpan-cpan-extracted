# Paranoid::BerkeleyDB -- BerkeleyDB Wrapper
#
# (c) 2005 - 2022, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/BerkeleyDB.pm, 2.06 2022/03/08 22:26:06 acorliss Exp $
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

package Paranoid::BerkeleyDB;

use strict;
use warnings;
use vars qw($VERSION);
use Fcntl qw(:DEFAULT :flock :mode :seek);
use Paranoid;
use Paranoid::Debug qw(:all);
use Paranoid::IO;
use Paranoid::IO::Lockfile;
use Class::EHierarchy qw(:all);
use BerkeleyDB;
use Paranoid::BerkeleyDB::Env;
use Paranoid::BerkeleyDB::Db;
use Carp;
use Cwd;

($VERSION) = ( q$Revision: 2.06 $ =~ /(\d+(?:\.\d+)+)/sm );

use vars qw(@ISA @_properties);

@ISA = qw(Class::EHierarchy);

@_properties = ( [ CEH_RESTR | CEH_REF, 'cursor' ], );

our $db46 = 0;

#####################################################################
#
# module code follows
#
#####################################################################

sub _initialize {

    # Purpose:  Create the database object and env object (if needed)
    # Returns:  Boolean
    # Usage:    $rv = $obj->_initialize(%params);

    my $obj    = shift;
    my %params = @_;
    my $rv     = 0;
    my ( $db, $env, $fpath );

    subPreamble( PDLEVEL1, '%', %params );

    # Set db46 flag
    $db46 = 1
        if DB_VERSION_MAJOR > 4
            or ( DB_VERSION_MAJOR == 4 and DB_VERSION_MINOR >= 6 );

    # Get the filename's path, in case Home is not set
    ($fpath) = (
          exists $params{Filename} ? ( $params{Filename} =~ m#^(.*)/#s )
        : exists $params{Db} ? ( $params{Db}{'-Filename'} =~ m#^(.*)/#s )
        : getcwd() );

    # Set up the environment
    if (    exists $params{Env}
        and defined $params{Env}
        and ref $params{Env} eq 'HASH' ) {
        $params{Env}{'-Home'} = $fpath
            if !exists $params{Env}{Home}
                and defined $fpath
                and length $fpath;
        $env = new Paranoid::BerkeleyDB::Env %{ $params{Env} };
    } elsif ( exists $params{Env}
        and defined $params{Env}
        and $params{Env}->isa('Paranoid::BerkeleyDB::Env') ) {
        $env = $params{Env};
    } else {
        $params{Home} = $fpath unless exists $params{Home};
        $env = new Paranoid::BerkeleyDB::Env '-Home' => $params{Home};
    }

    Paranoid::ERROR =
        pdebug( 'failed to acquire a bdb environment', PDLEVEL1 )
        unless defined $env;

    # Set up the database
    if ( defined $env ) {
        if ( exists $params{Filename} ) {
            $db = new Paranoid::BerkeleyDB::Db
                '-Filename' => $params{Filename},
                '-Env'      => $env;
        } elsif ( exists $params{Db}
            and defined $params{Db}
            and ref $params{Db} eq 'HASH' ) {
            $params{Db}{'-Env'} = $env;
            $db = new Paranoid::BerkeleyDB::Db %{ $params{Db} };
        }

        if ( defined $db ) {
            $obj->adopt($env);
            $env->alias('env');
            $db->alias('db');
            $rv = 1;
        } else {
            Paranoid::ERROR =
                pdebug( 'failed to open the database', PDLEVEL1 );
        }
    }

    subPostamble( PDLEVEL1, '$', $rv );

    return $rv;
}

sub _deconstruct {

    # Purpose:  Object cleanup
    # Returns:  Boolean
    # Usage:    $rv = $obj->deconstruct;

    my $obj = shift;

    subPreamble(PDLEVEL1);

    $obj->set( 'cursor', undef ) if !$obj->isStale;

    subPostamble( PDLEVEL1, '$', 1 );

    return 1;
}

sub dbh {

    # Purpose:  Performs PID check before returning dbh
    # Returns:  Db ref
    # Usage:    $dbh = $obj->dbh;

    my $obj = shift;
    my ( $rv, @children );

    subPreamble(PDLEVEL3);

    if ( !$obj->isStale ) {
        $rv = $obj->getByAlias('db')->dbh;
    } else {
        pdebug( 'dbh method called on stale object', PDLEVEL1 );
    }

    subPostamble( PDLEVEL1, '$', $rv );

    return $rv;
}

sub cds_lock {

    # Purpose:  Simple wrapper to get a CDS lock
    # Returns:  CDS Lock
    # Usage:    $lock = $dbh->cds_lock;

    my $obj = shift;
    my $dbh;

    $dbh = $obj->dbh if !$obj->isStale;

    return defined $dbh ? $dbh->cds_lock : undef;
}

sub TIEHASH {
    my @args = @_;

    shift @args;

    return new Paranoid::BerkeleyDB @args;
}

sub FETCH {
    my $obj = shift;
    my $key = shift;
    my ( $dbh, $val, $rv );

    subPreamble( PDLEVEL3, '$', $key );

    if ( !$obj->isStale ) {
        $dbh = $obj->dbh;
        if ( !$dbh->db_get( $key, $val ) ) {
            $rv = $val;
        }
    } else {
        $@ = pdebug( 'FETCH called on a stale object', PDLEVEL1 );
        carp $@;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub STORE {
    my $obj = shift;
    my $key = shift;
    my $val = shift;
    my $rv;

    subPreamble( PDLEVEL3, '$$', $key, $val );

    if ( !$obj->isStale ) {
        $rv = !$obj->dbh->db_put( $key, $val );
    } else {
        $@ = pdebug( 'STORE called on a stale object', PDLEVEL1 );
        carp $@;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub EXISTS {
    my $obj = shift;
    my $key = shift;
    my ( $dbh, $val, $rv );

    subPreamble( PDLEVEL3, '$', $key );

    if ( !$obj->isStale ) {
        $dbh = $obj->dbh;
        $rv =
              $db46
            ? $dbh->db_exists($key) != DB_NOTFOUND
            : $dbh->db_get( $key, $val ) == 0;
    } else {
        $@ = pdebug( 'EXISTS called on a stale object', PDLEVEL1 );
        carp $@;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub DELETE {
    my $obj = shift;
    my $key = shift;
    my $rv;

    subPreamble( PDLEVEL3, '$', $key );

    if ( !$obj->isStale ) {
        $rv = !$obj->dbh->db_del($key);
    } else {
        $@ = pdebug( 'DELETE called on a stale object', PDLEVEL1 );
        carp $@;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub CLEAR {
    my $obj = shift;
    my $rv  = 0;
    my ( $dbh, $lock );

    subPreamble(PDLEVEL3);

    if ( !$obj->isStale ) {
        $dbh = $obj->dbh;
        $lock = $dbh->cds_lock if $dbh->cds_enabled;
        $dbh->truncate($rv);
        $lock->cds_unlock if defined $lock;
    } else {
        $@ = pdebug( 'CLEAR called on a stale object', PDLEVEL1 );
        carp $@;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub FIRSTKEY {
    my $obj = shift;
    my ( $key, $val ) = ( '', '' );
    my ( $cursor, %o );

    subPreamble(PDLEVEL3);

    if ( !$obj->isStale ) {
        $cursor = $obj->dbh->db_cursor;

        if ( defined $cursor and $cursor->c_get( $key, $val, DB_NEXT ) == 0 )
        {
            %o = ( $key => $val );
            $obj->set( 'cursor', $cursor );
        }
    } else {
        $@ = pdebug( 'FIRSTKEY called on a stale object', PDLEVEL1 );
        carp $@;
    }

    subPostamble( PDLEVEL3, '$$', %o );

    return each %o;
}

sub NEXTKEY {
    my $obj    = shift;
    my $cursor = $obj->get('cursor');
    my ( $key, $val ) = ( '', '' );
    my (%o);

    subPreamble(PDLEVEL3);

    if ( !$obj->isStale ) {
        if ( defined $cursor ) {
            if ( $cursor->c_get( $key, $val, DB_NEXT ) == 0 ) {
                %o = ( $key => $val );
            } else {
                $obj->set( 'cursor', undef );
            }
        }
    } else {
        $@ = pdebug( 'NEXTKEY called on a stale object', PDLEVEL1 );
        carp $@;
    }

    subPostamble( PDLEVEL3, '$$', %o );

    return each %o;
}

sub SCALAR {
    my $obj = shift;
    my ( $key, $rv );

    subPreamble(PDLEVEL3);

    if ( !$obj->isStale ) {
        if ( defined( $key = $obj->FIRSTKEY ) ) {
            $rv = 1;
            $obj->set( 'cursor', undef );
        } else {
            $rv = 0;
        }
    } else {
        $@ = pdebug( 'SCALAR called on a stale object', PDLEVEL1 );
        carp $@;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub UNTIE {
    my $obj = shift;
    my $rv  = 1;

    subPreamble(PDLEVEL3);

    if ( !$obj->isStale ) {
        $obj->set( 'cursor', undef );
    } else {
        $@ = pdebug( 'UNTIE called on a stale object', PDLEVEL1 );
        carp $@;
    }

    subPostamble( PDLEVEL1, '$', $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::BerkeleyDB -- BerkeleyDB Wrapper

=head1 VERSION

$Id: lib/Paranoid/BerkeleyDB.pm, 2.06 2022/03/08 22:26:06 acorliss Exp $

=head1 SYNOPSIS

  tie %db, 'Paranoid::BerkeleyDB', Filename => './dbdir/data.db';

  # Normal hash activities...

  # Ensure atomic updates
  $dref = tied %db;
  $lock = $dref->cds_lock;
  $db{$key}++;
  $lock->cds_unlock;

  untie %db;

=head1 DESCRIPTION

This module provides an OO/tie-based wrapper for BerkeleyDB CDS
implementations intended for use in tied hashes.

B<NOTE:> This module breaks significantly with previous incarnations of this
module.  The primary differences are as follows:

    Pros
    -------------------------------------------------------------
    * Places no limitations on the developer regarding BerekelyDB
      environment and database options
    * Automatically reuses existing environments for multiple 
      tied hashses
    * Uses Btree databases in lieu of hashes, which tended to 
      have issues when the database size grew too large
    * Has a fully implemented tied hash interface incorporating 
      CDS locks
    * Has pervasive debugging built in using L<Paranoid::Debug>

    Cons
    -------------------------------------------------------------
    * Is no longer considered fork-safe, attempted accesses will
      case the child process to B<croak>.
    * Uses Btree databases in lieu of hashes, which does add 
      some additional memory overhead

=head1 SUBROUTINES/METHODS

=head2 new

  tie %db, 'Paranoid::BerkeleyDB', 
    Filename => './dbdir/data.db';
  tie %db, 'Paranoid::BerkeleyDB', 
    Home     => './dbenv';
    Filename => './dbdir/data.db';

This method is called implicitly when an object is tied.  It supports a few
differnet invocation styles.  The simplest involves simply providing the
B<Home> and B<Filename> options.  This will set up a CDS environment using the
defaults documented in L<Paranoid::BerkeleyDB::Env(3)> and
L<Paranoid::BerkeleyDB::Db(3)>.

Alternately, you can provide it with B<Filename> and a
L<Paranoid::BerkeleyDB::Env(3)> object (or subclassed object) that you
instantiated yourself:

  tie %db, 'Paranoid::BerkeleyDB', 
    Env      => $env,
    Filename => 'data.db';

Finally, you can provide it with two hash options to fully control the
environment and database instantiation of L<Paranoid::BerkeleyDB::Env(3)> and
L<Paranoid::BerkeleyDB::Db(3)>:

  tie %db, 'Paranoid::BerkeleyDB', 
    Env      => { %envOpts },
    Db       => { %dbOpts };

=head2 dbh

    $dref = tied %db;
    $dbh  = $dref->dbh;

This method provides access to the L<BerkeleyDB::Btree(3)> object reference.

=head2 cds_lock

    $dref = tied %db;
    $lock = $dref->cds_lock;

This method provides access to the CDS locks for atomic updates.

=head1 DEPENDENCIES

=over

=item o

L<BerkeleyDB>

=item o

L<Carp>

=item o

L<Class::EHierarchy>

=item o

L<Fcntl>

=item o

L<Paranoid>

=item o

L<Paranoid::BerkeleyDB::Db>

=item o

L<Paranoid::BerkeleyDB::Env>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::IO>

=item o

L<Paranoid::IO::Lockfile>

=back

=head1 BUGS AND LIMITATIONS

B<-Filename> is interpreted differently depending on whether you're using an
environment or not.  If you're using this module as a standalone DB object any
relative paths are interpreted according to your current working directory.
If you are using an environment, however, it is interpreted relative to that
environment's B<-Home>.

=head1 SEE ALSO

    L<BerkeleyDB(3)>, L<Paranoid::BerkeleyDB::Env>,
    L<Paranoid::BerkeleyDB::Db>

=head1 HISTORY

02/12/2016  Complete rewrite

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2022, Arthur Corliss (corliss@digitalmages.com)

