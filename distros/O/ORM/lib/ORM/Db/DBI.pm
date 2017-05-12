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

package ORM::Db::DBI;

$VERSION = 0.83;

use DBI;
use base 'ORM::Db';
use ORM::Db::DBIResultSet;
use ORM::Db::DBIResultSetFull;

## use: $db = $class->new
## (
##     host     => string,
##     database => string,
##     options  => string,
##     user     => string,
##     password => string,
##
##     delayed_connect => boolean,
##     connect_retries => integer,
##     retry_sleep     => integer,
## )
##
## 'retry_sleep' in seconds.
##
sub new
{
    my $class = shift;
    my $self  = {};
    my %arg   = @_;
    my $data_source;

    $self->{connect_retries} = defined $arg{connect_retries} ? int( $arg{connect_retries} ) : 3;
    $self->{retry_sleep}     = defined $arg{retry_sleep}     ? int( $arg{retry_sleep} )     : 1;
    $self->{delayed_connect} = $arg{delayed_connect};
    $self->{database}        = $arg{database};

    if( $arg{data_source} )
    {
        $data_source = $arg{data_source};
    }
    else
    {
        $data_source =
            "DBI:$arg{driver}:$arg{database}"
            . ($arg{host}    ? ":$arg{host}" : '')
            . ($arg{options} ? ";$arg{options}" : '');
    }

    $self->{db_arg} = [ $data_source, $arg{user}, $arg{password} ];
    $self->{db}     = DBI->connect( @{$self->{db_arg}} ) unless( $arg{delayed_connect} );

    return bless $self, $class;
}

sub disconnect
{
    my $self = shift;
    
    $self->{db}              = undef;
    $self->{delayed_connect} = 1;
}

sub database { $_[0]->{database}; }

sub count
{
    my $self = shift;
    my %arg  = @_;
    my $tjoin;
    my $cond;

    $tjoin = ORM::Tjoin->new( class=>$arg{class}, all_tables=>1 );
    $tjoin->merge( $arg{filter}->_tjoin ) if( $arg{filter} );
    $tjoin->assign_aliases;

    if( $arg{filter} )
    {
        $cond = $arg{filter}->_sql_str( tjoin=>$tjoin );
    }

    my $res = $self->select
    (
        error => $arg{error},
        query =>
        (
            "SELECT count(DISTINCT "
            . $self->qt( $tjoin->first_basic_table_alias ) . ".id) AS "
            . $self->qi( 'count' ) . "\n"
            . 'FROM ' . $tjoin->sql_table_list . "\n"
            . ( $cond && "WHERE $cond\n" )
        ),
    );

    return $res ? $res->next_row->{count} : 0;
}

sub select_base
{
    my $self = shift;
    my %arg  = @_;

    # Prepare $tjoin object
    my $tjoin = ORM::Tjoin->new( class=>$arg{class}, all_tables=>1 );

    if( $arg{data} )
    {
        for my $name ( keys %{$arg{data}} )
        {
            $tjoin->merge( $arg{data}{$name}->_tjoin ) if( defined $arg{data}{$name} );
        }
        for my $group_by ( @{$arg{group_by}} )
        {
            if( ref $group_by && UNIVERSAL::isa( $group_by, 'ORM::Metaprop' ) )
            {
                $tjoin->merge( $group_by->_tjoin );
            }
        }
    }

    $tjoin->merge( $arg{order}->_tjoin )       if( $arg{order} );
    $tjoin->merge( $arg{filter}->_tjoin )      if( $arg{filter} );
    $tjoin->merge( $arg{post_filter}->_tjoin ) if( $arg{post_filter} );
    $tjoin->assign_aliases;

    # Prepare WHERE statement for SQL query
    my $cond   = $arg{filter} && $arg{filter}->_sql_str( tjoin=>$tjoin );

    # Prepare HAVING statement for SQL query
    my $having = $arg{post_filter} && $arg{post_filter}->_sql_str( tjoin=>$tjoin );

    # Prepare GROUP BY statement for SQL query
    my $group_by;
    for my $grp ( @{$arg{group_by}} )
    {
        $group_by .= ', ' if( $group_by );
        if( UNIVERSAL::isa( $grp, 'ORM::Expr' ) )
        {
            $group_by .= $grp->_sql_str( tjoin=>$tjoin );
        }
        else
        {
            $group_by .= $self->qi( $grp );
        }
    }

    # Prepare ORDER statement for SQL query
    my $order = $arg{order} && $arg{order}->sql_order_by( tjoin=>$tjoin );

    # Prepare SELECT statement for SQL query
    my $select;
    if( $arg{data} )
    {
        $select = '';
        for my $alias ( keys %{$arg{data}} )
        {
            my $data = ref $arg{data}{$alias} ? $arg{data}{$alias} : ORM::Const->new( $arg{data}{$alias} );

            $select .= ",\n" if( $select );
            $select .= '  ' . $data->_sql_str( tjoin=>$tjoin ) . ' AS ' . $self->qi( $alias );
        }
    }
    else
    {
        $select = '  DISTINCT ' . $tjoin->sql_select_basic_tables;
    }

    # Prepare LIMIT statement for SQL query
    my $limit = $self->_sql_limit( $arg{page}, $arg{pagesize} );

    # Prepare query string and fetch data
    my $query =
        "SELECT\n$select\n"
        . 'FROM ' . $tjoin->sql_table_list . "\n"
        . ( $cond       ? "WHERE\n  $cond\n" : '' )
        . ( $group_by   ? "GROUP BY $group_by\n" : '' )
        . ( $having     ? "HAVING\n  $having\n" : '' )
        . ( $order      ? "ORDER BY $order\n" : '' )
        . ( $limit      ? "$limit\n" : '' )
        . ( $self->{ta} ? $self->_ta_select."\n" : '' );

    $self->select
    (
        tables   => $tjoin->select_basic_tables,
        query    => $query,
        error    => $arg{error},
    );
}

