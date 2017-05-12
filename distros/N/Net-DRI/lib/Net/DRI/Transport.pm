## Domain Registry Interface, Superclass of all Transport/* modules (hence virtual class, never used directly)
##
## Copyright (c) 2005-2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::Transport;

use strict;
use warnings;

use base qw(Class::Accessor::Chained::Fast Net::DRI::BaseClass);
__PACKAGE__->mk_accessors(qw/name version retry pause trace timeout defer current_state has_state is_sync time_creation time_open time_used trid_factory logging/);

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.20 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Transport - Superclass of all Transport Modules in Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

This is a superclass that should never be used directly, but only through its subclasses.

=head1 METHODS

During the new() call, subclasses will call this new() method, which expects a ref hash with some
keys (other are handled by the subclasses), among which:

=head2 defer

do we open the connection right now (0) or later (1)

=head2 timeout

time to wait (in seconds) for server reply (default 60)

=head2 retry

number of times we try to send the message to the registry (default 2)

=head2 trid

(optional) code reference of a subroutine generating a transaction id when passed a name ; 
if not defined, $dri->trid_factory() is used, which is Net::DRI::Util::create_trid_1 by default

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005-2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################
sub new
{
 my ($class,$ctx,$ropts)=@_;
 my $ndr=$ctx->{registry};
 my $pname=$ctx->{profile};

 my $self={
 	   is_sync   => exists($ropts->{is_sync})? $ropts->{is_sync} : 1, ## do we need to wait for reply as soon as command sent ?
           retry     => exists($ropts->{retry})?   $ropts->{retry}   : 2,  ## by default, we will try once only
           pause     => exists($ropts->{pause})?   $ropts->{pause}   : 10, ## time in seconds to wait between two retries
#           trace     => exists($ropts->{trace})?   $ropts->{trace}   : 0, ## NOT IMPL
           timeout   => exists($ropts->{timeout})? $ropts->{timeout} : 60,
           defer     => exists($ropts->{defer})?   $ropts->{defer}   : 0, ## defer opening connection as long as possible (irrelevant if stateless) ## XX maybe not here, too low
           logging   => exists($ropts->{logging})? $ropts->{logging} : $ndr->logging(),
           trid_factory => (exists($ropts->{trid}) && (ref($ropts->{trid}) eq 'CODE'))? $ropts->{trid} : $ndr->trid_factory(),
           current_state => undef, ## for stateless transport, otherwise 0=close, 1=open
           has_state     => undef, ## do we need to open a session before sending commands ?
           transport     => undef, ## will be defined in subclasses
           time_creation => time(),
           logging_ctx => { registry => $ndr->name(), profile => $pname, protocol => $ctx->{protocol}->name() },
          };

 if (exists($ropts->{log_fh}) && defined($ropts->{log_fh}))
 {
  print STDERR 'log_fh is deprecated and will not be used now, please use new Logging framework',"\n";
 }

 bless $self,$class;
 $self->log_setup_channel($class,'transport',$self->{logging_ctx}); ## if we need the transport name here, we will have to put that further below, in another method called after new() ; otherwise we derive it from $class
 $self->log_output('debug','core',sprintf('Added transport %s for registry %s',$class,$ndr->name()));
 return $self;
}

sub transport_data { my ($self,$data)=@_; return defined $data ? $self->{transport}->{$data} : $self->{transport}; }

sub log_output
{
 my ($self,$level,$type,$data1,$data2)=@_;
 return $self->logging()->output($level,$type,$data1) unless defined $data2;
 $self->{logging_ctx}->{transport}=$self->name().'/'.$self->version() unless exists $self->{logging_ctx}->{transport};
 return $self->logging()->output($level,$type,{ %{$self->{logging_ctx}}, %$data1, %$data2 });
}

sub send
{
 my ($self,$ctx,$tosend,$cb1,$cb2,$count)=@_; ## $cb1=how to send, $cb2=how to test if fatal (to break loop) or not (retry once more)
 Net::DRI::Exception::err_insufficient_parameters() unless ($cb1 && (ref($cb1) eq 'CODE'));
 my $ok=0;

 ## Try to reconnect if needed
 $self->open_connection($ctx) if ($self->has_state() && !$self->current_state());
 ## Here $tosend is a Net::DRI::Protocol::Message object (in fact, a subclass of that), in perl internal encoding, no transport related data (such as EPP 4 bytes header)
 $self->log_output('notice','transport',$ctx,{phase=>'active',direction=>'out',message=>$tosend});
 $ok=$self->$cb1($count,$tosend,$ctx);
 $self->time_used(time());

 Net::DRI::Exception->die(0,'transport',4,'Unable to send message to registry') unless $ok;
}

sub receive
{
 my ($self,$ctx,$cb1,$cb2,$count)=@_;
 Net::DRI::Exception::err_insufficient_parameters() unless ($cb1 && (ref($cb1) eq 'CODE'));

 my $ans;
 $ans=$self->$cb1($count,$ctx); ## a Net::DRI::Data::Raw object
 Net::DRI::Exception->die(0,'transport',5,'Unable to receive message from registry') unless defined($ans);
 ## $ans should have been properly decoded into a native Perl string
 $self->log_output('notice','transport',$ctx,{phase=>'active',direction=>'in',message=>$ans});
 return $ans;
}

sub try_again ## TO BE SUBCLASSED
{
 my ($self,$ctx,$po,$err,$count,$istimeout,$step,$rpause,$rtimeout)=@_; ## $step is 0 before send, 1 after, and 2 after receive successful
 ## Should return 1 if we try again, or 0 if we should stop processing now
 return ($istimeout && ($count <= $self->{retry}))? 1 : 0;
}

sub open_connection
{
 my ($self,$ctx)=@_;
 return unless $self->has_state();
 Net::DRI::Exception::err_method_not_implemented();
}

sub end
{
 my ($self)=@_;
 return unless $self->has_state();
 Net::DRI::Exception::err_method_not_implemented();
}

####################################################################################################
## Returns 1 if we are still connected, 0 otherwise (and sets current_state to 0)
## Pass a true value if you want the connection to be automatically redone if the ping failed
sub ping
{
 my ($self,$autorecon)=@_;
 return unless $self->has_state();
 Net::DRI::Exception::err_method_not_implemented();
}

####################################################################################################
1;
