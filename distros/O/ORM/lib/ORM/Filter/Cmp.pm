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

package ORM::Filter::Cmp;

$VERSION=0.8;

use overload 'fallback' => 1;
use base 'ORM::Filter';

##
## CONSTRUCTORS
##

sub new
{
    my $class = shift;
    my $self  = { op => $_[0] };

    if( UNIVERSAL::isa( $_[1], 'ORM::Expr' ) )
    {
        $self->{arg1} = $_[1];
    }
    else
    {
        $self->{arg1} = ( ref $_[1] ? $_[1]->__ORM_db_value : $_[1] );
    }

    if( UNIVERSAL::isa( $_[2], 'ORM::Expr' ) )
    {
        $self->{arg2} = $_[2];
    }
    else
    {
        $self->{arg2} = ( ref $_[2] ? $_[2]->__ORM_db_value : $_[2] );
    }

    return bless $self, $class;
}

sub _sql_str
{
    my $self = shift;
    my %arg  = @_;

    return
        '(' . $self->scalar2sql( $self->{arg1}, $arg{tjoin} )
        . " $self->{op} "
        . $self->scalar2sql( $self->{arg2}, $arg{tjoin} ) . ')';
}

sub _tjoin
{
    my $self  = shift;
    my $tjoin = ORM::Tjoin->new;

    $tjoin->merge( $self->{arg1}->_tjoin ) if( ref $self->{arg1} );
    $tjoin->merge( $self->{arg2}->_tjoin ) if( ref $self->{arg2} );

    return $tjoin;
}
