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

package ORM::Date;

$VERSION=0.8;

use Carp;
use POSIX;
use ORM::Datetime;
use overload
        '>'   => sub { ( my $err = _check_args( @_ ) ); $err && croak $err; $_[0]->epoch >   $_[1]->epoch; },
        '<'   => sub { ( my $err = _check_args( @_ ) ); $err && croak $err; $_[0]->epoch <   $_[1]->epoch; },
        '>='  => sub { ( my $err = _check_args( @_ ) ); $err && croak $err; $_[0]->epoch >=  $_[1]->epoch; },
        '<='  => sub { ( my $err = _check_args( @_ ) ); $err && croak $err; $_[0]->epoch <=  $_[1]->epoch; },
        '=='  => sub { ( my $err = _check_args( @_ ) ); $err && croak $err; $_[0]->epoch ==  $_[1]->epoch; },
        '!='  => sub { ( my $err = _check_args( @_ ) ); $err && croak $err; $_[0]->epoch !=  $_[1]->epoch; },
        '<=>' => sub { ( my $err = _check_args( @_ ) ); $err && croak $err; $_[0]->epoch <=> $_[1]->epoch; },
        'cmp' => sub { ( my $err = _check_args( @_ ) ); $err && croak $err; $_[0]->epoch cmp $_[1]->epoch; },
        'fallback' => 1;

my $use_local_tz = 1;

##
## CONSTRUCTORS
##

sub new_epoch
{
    my $class = shift;
    my $epoch = shift;

    return bless { epoch=>$epoch }, $class;
}

sub new
{
    my $class = shift;
    my $array = shift;

    my $time = POSIX::mktime
    (
        $array->[5],
        $array->[4],
        $array->[3],
        $array->[2],
        $array->[1]-1,
        $array->[0]-1900,
        0,0,-1
    );

    unless( defined $time )
    {
        croak "Specified time [".join( ',',@$array )."] cannot be represented";
    }

    $class->new_epoch( $time );
}

sub new_mysql
{
    my $class = shift;
    my $str   = shift;
    my $date;

    if( $str =~ /^(\d{4,4})\-0*(\d+)\-0*(\d+)$/ )
    {
        $date = $class->new( [ $1, $2, $3, 0, 0, 0 ] );
    }
    elsif( $str =~ /^(\d{4,4})\-0*(\d+)\-0*(\d+)(\s+0*(\d+)\:0*(\d+)(\:0*(\d+))?)$/ )
    {
        $date = $class->new( [ $1, $2, $3, $5, $6, $8 ] );
    }

    return $date;
}

sub copy
{
    my $class = shift;
    my $self;

    if( ref $class )
    {
        $self  = $class;
        $class = ref $class;
    }
    else
    {
        $self = shift;
    }

    return $class->new_epoch( $self->{epoch} );
}

sub diff
{
    my $self = shift;
    my @diff = @{$_[0]};

    return (ref $self)->new
    (
        [
            $self->year  + $diff[0],
            $self->month + $diff[1],
            $self->mday  + $diff[2],
            $self->hour  + $diff[3],
            $self->min   + $diff[4],
            $self->sec   + $diff[5],
        ],
    );
}

sub current
{
    my $class = shift;
    my $date  = $class->new_epoch( time );
    $class->new( [$date->year,$date->month,$date->mday,0,0,0] );
}
sub earlier24h
{
    my $class = shift;
    my $date  = $class->new_epoch( time-24*60*60 );
    $class->new( [$date->year,$date->month,$date->mday,0,0,0] );
}

sub date       { ORM::Date->new_epoch( $_[0]->epoch ); }
sub datetime   { ORM::Datetime->new_epoch( $_[0]->epoch ); }

##
## OBJECT PROPERTIES
##

sub epoch { $_[0]->{epoch}; }
sub sec   { $_[0]->_tz_time( $_[0]->epoch )->[0]; }
sub min   { $_[0]->_tz_time( $_[0]->epoch )->[1]; }
sub hour  { $_[0]->_tz_time( $_[0]->epoch )->[2]; }
sub mday  { $_[0]->_tz_time( $_[0]->epoch )->[3]; }
sub wday  { $_[0]->_tz_time( $_[0]->epoch )->[6]; }
sub yday  { $_[0]->_tz_time( $_[0]->epoch )->[7]; }
sub month { $_[0]->_tz_time( $_[0]->epoch )->[4]; }
sub year  { $_[0]->_tz_time( $_[0]->epoch )->[5]; }

sub mysql_date
{
    my $self = shift;
    my $time = $self->_tz_time( $self->epoch );

    sprintf '%04d-%02d-%02d', $time->[5], $time->[4], $time->[3];
}

sub mysql_time
{
    my $self = shift;
    my $time = $self->_tz_time( $self->epoch );

    sprintf '%02d:%02d:%02d', $time->[2], $time->[1], $time->[0];
}

sub mysql_datetime
{
    my $self = shift;
    my $time = $self->_tz_time( $self->epoch );

    sprintf '%04d-%02d-%02d %02d:%02d:%02d'
        , $time->[5], $time->[4], $time->[3]
        , $time->[2], $time->[1], $time->[0];
}

sub datetime_str
{
    my $self = shift;

    scalar $self->_tz_time_str( $self->epoch );
}

##
## OBJECT METHODS
##

sub set_epoch { $_[0]->{epoch} = $_[1]; }

##
## CLASS PROPERTIES
##

sub use_local_tz { $use_local_tz = 1; }
sub use_utc_tz   { $use_local_tz = 0; }

##
## PROTECTED PROPERTIES
##

sub _tz_time
{
    my $class = shift;
    my $time  = shift;
    my @time  = $use_local_tz ? localtime $time : gmtime $time;

    $time[4] ++;
    $time[5] += 1900;

    return \@time;
}

sub _tz_time_str
{
    my $class = shift;
    my $time  = shift;

    return $use_local_tz ? localtime $time : gmtime $time;
}

sub _check_args
{
    my @arg = $_[2] ? ( $_[1], $_[0] ) : @_;
    my $err = undef;

    if( ! UNIVERSAL::isa( $arg[0], 'ORM::Date' ) )
    {
        $err = "First arg must be an 'ORM::Date' instance.";
    }
    elsif( ! UNIVERSAL::isa( $arg[1], 'ORM::Date' ) )
    {
        $err = "Second arg must be an 'ORM::Date' instance.";
    }

    $err;
}

1;
