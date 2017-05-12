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

package ORM::StatMetaprop;

$VERSION = 0.81;

use Carp;
use ORM::Ident;

sub new
{
    my $class = shift;
    my %arg   = @_;
    my $self  = { stat_class => $arg{stat_class} };

    return bless $self, $class;
}

sub AUTOLOAD
{
    my $self = shift;
    my $meta;

    if( ref $self )
    {
        my $prop           = substr( $AUTOLOAD, rindex( $AUTOLOAD, '::' )+2 );
        my $prop_meta_expr = $self->{stat_class}->data->{$prop};

        if( $prop_meta_expr )
        {
            my $prop_meta_class = ref $prop_meta_expr;

            if( $prop_meta_class )
            {
                $meta = $prop_meta_class->new( expr=>ORM::Ident->new( $prop, $self->{stat_class}->stat_class ) );
            }
            else
            {
                croak "Can't detect meta-class for property '$prop' of class '$self->{stat_class}'";
            }
        }
        else
        {
            croak "Class '$self->{stat_class}' has no property '$prop'";
        }
    }
    else
    {
        croak "Undefined static method called: $AUTOLOAD";
    }

    return $meta;
}
