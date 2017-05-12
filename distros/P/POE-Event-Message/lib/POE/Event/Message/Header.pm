# -*- Perl -*-
#
# File:  POE/Event/Message/Header.pm
# Desc:  A generic network message header class to use as a starting point. 
# Date:  Mon Oct 10 10:10:59 2005
# Stat:  Prototype, Experimental
#      
package POE::Event::Message::Header;
use 5.006;
use strict;
use warnings;

our $PACK    = __PACKAGE__;
our $VERSION = '0.04';
### @ISA     = qw( );

### POE::Kernel;                      ## Don't use POE here!
use POE::Event::Message::UniqueID;

my $IdClass = "POE::Event::Message::UniqueID";

sub new
{   my($self,$hRef) = @_;

    $self = bless {}, ref($self)||$self;

    if ($hRef and $hRef =~ /HASH/) {
	foreach (keys %$hRef) { $self->{$_} = $hRef->{$_} }

	$self->set('r2id', $self->id() ||0 )   unless $self->r2id();

    } else {

	# $self->set('r2id', undef );         # InResponseTo message id
	# $self->set('ttl',  undef );         # message TimeToLive
	# $self->set('type', undef );         # message type
    }

    $self->set('id', $IdClass->generate() );  # guaranteed unique message id

    return $self;
}

sub set    { $_[0]->{$_[1]}=$_[2]         }   # Note that the 'param' method
sub get    { return( $_[0]->{$_[1]}||"" ) }   #    combines 'set' and 'get'
sub param  { $_[2] ? $_[0]->{$_[1]}=$_[2] : return( $_[0]->{$_[1]}||"" )  }
sub setErr { return( $_[0]->{STATUS}=$_[1]||0, $_[0]->{ERROR}=$_[2]||"" ) }
sub status { return( $_[0]->{STATUS}||0, $_[0]->{ERROR}||"" )             }
sub stat   { ( wantarray ? ($_[0]->{ERROR}||"") : ($_[0]->{STATUS} ||0) ) }
sub err    { return($_[0]->{ERROR}||"")                                   }
sub del    { delete $_[0]->{$_[1]} }

*delete = \&del;
*reset  = \&del;

sub id     { $_[0]->get('id')            }    # unique message ID
sub r2id   { $_[0]->get('r2id')          }    # orig. msg ID, in a response
sub ttl    { $_[0]->param('ttl',  $_[1]) }    # message time-to-live
sub type   { $_[0]->param('type', $_[1]) }    # message type  (reply | bcast)
sub mode   { $_[0]->param('mode', $_[1]) }    # response mode (post | call)

*rid       = \&r2id;
*origId    = \&r2id;

*setType   = \&type;     # Type:  reply or bcast  (default: reply)
*getType   = \&type;     # Type:  reply or bcast  (default: reply)

*setMode   = \&mode;     # Mode:  post  or call   (default: post)
*getMode   = \&mode;     # Mode:  post  or call   (default: post)

#-----------------------------------------------------------------------
# Self routing messages without CODE refs, suitable for Filtering.
# Keep first implementation simple (if you call allowing multiple 
# "RouteBack" destinations simple :-), and anticipate extensions.
# 
#   $message->header->addRouteBack( $mode, $service, $event, @args );
#
#      $mode defaults to "post",
#      $service defaults to "current_active",
#      and "initial state" @args are optionsl

# NOTE: these are LIFO stacks, and are "pushed" when "add" methods are
# used and "popped" when "del" methods are used. See the "Message"
# class for the various methods that make use of these stacks.

sub addRouteTo         { shift->_addRouting( "RouteTo",   undef, undef, @_ ) }
sub addRouteBack       { shift->_addRouting( "RouteBack", undef, undef, @_ ) }
sub addRemoteRouteTo   { shift->_addRouting( "RouteTo",   @_               ) }
sub addRemoteRouteBack { shift->_addRouting( "RouteBack", @_               ) }

