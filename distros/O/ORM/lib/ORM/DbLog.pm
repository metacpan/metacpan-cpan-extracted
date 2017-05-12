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

package ORM::DbLog;

$VERSION=0.8;

use ORM::Date;

my $STDERR;
my $STDOUT;
my $FILE;
my $MEM_LOG_SIZE = 0;
my @MEM_LOG;

##
## CONSTRUCTOR
##

sub new
{
    my $class = shift;
    my %arg   = @_;
    my $self;
    my $caller;

    for( my $i=1; ; $i++ )
    {
        $caller = (caller $i )[3];
        last if( ! defined $caller || ( substr $caller, 0, 9 ) ne 'ORM::Db::' );
    }

    $self->{sql}    = $arg{sql};
    $self->{error}  = $arg{error};
    $self->{date}   = ORM::Datetime->current;
    $self->{caller} = $caller;

    bless $self, $class;

    $class->_push_to_memory_log( $self );

    if( $class->write_to_stderr )
    {
        print STDERR $self->text;
    }

    if( $class->write_to_stdout )
    {
        print $self->text;
    }

    if( $class->write_to_file )
    {
        $class->write_to_file->print( $self->text );
    }

    return $self;
}

##
## OBJECT PROPERTIES
##

sub sql    { $_[0]->{sql}; }
sub error  { $_[0]->{error}; }
sub date   { $_[0]->{date}; }
sub caller { $_[0]->{caller}; }

sub text
{
    my $self = shift;
    my $str;

    $str .= "--------------------------\n";
    $str .= '['.$self->date->datetime_str.']: '.$self->caller.': '.( $self->error ? 'FAILED' : 'Success' )."\n";
    $str .= $self->sql . "\n";
    $str .= 'ERROR: ' . $self->error if( $self->error );
    $str .= "\n";

    return $str;
}

##
## CLASS METHODS
##

sub write_to_stderr
{
    my $class  = shift;

    if( @_ ) { $STDERR = shift; }
    return $STDERR;
}

sub write_to_stdout
{
    my $class  = shift;

    if( @_ ) { $STDOUT = shift; }
    return $STDOUT;
}

sub write_to_file
{
    my $class  = shift;

    if( @_ ) { $FILE = shift; }
    return $FILE;
}

sub memory_log_size
{
    my $class = shift;

    if( @_ ) { $MEM_LOG_SIZE = shift; }
    return $MEM_LOG_SIZE;
}

sub memory_log_charge
{
    return scalar @MEM_LOG;
}

sub memory_log
{
    my $class = shift;
    my $index;

    return $MEM_LOG[$index];
}

sub _push_to_memory_log
{
    my $class = shift;
    my $log   = shift;

    if( $class->memory_log_size )
    {
        if( $class->memory_log_charge >= $class->memory_log_size )
        {
            shift @MEM_LOG;
        }
        push @MEM_LOG, $log;
    }
}

1;
