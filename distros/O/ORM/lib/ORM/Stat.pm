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

package ORM::Stat;

use ORM::StatMetaprop;
use ORM::Error;

$VERSION = 0.81;

sub new
{
    my $class = shift;
    my %arg   = @_;
    my $self;

    $self =
    {
        class         => $arg{class},
        data          => $arg{data},
        filter        => $arg{filter},
        group_by      => $arg{group_by},
        default_order => $arg{default_order},
    };

    bless $self, $class;
}

sub find
{
    my $class = shift;
    my %arg   = @_;
    my $error = ORM::Error->new;

    my $obj = $class->stat_class->stat
    (
        data        => $class->data,
        preload     => $class->preload,
        filter      => ( $class->filter & $arg{pre_filter} ),
        group_by    => $class->group_by,

        post_filter => ( $class->post_filter & $arg{filter} ),
        order       => ($arg{order}||$class->default_order),
        page        => $arg{page},
        pagesize    => $arg{pagesize},
        error       => $error,
        debug       => $arg{debug},
    );

    unless( $error->fatal )
    {
        for( my $i=$#$obj; $i>=0; $i-- )
        {
            bless $obj->[$i], $class;
        }
    }

    $error->upto( $arg{error} );
    return $error->fatal ? undef : (wantarray ? @$obj : $obj);
}

sub count
{
    my $class = shift;
    my %arg   = @_;
    my $error = ORM::Error->new;
    my $count;

    my $count = $class->stat_class->stat
    (
        data        => $class->data,
        filter      => ( $class->filter & $arg{pre_filter} ),
        group_by    => $class->group_by,

        post_filter => ( $class->post_filter & $arg{filter} ),
        count       => 1,
        error       => $error,
        debug       => $arg{debug},
    );

    $error->upto( $arg{error} );
    return $count;
}

sub preload { undef; }

sub _all_props
{
    my $class = shift;
    keys %{$class->data};
}

sub _property
{
    my $self = shift;
    my $prop = shift;

    $self->{$prop};
}

sub _property_id
{
    my $self = shift;
    my $prop = shift;

    ref $self->{$prop} ? $self->{$prop}->__ORM_db_value : $self->{$prop};
}

sub M
{
    my $class = shift;
    ORM::StatMetaprop->new( stat_class=>$class );
}

sub AUTOLOAD
{
    if( $AUTOLOAD =~ /^(.+)::(.+)$/ )
    {
        my $prop = $2;
        my $self = shift;

        $self->_property( $prop );
    }
}

sub DESTROY
{
}

1;
