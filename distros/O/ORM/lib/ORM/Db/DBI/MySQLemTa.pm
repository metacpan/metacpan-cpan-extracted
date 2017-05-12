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

# This module tries to emulate transactions for old MySQL databases

package ORM::Db::DBI::MySQLemTa;

$VERSION = 0.83;

use base 'ORM::Db::DBI';

##
## CONSTRUCTORS
##

sub new
{
    my $class = shift;
    my %arg   = @_;

    $arg{driver} = 'mysql';
    $class->SUPER::new( %arg );
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
    die "'begin_transaction' is not implemented yet for '$_[0]'";
}

sub commit_transaction
{
    die "'commit_transaction' is not implemented yet for '$_[0]'";
}

sub rollback_transaction
{
    die "'rollback_transaction' is not implemented yet for '$_[0]'";
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
