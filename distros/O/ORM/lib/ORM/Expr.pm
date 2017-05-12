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

package ORM::Expr;

$VERSION=0.81;

use ORM::Filter::Cmp;
use ORM::Filter::Group;
use ORM::Filter::Func;
use ORM::Filter::Interval;
use ORM::Filter::Case;

use overload
    '<'   => sub { ORM::Filter::Cmp->new( '<',  _re_args( @_ ) ); },
    '<='  => sub { ORM::Filter::Cmp->new( '<=', _re_args( @_ ) ); },
    '>'   => sub { ORM::Filter::Cmp->new( '>',  _re_args( @_ ) ); },
    '>='  => sub { ORM::Filter::Cmp->new( '>=', _re_args( @_ ) ); },
    '=='  => \&_overloaded_eq,
    '!='  => \&_overloaded_ne,

    'lt'  => sub { ORM::Filter::Cmp->new( '<',  _re_args( @_ ) ); },
    'le'  => sub { ORM::Filter::Cmp->new( '<=', _re_args( @_ ) ); },
    'gt'  => sub { ORM::Filter::Cmp->new( '>',  _re_args( @_ ) ); },
    'ge'  => sub { ORM::Filter::Cmp->new( '>=', _re_args( @_ ) ); },
    'eq'  => \&_overloaded_eq,
    'ne'  => \&_overloaded_ne,

    '/'   => sub { ORM::Filter::Cmp->new( '/',  _re_args( @_ ) ); },
    '*'   => sub { ORM::Filter::Cmp->new( '*',  _re_args( @_ ) ); },
    '+'   => sub { ORM::Filter::Cmp->new( '+',  _re_args( @_ ) ); },
    '-'   => sub { ORM::Filter::Cmp->new( '-',  _re_args( @_ ) ); },
    'neg' => sub { ORM::Filter::Func->new( '-', $_[0] ); },

    '&'   => sub { ORM::Filter::Group->new( 'AND', _re_args( @_ ) ); },
    '|'   => sub { ORM::Filter::Group->new( 'OR',  _re_args( @_ ) ); },
    '!'   => sub { ORM::Filter::Func->new( '!',  $_[0] ); },

    'fallback' => 1;

##
## CONSTRUCTORS
## 

sub _lt  { ORM::Filter::Cmp->new( '<',  _autoshift( @_ ) ); }
sub _le  { ORM::Filter::Cmp->new( '<=', _autoshift( @_ ) ); }
sub _gt  { ORM::Filter::Cmp->new( '>',  _autoshift( @_ ) ); }
sub _ge  { ORM::Filter::Cmp->new( '>=', _autoshift( @_ ) ); }
sub _eq  { ORM::Filter::Cmp->new( '=',  _autoshift( @_ ) ); }
sub _ne  { ORM::Filter::Cmp->new( '!=', _autoshift( @_ ) ); }

sub _overloaded_eq
{
    if( defined $_[1] )
    {
        ORM::Filter::Cmp->new( '=',  _re_args( @_ ) );
    }
    else
    {
        $_[0]->_is_undef;
    }
}

sub _overloaded_ne
{
    if( defined $_[1] )
    {
        ORM::Filter::Cmp->new( '!=',  _re_args( @_ ) );
    }
    else
    {
        $_[0]->_is_defined;
    }
}

sub _div { ORM::Filter::Cmp->new( '/',  _autoshift( @_ ) ); }
sub _mul { ORM::Filter::Cmp->new( '*',  _autoshift( @_ ) ); }
sub _add { ORM::Filter::Cmp->new( '+',  _autoshift( @_ ) ); }
sub _sub { ORM::Filter::Cmp->new( '-',  _autoshift( @_ ) ); }
sub _neg { ORM::Filter::Func->new( '-', _autoshift( @_ ) ); }

sub _and { ORM::Filter::Group->new( 'AND', _autoshift( @_ ) ); }
sub _or  { ORM::Filter::Group->new( 'OR',  _autoshift( @_ ) ); }
sub _not { ORM::Filter::Func->new(  'NOT', _autoshift( @_ ) ); }

sub _brackets   { shift; ORM::Filter::Func->new( '', @_ ); }

sub _func       { shift; ORM::Filter::Func->new( @_ ); }
sub _if         { shift; ORM::Filter::Func->new( 'IF', @_ ); }
sub _case       { shift; ORM::Filter::Case->new( @_ ); }
sub _list       { shift; ORM::Filter::Group->new( ',',  @_ ); }

sub _interval_months { shift; ORM::Filter::Interval->new( 'MONTH', $_[0] ); }
sub _interval_days   { shift; ORM::Filter::Interval->new( 'DAY',   $_[0] ); }

##
## PROPERTIES
##

sub _date_format   { ORM::Filter::Func->new( 'DATE_FORMAT', $_[0], $_[1] ); }
sub _time          { ORM::Filter::Func->new( 'TIME', $_[0] ); }

sub _bit_and       { ORM::Filter::Cmp->new( '&', _autoshift( @_ ) ); }
sub _bit_or        { ORM::Filter::Cmp->new( '|', _autoshift( @_ ) ); }
sub _match         { ORM::Filter::Cmp->new( 'REGEXP', @_ ); }
sub _regexp        { ORM::Filter::Cmp->new( 'REGEXP', @_ ); }
sub _like          { ORM::Filter::Cmp->new( 'LIKE', @_ ); }
sub _append        { $_[0]->_tjoin->null_class->_db->_func_concat( @_ ); }
sub _length        { ORM::Filter::Func->new( 'LENGTH', $_[0] ); }
sub _is_undef      { ORM::Filter::Cmp->new( 'IS', $_[0], undef ); }
sub _is_defined    { ORM::Filter::Cmp->new( 'IS NOT', $_[0], undef ); }
sub _set_to        { ORM::Filter::Cmp->new( '=', @_ ); }
sub _substr
{
    if( defined $_[2] )
    {
        ORM::Filter::Func->new( 'SUBSTRING', $_[0], $_[1]+1, $_[2] );
    }
    else
    {
        ORM::Filter::Func->new( 'SUBSTRING', $_[0], $_[1]+1 );
    }
}
sub _replace
{
    ORM::Filter::Func->new( 'REPLACE', $_[0], $_[1], $_[2] );
}
sub _between { ( $_[0] >= $_[1] ) & ( $_[0] <= $_[2] ); }
sub _in
{
    my $op1 = shift;

    if( @_ )
    {
        my $op2 = ORM::Expr->_brackets( @_ );
        ORM::Filter::Cmp->new( 'IN', $op1, $op2 );
    }
    else
    {
        ORM::Filter::Cmp->new( '=', 1, 2 );
    }
}

##
## PROPERTIES to use with ORM->stat
##

sub _sum        { ORM::Filter::Func->new( 'SUM', @_ ); }
sub _max        { ORM::Filter::Func->new( 'MAX', @_ ); }
sub _min        { ORM::Filter::Func->new( 'MIN', @_ ); }
sub _count      { ORM::Filter::Func->new( 'COUNT', @_ ); }

##
## PROTECTED
##

sub _tjoin     { die "You forget to override '_tjoin' in '$_[0]'"; }
sub _sql_str   { die "You forget to override '_sql_str' in '$_[0]'"; }
sub _re_args   { $_[2] ? ( $_[1], $_[0] ) : ( $_[0], $_[1] ); }
sub _autoshift { ( ! ref $_[0] && shift @_ ); @_; }
