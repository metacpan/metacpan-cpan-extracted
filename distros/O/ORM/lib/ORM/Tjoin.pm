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

# Instance of the class represents tree data structure,
# describing links between DB tables in joins.

package ORM::Tjoin;

use Carp;
use ORM::TjoinNull;

$VERSION=0.81;

##
## CLASS METHODS
##

## use: ORM::Tjoin->new
## (
##     class      => STRING,
##     alias      => STRING,
##     left_prop  => STRING||undef,
##     prop       => STRING||undef,
##     all_tables => BOOLEAN,
## );
##
sub new
{
    my $class = shift;
    my %arg   = @_;
    my $self;

    if( ! exists $arg{class} )
    {
        $self = ORM::TjoinNull->new( null_class=>$arg{null_class} );
    }
    elsif( !UNIVERSAL::isa( $arg{class}, 'ORM' ) || $arg{class}->_is_initial )
    {
        croak "Internal error! '$arg{class}' is not a valid descendant of ORM.";
    }
    else
    {
        $self = 
        {
            class       => $arg{class},
            left_prop   => ( $arg{left_prop}||'id' ),
            alias       => ( $arg{alias}||undef ),
            alias_num   => undef,
            cond        => $arg{cond},
            fingerprint => ( ($arg{left_prop}||'id').' '.($arg{alias}||'').' '.($arg{cond}||'').' '.$arg{class} ),
            link        => {},
        };

        if( $self->{cond} && $self->{cond}->_tjoin->class ne $self->{class} )
        {
            croak "Join condition class '".$self->{cond}->_tjoin->class."' does not match Tjoin class '$self->{class}'";
        }

        bless $self, $class;

        my @tables  = $self->class->_db_tables;
        my $primary = $self->{left_prop} eq 'id' ? '' : $self->class->_prop2table( $self->{left_prop} );
        for( my $i=0; $i < @tables; $i++ )
        {
            $self->{class_table}{$tables[$i]} = $tables[$i] eq $primary ? -10000 : -$i;
        }

        if( $arg{all_tables} )
        {
            %{$self->{used_table}} = %{$self->{class_table}};
        }
        else
        {
            $self->use_prop( $self->{left_prop} );
            $self->use_prop( $arg{prop} ) if( $arg{prop} );
        }
    }

    return $self;
}

sub copy
{
    # Must copy:
    #
    # class
    # left_prop
    # alias
    # alias_num
    # fingerprint
    # link ( copy by content )
    # class_table ( copy by reference )
    # used_table ( copy by content )
    # tables ( copy by content )

    my $self = shift;
    my $copy =
    {
        class       => $self->{class},
        left_prop   => $self->{left_prop},
        alias       => $self->{alias},
        alias_num   => $self->{alias_num},
        cond        => $self->{cond},
        fingerprint => $self->{fingerprint},
        class_table => $self->{class_table},
    };

    %{$copy->{used_table}} = %{$self->{used_table}} if( $self->{used_table} );
    @{$copy->{tables}}     = @{$self->{tables}}     if( $self->{tables} );

    for my $prop ( keys %{$self->{link}} )
    {
        for my $fingerprint ( keys %{$self->{link}{$prop}} )
        {
            $copy->{link}{$prop}{$fingerprint} = $self->{link}{$prop}{$fingerprint}->copy;
        }
    }

    return bless $copy, ref $self;
}

##
## PROPERTIES
##

sub class       { $_[0]->{class}; }
sub null_class  { $_[0]->{class}; }
sub fingerprint { $_[0]->{fingerprint}; }

sub sql_cond_str
{
    my $self = shift;
    my $sql  = '';

    if( $self->{cond} )
    {
        $sql = ' AND ' . $self->{cond}->_sql_str( tjoin=>$self );
    }

    return $sql;
}

