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

package ORM::Base;

use Carp;

$VERSION = 0.8;

my %require;
my %loaded;
my $active = 0;
my $debug  = 0;

sub import
{
    my $class   = shift;
    my $base    = shift;
    my %arg     = @_;
    my $derived = caller 0;
    my $i_am_active;

    unless( $active )
    {
        print STDERR "***** Start loading *****\n" if( $debug );
        $active      = 1;
        $i_am_active = 1;
    }

    my $eval = "package $derived; use base $base; ";

    if( $arg{i_am_history} )
    {
        $eval .= 'do \'ORM/History.pm\';';
        $arg{history_is_enabled} = 0;
    }

    eval $eval;
    
    croak "Failed to load package $base\n$@" if( $@ );
    $loaded{$base}    = 1;
    $loaded{$derived} = 1;
    print STDERR "  Loading class $derived\n" if( $debug );

    my @require = $base->_derive( derived_class=>$derived, %arg );
    if( $derived->_history_class && !$loaded{$derived->_history_class} )
    {
        push @require, $derived->_history_class;
    }
    for my $module ( @require )
    {
        if( $loaded{$module} )
        {
            print STDERR "    $derived requested $module (already loaded)\n" if( $debug );
        }
        elsif( $require{$module} )
        {
            print STDERR "    $derived requested $module (already in queue)\n" if( $debug );
        }
        else
        {
            print STDERR "    $derived requested $module (queued)\n" if( $debug );
            $require{$module} = 1;
        }
    }

    if( $i_am_active )
    {
        while( %require )
        {
            my $load;

            for my $module ( keys %require )
            {
                $loaded{$module} = 1;
                $load           .= "require $module; ";
            }

            %require = ();
            print STDERR "Loading queued: $load\n" if( $debug );
            eval $load;
            croak "Failed to load packages: $load\n$@" if( $@ );
        }
        %loaded = ();
        $active = 0;
        print STDERR "***** Finish loading *****\n\n" if( $debug );
    }
}

1;
