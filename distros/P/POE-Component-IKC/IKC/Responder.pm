package POE::Component::IKC::Responder;

############################################################
# $Id: Responder.pm 1248 2014-07-07 09:06:58Z fil $
# Based on tests/refserver.perl
# Contributed by Artur Bergman <artur@vogon-solutions.com>
# Revised for 0.06 by Rocco Caputo <troc@netrus.net>
# Turned into a module by Philp Gwyn <fil@pied.nu>
#
# Copyright 1999-2014 Philip Gwyn.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Contributed portions of IKC may be copyright by their respective
# contributors.  

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $ikc);
use Carp;
use Data::Dump qw( pp );

use POE qw(Session);
use POE::Component::IKC::Specifier;
use POE::Component::IKC::Timing;
use Scalar::Util qw(reftype);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(create_ikc_responder $ikc);
$VERSION = '0.2402';

sub DEBUG { 0 }

##############################################################################

#----------------------------------------------------
# This is just a convenient way to create only one responder.
sub create_ikc_responder 
{
    carp "create_ikc_responder is deprecated.  Use ", __PACKAGE__, "->spawn instead";
    __PACKAGE__->spawn();
}

sub spawn
{
    my($package)=@_;
    return 1 if $ikc;
    POE::Session->create( 
        package_states => [
            $package, [qw(
                      _start _stop _child
                      request post call raw_message post2
                      remote_error channel_error
                      register unregister register_local register_channel
                      default
                      publish retract subscribe unsubscribe
                      published
                      monitor inform_monitors shutdown 
                      do_you_have ping sig_INT
                    )]
        ]);
    return 1;
}



