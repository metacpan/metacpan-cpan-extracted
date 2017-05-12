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

use English;
use Cwd 'abs_path';
use ORM::Meta::ORM::History;

##
## CONSTRUCTORS
##

## use: $hist = $history_class->new
## (
##     obj     => ORM,
##     changed => { $prop1_name => [ $old_value, $new_value ], ... },
##     error   => ORM::Error,
## );
##
## use: $hist = $history_class->new
## (
##     obj     => ORM,
##     created => 1,
##     error   => ORM::Error,
## );
##
## use: $hist = $history_class->new
## (
##     obj     => ORM,
##     deleted => 1,
##     error   => ORM::Error,
## );
##
sub new
{
    my $class = shift;
    my %arg   = @_;
    my %prop  = defined $arg{prop} ? %{$arg{prop}} : ();
    my $error = ORM::Error->new;
    my @record;

    # Define common properties
    delete $arg{prop};

    $prop{obj_class} = ref $arg{obj};
    $prop{obj_id}    = $arg{obj}->id;
    $prop{date}      = time;

    if( $::ENV{REQUEST_URI} )
    {
        $prop{editor} =
            "WWW: " .
            $::ENV{REMOTE_USER} . '@' . $::ENV{SERVER_NAME} . ':' .
            $::ENV{SERVER_PORT} . $::ENV{REQUEST_URI} .
            ", RemoteIP: " . $::ENV{REMOTE_ADDR};
    }
    else
    {
        my $exec;
        $exec = abs_path( $0 ) unless( $OSNAME eq 'MSWin32' );
        $prop{editor} = "Exec[$PID]: $exec, UID: ${UID}:".(int $GID).", EUID: ${EUID}:".(int $EGID);
    }

    # Define operation related properties and create objects
    if( $arg{created} )
    {
        $prop{slaved_by} = undef;
        $prop{prop_name} = 'id';
        $prop{old_value} = undef;
        $prop{new_value} = $arg{obj}->id;
        push @record, $class->SUPER::new( prop=>\%prop, error=>$error );
    }
    elsif( $arg{deleted} )
    {
        $prop{slaved_by} = undef;
        $prop{prop_name} = 'id';
        $prop{old_value} = $arg{obj}->id;
        $prop{new_value} = undef;
        $prop{slaved_by} = $class->SUPER::new( prop=>\%prop, error=>$error );
        push @record, $prop{slaved_by};

        for my $prop ( (ref $arg{obj})->_not_mandatory_props )
        {
            if( $error->fatal )
            {
                last;
            }
            else
            {
                $prop{prop_name} = $prop;
                $prop{old_value} = $arg{obj}{_ORM_data}{$prop};
                $prop{new_value} = undef;
                push @record, $class->SUPER::new( prop=>\%prop, error=>$error );
            }
        }
    }
    else
    {
        $prop{slaved_by} = undef;
        for my $prop ( keys %{$arg{changed}} )
        {
            my $record;
            if( $error->fatal )
            {
                last;
            }
            else
            {
                $prop{prop_name} = $prop;
                $prop{old_value} = $arg{changed}{$prop}[0];
                $prop{new_value} = $arg{changed}{$prop}[1];

                $record          = $class->SUPER::new( prop=>\%prop, %arg );
                $prop{slaved_by} = $record unless( $prop{slaved_by} );
                push @record, $record;
            }
        }
    }

    # Rollback creation of history object if error occured
    if( $error->fatal )
    {
        while( my $record = pop @record )
        {
            $record->SUPER::delete( error=>$error ) if( defined $record );
        }
    }

    $error->upto( $arg{error} );
    return $record[0];
}

##
## PROPERTIES
##

sub obj
{
    my $self = shift;

    unless( $self->{obj} )
    {
        $self->_load_ORM_class( $self->obj_class );
        $self->{obj} = $self->obj_class->find_id( id=>$self->obj_id );
    }

    return $self->{obj};
}

sub master { ! $_[0]->slaved_by; }

##
## METHODS
##

sub update
{
    my $self = shift;
    my %arg  = @_;

    $arg{error} && $arg{error}->add_fatal( "Updates of history have no sense" );
}

sub delete
{
    my $self  = shift;
    my $class = ref $self;

    if( $self->slaved_by )
    {
        $arg{error}->add_fatal( "You should not delete slaved objects, delete master instead" );
    }
    else
    {
        my @slave = $class->find
        (
            filter => ( $class->M->slaved_by == $self ),
            error  => $error,
        );
        for my $slave ( @slave )
        {
            $slave->delete( @_ );
        }
        $self->SUPER::delete( @_ );
    }
}

sub rollback
{
    my $self  = shift;
    my $class = ref $self;
    my %arg   = @_;

    if( $self->slaved_by )
    {
        $arg{error}->add_fatal
        (
            "You should not rollback slaved object, rollback its master instead"
        );
    }
    else
    {
        my $error = ORM::Error->new;
        my $obj;
        my @slave;

        # Case of created object
        if( $self->prop_name eq 'id' && $self->old_value == undef )
        {
            $obj = $self->obj_class->find_id( id=>$self->obj_id, error=>$error );
            if( $obj )
            {
                $obj->delete( error=>$error, history=>0 );
            }
            else
            {
                $error->add_fatal
                (
                    "Can't rollback creation of object #" . $self->obj_id
                    . " of class '".$self->obj_class."' because it doesn't exist"
                );
            }
        }
        # Case of deleted object
        elsif( $self->prop_name eq 'id' && $self->new_value == undef )
        {
            @slave = $class->find
            (
                filter => ( $class->M->slaved_by == $self ),
                error  => $error,
            );
            unless( $error->fatal )
            {
                my %prop;
                for my $slave ( @slave )
                {
                    $prop{$slave->prop_name} = $slave->old_value;
                }
                $obj = $self->obj_class->new
                (
                    prop      => \%prop,
                    repair_id => $self->old_value,
                    error     => $error,
                    history   => 0,
                );
            }
        }
        # Case of changed object
        else
        {
            $obj = $self->obj_class->find_id( id=>$self->obj_id, error=>$error );
            if( $obj )
            {
                @slave = $class->find
                (
                    filter => ( $class->M->slaved_by == $self ),
                    error  => $error,
                );
                unless( $error->fatal )
                {
                    my %prop;
                    my %old_prop;
                    for my $slave ( $self, @slave )
                    {
                        $prop{$slave->prop_name}     = $slave->old_value;
                        $old_prop{$slave->prop_name} = $slave->new_value;
                    }
                    $obj->update
                    (
                        prop     => \%prop,
                        old_prop => \%old_prop,
                        error    => $error,
                        history  => 0,
                    );
                }
            }
            else
            {
                $error->add_fatal
                (
                    "Can't rollback update of object #" . $self->obj_id
                    . " of class '".$self->obj_class."' because it doesn't exist"
                );
            }
        }

        unless( $error->fatal )
        {
            $self->delete( error=>$error );
        }

        $error->upto( $arg{error} );
    }
}

sub metaprop_class { 'ORM::Meta::ORM::History'; }
