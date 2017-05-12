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

package ORM::Meta::Array;

$VERSION=0.83;
use base 'ORM::Metaprop';

package Array;

use Data::Dumper;

sub __ORM_db_value
{
    my $self  = shift;
    my @array = $self->get;

    Dumper( \@array );
}

sub __ORM_new_db_value
{
    my $class = shift;
    my %arg   = @_;
    my $self;
    my $VAR1;

    # Automatically convert ARRAY to Array
    if( ref $arg{value} eq 'ARRAY' )
    {
        $self = Array->new( array=>$arg{value} );
    }
    # Construct Array from Data::Dumper value
    else
    {
        eval $arg{value};
        die $@ if( $@ );
        $self = Array->new( array=>$VAR1 );
    }

    return $self;
}
