package POE::XUL::State;
# $Id: State.pm 1566 2010-11-03 03:13:32Z fil $
# Copyright Philip Gwyn 2007-2010.  All rights reserved.
# Based on code Copyright 2003-2004 Ran Eilam. All rights reserved.

#
# ROLE: Track all the changes to a node so they may be sent to the browser.
# All normal responses are generated here, either by ->flush.  Or in
# some cases calling the make_command directly.
#
# {buffer} is list of attribute key/value pairs set on state since last flush
# {is_new} is true if we have never been flushed before
# {is_destroyed} true after node has been destroyed
#

use strict;
use warnings;

use Scalar::Util qw( blessed );
use Carp;

use constant DEBUG => 0;

our $VERSION = '0.0601';
our $ID = 0;


##############################################################
sub new 
{ 
    my( $package, $node ) = @_;
    my $self = bless {
            buffer => [], 
            deferred_buffer => [], 
            is_new => 1, 
            is_destroyed => 0, 
            is_textnode => 0
        }, $package;

    my $id;
    if( blessed $node and $node->can( 'getAttribute' ) and
                     $node->getAttribute( 'id' ) ) {
        $id = $node->getAttribute( 'id' );
    }
    else {
        $id = 'PX' . $ID++;
        if( $node ) {
            # set the nodes attribute to the generated ID
            # 2008/10 do NOT use setAttribute, it will call the CM which will
            # try to build a new State.  Infinite recursion.
            $node->{attributes}{id} ||= $id;
        }
    }
    $self->{orig_id} = $self->{id} = $id;

    return $self;
}

##############################################################
sub flush 
{
	my( $self ) = @_;
	my @out = $self->as_command;
	$self->{is_new} = 0;
    $self->{index} = delete $self->{trueindex} if defined $self->{trueindex};
	$self->clear_buffer;
	return @out;
}

# command building ------------------------------------------------------------

sub as_command {
	my $self = shift;

	my $is_new       = $self->{is_new};
	my $is_destroyed = $self->{is_destroyed};

    # TODO: this is probably a bad idea
	return if $is_new && $is_destroyed;

    if( $is_destroyed ) {
        return $self->get_buffer_as_commands;
    }
    elsif( $self->is_textnode ) {
        return $self->make_command_textnode;
    }
    elsif( $self->{cdata} ) {
    	return unless $self->{is_new};
        return $self->make_command_cdata;
    }
    else {
        return $self->make_command_new, $self->get_buffer_as_commands;
    }
}

sub as_deferred_command {
	my $self = shift;

	my $is_new       = $self->{is_new};
	my $is_destroyed = $self->{is_destroyed};

    # TODO: this is probably a bad idea
	return if $is_destroyed;
    return $self->get_buffer_as_deferred_commands;
}

##############################################################
sub make_command_new 
{
	my( $self ) = @_;
	return unless $self->{is_new};
    # return unless $self->get_tag;
    
	my @cmd = ( 'new', 
                $self->{orig_id}, 
                $self->get_tag, 
                ( $self->get_parent_id || '' )
              );
    if( exists $self->{index} ) {
        push @cmd, $self->{index};
    }

    delete $self->{orig_id};

    return \@cmd;
}

##############################################################
sub make_command_bye 
{
	my( $self, $parent_id, $index ) = @_;
    return [ bye => $self->{id} ] #, $parent_id, $index ];
}

##############################################################
sub make_command_textnode
{
	my( $self ) = @_;
    return unless $self->{buffer} and $self->{buffer}[-1];
    my $ret = [ 'textnode',
                $self->get_parent_id, 
                $self->{index},
                $self->{buffer}[-1][-1]
              ];
    return $ret;
}

##############################################################
sub make_command_textnode_bye 
{
	my( $self, $parent_id, $index ) = @_;
    return [ 'bye-textnode', $parent_id, $index ];
}

##############################################################
sub make_command_cdata
{
	my( $self ) = @_;
    # use Data::Dumper;
    # warn Dumper $self->{buffer};
    my $ret = [ 'cdata',
                $self->get_parent_id, 
                $self->{index},
                $self->{cdata}
              ];
    return $ret;
}

##############################################################
sub make_command_cdata_bye 
{
	my( $self, $parent_id, $index ) = @_;
    return [ 'bye-cdata', $parent_id, $index ];
}