sub sql_table_list
{
    my $self   = shift;
    my $nested = shift;
    my $tables = $self->tables;
    my $sql    = '';

    #$self->assign_aliases unless( $self->{alias_num} );

    for( my $i=0; $i < @$tables; $i++ )
    {
        if( $i == 0 )
        {
            $sql .= "\n  ".$self->table_as_alias( $tables->[$i] ) unless( $nested );
        }
        else
        {
            $sql .=
                "\n".($nested||'').'  '.($nested ? 'LEFT' : 'INNER')." JOIN ".$self->table_as_alias( $tables->[$i] )
                . " ON( "
                    . $self->full_field_name( 'id', $tables->[0]  ) . '='
                    . $self->full_field_name( 'id', $tables->[$i] )
                . " )";
        }
    }

    for my $prop ( keys %{$self->{link}} )
    {
        for my $fingerprint ( keys %{$self->{link}{$prop}} )
        {
            $sql .=
                "\n".($nested||'')."    LEFT JOIN " . $self->{link}{$prop}{$fingerprint}->first_basic_table_as_alias
                . " ON( "
                    . $self->full_field_name( $prop ) . '='
                    . $self->{link}{$prop}{$fingerprint}->full_left_field_name
                    . $self->{link}{$prop}{$fingerprint}->sql_cond_str
                . " )";
            $sql .= $self->{link}{$prop}{$fingerprint}->sql_table_list( ($nested||'').'  ' );
        }
    }

    return $sql;
}

sub text
{
    my $self   = shift;
    my $nested = shift;
    my $text;

    $text .= $self->class . "\n";
    for my $prop ( keys %{$self->{link}} )
    {
        for my $fingerprint ( keys %{$self->{link}{$prop}} )
        {
            $text .=
                $nested
                . $prop
                . ' -> '
                . $self->{link}{$prop}{$fingerprint}->text( $nested.'  ' );
        }
    }

    return $text;
}

sub sql_select_basic_tables
{
    my $self   = shift;
    my $tables = $self->tables;
    my $sql;

    #$self->assign_aliases unless( $self->{alias_num} );

    for my $table ( @{$self->tables} )
    {
        $sql .= ", " if( $sql );
        $sql .= $self->class->ORM::qt( $self->table_alias_or_name( $table ) ) . '.*';
    }

    return $sql;
}

sub corresponding_node
{
    my $self  = shift;
    my $tjoin = shift;
    my $node;

#    if( $self->class eq $tjoin->class )
#    {
        my $prop = (keys %{$tjoin->{link}})[0];
        if( $prop )
        {
            my $fingerprint = (keys %{$tjoin->{link}{$prop}})[0];
            if( $self->{link}{$prop}{$fingerprint} )
            {
                $node = $self->{link}{$prop}{$fingerprint}->corresponding_node
                (
                    $tjoin->{link}{$prop}{$fingerprint}
                );
            }
        }
        else
        {
            $node = $self;
        }
#    }

    return $node;
}

##
## TABLES PROPERTIES
##

sub tables
{
    my $self    = shift;

    if( ! defined $self->{tables} || ! @{$self->{tables}} )
    {
        if( defined $self->{used_table} && %{$self->{used_table}} )
        {
            @{$self->{tables}} = sort { $self->{used_table}{$a} <=> $self->{used_table}{$b} } keys %{$self->{used_table}};
        }
        else
        {
            $self->{tables}[0] = $self->class->_db_table( 0 );
        }
    }

    return $self->{tables};
}

sub tables_count               { scalar @{ $_[0]->tables }; }

sub select_basic_tables        { $_[0]->tables; }
sub first_basic_table_alias    { $_[0]->table_alias_or_name( $_[0]->tables->[0] ); }
sub first_basic_table_as_alias { $_[0]->table_as_alias( $_[0]->tables->[0] ); }

sub table_alias
{
    my $self   = shift;
    my $table  = shift;
    my $alias;

    if( $self->{alias_num} )
    {
        $alias = '_T'.$self->{alias_num}.($self->{alias} ? '_'.$self->{alias} : '').'_'.$table;
    }

    return $alias;
}

sub table_alias_or_name
{
    my $self  = shift;
    my $table = shift;

    return $self->table_alias( $table ) || $table;
}