sub select_full
{
    my $self  = shift;
    my %arg   = @_;
    my $error = ORM::Error->new;
    my $fullres;

    my $res = $self->select_base
    (
        class    => $arg{class},
        filter   => $arg{filter},
        order    => $arg{order},
        page     => $arg{page},
        pagesize => $arg{pagesize},
        error    => $error,
    );

    unless( $error->fatal )
    {
        my %class2id;
        my %id2data;
        my %residual_tables;
        my $residual;
        my $residual_data;
        my $data;

        $fullres = ORM::Db::DBIResultSetFull->new;

        while( $data = $res->next_row )
        {
            my $obj = $arg{class}->_cache->get( $data->{id}, 0 );
            if( $obj )
            {
                $fullres->add_row( $obj );
            }
            else
            {
                $fullres->add_row( $data );
                if( $data->{class} ne $arg{class} )
                {
                    $class2id{ $data->{class} } .= $data->{id}.',';
                    $id2data{ $data->{id} }      = $data;
                }
            }
        }

        for my $inh_class ( keys %class2id )
        {
            $arg{class}->_load_ORM_class( $inh_class );
            %residual_tables = ();
            chop $class2id{ $inh_class };
            for
            (
                my $i = scalar( @{$res->result_tables} );
                $i < $inh_class->_db_tables_count;
                $i++
            )
            {
                $residual_tables{ $inh_class->_db_table( $i ) } = 1;
            }
            if( %residual_tables )
            {
                $residual = $self->select_tables
                (
                    id     => $class2id{ $inh_class },
                    tables => \%residual_tables,
                    error  => $error,
                );
                last if( $error->fatal );
                while( $residual_data = $residual->next_row )
                {
                    $data = $id2data{ $residual_data->{id} };
                    for my $key ( keys %$residual_data )
                    {
                        $data->{$key} = $residual_data->{$key};
                    }
                }
            }
        }
    }

    $error->upto( $arg{error} );
    return $error->fatal ? undef : $fullres;
}

