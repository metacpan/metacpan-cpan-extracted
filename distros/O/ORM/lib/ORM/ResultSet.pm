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

package ORM::ResultSet;

use ORM;

$VERSION = 0.8;

##
## CONSTRUCTORS
##

## use: $result_set = ORM::ResultSet->new( class=>string, result=>ORM::DbResultSet );
##
sub new
{
    my $class = shift;
    my %arg   = @_;

    bless { class=>$arg{class}, result=>$arg{result} }, $class;
}

##
## PROPERTIES
##

sub class { $_[0]->{class}; }

sub next
{
    my $self = shift;
    my $obj;

    if( exists $self->{preview} )
    {
        $obj = $self->{preview};
        delete $self->{preview};
    }
    else
    {
        my $res = $self->{result} && $self->{result}->next_row;

        if( $res )
        {
            $obj = $self->{class}->_cache->get( $res->{id}, 0 );
            unless( $obj )
            {
                $obj = $self->{class}->_find_constructor( $res, $self->{result}->result_tables );
                $self->{class}->_cache->add( $obj );
            }
        }
    }

    return $obj;
}

sub preview
{
    my $self = shift;

    $self->{preview} = $self->next( @_ ) unless( exists $self->{preview} );
    return $self->{preview};
}

sub amount
{
    my $self = shift;

    $self->{result}->rows;
}
