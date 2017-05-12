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

package ORM::Filter::Func;

$VERSION=0.8;

use overload 'fallback' => 1;
use base 'ORM::Filter';

##
## CONSTRUCTORS
##

sub concat { (shift @_)->new( 'CONCAT', @_ ); }

sub new
{
    my $class = shift;
    my $self  = { func => shift };

    for my $arg ( @_ )
    {
        if( ref $arg )
        {
            if( UNIVERSAL::isa( $arg, 'ORM::Expr' ) )
            {
                push @{$self->{arg}}, $arg;
            }
            else
            {
                push @{$self->{arg}}, $arg->__ORM_db_value;
            }
        }
        else
        {
            push @{$self->{arg}}, $arg;
        }
    }

    return bless $self, $class;
}

##
## PROPERTIES
##

sub _sql_str
{
    my $self = shift;
    my %arg  = @_;
    my $sql;

    for my $arg ( @{$self->{arg}} )
    {
        $sql .= $self->scalar2sql( $arg, $arg{tjoin} ).',';
    };
    chop $sql;

    return "$self->{func}( $sql )";
}

sub _tjoin
{
    my $self  = shift;
    my $tjoin = ORM::Tjoin->new;

    for my $arg ( @{$self->{arg}} )
    {
        $tjoin->merge( $arg->_tjoin ) if( ref $arg );
    }

    return $tjoin;
}

