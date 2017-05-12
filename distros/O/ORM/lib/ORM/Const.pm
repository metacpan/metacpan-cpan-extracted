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

package ORM::Const;

use base 'ORM::Expr';

$VERSION = 0.8;

sub new
{
    my $class  = shift;
    my $value  = shift;
    my $nclass = shift;
    my $self   = { value=>$value, tjoin=>ORM::Tjoin->new( null_class=>$nclass ) };

    return bless $self, $class;
}

sub new_int
{
    my $class = shift;
    my $self  = { value=>(int shift), int=>1 };

    return bless $self, $class;
}

sub _sql_str
{
    my $self = shift;
    my %arg  = @_;

    $self->{int} ? $self->{value} : $arg{tjoin}->class->ORM::qc( $self->{value} );
}

sub value  { $_[0]->{value}; }
sub _tjoin { $_[0]->{tjoin}; }

1;
