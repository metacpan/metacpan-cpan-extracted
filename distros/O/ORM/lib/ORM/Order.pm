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

package ORM::Order;

$VERSION=0.8;

use ORM::Metaprop;

## use: $order = $class->new
## (
##     (
##         ORM::Metaprop
##         | [ORM::Metaprop, ('ASC'|'DESC')] 
##     ),
##     ... 
## )
##
## OR
##
## $order = $class->new( STRING )
##
sub new
{
    my $class = shift;
    my @order;

    if( ref $_[0] )
    {
        @order = @_;
        # Validating $arg{order}
        for( my $i=0; $i<@order; $i++ )
        {
            if( ref $order[$i] eq 'ARRAY' )
            {
                $order[$i][1] = ( $order[$i][1] =~ /^DESC$/i ) ? 'DESC' : 'ASC';
            }
            else
            {
                $order[$i] = [ $order[$i], 'ASC' ];
            }
        }
    }
    else
    {
        my %arg = @_;
        my $obj_class = $arg{class};
        my $order_str = $arg{sort_str};

        for my $field ( split /[\,]+/, $order_str )
        {
            my( $prop, $dir ) = split /\s/, $field;
            push @order,
            [
                $obj_class->M->_prop( $prop ),
                ( ( $dir =~ /^DESC$/i ) ? 'DESC' : 'ASC' ),
            ];
        }
    }
    return scalar(@order) ? ( bless { order=>\@order }, $class ) : undef;
}

sub _tjoin
{
    my $self  = shift;

    if( !$self->{tjoin} )
    {
        $self->{tjoin} = ORM::Tjoin->new;
        for my $prop ( @{$self->{order}} )
        {
            $self->{tjoin}->merge( $prop->[0]->_tjoin );
        }
    }

    return $self->{tjoin};
}

sub sql_order_by
{
    my $self  = shift;
    my %arg   = @_;
    my $sql;

    for my $prop ( @{$self->{order}} )
    {
        $sql .= $prop->[0]->_sql_str( tjoin=>$arg{tjoin} ) .' '. $prop->[1] .',';
    }
    chop $sql;

    return $sql;
}

sub cond
{
    my $self  = shift;
    my $index = shift;

    return $self->{order}[$index];
}

sub conds_amount
{
    my $self = shift;
    return scalar @{$self->{order}};
}
