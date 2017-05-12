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

package ORM::Broken;

use Carp;

$VERSION = 0.8;

sub AUTOLOAD
{
    my $self   = shift;
    my $method = $AUTOLOAD;

    if( ref $self )
    {
        if( $self->{deleted} )
        {
            croak
                "Object of class '$self->{class}' with id #$self->{id}"
                . " has been deleted and should not be used.";
        }
        else
        {
            croak
                "Object of class '$self->{class}' with id #$self->{id}"
                . " is broken after lazy load and should not be used."
                . ( $self->{error}
                    ? ("Error occured during lazy load:\n".$self->{error}->text)
                    : "Object not found during lazy load."
                );
        }
    }
    else
    {
        croak "Warning! Use of broken object!";
    }
}

sub DESTROY
{
}

1;
