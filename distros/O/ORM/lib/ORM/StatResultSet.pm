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

package ORM::StatResultSet;

use ORM;

$VERSION = 0.8;

##
## CONSTRUCTORS
##

## use: $result_set = ORM::StatResultSet->new
## (
##     class     => string,
##     result    => ORM::DbResultSet,
##     preload   => HASH,
##     conv      => HASH,
##     lazy_load => boolean,
## );
##
sub new
{
    my $class = shift;
    my %arg   = @_;

    bless
    {
        class     => $arg{class},
        result    => $arg{result},
        preload   => $arg{preload},
        conv      => $arg{conv},
        lazy_load => $arg{lazy_load},
    }, $class;
}

##
## PROPERTIES
##

sub class { $_[0]->{class}; }

sub next
{
    my $self  = shift;
    my %arg   = @_;
    my $res;
    my $error;

    if( exists $self->{preview} )
    {
        $res = $self->{preview};
        delete $self->{preview};
    }
    else
    {
        my $pre_res = $self->{result} && $self->{result}->next_row;
        return undef unless( defined $pre_res );

        $error = ORM::Error->new;

        # Convert raw values to objects
        for my $name ( keys %{$self->{conv}} )
        {
            if( !$self->{conv}{$name} )
            {
                $res->{$name} = $pre_res->{$name};
            }
            elsif( $self->{preload}{$name} )
            {
                $res->{$name} = $self->{conv}{$name}->_cache->get( $pre_res->{$name}, 0 );

                unless( $res->{$name} )
                {
                    my %prop;

                    for my $prop_name ( $self->{conv}{$name}->_all_props )
                    {
                        $prop{$prop_name} = $pre_res->{"_${name} ${prop_name}"};
                    }
                    $prop{id} = $pre_res->{$name};

                    $res->{$name} = $self->{conv}{$name}->_find_constructor
                    (
                        \%prop,
                        $self->{conv}{$name}->_db_tables_ref,
                    );

                    $self->{conv}{$name}->_cache->add( $res->{$name} );
                }
            }
            else
            {
                $res->{$name} = $self->{conv}{$name}->__ORM_new_db_value
                (
                    value     => $pre_res->{$name},
                    error     => $error,
                    lazy_load => $self->{lazy_load},
                );
            }
        }

        $error->upto( $arg{error} );
    }

    return $res;
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
