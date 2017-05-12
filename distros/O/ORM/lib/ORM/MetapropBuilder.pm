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

package ORM::MetapropBuilder;

$VERSION=0.8;

use ORM::Metaprop;
use Carp;
use overload
    '-' => sub
    {
        if( $_[0]{need_value} )
        {
            (ref $_[0]{need_value})->stat
            (
                data   => { value=>$_[0]{prop} },
                filter => ( $_[0]{need_value}->M('id') == $_[0]{need_value}->id ),
                error  => $_[0]{error},
            )->[0]{value};
        }
        else
        {
            $_[0]{prop};
        }
    },
    fallback => 1;

##
## CONSTRUCTORS
##

sub AUTOLOAD
{
    my $self  = shift;
    my %arg   = @_;

    if( ref $self )
    {
        my $prop = substr( $AUTOLOAD, rindex( $AUTOLOAD, '::' )+2 );

        if( $self->{prop} )
        {
            if( $self->{prop}->_prop_ref_class )
            {
                if( $self->{prop}->_prop_ref_class->_has_prop( $prop ) )
                {
                    unless( $self->{prop}->_expand( $prop, @_ ) )
                    {
                        croak "Failed to expand property '$prop' for ".$self->{prop}->_prop_ref_class;
                    }
                }
                else
                {
                    $self->{prop} = $self->{prop}->$prop( @_ );
                }
            }
            else
            {
                $self->{prop} = $self->{prop}->$prop( @_ );
            }
        }
    }
    else
    {
        my $class = $self;
        $self =
        {
            prop => ORM::Metaprop->_new_flat( class => $arg{prop_class} ),
        };
        if( $arg{need_value} )
        {
            $self->{need_value} = $arg{need_value};
            $self->{error}      = $arg{error};
        }
        bless $self, $class;
        #print "Init builder ($self).\n";
    }

    return $self;
}

sub DESTROY
{
}
