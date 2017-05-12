#
# DESCRIPTION
#   PerlORM - Object relational mapper (ORM) for Perl. PerlORM is Perl
#   library that implements object-relational mapping. Its features are
#   much similar to those of Java's Hibernate library, but interface is
#   much different and easier to use.
#
# AUTHOR
#   Alexey V. Akimov <akimov_alexey@sourceforge.net>
#
# COPYRIGHT
#   Copyright (C) 2005-2006 Alexey V. Akimov
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Lesser General Public
#   License as published by the Free Software Foundation; either
#   version 2.1 of the License, or (at your option) any later version.
#   
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Lesser General Public License for more details.
#   
#   You should have received a copy of the GNU Lesser General Public
#   License along with this library; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

package ORM::Db::DBI::MySQL;

$VERSION = 0.83;

use base 'ORM::Db::DBI';

##
## CONSTRUCTORS
##

sub new
{
    my $class = shift;
    my %arg   = @_;
    my $self;

    $arg{driver} = 'mysql';
    $self = $class->SUPER::new( %arg );

    $self->{allow_nontransactional_tables} = $arg{allow_nontransactional_tables};

    return $self;
}

##
## CLASS METHODS
##

sub qc
{
    my $self = shift;
    my $str  = shift;

    if( defined $str )
    {
        $str =~ s/\'/\'\'/g;
        $str =~ s/\\/\\\\/g;
        $str =~ s/\n/\\n/g;
        $str =~ s/\r/\\r/g;
        $str = "'$str'";
    }
    else
    {
        $str = 'NULL';
    }

    return $str;
}

sub qi
{
    my $self = shift;
    my $str  = shift;

    $str =~ s/\`/\`\`/g;
    $str = "`$str`"; #"

    return $str;
}

sub qt { $_[0]->qi( $_[1] ); }
sub qf { $_[0]->qi( $_[1] ); }

##
## OBJECT METHODS
##

sub begin_transaction
{
    my $self  = shift;
    my %arg   = @_;

    $self->{ta} = 1;
    $self->do( query=>"START TRANSACTION", error=>$arg{error} );
}

sub commit_transaction
{
    my $self  = shift;
    my %arg   = @_;

    delete $self->{ta};
    $self->do( query=>"COMMIT", error=>$arg{error} );
}

sub rollback_transaction
{
    my $self  = shift;
    my %arg   = @_;

    delete $self->{ta};
    unless( $self->{lost_connection} )
    {
        $self->do( query=>"ROLLBACK", error=>$arg{error} );
    }
}

sub update_object
{
    my $self = shift;

    $self->update_object_part( all_tables=>1, @_ );
}

## Can be optimized to check consistency
## right in DELETE statement using JOINS
##
sub delete_object
{
    my $self      = shift;
    my %arg       = @_;
    my $obj       = $arg{object};
    my $obj_class = ref $obj;
    my $error     = ORM::Error->new;
    my $ta        = $obj_class->new_transaction( error=>$error );
    my $join      = $obj_class->_db_tables_inner_join;
    my $rows_affected;

    $self->check_object_referers
    (
        object => $obj,
        error  => $error,
        check  => $arg{emulate_foreign_keys},
    );

    unless( $error->fatal )
    {
        $rows_affected = $self->do
        (
            error => $error,
            query =>
            (
                "DELETE " . $obj_class->_db_tables_str
                . " FROM " . $obj_class->_db_tables_str
                . " WHERE "
                    . $self->qt( $obj_class->_db_table(0) ).'.id = '.$self->qc( $obj->id )
                    . ( $join ? " AND $join" : '' ),
            ),
        );

        if( $rows_affected != $obj_class->_db_tables_count )
        {
            $error->add_fatal
            (
                "Failed to delete ID#".$obj->id." from '"
                . $obj_class->_db_tables_str
                . "', $rows_affected rows affected"
            );
        }

        unless( $error->fatal )
        {
            $self->check_object_referers
            (
                object => $obj,
                error  => $error,
                check  => $arg{emulate_foreign_keys},
            );
        }
    }

    $error->upto( $arg{error} );
}

## use: $id = $db->insertid()
##
sub insertid
{
    my $self = shift;
    $self->_db_handler ? $self->_db_handler->{mysql_insertid} : undef;
}

sub table_struct
{
    my $self   = shift;
    my %arg    = @_;
    my $error  = ORM::Error->new;
    my %field;
    my %defaults;
    my $res;
    my $data;

    ## Fetch table structure
    $res = $self->select( error=>$error, query=>( 'SHOW COLUMNS FROM '.$self->qt($arg{table}) ) );
    unless( $error->fatal )
    {
        while( $data = $res->next_row )
        {
            $defaults{$data->{Field}} = $data->{Default};
            $field{$data->{Field}}    = $arg{class}->_db_type_to_class( $data->{Field}, $data->{Type} );
        }
    }

    ## Check whether table's engine supports transactions
    unless( $error->fatal )
    {
        $res  = $self->select( error=>$error, query=>( 'SHOW TABLE STATUS LIKE '.$self->ql( $arg{table} ) ) );
        $data = $res && $res->next_row;

        my $engine = $data->{Engine} || $data->{Type};

        if( !$data )
        {
            $error->add_fatal( 'Can\'t detect engine for "'.$arg{table}.'"' );
        }
        elsif( !$self->{allow_nontransactional_tables} && $engine ne 'InnoDB' && $engine ne 'BDB' )
        {
            $error->add_fatal
            (
                "Engine for table '$arg{table}' is '$engine', should be 'InnoDB' or 'BDB'."
            );
        }
    }

    ## Fetch class references
    if( scalar( %field ) )
    {
        $res = $self->select
        (
            error => $error,
            query => 'SELECT * FROM '.$self->qt('_ORM_refs').' WHERE class='.$self->qc( $arg{class} ),
        );
        unless( $error->fatal )
        {
            while( $data = $res->next_row )
            {
                if( exists $field{$data->{prop}} )
                {
                    $field{$data->{prop}} = $data->{ref_class};
                }
            }
        }
    }

    $error->upto( $arg{error} );
    return \%field, \%defaults;
}

sub _lost_connection
{
    my $self = shift;
    my $err  = shift;

    defined $err && ( $err == 2006 || $err == 2013 );
}


## use: $encrypted_password = $db->pwd( $password )
##
sub pwd
{
    my $self = shift;
    my $pwd  = shift;
    my $st;

    $st = $self->_db_handler && $self->_db_handler->prepare( 'select password('.($self->qc($pwd)).')' );
    if( $st )
    {
        $st->execute;
        return ($st->fetchrow_arrayref)->[0];
    }
    else
    {
        return undef;
    }
}

##
## SQL FUNCTIONS
##

sub _func_concat        { shift; ORM::Filter::Func->new( 'CONCAT', @_ ); }
