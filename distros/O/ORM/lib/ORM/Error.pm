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

package ORM::Error;

use Exception::Class;
use base 'Exception::Class::Base';
use overload 'fallback'=>1;

$VERSION=0.83;

ORM::Error->Trace( 1 );
ORM::Error->RespectOverload( 1 );

##
## CONSTRUCTORS
##

sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new();

    return $self;
}

sub new_fatal
{
    my $class = shift;
    my $msg   = shift;
    my $self  = $class->new();

    $self->add_fatal( $msg );

    return $self;
}

sub new_warn
{
    my $class = shift;
    my $msg   = shift;
    my $self  = $class->new();

    $self->add_warn( $msg );

    return $self;
}

##
## OBJECT METHODS
##

sub add
{
    my $self = shift;
    my %arg  = @_;

    if( ref $arg{error} )
    {
        for my $err ( @{$arg{error}->{list}} )
        {
            my $type = $arg{conv}{$err->{type}} || $err->{type};
            $self->{fatal} = ( $type eq 'fatal' );
            push @{$self->{list}},
            {
                class   => $err->{class},
                sub     => $err->{sub},
                type    => $type,
                comment => $err->{comment},
            };
        }
    }
    else
    {
        my( $package, $filename, $line, $sub ) = caller 1;

        if( $package )
        {
            $sub =~ s/^${package}:://;
        }
        else
        {
            $package = caller;
        }

        $self->{fatal} = ( $arg{type} eq 'fatal' );

        push @{$self->{list}},
        {
            class   => $package,
            sub     => ( $sub || 'main' ),
            type    => $arg{type},
            comment => $arg{comment},
        };
    }
}

sub add_fatal
{
    my $self = shift;

    my( $package, $filename, $line, $sub ) = caller 1;

    if( $package )
    {
        $sub =~ s/^${package}:://;
    }
    else
    {
        $package = caller;
    }

    $self->{fatal} = 1;

    push @{$self->{list}},
    {
        class   => $package,
        sub     => ( $sub || 'main' ),
        type    => 'fatal',
        comment => $_[0],
    };
}

sub add_warn
{
    my $self = shift;

    my( $package, $filename, $line, $sub ) = caller 1;
    $sub =~ s/^${package}:://;
    $package = caller unless( $package );

    push @{$self->{list}},
    {
        class   => $package,
        sub     => ( $sub || 'main' ),
        type    => 'warning',
        comment => $_[0],
    };
}

sub upto
{
    my $self = shift;
    my $up   = shift;

    if( UNIVERSAL::isa( $up, 'ORM::Error' ) )
    {
        $up->add( error=>$self );
    }
    elsif( $self->fatal )
    {
        $self->throw;
    }
}

##
## OBJECT PROPERTIES
##

sub full_message { shift->short_text( @_ ); }

sub short_text
{
    my $self = shift;
    my $text = '';

    for( @{$self->{list}} )
    {
        $text .= "* $_->{comment}\n";
    }

    return $text;
}

sub short_html
{
    my $self = shift;
    my $text = '<ul class="linkmenu">';

    for( @{$self->{list}} )
    {
        $text .= "<li>&nbsp;$_->{comment}</li>\n";
    }
    $text .= '</ul>';

    return $text;
}

sub text
{
    my $self = shift;
    my $text = '';

    for( @{$self->{list}} )
    {
        $text .= sprintf "%s: %s->%s(): %s\n",
            $_->{type}, $_->{class}, $_->{sub}, $_->{comment};
    }

    return $text;
}

sub any   { defined $_[0]->{list} && scalar @{$_[0]->{list}}; }
sub fatal { $_[0]->{fatal}; }