##############################################################
sub make_command_SID
{
    my( $package, $SID ) = @_;
    return [ 'SID', $SID ];
}

##############################################################
sub make_command_boot
{
    my( $package, $msg ) = @_;
    return [ 'boot', $msg ];
}

#############################################################
sub make_command_set 
{
	my($self, $key, $value) = @_;

    return [ 'set', $self->{id}, $key, $value ];
}

#############################################################
sub make_command_method
{
	my($self, $key, $args) = @_;

    return [ 'method', $self->{id}, $key, $args ];
}

#############################################################
sub make_command_style
{
	my($self, $property, $value) = @_;

    $property =~ s/-([a-z])/\U$1/g;
    return [ 'style', $self->{id}, $property, $value ];
}

#############################################################
sub make_command_remove
{
	my($self, $key) = @_;
    return [ 'remove', $self->{id}, $key ];
}



#############################################################
sub get_buffer_as_commands 
{
	my( $self ) = @_;
    return $self->get_buffer;
}

#############################################################
sub get_buffer_as_deferred_commands 
{
	my( $self ) = @_;

    # Just in case the ID changed since the command was added 
    # to the deferred buffer
    foreach my $cmd ( $self->get_deferred_buffer ) {
        $cmd->[1] = $self->{id};
    }
    return $self->get_deferred_buffer;
}

sub set_trueindex
{
    my( $self, $index ) = @_;

    $self->{trueindex} = $index;
}


#############################################################
sub set_attribute 
{ 
    my( $self, $key, $value ) = @_;
    if( $key eq 'id' and ($self->{orig_id}||'' ) eq $value ) {
        return;
    }
    my $cmd = $self->make_command_set( $key, $value );
    if( $key eq 'selectedIndex' ) {
        push @{ $self->{deferred_buffer} }, $cmd;
    }
    else {
        push @{$self->{buffer}}, $cmd;
    }
    return;
}

#############################################################
sub remove_attribute 
{ 
    my( $self, $key ) = @_;

    push @{$self->{buffer}}, $self->make_command_remove( $key );
    return;
}

#############################################################
sub method_call
{ 
    my( $self, $key, $args ) = @_;
    push @{$self->{buffer}}, $self->make_command_method( $key, $args );
    return;
}

#############################################################
sub style_change
{
    my( $self, $property, $value ) = @_;
    push @{$self->{buffer}}, $self->make_command_style( $property, $value );
    return;
}

#############################################################
sub is_destroyed  
{ 
    my( $self, $parent, $index ) = @_;
    $self->{is_destroyed} = 1;

    my $cmd;
    if( $self->{is_textnode} ) {
        $cmd = $self->make_command_textnode_bye( $parent->id, $index );
    }
    else {
        $cmd = $self->make_command_bye( $parent->id, $index );
    }
    # 2007/05 -- If the node disapears, we want to skip all other commands
    # that might be sent.  However, there might be a case were a commands
    # side effects are desired, so we are pushing.  However that breaks when
    # something is a "late" command.
    push @{ $self->{buffer} }, $cmd;
    return;
}

#############################################################
sub dispose
{
    my( $self ) = @_;
    $self->clear_buffer;
}

# accessors -------------------------------------------------------------------

sub get_id        { $_[0]->{id}           }
sub id            { $_[0]->{id}           }
sub get_tag       { $_[0]->{tag}          }
sub is_new        { $_[0]->{is_new}       }
sub get_buffer    { @{$_[0]->{buffer}}    }
sub get_deferred_buffer { @{ $_[0]->{deferred_buffer} } }
sub is_textnode   { $_[0]->{is_textnode}  }
sub get_parent_id { 
    my( $self ) = @_;
    return unless $self->{parent};
    $self->{parent}->id;
}

# modifiers -------------------------------------------------------------------

sub set_id        { delete $_[0]->{default_id}; $_[0]->{id}           = $_[1]           }
sub set_tag       { $_[0]->{tag}          = lc $_[1]        }
sub set_old       { $_[0]->{is_new}       = 0               }
sub set_index     { $_[0]->{index}        = $_[1]           }
sub clear_buffer  { $_[0]->{buffer}       = [];
                    $_[0]->{deferred_buffer} = [];          }
sub set_destroyed { $_[0]->{is_destroyed} = 1               }
sub set_textnode  { $_[0]->{is_textnode} = 1                }
# sub set_parent_id { $_[0]->{parent_id}    = $_[1]           }


1;