#----------------------------------------------------
# Accept POE's standard _start message, and start the responder.
sub _start
{
    my($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
    DEBUG and warn "$$: Responder started.\n";
    $kernel->alias_set('IKC');              # allow it to be called by name

#    $kernel->signal(INT=>'sig_INT');  # sig_INT is empty, so don't bother
    $ikc=POE::Component::IKC::Responder::Object->new($kernel, $session);
    $heap->{self}=$ikc;
}


sub _stop
{
    DEBUG and 
        warn "$$: $_[HEAP] responder _stop\n";
    # use YAML qw(Dump);
    # use Data::Denter;
    # warn Denter $poe_kernel;
}

sub _child
{
    my( $heap, $reason, $session, $ret ) = @_[ HEAP, ARG0, ARG1, ARG2 ];
    DEBUG and 
        warn "$$: $_[HEAP] responder _child $reason, $session\n";
}

#----------------------------------------------------
# Shutdown everything IKC related that we know about
sub shutdown
{
    my($kernel, $heap)=@_[KERNEL, HEAP];
    $heap->{self}->shutdown($kernel);
}

#----------------------------------------------------
# Foreign kernel called something here
sub request
{
    my($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];
    $heap->{self}->request($request);
}

#----------------------------------------------------
# Register foreign kernels so that we can send states to them
sub register
{
    my($heap, $channel, $rid, $aliases, $pid) = @_[HEAP, SENDER, ARG0..$#_];
    # warn "pid=$pid" if $pid;
    $heap->{self}->register($channel, $rid, $aliases, $pid);
}

#----------------------------------------------------
# Register new aliases for local kernel
sub register_local
{
    my($heap, $aliases) = @_[HEAP, ARG0];
    $heap->{self}->register_local($aliases);
}

#----------------------------------------------------
# Unregister foreign kernels when this disconnect (say)
sub unregister
{
    my($kernel, $heap, $channel, $rid, $aliases) = 
                                        @_[KERNEL, HEAP, SENDER, ARG0, ARG1];
    $heap->{self}->unregister($channel, $rid, $aliases);
}

#----------------------------------------------------
# Set a default foreign channel to send messages to
sub default
{
    my($heap, $name) = @_[HEAP, ARG0];
    $heap->{self}->default($name);
}

#----------------------------------------------------
# Register a channel.  So we can tell it to shutdown before it finishes
# negociating
sub register_channel
{
    my($heap, $channel) = @_[HEAP, SENDER];
    $heap->{self}->register_channel($channel);
}



##############################################################################
## This state allows sessions to monitor a remote kernel

#----------------------------------------------------
# Watch any activity regarding a foreign kernel
sub monitor
{
    my($heap, $name, $states, $sender) = @_[HEAP, ARG0, ARG1, SENDER];
    $heap->{self}->monitor($sender, $name, $states);
    return
}

##############################################################################
## These are the 4 states that interact with the foreign kernel

#----------------------------------------------------
# Send a request to the foreign kernel
sub post
{
    my($heap, $to, $params, $sender) = @_[HEAP, ARG0, ARG1, SENDER];
    $heap->{self}->post($to, $params, $sender);
}

#----------------------------------------------------
# Send a request to the foreign kernel
sub post2
{
    my($heap, $to, $sender, $params) = @_[HEAP, ARG0, ARG1, ARG2];
    $heap->{self}->post($to, $params, $sender);
}

#----------------------------------------------------
# Send a request to the foreign kernel and ask it to provide 
# the state's return value back
sub call
{
    my($kernel, $heap, $sender, $to, $params, $rsvp) = 
                    @_[KERNEL, HEAP, SENDER, ARG0, ARG1, ARG2];

    $heap->{self}->call($to, $params, $rsvp, $sender);
    return;
}

#----------------------------------------------------
# Send a raw message over.  use at your own risk :)
# This is useful for sending errors to remote ClientLite
sub raw_message
{
    my($heap, $msg, $sender) = @_[HEAP, ARG0, ARG1];
    $heap->{self}->send_msg($msg, $sender);
}

#----------------------------------------------------
# Remote kernel had an error 
sub remote_error
{
    my($heap, $msg) = @_[HEAP, ARG0];
    $heap->{self}->remote_error( $msg );
}

#----------------------------------------------------
# Local channel had an error
sub channel_error
{
    my($heap, $msg) = @_[HEAP, ARG0];
    return $heap->{self}->channel_error( $msg );
}




##############################################################################
# publish/retract/subscribe mechanism of setting up foreign sessions

#----------------------------------------------------
sub publish
{
    my($kernel, $heap, $sender, $session, $states)=
      @_[KERNEL, HEAP, SENDER,  ARG0,     ARG1];
    $session||=$sender;
    $heap->{self}->publish($session, $states);
}

#----------------------------------------------------
sub published
{
    my($kernel, $heap, $which)=@_[KERNEL, HEAP, ARG0];
    $heap->{self}->published($which);
}

#----------------------------------------------------
sub retract
{
    my($heap, $sender, $session, $states)=
        @_[HEAP, SENDER, ARG0, ARG1];

    $session||=$sender;
    $heap->{self}->retract($session, $states);
}


#----------------------------------------------------
sub subscribe
{
    my($kernel, $heap, $sender, $sessions, $callback)=
                @_[KERNEL, HEAP, SENDER, ARG0, ARG1];
    $sessions=[$sessions] unless ref $sessions;
    return unless @$sessions;

    $sender = $sender->ID if ref $sender;
    if($callback and 'CODE' ne ref $callback)
    {
        my $state=$callback;
        $callback=sub 
        {
            DEBUG and 
                warn "Subscription callback to '$state'\n";
            $kernel->post($sender, $state, @_);
        };
    }
    $heap->{self}->subscribe($sessions, $callback, $sender);
}

# Called by a foreign IKC session 
# We respond with the session, or with "NOT $specifier";
sub do_you_have
{
    my($kernel, $heap, $param)=@_[KERNEL, HEAP, ARG0];
    my $ses=specifier_parse($param->[0]);
    die "Bad state $param->[0]\n" unless $ses;

    my $self=$heap->{self};
    
    DEBUG and 
        warn "$$: Wants to subscribe to ", specifier_name($ses), "\n";
    if(exists $self->{'local'}{$ses->{session}} and
       (not $ses->{state} or 
        exists $self->{'local'}{$ses->{session}}{$ses->{state}}
       ))
    {
        $ses->{kernel}||=$kernel->ID;       # make sure we uniquely identify 
        DEBUG and 
            warn "$$: Allowed (we are $ses->{kernel})\n";
        return [$ses, $kernel->ID];         # this session
    } else
    {
        DEBUG and 
            warn "$$: ", specifier_name($ses), " is not published in this kernel\n";
        return "Refused subscription ".specifier_name($ses);
    }
}

#----------------------------------------------------
sub unsubscribe
{
    my($kernel, $heap, $sessions)=@_[KERNEL, HEAP, ARG0];
    $heap->{self}->unsubscribe($sessions);
}


#----------------------------------------------------
sub ping
{
    "PONG";
}

#----------------------------------------------------
# User wants to kill process / kernel
sub sig_INT
{
    my ($heap, $kernel)=@_[HEAP, KERNEL];
    DEBUG && warn "$$: Responder::sig_INT\n";
    $kernel->sig_handled();
    return;
}


#----------------------------------------------------
# User wants to kill process / kernel
sub inform_monitors
{
    my ($heap)=$_[HEAP];
    $heap->{self}->inform_monitors(@_[ARG0..$#_]);
}




##############################################################################



##############################################################################
# Here is the object interface
package POE::Component::IKC::Responder::Object;
use strict;

use Carp;
use POE::Component::IKC::Specifier;
use POE::Component::IKC::Proxy;
use POE::Component::IKC::LocalKernel;
use POE qw(Session);

use Data::Dump qw( pp );

sub DEBUG { 0 }
sub DEBUG2 { 0 }
sub DEBUGM { DEBUG or 0 }
sub new
{
    my($package, $kernel, $session)=@_;
    my $self=bless 
        {
            'local'=>{IKC=>{remote_error=>1, # these states are auto-published
                            do_you_have=>1,
                            ping=>1,
                           },
                     },
            remote=>{},
            rsvp=>{},
            kernel=>{},
            channel=>{},
            channel_startup=>{},
            default=>{},
            monitors=>{},
            poe_kernel=>$kernel,
#            myself=>$session->ID,
        }, $package;
}

#----------------------------------------------------
# shutdown
sub shutdown
{
    my($self, $kernel)=@_;
    DEBUG and 
        warn "$$: Some one wants us to go away... off we go\n";
    # kill our alias
    $kernel->alias_remove('IKC');

    # tell every channel to shutdown
    while(my($rid, $c)=each %{$self->{channel}}) {
        DEBUG and 
                warn "$$: Posting shutdown to $rid (id=$c)\n";
        $kernel->post($c, 'shutdown');
    }
    $self->{channel} = {};

    # even the channels that haven't negociated yet
    foreach my $c ( keys %{ $self->{channel_startup} } ) {
        DEBUG and 
                warn "$$: Posting shutdown to channel (id=$c)\n";
        $kernel->post( $c, 'shutdown' );
    }
    $self->{channel_startup} = {};

    # tell monitors to shutdown
    $self->inform_monitors('*', 'shutdown');
    # kill pending subscription states
    foreach my $uevent (keys %{$self->{pending_subscription}}) {
        $self->_remove_state($uevent);
    }
#    use YAML qw(Dump);
#    warn Dump $kernel;
}


#----------------------------------------------------
# Error in a remote kernel
sub remote_error
{
    my( $self, $msg ) = @_;
    $self->_do_error( remote => $msg );
}

# Error in the local kernel
sub local_error
{
    my( $self, $msg ) = @_;
    $self->_do_error( local => $msg );
}

# Error in a local channel
sub channel_error
{
    my( $self, $msg ) = @_;
    return $self->_do_error( channel => $msg, 1 );
}

sub _do_error
{
    my( $self, $where, $msg, $ignore ) = @_;
    my $n;
    eval {
        my $kernel = '*';
        my $when = $where;
        if( ref $msg ) {
            ( $msg, $kernel, $when ) = @$msg;
            $kernel ||= '*';
            $when = "$where-$when" unless $when =~ /^$where-/;
        }
        $n = $self->inform_monitors( $kernel, 'error', $when, $msg );
    };
    return $n if $n;
    warn "$$: \u$where error: ", pp( $msg ), "\n" unless $ignore;
    return;
}







#----------------------------------------------------
# Foreign kernel called something here
sub request    
{
    my($self, $request)=@_;;
    my($kernel)=@{$self}{qw(poe_kernel)};
    DEBUG2 and 
        warn "IKC request=", pp $request;

    # We ignore the kernel for now, but we should really use it to decide
    # weither we should run the request or not
    my $when = 'request';
    my $to=specifier_parse($request->{event});
    my $rkernel = $to->{kernel};
    eval {
        die "$request->{event} isn't a valid specifier" unless $to;
        my $args = $self->_req_args( $request, $to );

        # this is where we'd catch a disconnect message
        # 2001/07 : eh?

        $when = 'check';
        $self->_req_is_published( $to );

        # maybe caller specified #arg?  This got into $msg->{rsvp}, which
        # went to the remote side, then came back here as $to
        if(exists $to->{args}) {
            push @$args, $to->{args};   # it goes on the end
        }

        $when = 'resolve';
        my $session=$kernel->alias_resolve($to->{session});
        die "Unknown session '$to->{session}'" unless $session;

        $when = 'invocation';
        _thunked_post($request->{rsvp}, ["$session", $to->{state}, @$args],
                          $request->{from}, $request->{wantarray});
    };


    # Error handling consists of posting a "remote_error" state to
    # the foreign kernel.
    # $request->{errors_to} is set by the local IKC::Channel
    if($@) {
        $self->_error_response( $@, $request, $to, $rkernel, $when );
    }
}

sub _req_args
{
    my( $self, $request, $to ) = @_;
    my $args = $request->{params};

    ### allow proxied states to have multiple ARGs
    if($to->{state} eq 'IKC:proxy') {
        $to->{state}=$args->[0];
        $args=$args->[1];
        DEBUG and warn "IKC proxied request for ", specifier_name($to), "\n";
    } 
    else {
        DEBUG and warn "IKC request for ", specifier_name($to), "\n";
        $args=[$args];
    }
    return $args;
}

sub _req_is_published
{
    my( $self, $to ) = @_;

    # find out if the state we want to get at has been published
    if(exists $self->{rsvp}{$to->{session}} and
       exists $self->{rsvp}{$to->{session}}{$to->{state}} and
       $self->{rsvp}{$to->{session}}{$to->{state}}
      ) {
        $self->{rsvp}{$to->{session}}{$to->{state}}--;
        DEBUG and warn "Allow $to->{session}/$to->{state} is now $self->{rsvp}{$to->{session}}{$to->{state}}\n";
    }
    elsif(not exists $self->{'local'}{$to->{session}}) {
        my $p=$self->published;
        DEBUG and
            warn "$$: Available: ",
                join "\n", '',
                    map({ "    $_=>[" . join(', ', @{$p->{$_}}) . "]"} keys %$p),
                    '';
        die "Session '$to->{session}' is not available for remote kernels\n",
    }
    elsif(not exists $self->{'local'}{$to->{session}}{$to->{state}}) {
        die "Session '$to->{session}' has not published state '",
            $to->{state}, "'\n";
    }
    return 1;
}

sub _error_response
{
    my( $self, $err, $request, $to, $rkernel, $when ) = @_;

    chomp( $err );
    $err=$err.'.  Request '.specifier_name($to);
    $err.=' sent by '.specifier_name($request->{from})
                                                    if $request->{from};

    # Tell local sessions about this error
    $self->local_error( [ $err, $rkernel, $when ] );

    # never respond to an error message with an error message
    return if $request->{is_error};

    # Tell remote sessions about this error
    $self->send_msg( { event=>$request->{errors_to},
                       params=>[ $err, $rkernel, $when ],
                       is_error=>1,
                   } );
}




#----------------------------------------------------
# Register foreign kernels so that we can send states to them
sub register
{
    my($self, $channel, $rid, $aliases, $pid)=@_;
    $aliases=[$aliases] if not ref $aliases;

    my($kernel)=@{$self}{qw(poe_kernel)};
    
    $channel = $channel->ID;
    delete $self->{channel_startup}{ $channel };

    if($self->{channel}{$rid}) {
        warn "$$: Remote kernel '$rid' already exists\n";
        return;
    } 
    else {
        DEBUG and 
            warn "$$: Registered remote kernel '$rid' (id=$channel)\n";
        $self->{channel}{$rid}=$channel;
        $self->{remote}{$rid}=[];       # list of proxy sessions
        $self->{alias}{$rid}=$aliases;  
        $self->{default}||=$rid;
    }


    foreach my $name (@$aliases) {
        unless(defined $name) {
            warn "$$: attempt to register undefined remote kernel alias\n";
            next;
        }
        if($self->{kernel}{$name}) {
            DEBUG and warn "$$: Remote alias '$name' already exists\n";
            next;
        }
        DEBUG and warn "$$: Registered alias '$name'\n";
        $self->{kernel}{$name}=$rid;    # find real remote ID
        $self->{remote}{$name}||=[];    # list of proxy sessions
    }
    # warn "pid=$pid" if $pid;
    $self->inform_monitors($rid, 'register', $pid);

    return 1;
}

#----------------------------------------------------
# Register a new alias for the local kernel
sub register_local
{
    my($self, $aliases)=@_;
    $aliases=[$aliases] if not ref $aliases;

    my($kernel)=@{$self}{qw(poe_kernel)};

    my $rid=$kernel->ID;
    DEBUG and 
            warn "$$: Registering local kernel '$rid'\n";

    $self->{local_channel}||=POE::Component::IKC::LocalKernel->spawn->ID;
    my $channel=$self->{local_channel};

    $self->{channel}{$rid}||=$channel;
    $self->{remote}{$rid}||=[];       # list of proxy sessions
    $self->{alias}{$rid}||=[];

    foreach my $name (@$aliases) {
        unless(defined $name) {
            DEBUG and warn "$$: attempt to register undefined local kernel alias\n";
            next;
        }
        if($self->{kernel}{$name}) {
            DEBUG and warn "$$: Local kernel alias '$name' already exists\n";
            next;
        }
        DEBUG and warn "$$: Registered local alias '$name'\n";
        $self->{kernel}{$name}=$rid;    # find real remote ID
        $self->{remote}{$name}||=[];    # list of proxy sessions
        push @{$self->{alias}{$rid}}, $name;
    }
    return 1;
}

#----------------------------------------------------
# Register a starting channel
sub register_channel
{
    my( $self, $channel ) = @_;
    $channel = $channel->ID;
    DEBUG and 
        warn "$$: Registered channel (id=$channel)\n";
    $self->{channel_startup}{ $channel } = 1;
    return;
}


#----------------------------------------------------
sub default
{
    my($self, $name) = @_;
    if(exists $self->{kernel}{$name}) {
        $self->{default}=$self->{kernel}{$name};

    } 
    elsif(exists $self->{channel}{$name}) {
        $self->{default}=$name;

    } 
    else {
        carp "We do not know the kernel $name.\n";
        return;
    }

    DEBUG and warn "Default kernel is on channel $name.\n";
}

#----------------------------------------------------
# Unregister foreign kernels when they disconnect (say)
sub unregister
{
    my($self, $channel, $rid, $aliases)=@_;
    my($kernel)=@{$self}{qw(poe_kernel)};
    return unless $rid;
    $channel = $channel->ID;

    unless($aliases) {
        unless($self->{channel}{$rid}) {    # unregister one alias only
            $aliases=[$rid];                    
            undef $rid;
        }
    } 
    elsif(not ref $aliases) {
        $aliases=[$aliases];
    }

    my @todo;
    if($rid) {
        if($self->{channel}{$rid}) {    # this is in fact the real name
            DEBUG and 
                warn "Unregistered kernel '$rid'.\n";
            $self->inform_monitors($rid, 'unregister');

            $self->{'default'}='' if $self->{'default'} eq $rid;
            $kernel->post($self->{channel}{$rid}, 'close');
            delete $self->{channel}{$rid};
            # delete $self->{monitors}{$rid};
            $aliases||=delete $self->{alias}{$rid};

            push @todo, $rid;
        } 
        else {
            warn "$rid isn't a channel???\n";
        }
    }


    foreach my $name (@$aliases) {
        next unless defined $name;
        # delete $self->{monitors}{$name};
        if($self->{kernel}{$name}) {
            DEBUG and 
                warn "Unregistered kernel alias '$name'.\n";
            delete $self->{kernel}{$name};
            $self->{'default'}='' if $self->{'default'} eq $name;
            push @todo, $name;
        } 
        else {
            DEBUG and warn "Already done: $name\n";
            next;
        }
    }

                # tell the proxies they are no longer needed
    foreach my $name (@todo) {
        if($name) {
            foreach my $alias (@{$self->{remote}{$name}}) {
                $self->{poe_kernel}->post($alias, '_delete');
            }
            delete $self->{remote}{$name};
        }
    }
    return 1;
}


#----------------------------------------------------
# Internal function that does all the work of preparing a request to be sent
sub send_msg
{
    my($self, $msg, $sender)=@_;
    my($kernel)=@{$self}{qw(poe_kernel)};

    my $e=$msg->{rsvp} ? 'call' : 'post';

    my $to=specifier_parse($msg->{event});
    unless($to) {
        die "Bad state ", pp $msg;
    }
    unless($to) {
        warn "Bad or missing 'event' parameter '$msg->{event}' to IKC/$e\n";
        return;
    }
    unless($to->{session}) {
        warn "Need a session name for IKC/$e\n", pp $to;
        return;
    }
    unless($to->{state})   {
        warn "Need a state name for IKC/$e\n", pp $to;
        return;
    }

    my $name=$to->{kernel}||$self->{'default'};
    unless($name) {
        warn "Unable to decide which kernel to send state '$to->{state}' to.";
        return;
    }

    DEBUG and warn "send_msg poe://IKC/$e to '", specifier_name($to), "'\n";

    # This way the thunk session will proxy a request back to us
    if($sender and not $msg->{from} and
        # <sungo> Leolo: question. doesnt .13 require bleadPOE?
        # <Leolo> sungo : i can put the offending code into a conditional
        # if you want
        $self->{poe_kernel}->can('alias_list')) 
    {
        my $sid=$sender;
        $sid = $sender->ID if ref $sender;
        foreach my $a ($self->{poe_kernel}->alias_list($sender)) {
            $sid .= " ($a)";
            if($self->{'local'}{$a}) {  # SENDER published something
                $msg->{from}={  kernel=>$self->{poe_kernel}->ID,
                                session=>$a,
                                state=>'IKC:proxy',
                             };
                last;
            }
        }

        DEBUG2 and do {
            unless($msg->{from}) {
                warn "Session $sid didn't publish anything SENDER isn't set";#, Denter $self->{'local'}, $sender;
            } else {
                warn "Session $sid will be thunked";
            }
        }
    }

    # This is where we should recurse $msg->{params} to turn anything
    # extravagant like a subref, $poe_kernel, session etc into a call back to
    # us.
    # $msg->{params}=$self->marshall($msg->{params});

    # Get a list of channels to send the message to
    my @channels=$self->channel_list( $name );
    unless(@channels) {
        my $err = (($name eq '*')
                    ? "$$: Not connected to any foreign kernels."
                    : "$$: Unknown kernel '$name'.");
        $self->inform_monitors( '*', 'error', 'resolve', $err );
        return 0;
    }


    # now send the message over the wire
    # hmmm.... i wonder if this could be stream-lined into a direct call
    my $count=0;
    my $rsvp;
    $rsvp=$msg->{rsvp} if exists $msg->{rsvp};
    foreach my $channel (@channels) {

        # We need to be able to access this state w/out forcing folks
        # to use publish
        if($rsvp) {
            DEBUG and warn "Allow $rsvp->{session}/$rsvp->{state} once\n";
            $self->{rsvp}{$rsvp->{session}}{$rsvp->{state}}++;
        }

        DEBUG2 and warn "Sending to '$channel'...";
        if($kernel->call($channel, 'send', $msg)) {
            $count++;
            DEBUG2 and warn " done.\n";
        }
        else {
            DEBUG2 and warn " failed.\n";
            $self->{rsvp}{$rsvp->{session}}{$rsvp->{state}}-- if $rsvp;
        }
    }

    DEBUG2 and warn specifier_name($to), " sent to $count kernel(s).\n";
    DEBUG and do {warn "$$: send_msg failed!\n" unless $count};
    return $count;
}

#----------------------------------------------------
sub _true_type
{
    my($self, $data, $can)=@_;
    my $r=ref $data;
    return unless $r;
    return reftype( $data );
}

#----------------------------------------------------
sub marshall
{
    my($self, $data)=@_;
    my $r=$self->_true_type($data, 'ikc_marshall');
    return $data unless $r;

    if($r eq 'HASH') {
        foreach my $q (values %$data) {
            $data->{$q}=$self->marshall($data->{$q})
                    if ref $data->{$q};
        }
    } 
    elsif($r eq 'ARRAY') {
        foreach my $q (@$data) {
            $q=$self->marshall($q) if ref $q;
        }
    } 
    elsif($r eq 'SCALAR') {
        $$data=$self->marshall($$data) if ref $$data;
    } 
    elsif($r eq 'CODE') {
        my $q=Devel::Peek::CvGV($data);
        if($q=~/__ANON__$/) {
            warn "Can't marshall anonymous code ref $q\n";
            return;
        }
        return "-IKC-CODEREF-$q";
    } else {
        warn "Marshalling $r wouldn't be meaningful\n";
        return;
    }
    return $data;
}

#----------------------------------------------------
sub demarshall
{
    my($self, $data)=@_;
    my $r=$self->_true_type($data, 'ikc_demarshall');
    unless($r) {
        if($r=~/^-IKC-CODEREF-(.+)-(\*[:\w]+)$/) {
            my $func=$2;
            my $rk=$1;
            die "need to call $func in $rk";
            $data=sub {$poe_kernel->post(IKC=>'post',
                            "poe://$rk/IKC/coderef"=>$func)};
        }
        return $data;
    }

    if($r eq 'HASH') {
        foreach my $q (values %$data) {
            $data->{$q}=$self->demarshall($data->{$q})
                    if ref $data->{$q};
        }
    } 
    elsif($r eq 'ARRAY') {
        foreach my $q (@$data) {
            $q=$self->demarshall($q) if ref $q;
        }
    } 
    elsif($r eq 'SCALAR') {
        $$data=$self->demarshall($$data) if ref $$data;
    } 
    return $data;
}

#----------------------------------------------------
## Turn a kernel name or alias into a list of possible channels
sub channel_list
{
    my($self, $name)=@_;

    if($name eq '*') {                              # all kernels
        return values %{$self->{channel}}; 
    }  
    if(exists $self->{kernel}{$name}) {             # kernel alias
        my $t=$self->{kernel}{$name};
        unless(exists $self->{channel}{$t}) {
            die "What happened to channel $t!";
        }
        return ($self->{channel}{$t})
    }

    if(exists $self->{channel}{$name}) {            # kernel ID
        return ($self->{channel}{$name})
    }
    return ();    
}

#----------------------------------------------------
## Get a list of all the channel names (for debugging)
sub channel_names
{
    my($self, $name) = @_;

    if( $name and $name ne '*' ) {
        return "$name (".join(', ', grep { $self->{kernel}{$_} eq $name }
                                    keys %{ $self->{kernel} }
                             ) .")";
    }

    my @ret;
    foreach $name ( keys %{ $self->{channel} } ) {
        push @ret, $self->channel_names( $name );
    }

    return @ret if wantarray;
    return join ', ', @ret;
}

#----------------------------------------------------
# Send a request to the foreign kernel
sub post
{
    my($self, $to, $params, $sender) = @_;

    $to="poe://$to" unless ref $to or $to=~/^poe:/;
    $self->send_msg({params=>$params, 'event'=>$to}, $sender);
}

#----------------------------------------------------
# Send a request to the foreign kernel and ask it to provide 
# the state's return value back
sub call
{
    my($self, $to, $params, $rsvp, $sender)=@_;

    $to="poe://$to"     if $to   and not ref $to   and $to!~/^poe:/;
    $rsvp="poe://$rsvp" if $rsvp and not ref $rsvp and $rsvp!~/^poe:/;

    unless($rsvp) {
        warn "$$: Missing 'rsvp' parameter in poe:IKC/call\n";
        return;
    }
    my $t=specifier_parse($rsvp);
    unless($t) {
        warn "$$: Bad 'rsvp' parameter '$rsvp' in poe:IKC/call\n";
        return;
    }
    $rsvp=$t;
    unless($rsvp->{state})
    {
        DEBUG and warn pp $rsvp;
        warn "$$: rsvp state not set in poe:IKC/call\n";
        return;
    }

    # Question : should $rsvp->{session} be forced to be the sender?
    # or will we allow people to point callbacks to other poe:kernel/sessions
    $rsvp->{session}||=$sender->ID if ref $sender;    # maybe a session ID?
    if(not $rsvp->{session})                            # no session alias
    {
        die "IKC call requires session IDs, please patch your version of POE\n";
    }
    DEBUG2 and warn "RSVP is ", specifier_name($rsvp), "\n";

    $self->send_msg({params=>$params, 'event'=>$to,
                     rsvp=>$rsvp
                    }, $sender
                   );
}

##############################################################################
# publish/retract/subscribe mechanism of setting up foreign sessions

sub _aliases
{
    my($kernel, $session)=@_;
    return $session unless ref $session; # make sure it's an object

    if($kernel->can('alias_list')) {
            # post-0.15 we register as all aliases for session
        my @a=$kernel->alias_list($session->ID);
        return @a if @a;
    } 

    # pre-0.15 means that we register as session ID... which is less
    # then useful
    return $session->ID;
}

#----------------------------------------------------
sub publish
{
    my($self, $session, $states)=@_;
    unless($session) {
        carp "You must specify the session that publishes these states";
        return 0;
    }
    my @aliases =_aliases($self->{poe_kernel}, $session);

    foreach my $alias (@aliases) {
        $self->{'local'}{$alias}||={};
        my $p=$self->{'local'}{$alias};

        die "\$states isn't an array ref" unless ref($states) eq 'ARRAY';
        foreach my $q (@$states) {
            DEBUG and 
                print STDERR "$$: Published poe:$alias/$q\n";
            $p->{$q}=1;
        }
    }
    return 1;
}

#----------------------------------------------------
sub published
{
    my($self, $session)=@_;

    if($session) {
        my $sid=$session;
        if(not ref $session) {
            $sid||=$self->{poe_kernel}->ID_lookup($session);
        }
        return [keys %{$self->{'local'}{$sid}}];
    }

    my %ret;
    foreach my $sid (keys %{$self->{'local'}}) {
        $ret{$sid}=[keys %{$self->{'local'}{$sid}}];
    }
    return \%ret;
}

#----------------------------------------------------
sub retract
{
    my($self, $session, $states)=@_;

    unless($session) {
        warn "You must specify the session that publishes these states";
        return 0;
    }
    my @aliases=_aliases($self->{poe_kernel}, $session);
    foreach my $alias (@aliases) {
        unless($self->{'local'}{$alias}) {
            warn "Session '$session' ($alias) didn't publish anything, can't retract";
            return 0;
        }

        if($states) {
            my $p=$self->{'local'}{$alias};
            foreach my $q (@$states) {
                delete $p->{$q};
            }
            delete $self->{'local'}{$alias} unless keys %$p;
        } else {
            delete $self->{'local'}{$alias};
        }
    }
    return 1;
}

#----------------------------------------------------
# Subscribing is in two phases
# 1- we call a IKC/do_you_have to the foreign kernels
# 2- the foreign responds with the session-specifier (if it has published it)
#
# We create a unique state for the callback for each subscription request
# from the user session.  It keeps count of how many subscription receipts
# it receives and when they are all subscribed, it localy posts the callback
# event.  
#
# If more then one kernel sends a subscription receipt, first one is used.
sub subscribe
{
    my($self, $sessions, $callback, $s_id)=@_;
    my($kernel)=@{$self}{qw(poe_kernel)};

    $s_id||=join '-', caller;

    my($ses, $s, $fiddle);
                                # unique identifier for this request
    $callback||='';
    my $unique="IKC:receipt $s_id $callback";  
    my $id=$kernel->ID;

    my $count;
    foreach my $spec (@$sessions)
    {
        $ses=specifier_parse($spec);   # Session specifier
                                    # Create the subscription receipt state
        $kernel->state($unique.$spec,  sub {
                      _subscribe_receipt($self, $unique, $spec, $_[ARG0])
                    });
        $kernel->delay($unique.$spec, 60);  # timeout
        $self->{pending_subscription}{$unique.$spec}=1;

        if($ses->{kernel})
        {
            $count=$self->send_msg(
                    {event=>{kernel=>$ses->{kernel}, session=>'IKC', 
                                state=>'do_you_have'
                            },
                     params=>[$ses, $id],
                     from=>{kernel=>$id, session=>'IKC'},
                     rsvp=>{kernel=>$id, session=>'IKC', state=>$unique.$spec},
                    }, 
                 );
            DEBUG and warn "$$: do_you_have sent to $count sessions\n";
            if( $count == 0 ) {
                # This post failed.  Session that posted this would
                # surely want to know
                $self->inform_monitors( '*', 'error', 
                                        'subscribe', 
                                        "Unknown kernel $ses->{kernel}" );
            }
        } else
        {                       # Bleh.  User shouldn't be that dumb       
            die "You can't subscribe to a session within the current kernel.";
        }
        

        if($callback)           # We need to keep some information around
        {                       # for when the subscription receipt comes in
            $self->{subscription_callback}{$unique}||=
                        {   callback=>$callback, 
                            sessions=>{}, yes=>[], count=>0, 
                            states=>{},
                        };
            $fiddle=$self->{subscription_callback}{$unique};
            $fiddle->{states}{$unique.$spec}=$count;
            $fiddle->{count}+=($count||0);
            $fiddle->{sessions}->{$spec}=1;
            if(not $count)
            {
                $fiddle->{count}++;
                $kernel->yield($unique.$spec);
            } else
            {
                DEBUG and warn "Sent $count subscription requests for [$spec]\n";
            }
        }
    }

    return 1;
}

#----------------------------------------------------
# Subscription receipt
# All foreign kernel's that have published the desired session
# will send back a receipt.  
# Others will send a "NOT".
# This will cause problems when the Proxy session creates an alias :(
#
# Callback is called we are "done".  But what is "done"?  When at least
# one remote kernel has allowed us to subscribe to each session we are
# waiting for.  However, at some point we should give up.
# 
# Scenarios :
# one foreign kernel says 'yes', one 'no'.
#   - 'yes' creates a proxy
#   - 'no' decrements wait count 
#       ... callback is called with session specifier
# 2 foreign kernels says 'yes'
#   - first 'yes' creates a proxy
#   - 2nd 'yes' should also create a proxy!  alias conflict (for now)
#       ... callback is called with session specifier
# one foreign kernel says 'no', and after, another says no
#   - first 'no' decrements wait count
#   - second 'no' decrements wait count
#       ... Subscription failed!  callback is called with specifier empty
# no answers ever came...
#   - we wait forever :(

sub _subscribe_receipt
{
    my($self, $unique, $spec, $resp)=@_;
    my $accepted=1;
    
    my($ses, $rid)=@$resp if $resp and ref $resp and @$resp;
    my $del;

    if(not $ses or not ref $ses) {               # REFUSED
        $resp ||= "Refused subscription to $spec";
        $self->inform_monitors( '*', 'error', 
                                         'subscribe', 
                                         $resp )
            or warn "$$: $resp";
        $accepted=0;
        $del=$unique.$spec;
    } 
    else {                                      # accepted
        $ses=specifier_parse($ses);
        die "Bad state" unless $ses;
        my($kernel)=@{$self}{qw(poe_kernel)};

        DEBUG and warn "Create proxy for ", specifier_name($ses), "\n";
        my $proxy=POE::Component::IKC::Proxy->spawn(
                      $ses->{kernel}, $ses->{session},
                      sub { $kernel->post(IKC=>'inform_monitors', 
                                $rid, 'subscribe', $ses)},
                      # 2002/04 monitor_stop is called in _stop, but we can't
                      # can't post() from _stop, so we call() ourself
                      sub { $kernel->call(IKC=>'inform_monitors', 
                                $rid, 'unsubscribe', $ses)},
                    );

        push @{$self->{remote}{$ses->{kernel}}}, $proxy;
    }

    # cleanup the subscription request
    if(exists $self->{subscription_callback}{$unique}) {
        DEBUG and 
            warn "Subscription [$unique] callback... ";
        my $fiddle=$self->{subscription_callback}{$unique};

        if($fiddle->{sessions}->{$spec} and $accepted) {
            delete $fiddle->{sessions}->{$spec};
            push @{$fiddle->{yes}}, $spec;
        }

        $fiddle->{count}-- if $fiddle->{count};
        if(0==$fiddle->{count}) {
            DEBUG and 
                warn "yes.";
            delete $self->{subscription_callback}{$unique};
            # use Data::Denter;
            # warn "Fiddle =", Denter $fiddle;
            $fiddle->{callback}->($fiddle->{yes});
        }
        else {
            DEBUG and 
                warn "no, $fiddle->{count} left.";
        }
        
        $fiddle->{states}{$unique.$spec}--;
        if($fiddle->{states}{$unique.$spec}<=0) {
            # this state is no longer needed
            $del=$unique.$spec;
        }
    } 
    else {
        # this state is no longer needed
        $del=$unique.$spec;
    }

    $self->_remove_state($del) if $del;
}

# clean-up
sub _remove_state
{
    my($self, $del)=@_;
    return unless $self->{pending_subscription}{$del};

    my $kernel=$self->{poe_kernel};
    $kernel->delay($del);
    $kernel->state($del);
    delete $self->{states}{$del};
    delete $self->{pending_subscription}{$del};
}

#----------------------------------------------------
sub unsubscribe
{
    my($self, $sessions)=@_;
    $sessions=[$sessions] unless ref $sessions;
    return unless @$sessions;
    foreach my $ses (@$sessions) {
        $self->{poe_kernel}->post($ses, '_shutdown');
    }
}

#----------------------------------------------------
sub ping
{
    "PONG";
}

#------------------------------------------------------------------
sub monitor
{
    my($self, $sender, $name, $states)=@_;
    # <Leolo_1> dngor : also, if i keep a ref to $_[SENDER], does this mess 
    #       up stuff?
    # <dngxor> yeah, it will mess stuff up.  take its ID instead; you can 
    #       post to an ID
    $sender=$sender->ID if ref $sender;
    my $spec=$name;
    $spec=specifier_part($spec, 'kernel') unless $spec eq '*';
    undef($states) unless ref $states and keys %$states;

    if($states) {
        $states->{__name}=$name;
        DEBUGM and 
            warn "$$: Session $sender is monitoring $spec\n";
        $self->{monitors}{$spec} ||= {};
        $self->{monitors}{$spec}{$sender}=$states;
    }
    else {
        DEBUGM and warn "$$: Session $sender is neglecting $spec\n";
        delete $self->{monitors}{$spec}{$sender};
        delete $self->{monitors}{$spec} if 0==keys %{$self->{monitors}{$spec}};
    }
    return;
}

#----------------------------------------------------
# Tell monitors about something in foreign kernel
# $rid == kernel name (in which case we ALSO inform about aliases) or alias
#         or * (tell every monitor about something... future use)
# $event == name of event we are informing about
# @params == other stuff
# NB : inform_monitors *MUST* post or call the monitors before exiting
#      because unregister will delete {monitors}{$rid} right after
sub inform_monitors
{
    my($self, $rid, $event, @params)=@_;
    my($kernel)=@{$self}{qw(poe_kernel)};
    $rid=specifier_part($rid, 'kernel') unless $rid eq '*';
    croak "$$: No kernel in $_[1]!" unless $rid;

    my $real=1 if $self->{channel}{$rid};
    DEBUGM and 
        do {
            warn "$$: inform $event $rid\n";
            warn "$$: $rid is", ($real ? '' : "n't"), " real\n";
        };

    my $count = 0;

    # got to be a better way of doing this...
    my @todo=($rid);
    push @todo, '*' unless $rid eq '*';
    foreach my $n (@todo) {
        next unless $n;

        my $ms=$self->{monitors}{$n};
        unless($ms and %$ms) {
            DEBUGM and 
                warn "$$: No sessions care about $event $n\n";
            next;
        }

        foreach my $sender (keys %$ms) {
            my $states=$ms->{$sender};
    
            my $e=$states->{$event};
            next unless $e;

            DEBUGM and 
                warn "$$: Informing Session $sender/$e about $n/$event\n";
                # ARG0 = what Session called the kernel
                # ARG1 = what kernel calls the kernel
                # ARG2 = true if kernel is name, false if alias
                # ARG3 = $states->{data}
                # ARG4.... = per-message info
            $kernel->post($sender, $e, $states->{__name}, $rid, $real,
                            $states->{data}, @params);
            $count++;
        }
    }

    # $rid might be an alias to something else, inform about those as well
    if($self->{channel}{$rid}) {
        foreach my $ra (@{$self->{alias}{$rid}}) {
            $count += $self->inform_monitors($ra, $event, @params);
        }
    }
    return $count;
}


##############################################################################
# These are Thunks used to post the actual state on behalf of the foreign
# kernel.  Currently, the thunks are used as a "proof of concept" and
# to accur extra over head. :)
# 
# On the first request, a thunk is created.  It is kept alive with an alias.
# On the next request, we check to see if the extref_count is zero.  If it
# is, we reuse the same request.  If not, we create a new thunk and continue
# using that.  What's more, we tell the thunk that it is active, so it should
# clear its alias.  This way, when the user code decrements the extref_count
# back to zero, the thunk they reserved can be cleared.
#

# Export thunk the quick way.
*_thunked_post=\&POE::Component::IKC::Responder::Thunk::thunk;
package POE::Component::IKC::Responder::Thunk;

use strict;

use Carp;
use Data::Dump qw( pp );
use POE::Component::IKC;
use POE::Session;
use POE;

sub DEBUG { 0 }
sub DEBUG2 { 0 }

#----------------------------------------------------
{
    my $NAME=__PACKAGE__.'00000000';
    $NAME=~s/\W+//g;
    my $current_thunk;

    #------------------------------
    sub thunk
    {
        # my($rsvp, $call, $from, $wantarray)=@_;
        unless( __active_thunk() ) {
            __create_thunk();
        }

        # we use call to make sure no other call to us could
        # happen between _start and __thunk
        $poe_kernel->call( $current_thunk => '__thunk', @_ );
    }

    #------------------------------
    sub __create_thunk
    {
        my $thunk = 
            POE::Session->create( 
                package_states => [ __PACKAGE__, 
                                    [ qw(_start _stop _default
                                        __thunk __active
                                    ) ]
                                  ],
                args => [++$NAME]
            );

        $current_thunk = $thunk->ID;
    }

    #------------------------------
    sub __active_thunk 
    {
        return unless $current_thunk;
        # 2009/05 - These next 2 lines call undocumented internal methods of 
        # the kernel.  If the kernel changes, they will break.
        # If they break, please contact gwyn-at-cpan.org.
        # 2011/08 - These have been changed for 1.311
        my $count = _ref_count( $current_thunk );
        if( defined $count ) {
            DEBUG and 
                warn "$$: $NAME count=$count\n";
            if( 0==$count ) {
                DEBUG and 
                    warn "$$: $NAME reuse\n";
                return 1;
            }
            DEBUG and 
                warn "$$: new thunk\n";
            $poe_kernel->call( $current_thunk => '__active' );
        }
        undef( $current_thunk );
        return;
    }
}

sub _ref_count
{
    my( $id ) = @_;
    # This code is badly behaved!
    return unless $poe_kernel->_data_ses_exists( $id );
    if( $poe_kernel->can( '_data_extref_count_ses' ) ) {
        return $poe_kernel->_data_extref_count_ses( $id )||0;
    }
    else {
        # This is for the code that dngor had that extrefs as a sub object, not
        # as a mixin'
        $poe_kernel->[ POE::Kernel::KR_EXTRA_REFS() ]->count_session_refs( $id )||0;
    }
}


#----------------------------------------------------
sub _start
{
    my($kernel, $heap, $name )= @_[KERNEL, HEAP, ARG0];
    $heap->{alias} = $heap->{name} = $name;
    DEBUG and warn "$$: $name create\n";
    $kernel->alias_set( $heap->{alias} );
}

#----------------------------------------------------
sub __active
{
    my($kernel, $heap) = @_[KERNEL, HEAP];
    DEBUG and 
        warn "$$: $heap->{name} active\n";
    $kernel->alias_set( delete $heap->{alias} ) if $heap->{alias};
    return 1;
}

#----------------------------------------------------
sub _stop
{
    DEBUG and 
        warn "$$: $_[HEAP]->{name} delete\n";
}

#----------------------------------------------------
sub __thunk
{
    my($kernel, $heap,          $rsvp, $call, $from, $wantarray)=
                @_[KERNEL, HEAP, ARG0, ARG1,  ARG2,  ARG3];
    $heap->{from} = $from;
    # warn "no FROM" unless $from;

    if($rsvp) {                         # foreign session wants returned value
        DEBUG2 and warn "Calling ", pp $call;

        DEBUG2 and do { warn "Wants an array" if $wantarray};

        my(@ret, $yes);
        if($wantarray) {
            @ret=$kernel->call(@$call);
            $yes = 0<@ret;
        } else {
            $ret[0]=$kernel->call(@$call);
            $yes = defined $ret[0];
        }
        if($yes) {
            DEBUG2 and do {
                local $"=', ';
                warn "Posted response '@ret' to ", pp $rsvp;
            };
            # This is the POSTBACK
            $POE::Component::IKC::Responder::ikc->send_msg(
                    {params=>($wantarray ? \@ret : $ret[0]), event=>$rsvp},
                    $call->[0]);
        }
    }
    else {
        # 2009/05 - use ->call() so that {from} can't be modified
        # before refcount_increment is called
        DEBUG2 and warn "Posting ", pp $call;
        $kernel->call(@$call);
    }
}

#----------------------------------------------------
sub _default
{
    my($kernel, $heap, $sender, $state, $args)=
            @_[KERNEL, HEAP, SENDER, ARG0, ARG1];
    return if $state =~ /^_/;
    
    unless($heap->{from}) {
        warn "$$: Attempt to respond to an anonymous foreign post with '$state'\n";
        return;
    }

    if( not $heap->{from}{state} ) {
        my $event = { %{$heap->{from}} };
        $event->{state} = $state;

        $POE::Component::IKC::Responder::ikc->send_msg(
                {params=>$args, event=>$event}, $sender
              );
    }
    else {
        $POE::Component::IKC::Responder::ikc->send_msg(
                {params=>[$state, $args], event=>$heap->{from}}, $sender
              );
    }
}

1;
__END__

=head1 NAME

POE::Component::IKC::Responder - POE IKC state handler

=head1 SYNOPSIS

    use POE;
    use POE::Component::IKC::Responder;
    create_ikc_responder();
    ...
    $kernel->post('IKC', 'post', $to_state, $state);

    $ikc->publish('my_name', [qw(state1 state2 state3)]);

=head1 DESCRIPTION

This module implements POE IKC state handling.  The responder handles
posting states to foreign kernels and calling states in the local kernel at
the request of foreign kernels.

There are 2 interfaces to the responder.  Either by sending states to the 
'IKC' session or the object interface.  While the latter is faster, the
better behaved, because POE is a cooperative system.

=head1 STATES/METHODS

=head2 C<spawn>

    POE::Component::IKC::Responder->spawn();

This function creates the Responder session and object.  Normally, 
L<POE::Component::IKC::Client> or L<POE::Component::IKC::Server> does 
this for you.  But in some applications
you want to make sure that the Responder is up and running before then.


=head2 C<post>

Sends an state request to a foreign kernel.  Returns logical true if the
state was sent and logical false if it was unable to send the request to the 
foreign kernel.  This does not mean that the foreign kernel was able to 
post the state, however.  Parameters are as follows :

=over 2

=item C<foreign_state>

Specifier for the foreign state.   See L<POE::Component::IKC::Specifier>.

=item C<parameters>

A reference to anything you want the foreign state to get as ARG0.  If you
want to specify several parameters, use an array ref and have the foreign
state dereference it.

    $kernel->post('IKC', 'post', 
        {kernel=>'Syslog', session=>'logger', state=>'log'},
        [$faculty, $priority, $message];

or

    $ikc->post('poe://Syslog/logger/log', [$faculty, $priority, $message]);

This logs an state with a hypothetical logger.  

=back

See the L</PROXY SENDER> below.


=head2 C<call>

This is identical to C<post>, except it has a 3rd parameter that describes
what state should receive the return value from the foreign kernel.

    $kernel->post('IKC', 'call', 
                'poe://Pulse/timeserver/time', '',
                'poe:get_time');

or

    $ikc->call({kernel=>'Pulse', session=>'timeserver', state=>'time'},
                '', 'poe://me/get_time');

This asks the foreign kernel 'Pulse' for the time.  'get_time' state in the
current session is posted with whatever the foreign state returned.  

You do not have to publish callback messages, because they are temporarily
published.  How temporary?  They can be posted from a remote kernel ONCE
only.  This, of course, is a problem because someone else could get in a
post before the callback.  Such is life.



=over 3

=item C<foreign_state>

Identical to the C<post> C<foreign_state> parameter.

=item C<parameters>

Identical to the C<post> C<parameters> parameter.

=item C<rsvp>

Event identification for the callback.  That is, this state is called with
the return value of the foreign state.  Can be a C<foreign_state> specifier
or simply the name of an state in the current session.

=back

    $kernel->call('IKC', 'post', 
        {kernel=>'e-comm', session=>'CC', state=>'check'},
        {CC=>$cc, expiry=>$expiry}, folder=>$holder},
        'is_valid');
    # or
    $ikc->call('poe://e-comm/CC/check',
        {CC=>$cc, expiry=>$expiry}, folder=>$holder},
        'poe://me/is_valid');

This asks the e-comm server to check if a credit card number is "well
formed".  Yes, this would probably be massive overkill. 

The C<rsvp> state does not need to be published.  IKC keeps track of the
rsvp state and will allow the foreign kernel to post to it.


See the L<PROXY SENDER> below.





=head2 C<default>

Sets the default foreign kernel.  You must be connected to the foreign
kernel first.

Unique parameter is the name of the foreign kernel kernel.

Returns logical true on success.




=head2 C<register>

Registers foreign kernel names with the responder.  This is done during the
negociation phase of IKC and is normaly handled by C<IKC::Channel>.  Will
define the default kernel if no previous default kernel exists.

First parameter is either a single kernel name.  Second optional parameter
is an array ref of kernel aliases to be registered.




=head2 C<unregister>

Unregisters one or more foreign kernel names with the responder.  This is
done when the foreign kernel disconnects by L<POE::Component::IKC::Channel>. 
If this is the
default kernel, there is no more default kernel.

First parameter is either a single kernel name or a kernel alias.  Second
optional parameter is an array ref of kernel aliases to be unregistered. 
This second parameter is a tad silly, because if you unregister a remote
kernel, it goes without saying that all it's aliases get unregistered also.



=head2 C<register_local>

Registers new aliases for local kernel with the responder.  This is done
internally by L<POE::Component::IKC::Server> and L<POE::Component::IKC::Client>. Will NOT define the default
kernel.

First and only parameter is an array ref of kernel aliases to be registered.




=head2 C<publish>

Tell IKC that some states in the current session are available for use by
foreign sessions.

=over 2

=item C<session>

A session alias by which the foreign kernels will call it.  The alias must
already have been registered with the local kernel.

=item C<states>

Arrayref of states that foreign kernels may post.

    $kernel->post('IKC', 'publish', 'me', [qw(foo bar baz)]);
    # or
    $ikc->publish('me', [qw(foo bar baz)]);

=back





=head2 C<retract>

Tell IKC that some states should no longer be available for use by foreign
sessions.  You do not have to retract all published states.

=over 2

=item C<session>

Same as in C<publish>

=item C<states>

Same as in C<publish>.  If not supplied, *all* published states are
retracted.

    $kernel->post('IKC', 'retract', 'me', [qw(foo mibble dot)]);
    # or
    $ikc->retract('me', [qw(foo)]);

=back




=head2 C<published>

    $list=$kernel->call(IKC=>'published', $session);

Returns a list of all the published states.

    $hash=$kernel->call(IKC=>'published');

Returns a hashref, keyed on session IDs.  Values are arrayref of states 
published by that session.

=over 2

=item C<session>

A session alias that you wish the list of states for.

=back






=head2 C<subscribe>

Subscribe to foreign sessions or states.  When you have subscribed to a
foreign session, a proxy session is created on the local kernel that will
allow you to post to it like any other local session.

=over 3

=item C<specifiers>

An arrayref of the session or state specifiers you wish to subscribe to. 
While the wildcard '*' kernel may be used, only the first kernel that
acknowledges the subscription will be proxied.

=item C<callback>

Either a state (for the state interface) or a coderef (for the object
interface) that is posted (or called) when all subscription requests have
either been replied to, or have timed out.

When called, it has a single parameter, an arrayref of all the specifiers
that IKC was able to subscribe to.  It is up to you to see if you have
enough of the foreign sessions or states to get the job done, or if you
should give up.

While C<callback> isn't required, it makes a lot of sense to use it because
it is only way to find out when the proxy sessions become available.

Example :

    $ikc->subscribe([qw(poe://Pulse/timeserver)], 
            sub { $kernel->post('poe://Pulse/timeserver', 'connect') });

(OK, that's a bad example because we don't check if we actually managed to
subscribe or not.)

    $kernel->post('IKC', 'subscribe', 
                    [qw(poe://e-comm/CC poe://TouchNet/validation
                        poe://Cantax/JDE poe://Informatrix/JDE)
                    ],
                    'poe:subscribed',
                  );
    # and in state 'subscribed'
    sub subscribed
    {
        my($kernel, $specs)=@_[KERNEL, ARG0];
        if(@$specs != 4)
        {
            die "Unable to find all the foreign sessions needed";
        }
        $kernel->post('poe://Cantax/JDE', 'write', {...somevalues...});
    }                
    
This is a bit of a mess.  You might want to use the C<subscribe> parameter
to L</spawn> instead.

Subscription receipt timeout is currently set to 120 seconds.

=back




=head2 C<unsubscribe>

Reverse of the L</subscribe> method.  However, it is currently not
documented well.

=head2 C<ping>

Responds with 'PONG'.  This is auto-published, so it can be called from
remote kernels to see if the local kernel is still around.  In fact, I don't
see any other use for this.

    $kernel->post('poe://remote/IKC', 'ping', 'some_state');
    $kernel->delay('some_state', 60);   # timeout
    
    sub some_state
    {
        my($pong)=$_[ARG0];
        return if $pong;            # all is cool
        
        # YOW!  Remote kernel timed out.  RUN AROUND SCREAMING!
    }



=head2 C<shutdown>

Hopefully causes IKC and all peripheral sessions to dissapear in a puff of
smoke.  At the very least, any sessions left will be either not related to
IKC or barely breathing (that is, only have aliases keeping them from GC). 
This should allow you to sanely shut down your process.


=head2 C<monitor>

Allows a session to monitor the state of remote kernels.  Currently, a
session is informed when a remote kernel is registered, unregistered,
subscribed to or unsubscribed from.  One should make sure that the IKC alias
exists before trying to monitor.  Do this by calling 
L<POE::Component::IKC::Responder>->spawn
or in an C<on_connect> callback.

    $kernel->post('IKC', 'monitor', $remote_kernel_id, $states);

=over 3

=item C<$remote_kernel_id>

Name or alias or IKC specifier of the remote kernel you wish to monitor. 
You can also specify C<*> to monitor ALL remote kernels.  If you do, your
monitor will be called several times for a given kernel.  This is because a
kernel has one name and many aliases.  For example, a remote kernel will
have a unique ID within the local kernel, a name (passed to or generated by
create_ikc_{kernel,client}) and a globaly unique ID assigned by the remote
kernel via $kernel->ID.  This suprises some people, but see the short note
after the explanation of the callback parameters.

Note: An effort has been made to insure that when monitoring C<*>,
L</register> is first called with the remote kernel's unique ID, and
subsequent calls are aliases.  This can't be guaranteed at this time,
however.

=item C<$states>

Hashref that specifies what callback states are called when something
interesting happens.  If $state is empty or undef, the session will no
longer monitor the given remote kernel.  

=back

=head2 Callback states


The following states can be monitored:



=over 6

=item C<channel>

Called when a channel becomes ready or goes away.  ARG3 is either C<ready>
or C<close>.  ARG4 is the numerical ID of the channel's session.  See
L</CHANNELS> below.

=item C<register>

Called when a remote kernel or alias is registered.  This is equivalent to
when the connection phase is finished.

=item C<unregister>

Called when a remote kernel or alias is unregistered.  This is equivalent to
when the remote kernel disconnects.

=item C<subscribe>

Called when IKC succeeds in subscribing to a remote session.  ARG3 is an
IKC::Specifier of what was subscribed to.  Use this for posting to the proxy
session.

=item C<unsubscribe>

Called when IKC succeeds in unsubscribing from a remote session.

=item C<shutdown>

You are informed whenever someone tries to do a sane shutdown of IKC and all
peripheral sessions.  This will called only once, after somebody posts an
IKC/shutdown event.

=item C<error>

You are informed of errors in local and remote kernels.  ARG3 is the operation that
failed. ARG4 is the error message.  See L</ERRORS> below.

=item C<data>

Little bit of data (can be scalar or reference) that is passed to the
callback.  This allows you to more magic.

=back



The callback states are called the following parameters :

=over 6

=item C<ARG0>

Name of the kernel that was passed to poe://*/IKC/monitor

=item C<ARG1>

ID or alias of remote kernel from IKC's point of view.

=item C<ARG2>

A flag.  If this is true, then ARG1 is the remote kernel unique ID, if
false, then ARG1 is an alias.  This is mostly useful when monitoring C<*>
and is in fact a bit bloatful.

=item C<ARG3>

C<$state-E<gt>{data}> ie any data you want.

=item C<ARG4> ... C<ARGN>

Callback-specific parameters.  See above.  

=back

Most of the time, ARG0 and ARG1 will be the same.  Exceptions are if you are
monitoring C<*> or if you supplied a full IKC event specifier to
IKC/monitor rather then just a plain kernel name. 




=head2 Short note about monitoring all kernels with C<*>

There are 2 reasons circonstances in which you will be monitoring all remote
kernels : names known in advance and names unknown in advance.

If you know kernel names in advance, you might be better off monitoring a
given kernel name.  However, you might prefer doing a case-like compare on
ARG1 (with regexes, say).  This would be useful for clustering, where
various redundant kernels could follow a naming convention like 
[application]-[host], so you could compare C<ARG1> with C</^credit-/> to
find out if you want to set up specific things for that kernel.

Not knowing the name of a kernel in advance, you could be doing some sort of
autodiscovery or maybe just monitoring for debuging, logging or book-keeping
purposes.  You obviously don't want to do autodiscovery for every alias of
every kernel, only for the "cannonical name", hence the need for ARG2.

=head2 Short note the second

You are more then allowed (in fact, you are encouraged) to use the same
callback states when monitoring multiple kernels.  In this case, you will
find ARG0 useful for telling them apart.


    $kernel->post('IKC', 'monitor', '*', 
                    {register=>'remote_register',
                     unregister=>'remote_unregister',
                     subscribe=>'remote_subscribe',
                     unsubscribe=>'remote_unsubscribe',
                     data=>'magic box'});

Now remote_{register,unregister,subscribe,unsubscribe} is called for any
remote kernel.

    $kernel->post('IKC', 'monitor', 'Pulse', {register=>'pulse_connected'});

C<pulse_connected> will be called in current session when you succeed in
connecting to a kernel called 'Pulse'.

    $kernel->post('IKC', 'monitor', '*');

Session is no longer monitoring all kernels, only 'Pulse'.

    $kernel->post('IKC', 'monitor', 'Pulse', {});

Now we aren't even interested in 'Pulse';


=head1 CHANNELS

Previous versions of IKC did not adequately allow you to control a connection.
With 0.2400 we added a much needed feature.

Each connection to a remote kernel is handled by a channel session.  You
find out the session's ID by monitoring for L</channel> operations.  You may
close a channel and the corresponding connection to the remote kernel by
sending it a L</shutdown> event.

    sub _start {
        # set up the monitor
        $poe_kernel->call( IKC => monitor => '*' => { channel => 'channel' } );
    }

    sub channel {
        my( $self, $rid, $rkernel, $real, $data, $op, $channel ) = @_[ OBJECT, ARG0..$#_ ];
        return unless $real;    # only care about the real kernel ID
        if( $op eq 'ready' ) {  # new channel is ready
            $self->{channel}{ $rkernel } = $channel;
        }
        elsif( $op eq 'close' ) {   # channel is gone
            delete $self->{channel}{ $rkernel };
        }
    }

    # this an event posted from your controler logic
    sub close_channel {
        my( $self, $rkernel ) = @_[ OBJECT, ARG0 ];
        # tell the channel to close
        $poe_kernel->post( $self->{channel}{ $rkernel } => 'shutdown' );
    }



=head1 ERRORS

Previous versions of IKC did not adequately allow you to monitor for errors
on a connection.  With 0.2400 we started monitoring errors.

There are 2 step during which you can have errors: when opening the connection and
during message exchange.  These 2 steps are handled diffrently.

You use L<POE::Component::IKC::Client/on_error> and
L<POE::Component::IKC::Server/on_error> to receive errors while a connection
is being opened.  Note that this includes the initial IKC handshake.

    sub on_error 
    {
        my( $op, $errnum, $errstr ) = @_;
        # Handle this like you would any POE socket error
        # But remember you can't rely on your session being active
    }


You use L</monitor> on error to receive errors during message exchange.  ARG3 is the
name of the operation.  ARG4 is the error message.  Current operations are:

=over 4

=item remote-request

Remote kernel was unable to parse a request that was sent from the local kernel.

=item remote-check

Remote kernel has not published an event that was sent from the local kernel.

=item remote-resolve

Remote kernel could not find a session that could handle the request.

=item remote-invocation

Remote kernel had an error when it tried to invoke the request handler. 
Please note this will not catch errors in the request handler, but only errors
in the thunk.


=item local-request

=item local-check

=item local-resolve

=item local-invocation

These 4 operations are the local equivalent of the previous 4.  They are
intented for logging.  In general no actions are required.

Note that 'local' and 'remote' refer to where the operation happened, not
where the request originated.  As an example, kernel A sends a
poe://B/foo/bar request to kernel B.  Kernel B has not published that event. 
Monitors on kernel A will see L<remote-check>.  Monitors on kernel B will
see L<local-check>.

=item channel-error

Receive channel errors during message exchange.   Channel errors are
equivalent to POE wheel errors.  The message will be C<"[$errnum] $errstr">.

=item subscribe

Failure to subscribe to a remote session.

=item fork

L<POE::Component::IKC::Server> failed to fork.

=item resolve

Error when trying to find a remote kernel or session.

=back

Example monitor for error events:

    sub monitor_error
    {   
        my( $self, $rid, $kernel, $real, $data, $op, $message ) = 
                @_[ OBJECT, ARG0 ... $#_ ];
        if( $op =~ /^channel-/ and $message =~ /\[(\d+)\] (.*)/ ) {
            return unless $real;
            my( $errnum, $errstr ) = ( $1, $2 );
            if( $op eq 'channel-read' and $errnum == 0 ) {
                warn "Connection closed";
                return;
            }
        }
        warn "Error during $op: $message";
    }

In particular, you will note we don't do anything when we detect the channel
closed.  Instead, it is recommended to attempt reconnection in the L</unregister> event.



=head1 EXPORTED FUNCTIONS

=head2 C<create_ikc_responder>

DEPRECATED.  Please use 
    
    POE::Compontent::IKC::Responder->spawn();



=head1 PROXY SENDER

Event handlers invoked via IKC will have a proxy SENDER session. You may use
it to post back to the remote session.   

    $poe_kernel->post( $_[SENDER], 'response', @args );

Normally this proxy session is available during the invocation of the event
handler.  You may claim it for longer by setting an external reference:

    $heap->{remote} = $_[SENDER]->ID;
    $poe_kernel->refcount_increment( $heap->{remote}, 'MINE' );

POE::Component::IKC will detect this and create a new proxy session for future
calls.  It will then be UP TO YOU to free the session:

    $poe_kernel->refcount_decrement( $heap->{remote}, 'MINE' );

Note that you will have to publish any events that will be posted back.


=head1 BUGS

Sending session references and coderefs to a foreign kernel is a bad idea.
At some point it would be desirable to recurse through the paramerters and
and turn any session references into state specifiers.

The C<rsvp> state in call is a bit problematic.  IKC allows it to be posted
to once, but doesn't check to see if the foreign kernel is the right one.

C<retract> does not currently tell foreign kernels that have subscribed to a
session/state about the retraction.

C<call()>ing a state in a proxied foreign session doesn't work, for obvious
reasons.



=head1 AUTHOR

Philip Gwyn, <perl-ikc at pied.nu>

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2014 by Philip Gwyn.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<http://www.perl.com/language/misc/Artistic.html>

=head1 SEE ALSO

L<POE>, 
L<POE::Component::IKC::Server>, 
L<POE::Component::IKC::Client>,
L<POE::Component::IKC::ClientLite>,
L<POE::Component::IKC::Channel>,
L<POE::Component::IKC::Proxy>,
L<POE::Component::IKC::Freezer>,
L<POE::Component::IKC::Specifier>.


=cut