sub _addRouting
{   my($self, $type, $host, $port, $mode, $service, $event, @args) = @_;

    if ($type !~ /^Route(To|Back)$/) {
	return $self->setErr(-1, "unknown 'type' ($type) in 'addRouting' method of '$PACK'");

    }

    $host ||= "";
    $port ||= "";
  # $mode ||= "post";
  ( $mode = $self->mode() || "post" ) unless ( $mode );

    if ($host and $port) {
	$service ||= "command";
	$event   ||= "dispatch";

    } elsif (! $service ) {
	if (! defined $INC{'POE/Kernel.pm'}) {
	    return $self->setErr(-1, "'POE::Kernel' module is not loaded in 'addRouteBack' method of '$PACK'");

	} else {
	    $service = POE::Kernel->get_active_session()->ID();
	}
    }

    ## warn "DEBUG: _addRouting: type='$type' mode='$mode' service='$service' event='$event'\n";

    if  (! ($service and $event) ) {
	return $self->setErr(-1, "missing 'service' and/or 'event' argument in 'addRouting' method of '$PACK'");
    }

    unshift @{ $self->{$type} }, [ $host,$port, $mode,$service,$event,@args ];
    return;
}

*unshiftRouteTo   = \&addRouteTo;       # add a RouteTo
*shiftRouteTo     = \&delRouteTo;       # del a RouteTo

*unshiftRouteBack = \&addRouteBack;     # add a RouteBack
*shiftRouteBack   = \&delRouteBack;     # del a Routeback

# FIX: syntax for "delRoute*" is clumsy when the lists are empty.

sub delRouteTo   { @{ (shift @{ $_[0]->{RouteTo}   } ||[]) } }
sub delRouteBack { @{ (shift @{ $_[0]->{RouteBack} } ||[]) } }

sub hasRouting   { ( ($_[0]->hasRouteTo()) || ($_[0]->hasRouteBack()) ) }

*getRouting   = \&hasRouting;
*getRouteTo   = \&hasRouteTo;
*getRouteBack = \&hasRouteBack;

sub hasRouteTo
{   my($self, $type) = @_;
    return undef  unless (defined $self->{"RouteTo"});
    return( $self->{'RouteTo'}->[ 0 ] );
}

sub hasRouteBack
{   my($self) = @_;
    return undef unless (defined $self->{"RouteBack"});
    return( $self->{'RouteBack'}->[ 0 ] );
}

sub nextRouteType
{   my($self) = @_;

    my $nextRoute = $self->hasRouteTo() || $self->hasRouteBack();

    return "remote" if ($nextRoute->[0] and $nextRoute->[1]);
    return ""       unless $nextRoute->[2];
    return "post"   if ($nextRoute->[2] =~ /^post/i);
    return "call"   if ($nextRoute->[2] =~ /^call/i);
    return "";
}

sub nextRouteIsRemote { ($_[0]->nextRouteType() eq "remote"      ? 1 : 0) }
sub nextRouteIsLocal  { ($_[0]->nextRouteType() =~ /(post|call)/ ? 1 : 0) }
sub nextRouteIsPost   { ($_[0]->nextRouteType() eq "post"        ? 1 : 0) }
sub nextRouteIsCall   { ($_[0]->nextRouteType() eq "call"        ? 1 : 0) }

#-----------------------------------------------------------------------

sub dump {
    my($self,$nohead)= @_;
    my($pack,$file,$line)=caller();
    my $text = "";
    unless ($nohead) {
	$text .= "DEBUG: ($PACK\:\:dump)\n  self='$self'\n";
	$text .= "CALLER $pack at line $line\n  ($file)\n";
    }
    my $value;
    foreach my $param (sort keys %$self) {
	$value = $self->{$param};
	$value = $self->zeroStr( $value, "" );  # handles value of "0"
	$text .= " $param = $value\n";
	# Kinda kludgy, might wanna fix this next bit.
	if ($param =~ /^Route(To|Back)$/) {
	    my $arrow = ( $param eq "RouteTo" ? "-->" : "<--" );
	    if (! @$value) {
		$text .= "  $arrow ((empty list))\n";
	        next;
	    }
	    foreach my $route (@$value) {
		$text .= "  $arrow '";
		foreach my $arg (@$route) {
		    $text .= ( $arg ? "$arg', '" : "', '" );
		}
		chop($text); chop($text); chop($text);
	    }
	    $text .= "\n"  
	}
    }
    $text .= "_" x 25 ."\n";
    return($text);
}