sub table_as_alias
{
    my $self   = shift;
    my $table  = shift;
    my $alias  = $self->table_alias( $table );

    if( $alias )
    {
        $alias = $self->class->ORM::qt( $table ).' AS '.$self->class->ORM::qt( $alias );
    }
    else
    {
        $alias = $self->class->ORM::qt( $table );
    }

    return $alias;
}

sub full_field_name
{
    my $self   = shift;
    my $prop   = shift;
    my $table  = shift || ( $prop eq 'id' ? $self->tables->[0] : $self->class->_prop2table( $prop ) );
    my $alias  = $self->table_alias( $table );
    my $name;

    if( $alias )
    {
        $name = $self->class->ORM::qt( $alias ).'.'.$self->class->ORM::qt( $prop );
    }
    else
    {
        $name = $self->class->ORM::qt( $prop );
    }

    return $name;
}

sub full_left_field_name
{
    my $self = shift;

    return $self->full_field_name( $self->{left_prop}, @_ );
}

##
## METHODS
##

sub use_prop
{
    my $self = shift;
    my $prop = shift;

    if( $prop eq 'id' )
    {
    }
    elsif( $prop eq 'class' )
    {
        my $table = $self->class->_db_table( 0 );
        unless( exists $self->{used_table}{$table} )
        {
            $self->{used_table}{$table} = $self->{class_table}{$table};
            delete $self->{tables};
        }
    }
    else
    {
        my $table = $self->class->_prop2table( $prop );
        unless( exists $self->{used_table}{$table} )
        {
            $self->{used_table}{$table} = $self->{class_table}{$table};
            delete $self->{tables};
        }
    }
}

sub assign_aliases
{
    my $self  = shift;
    my $alias = shift||1;

    $self->{alias_num} = $alias;
    for my $prop ( keys %{$self->{link}} )
    {
        for my $fingerprint ( keys %{$self->{link}{$prop}} )
        {
            $alias = $self->{link}{$prop}{$fingerprint}->assign_aliases( $alias+1 );
        }
    }

    $self->{alias_num} = undef if( $self->{alias_num} == 1 && $alias == 1 && $self->tables_count == 1 );

    return $alias;
}

## use: $tjoin->link( $prop => $tjoin );
##
sub link
{
    my $self  = shift;
    my $prop  = shift;
    my $tjoin = shift;

    $self->{alias_num} = undef;
    if( $self->class->_has_prop( $prop ) )
    {
        $self->{link}{ $prop }{ $tjoin->fingerprint } = $tjoin;
        $self->use_prop( $prop );
    }
    else
    {
        croak "Can't link tjoin '".$tjoin->class."' to property '$prop' (class '".$self->class."' doesn't have it)";
    }
}

sub merge
{
    my $self  = shift;
    my $tjoin = shift;

    if( ref $tjoin ne 'ORM::TjoinNull' )
    {
        if( UNIVERSAL::isa( $self->class, $tjoin->class ) )
        {
            # Do nothing
        }
        elsif( UNIVERSAL::isa( $tjoin->class, $self->class ) )
        {
            $self->{class}          = $tjoin->class;
            %{$self->{class_table}} = %{$tjoin->{class_table}};
        }
        else
        {
            croak "Internal error! Can't merge, '$self->{class}' and '".$tjoin->class."' are incompatible.";
        }    

        $self->{alias_num} = undef;

        for my $table ( @{ $tjoin->tables } )
        {
            unless( $self->{used_table}{$table} )
            {
                $self->{used_table}{$table} = $self->{class_table}{$table};
                delete $self->{tables};
            }
        }

        for my $prop ( keys %{$tjoin->{link}} )
        {
            for my $fingerprint ( keys %{$tjoin->{link}{$prop}} )
            {
                if( exists $self->{link}{$prop}{$fingerprint} )
                {
                    $self->{link}{$prop}{$fingerprint}->merge( $tjoin->{link}{$prop}{$fingerprint} );
                }
                else
                {
                    $self->link( $prop => $tjoin->{link}{$prop}{$fingerprint}->copy );
                }
            }
        }
    }
}