sub select_tables
{
    my $self   = shift;
    my %arg    = @_;
    my @tables = keys %{$arg{tables}};

    my $fields_to_select = '';
    my $tables_str       = '';
    my $inner_join       = '';

    for( my $i=0; $i<@tables; $i++ )
    {
        if( ref $arg{tables}{$tables[$i]} eq 'HASH' )
        {
            for my $prop ( keys %{$arg{tables}{$tables[$i]}} )
            {
                $fields_to_select .= $self->qt($tables[$i]).'.'.$self->qf($prop).',';
            }
        }
        else
        {
            $fields_to_select .= $self->qt( $tables[$i] ).'.*,';
        }

        $tables_str .= $self->qt( $tables[$i] ).',';

        if( $i < $#tables )
        {
            $inner_join .= $self->qt($tables[$i]).".id=".$self->qt($tables[$i+1]).".id AND ";
        }
    }
    chop $fields_to_select;
    chop $tables_str;

    my $query =
        'SELECT '   . $fields_to_select
        . ' FROM '  . $tables_str
        . ' WHERE ' . $inner_join . $self->qt( $tables[0] ).'.id IN ('.$arg{id}.')'
        . ( $self->{ta} ? ' '.$self->_ta_select : '' );

    $self->select
    (
        tables => [ keys %{$arg{tables}} ],
        query  => $query, 
        error  => $arg{error},
    );
}

sub select_stat { shift->select_base( @_ ); }

sub insert_object
{
    my $self      = shift;
    my %arg       = @_;
    my $obj       = $arg{object};
    my $obj_class = ref $obj;
    my $id        = $arg{id};
    my $error     = ORM::Error->new;
    my $ta        = $obj_class->new_transaction( error=>$error );

    # Insert new records into tables
    my @table = $obj_class->_db_tables;
    my %values;
    my $i;

    for( $i=0; $i<@table && !$error->fatal; $i++ )
    {
        %values = ();

        if( $i == 0 )
        {
            $values{id}    = $id        if( $id );
            $values{class} = $obj_class if( !$obj_class->_is_sealed );
        }
        else
        {
            $values{id} = $id;
        }

        for my $field ( $obj_class->_db_table_fields( $table[$i] ) )
        {
            $values{$field} = $obj->_property_id( $field );
        }

        my $rows_affected = $self->insert
        (
            table  => $table[$i],
            values => \%values,
            error  => $error,
        );

        if( $rows_affected == 1 )
        {
            $id = $self->insertid if( $i==0 && ! $id );
        }
        else
        {
            $error->add_fatal
            (
                "Insert into table '$table[$i]' failed, $rows_affected rows affected"
            );
        }
    }

    $error->upto( $arg{error} );
    return $id;
}

sub update_object
{
    my $self      = shift;
    my %arg       = @_;
    my $obj       = $arg{object};
    my $obj_class = ref $obj;
    my $error     = ORM::Error->new;
    my $ta        = $obj_class->new_transaction( error=>$error );
    my %table;

    unless( $error->fatal )
    {
        for my $prop ( keys %{$arg{values}} )
        {
            $table{ $obj_class->_prop2table($prop) }{ $prop } = $arg{values}{$prop};
        }

        for my $table ( keys %table )
        {
            $self->update_object_part
            (
                object => $obj,
                values => $table{ $table },
                error  => $error,
            );
        }
    }

    $error->upto( $arg{error} );
}

sub update_object_part
{
    my $self      = shift;
    my %arg       = @_;
    my $obj       = $arg{object};
    my $obj_class = ref $obj;

    my $check_all_props = 0;
    my $left_prop       = (each %{$arg{values}})[0];
    my $tjoin           = ORM::Tjoin->new( class=>$obj_class, left_prop=>$left_prop, all_tables=>$arg{all_tables} );

    for my $prop ( keys %{$arg{values}} )
    {
        $check_all_props = 1 if( ! ref $arg{values}{$prop} );
        if( UNIVERSAL::isa( $arg{values}{$prop}, 'ORM::Expr' ) )
        {
            $tjoin->merge( $arg{values}{$prop}->_tjoin );
        }
    }
    $tjoin->assign_aliases;

    # Prepare WHERE statement
    my $where;
    my $filter = ORM::Expr->_and( $obj->M->id == $obj->id );
    if( $check_all_props )
    {
        for my $prop ( keys %{$arg{old_values}} )
        {
            $filter->add_expr
            (
                defined $arg{old_values}{$prop}
                    ? $obj->M->_prop( $prop ) == $arg{old_values}{$prop}
                    : $obj->M->_prop( $prop )->_is_undef
            );
        }
    }
    $where = $filter->_sql_str( tjoin=>$tjoin );

    # Prepare SET statement
    my $set = '';
    for my $prop ( keys %{$arg{values}} )
    {
        $set .=
            $obj->M( $prop )->_sql_str( tjoin=>$tjoin )
            . '='
            . (
                ( UNIVERSAL::isa( $arg{values}{$prop}, 'ORM::Expr' ) )
                    ? $arg{values}{$prop}
                    : ORM::Const->new( $arg{values}{$prop} )
            )->_sql_str( tjoin=>$tjoin )
            . ',';
    }
    chop $set;

    my $rows_affected = $self->do
    (
        error => $arg{error},
        query =>
        (
            "UPDATE " . $tjoin->sql_table_list . "\n"
            . " SET $set\n"
            . " WHERE $where"
        ),
    );

    if( $rows_affected == 0 )
    {
        $arg{error} && $arg{error}->add_fatal
        (
            "Failed to update object with id#".$obj->id
            . " of class '$obj_class', $rows_affected rows affected,"
            . " may be object was updated elsewhere."
        );
    }
    elsif( $rows_affected > $tjoin->tables_count )
    {
        $arg{error} && $arg{error}->add_fatal
        (
            "Internal error occured!"
            . " More than expected number of rows was updated ($rows_affected)."
            . " Please report to developer."
        );
    }
}

sub delete_object
{
    my $self      = shift;
    my %arg       = @_;
    my $obj       = $arg{object};
    my $obj_class = ref $obj;
    my $error     = ORM::Error->new;
    my $ta        = $obj_class->new_transaction( error=>$error );
    my @table     = $obj_class->_db_tables;
    my $rows_affected;

    $self->check_object_referers
    (
        object => $obj,
        error  => $error,
        check  => $arg{emulate_foreign_keys},
    );

    unless( $error->fatal )
    {
        for( $i=$#table; $i>=0 && !$error->fatal; $i-- )
        {
            my $rows_affected = $self->delete_by_id
            (
                table => $table[$i],
                id    => $obj->id,
                error => $error,
            );
            if( $rows_affected != 1 )
            {
                $error->add_fatal( "Failed to delete row with id#$id from '$table[$i]' during object delete" );
            }
        }

        # must check twise, new referers could be created during deletion
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

sub optimize_tables
{
    my $self = shift;
    my %arg  = @_;

    $self->do
    (
        query => 'OPTIMIZE TABLE '.$arg{class}->_db_tables_str,
        error => $arg{error},
    );
}

sub referencing_classes
{
    my $self  = shift;
    my %arg   = @_;
    my $error = ORM::Error->new;
    my $res;
    my $data;
    my @res;

    $res = $self->select
    (
        error => $error,
        query =>
            'SELECT class,prop FROM '.$self->qt('_ORM_refs').' WHERE ref_class='
            . $self->qc( $arg{class} )
    );

    unless( $error->fatal )
    {
        while( $data = $res->next_row )
        {
            push @res, $data;
        }
    }

    $error->upto( $arg{error} );
    return @res;
}

sub begin_transaction
{
    my $self  = shift;
    my %arg   = @_;
    my $error = ORM::Error->new;

    $self->{ta} = 1;
    $self->_db_handler->begin_work();
    $error->add_fatal( $self->_db_handler->errstr ) if( $self->_db_handler->err );
    ORM::DbLog->new( sql=>"BEGIN", error=>$error->text );

    $error->upto( $arg{error} );
}

sub commit_transaction
{
    my $self  = shift;
    my %arg   = @_;
    my $error = ORM::Error->new;

    delete $self->{ta};
    $self->_db_handler->commit();
    $error->add_fatal( $self->_db_handler->errstr ) if( $self->_db_handler->err );
    ORM::DbLog->new( sql=>"COMMIT", error=>$error->text );

    $error->upto( $arg{error} );
}

sub rollback_transaction
{
    my $self  = shift;
    my %arg   = @_;
    my $error = ORM::Error->new;

    delete $self->{ta};
    unless( $self->{lost_connection} )
    {
        $self->_db_handler->rollback();
        $error->add_fatal( $self->_db_handler->errstr ) if( $self->_db_handler->err );
        ORM::DbLog->new( sql=>"ROLLBACK", error=>$error->text );
    }

    $error->upto( $arg{error} );
}

##
## PROTECTED METHODS
##

## use: $db->insert( table=>string, values=>hash, error=>ORM::Error )
##
sub insert
{
    my $self = shift;
    my %arg  = @_;
    my $keys;
    my $values;
    my $table;

    $table = $self->qt( $arg{table} );
    for my $key ( keys %{$arg{values}} )
    {
        $keys   .= $self->qf( $key ) . ',';
        $values .= $self->qc( $arg{values}{$key} ) . ',';
    }
    chop $keys;
    chop $values;

    $self->do
    (
        query => "INSERT INTO $table ($keys) VALUES ($values)",
        error => $arg{error},
    );
}

## use: $db->delete_by_id
## (
##     table => $string,
##     id    => number,
##     error => ORM::Error,
## )
##
sub delete_by_id
{
    my $self = shift;
    my %arg  = @_;

    $self->do
    (
        query => ( "DELETE FROM ".$self->qt($arg{table})." WHERE id=".$self->qc($arg{id}) ),
        error => $arg{error},
    );
}

## use: $db->do( query=>$string, error=>ORM::Error )
##
sub do
{
    my $self = shift;
    $self->select( return_rows_count=>1, @_ );
}

## use: $result = $db->select
## (
##     tables   => ARRAY,
##     query    => string,
##     error    => ORM::Error,
##
##     return_rows_count => 1,
## );
##
sub select
{
    my $self     = shift;
    my %arg      = @_;
    my $error    = ORM::Error->new;
    my $h_error  = ORM::Error->new;
    my $retry    = 1;
    my $tries    = $self->{connect_retries};
    my $query    = $arg{query};
    my $rows_affected;
    my $st;

    $self->{lost_connection} = 0;

    while( $retry )
    {
        $retry = 0;
        if( ! $self->{db} )
        {
            $self->_db_reconnect;
            $retry = $tries--;
            if( $retry )
            {
                if( $self->{delayed_connect} )
                {
                    delete $self->{delayed_connect};
                }
                else
                {
                    print STDERR 
                        "No connection, connecting to SQL server '"
                        . $self->{db_arg}[0]
                        . "' ($tries tries left)\n";
                }
                next;
            }
            else
            {
                $error->add_fatal( "No db connection" );
                $self->{lost_connection} = 1;
                last;
            }
        }

        $st                = $self->{db}->prepare( $query );
        $h_error           = ORM::Error->new;
        $st && ( $DBI::VERSION >= 1.21 ) &&
        (
            $st->{HandleError} = sub
            {
                $h_error->add_fatal( "DBI Error Handler($_[1],'".($_[2]||'')."'): $_[0]" );
                return 1;
            }
        );

        if( $st )
        {
            $st->execute;
        }
        else
        {
            $error->add_fatal( "Failed to execute query, 'prepare' returned undef, query='$query'" );
        }

        if( $st && $st->err && $self->_lost_connection( $st->err ) )
        {
            $self->_db_reconnect;
            $retry = $tries--;
            print STDERR
                "Lost connection, reconnecting to SQL server '"
                . $self->{db_arg}[0]
                . "' ($tries tries left)\n";
        }
    }

    # Catch up errors
    if( $st && $st->err )
    {
        $error->add_fatal
        (
            'DBI Error '.$st->err.': ' . $st->errstr
            . ', Query="' . $query . '"'
        );
    }
    elsif( $h_error->any )
    {
        $error->add( error=>$h_error );
    }

    ORM::DbLog->new
    (
        sql   => $query,
        error => $error->text,
    );
    $error->upto( $arg{error} );

    return $arg{return_rows_count}
        ? ( $st && $st->rows != 4294967294 ? $st->rows : 0 )
        : (   
            $error->fatal
                ? undef 
                : ORM::Db::DBIResultSet->new( result=>$st, tables=>$arg{tables} )
        );
}

sub ql
{
    my $class = shift;
    my $str   = shift;

    $str =~ s/_/\\_/g;
    $str =~ s/%/\\%/g;

    return $class->qc( $str );
}

sub _db_handler { $_[0]->{db}; }

sub _db_reconnect
{
    my $self = shift;

    $self->{db} = undef;
    sleep $self->{retry_sleep};
    $self->{db} = DBI->connect( @{$self->{db_arg}} );
}

sub _ta_select { 'FOR UPDATE'; }

sub _sql_limit
{
    my $self     = shift;
    my $page     = (int shift)||1;
    my $pagesize = int shift;
    my $sql;

    if( $pagesize )
    {
        $sql = "LIMIT ".(($page-1)*$pagesize).",$pagesize";
    }

    return $sql;
}

sub check_object_referers
{
    my $self      = shift;
    my %arg       = @_;
    my $obj       = $arg{object};
    my $obj_class = ref $obj;
    
    if( $arg{check} )
    {
        for my $ref ( $obj_class->_rev_refs )
        {
            my $referers = $ref->[0]->count
            (
                filter => ( $ref->[0]->M->_prop($ref->[1])==$obj->id ),
                error  => $arg{error},
            );
            if( $referers )
            {
                $arg{error}->add_fatal
                (
                    "Can't delete instance ID#" . $obj->id
                    . " of '$obj_class', because there're "
                    . "$referers instances of '$ref->[0]' refer to it."
                );
            }
        }
    }

    return undef;
}

##
## ABSTRACT METHODS
##

sub insertid
{
    die "You forget to override 'insertid' in '$_[0]'";
}

sub _lost_connection
{
    die "You forget to override '_lost_connection' in '$_[0]'";
}

##
## SQL FUNCTIONS
##

sub _func_concat { shift; ORM::Filter::Cmp->new( '||', @_ ); }