sub zeroStr
{   my($self,$value,$undef) = @_;
    return $undef unless defined $value;
    return "0"    if (length($value) and ! $value);
    return $value;
}
#_________________________
1; # Required by require()

__END__

=head1 NAME

POE::Event::Message::Header - Generic messaging protocol header

=head1 VERSION

This document describes version 0.02, released November, 2005.

=head1 SYNOPSIS

 use POE::Event::Message::Header;

 $header = new POE::Event::Message::Header;
 $header = new POE::Event::Message::Header( $priorHeader );

 $header->set( $attrName, $newValue );

 $value = $header->get( $attrName );

 $header->del( $attrName );

 $id = $header->id();
 $r2id = $header->r2id();

 $header->addRouteTo( Args );
 $header->addRouteBack( Args );

 $route = $header->delRouteTo( );       # delete and return next
 $route = $header->delRouteBack( );     # delete and return next

 $route = $header->hasRouting();        # retain and return next
 $route = $header->hasRouteTo();        # retain and return next
 $route = $header->hasRouteBack();      # retain and return next

 $next = $header->nextRouteType();      # post, call, remote or ''
 $bool = $header->nextRouteIsRemote();  # 1 if remote    or 0 if not
 $bool = $header->nextRouteIsLocal();   # 1 if post|call or 0
 $bool = $header->nextRouteIsPost();    # 1 if post      or 0
 $bool = $header->nextRouteIsCall();    # 1 if call      or 0

 print $header->dump();


=head1 DESCRIPTION

This class is not intended for direct use. Objects of this class are 
manipulated via the message envelope objects of the 'POE::Event::Message'
class.

This class is a starting point for creating a generic application
messaging protocol headers. The intent is for this to be used as a 
starting point when building network client/server applications.

Messages headers of this class have flexible routing capabilities that 
work both inside and outside of POE-based applications. Message objects
can contain complex Perl data structures.

=head2 Constructor

=over 4

=item new ( [ Header ] )

This method instantiates a new message header. Optionally it
can be used to create a response to an existing message. 

=over 4

=item Header

The optional B<Header> argument, when included, is expected
to be an original message of this class. This mechanism is
used to create a 'response' to the original message.

=back

=back


=head2 Methods

=over 4

=item set ( Attr, NewValue )

=item get ( Attr )

=item del ( Attr )

Store, retrieve or delete header attributes.

=over 4

=item Attr

The B<Attr> argument names the header attribute to be accessed
or modified.

=item NewValue

When calling the B<set> method, this is the new value for the named
attribute.

=back


=item addRouteTo ( Mode, Service, Event [, Args ] )

=item addRouteBack ( Mode, Service, Event [, Args ] )

=over 4

These methods add B<auto-routing> capabilities to messages that
use this class. For a discussion of arguments and usage, see
L<POE::Event::Message>.

=back


=item dump

This method is included for convenience when developing or debugging
applications that use this class. This does not produce a 'pretty'
output, but is formatted to show the contents of the message object
and the message header object, when one exists.

=back

=head1 DEPENDENCIES

This class depends upon the following classes:

 POE::Event::Message::UniqueID

=head1 INHERITANCE

None currently.

=head1 SEE ALSO

See
 L<POE::Event::Message::Header> and
 L<POE::Event::Message::UniqueID>.

=head1 AUTHOR

Chris Cobb [no dot spam at ccobb dot net]

=head1 COPYRIGHT

Copyright (c) 2005-2010 by Chris Cobb, All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
