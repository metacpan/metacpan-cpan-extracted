package POE::Component::IKC::ClientLite;

############################################################
# $Id: ClientLite.pm 1247 2014-07-07 09:06:34Z fil $
# By Philp Gwyn <fil@pied.nu>
#
# Copyright 1999-2014 Philip Gwyn.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Contributed portions of IKC may be copyright by their respective
# contributors.  

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $error $request);

use Socket;
use IO::Socket;
use IO::Select;
use POE::Component::IKC::Specifier;
use POE::Component::IKC::Protocol;
use Data::Dumper;
use POSIX qw(:errno_h);
use Carp;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(create_ikc_client);
$VERSION = '0.2402';

sub DEBUG { 0 }

$request=0;

###############################################################################
sub spawn
{
    my( $package, %parms ) = @_;

#    $parms{on_connect}||=sub{};         # would be silly for this to be blank
    $parms{ip}||='localhost';           
    $parms{port}||=603;                 # POE! (almost :)
    $parms{name}||="Client$$";
    $parms{connect_timeout} ||= $parms{timeout} || 30;
    $parms{timeout}||=30;
    $parms{serialiser}||=_default_freezer();
    $parms{block_size} ||= 65535;
    $parms{protocol} ||= 'IKC0';

    my %self;
    @self{qw(ip port name serialiser timeout connect_timeout block_size protocol)}=
            @parms{qw(ip port name serialiser timeout connect_timeout block_size protocol)};

    eval {
        @{$self{remote}}{qw(freeze thaw)}=_get_freezer($self{serialiser});
    };

    if($@) {
        $self{error}=$error=$@;
        return;
    }
    my $self=bless \%self, $package;
    $self->{remote}{aliases}={};
    $self->{remote}{name}="$self->{ip}:$self->{port}";

    $self->connect and return $self;
    return;
}

sub create_ikc_client
{
    my(%parms)=@_;
    my $package = $parms{package} || __PACKAGE__;
    carp "create_ikc_client is deprecated; use $package->spawn instead";
    $package->spawn( %parms );
}

sub name { $_[0]->{name}; }

#----------------------------------------------------
sub connect
{
    my($self)=@_;
    return 1 if($self->{remote}{connected} and $self->{remote}{socket} and
                $self->ping);  # are we already connected?

    my $remote=$self->{remote};
    delete $remote->{socket};
    delete $remote->{connected};

    my $name=$remote->{name};
    DEBUG && print "Connecting to $name...\n";
    my( $sock, $resp );

    my $DONE = 0;
    eval {
        local $SIG{__DIE__}='DEFAULT';
        local $SIG{__WARN__};
        local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
        $sock=IO::Socket::INET->new( PeerAddr=>$self->{ip},
                                     PeerPort=>$self->{port},
                                     # Proto=>'tcp', 
                                     Timeout=>$self->{connect_timeout}
                                    );
        die "Unable to connect to $name: $!\n" unless $sock;
        $sock->autoflush(1);
        local $/="\cM\cJ";
        local $\="\cM\cJ";

        # Attempt IKC0 protocol
        if( $self->{protocol} eq 'IKC0' ) {
            if( $self->_protocol_IKC0( $sock ) ) {
                $DONE = 1;
                return;
            }
        }

        # Fallback to IKC protocol
        $sock->print('HELLO');
        my $resp;

        alarm( $self->{connect_timeout} );
        while (defined($resp=$sock->getline))       # phase 000
        {
            chomp($resp);
            last if $resp eq 'DONE';
            die "Invalid IAM response from $name: $resp\n" 
                unless $resp=~/^IAM\s+([-:.\w]+)$/;
            $remote->{name}||=$1;
            $self->{ping}||="poe://$1/IKC/ping";
            $remote->{aliases}->{$1}=1;
            $sock->print('OK');
        }
        die "Phase 000: $!\n" unless defined $resp;


        alarm( $self->{connect_timeout} );
        $sock->print("IAM $self->{name}");          # phase 001
        chomp($resp=$sock->getline);
        die "Phase 001: $!\n" unless defined $resp;
        die "Didn't get OK from $name\n" unless $resp eq 'OK';
        $sock->print("DONE");

        alarm( $self->{connect_timeout} );
        $sock->print("FREEZER $self->{serialiser}");# phase 002
        chomp($resp=$sock->getline);
        die "Phase 002: $!\n" unless defined $resp;
        die "$name refused $self->{serialiser}\n" unless $resp eq 'OK';

        alarm( $self->{connect_timeout} );
        $sock->print('WORLD');                      # phase 003
        chomp($resp=$sock->getline);
        die "Phase 003: $!\n" unless defined $resp;
        die "Didn't get UP from $name\n" unless $resp eq 'UP';        
        $DONE = 1;
    };
    alarm( 0 );
    if($@)
    {
        $self->{error}=$error=$@;
        if( $error eq "alarm\n" ) {
            $self->{error}=$error="Timeout connecting to $self->{ip}:$self->{port}";
        }
        return;
    } 
    $remote->{socket}=$sock;
    $remote->{connected}=1;
    return 1;
}

#----------------------------------------------------
sub _protocol_IKC0
{
    my( $self, $sock ) = @_;

    my $remote=$self->{remote};
    my $name=$remote->{name};
    my $resp;

    my $setup = POE::Component::IKC::Protocol::__build_setup(
                            [ $self->{name} ], [ $self->{serialiser} ] );
    $sock->print( $setup ); 
    alarm( $self->{connect_timeout} );
    while (defined($resp=$sock->getline))       # phase 010
    {
        chomp($resp);
        return if $resp eq 'NOT';                 # move to phase 000
        die "Phase 010: Invalid response from $name: $resp\n" 
                                unless $resp =~ /^SETUP (.+)$/;
        my $neg = POE::Component::IKC::Protocol::__neg_setup( $1 );
        if( $neg->{bad} ) {
            $sock->print( 'NOT' );
            next;
        }
        die "Phase 010: Refused $self->{serialiser}, wants $neg->{freezer}[0]" 
                            unless $neg->{freezer}[0] eq $self->{serialiser};
        $remote->{name} = $neg->{kernel}[0];
        foreach my $a ( @{ $neg->{kernel} } ) {
            $remote->{aliases}{$a} = 1;
        }
        return 1;
    }
}


#----------------------------------------------------
sub error
{
    return $_[0]->{error} if @_==1;
    return $error;
}
#----------------------------------------------------
sub ping
{
    my($self)=@_;
    my $ret=eval {
        my $rsvp={kernel=>$self->{name}, 
                  session=>'IKC', state=>'pong'
                 };
        my $r=$self->_send_msg({event=>$self->{ping}, params=>'PING', 
                                rsvp=>$rsvp});
        return unless $r;
        my $pong=$self->_response($rsvp);
        return 1 if $pong and $pong eq 'PONG';
    }; 
    $self->{error}=$error=$@ if $@;
    $self->{remote}{connected}=$ret;
    return $ret;
}

#----------------------------------------------------
sub disconnect
{
    my($self)=@_;
    # 2001/01 why did we try to unregister ourselves?  unregister wouldn't
    # be safe for remote kernels anyway
    # $self->call('IKC/unregister', $self->{name}) if $self->{remote};
    delete @{$self->{remote}}{qw(socket connected name aliases)};
    $self->{remote}={};
}

sub DESTROY 
{
    my($self)=@_;
    $self->disconnect;
}
sub END
{
    DEBUG and print "end\n";
}

#----------------------------------------------------
# Post an event, maybe waits for a response and throws it away
#
sub post
{
    my($self, $spec, $params)=@_;
    unless(ref $spec or $spec=~m(^poe:)) {
        
        unless($self->{remote}{name}) {
            $self->{error}=$error="Attempting to post $spec to unknown kernel";
            # carp $error;
            return;
        }

        $spec="poe://$self->{remote}{name}/$spec";
    }

    my $ret=eval { 
        return 0 if(0==$self->_try_send({event=>$spec, params=>$params}));
        1;
    };
    if($@) {
        $self->{error}=$error=$@;
        return;
    }
    return $ret;
}

#----------------------------------------------------
# posts an event, waits for the response, returns the response
sub call
{
    my($self, $spec, $params)=@_;
    $spec="poe://$self->{remote}{name}/$spec" unless ref $spec or $spec=~m(^poe:);

    my $rsvp={kernel=>$self->{name}, session=>'IKCLite',
              state=>'response'.$request++};
    
    my $req={event=>$spec, params=>$params, 
             rsvp=>$rsvp, 'wantarray'=>wantarray(),
            };
    my @ret=eval { 
        return unless $self->_try_send($req); 
        DEBUG && print "Waiting for response...\n";
        return $self->_response($rsvp, $req->{wantarray});
    };
    if($@) {
        $self->{error}=$error=$@;
        return;
    }
    return @ret if $req->{wantarray};
    return $ret[0];
}

#----------------------------------------------------
# posts an event, waits for the response, returns the response
# this differs from call() in that the foreign server may
# need many states before getting a response
sub post_respond
{
    my($self, $spec, $params)=@_;
    $spec="poe://$self->{remote}{name}/$spec" unless ref $spec or $spec=~m(^poe:);

    my $ret;
    my $rsvp={kernel=>$self->{name}, session=>'IKCLite',
              state=>'response'.$request++};
    $ret=eval { 
        return unless $self->_try_send({event=>$spec, 
                                        params=>[$params, $rsvp], 
                                       }); 
        DEBUG && print "Waiting for response...\n";
        return $self->_response($rsvp);
    };
    if($@) {
        $self->{error}=$error=$@;
        return;
    }
    return $ret;
}

#----------------------------------------------------
sub responded
{
    my( $self, $state ) = @_;

    my $wantarray = wantarray;
    my $rsvp = { kernel=>$self->{name}, 
                 session=>'IKCLite',
                 state=>$state
               };
    my @ret = eval {
            DEBUG && print "Waiting for response...\n";
            return $self->_response($rsvp, $wantarray);
        };
    if($@) {
        $self->{error}=$error=$@;
        return;
    }
    return @ret if wantarray;
    return $ret[0];
}



#----------------------------------------------------
sub _from
{
    my( $self ) = @_;
    return { kernel => $self->{name},
             session => 'IKCLite',
             # state   => 'IKC:lite'
           }
}

#----------------------------------------------------
sub _try_send
{
    my($self, $msg)=@_;
    return unless $self->{remote}{connected} or $self->connect();

    $msg->{from} ||= $self->_from;

    my $ret=$self->_send_msg($msg);
    DEBUG && print "Sending message...\n";
    if(defined $ret and $ret==0) {
        return 0 unless $self->connect();
        DEBUG && print "Retry message...\n";
        $ret=$self->_send_msg($msg);
    }
    return $ret;
}

#----------------------------------------------------
sub _send_msg
{
    my($self, $msg)=@_;

    my $e=$msg->{rsvp} ? 'call' : 'post';

    my $to=specifier_parse($msg->{event});
    unless($to) {
        croak "Bad message ", Dumper $msg;
    }
    unless($to) {
        warn "Bad or missing 'to' parameter '$msg->{event}' to poe:/IKC/$e\n";
        return;
    }
    unless($to->{session}) {
        warn "Need a session name in poe:/IKC/$e";
        return;
    }
    unless($to->{state})   {
        carp "Need a state name in poe:IKC/$e";
        return;
    }

    my $frozen = $self->{remote}{freeze}->($msg);
    my $raw=length($frozen) . "\0" . $frozen;

    unless($self->{remote}{socket}->opened()) {
        $self->{connected}=0;
        $self->{error}=$error="Socket not open";
        return 0;
    }
    unless($self->{remote}{socket}->syswrite($raw, length $raw)) {
        $self->{connected}=0;
        return 0 if($!==EPIPE);
        $self->{error}=$error="Error writing: $!\n";
        return 0;
    }
    return 1;
}


#----------------------------------------------------
sub _response
{
    my($self, $rsvp, $wantarray)=@_;

    $rsvp=specifier_parse($rsvp);
    my $remote=$self->{remote};

    my $start = time;
    my $stopon = $start + $self->{timeout};

    my $select=IO::Select->new() or die $!;     # create the select object
    $select->add($remote->{socket});

    my(@ready, $s, $raw, $frozen, $ret, $l, $need);
    $raw='';

    my $blocks = 0;
    do {{
        my $timeout = $stopon-time;
        if( $timeout <= 0 ) {
            $timeout = 1;
        }
#        Torture::my_warn( "timeout=$timeout" );
        @ready=$select->can_read( $timeout );   # this is the select
        unless( @ready ) {                     # nothing ready == timeout
            # Torture::my_warn( 'select hates me' );
            last;
        }
    
        foreach $s (@ready)                     # let's see what's ready...
        {
            die "Hey!  $s isn't $remote->{socket}" 
                unless $s eq $remote->{socket};
        }
        DEBUG && print "Got something...\n";
        
                                    # read in another chunk
        $l = $remote->{socket}->sysread($raw, $self->{block_size}, 
                                                length($raw)); 

        unless(defined $l) {                    # disconnect, maybe?
            $remote->{connected}=0 if $!==EPIPE;               
            die "Error reading: $!\n";
        }
        $blocks ++;

        if(not $need and $raw=~s/(\d+)\0//s) {  # look for a marker?
            $need=$1 ;
            DEBUG && print "Need $need bytes...\n";
        }

        next unless $need;                      # still looking...

        if(length($raw) >= $need)               # do we have all we want?
        {
            # Torture::my_warn( 'Got it all' );
            DEBUG && print "Got it all...\n";

            $frozen=substr($raw, 0, $need);     # seems so...
            substr($raw, 0, $need)='';
            my $msg=$self->{remote}{thaw}->($frozen);   # thaw the message
            DEBUG && print "msg=", Dumper $msg;
            my $to=specifier_parse($msg->{event});

            die "$msg->{params}\n" if($msg->{is_error});    # throw an error out
            DEBUG && print "Not an error...\n";

                # make sure it's what we're waiting for...
            if($to->{session} ne 'IKC' and $to->{session} ne 'IKCLite')
            {
                warn "Unknown session $to->{session}\n";
                DEBUG && print "Not for us!  ($to->{session})...\n";
                next;
            }
            if($to->{session} ne $rsvp->{session} or
               $to->{state} ne $rsvp->{state})
            {
                warn specifier_name($to). " received, expecting " .
                     specifier_name($rsvp). "\n";
                DEBUG && print "Not for us!  ($to->{session}/$to->{state})...\n";
                next;
            }

            DEBUG and print "wantarray=$wantarray\n";
            if( $wantarray ) {
                DEBUG and print "Wanted an array\n";
                return @{$msg->{params}} if ref $msg->{params} eq 'ARRAY';
            }
            return $msg->{params};              # finaly!
        }
        # Torture::my_warn( "blocks=$blocks l=$l need=$need, got=", length $raw );
    }} while ($stopon >= time) ;     # do it until time's up

    $remote->{connected}=0;
    confess "Timed out waiting for response ", specifier_name( $rsvp );
#    die "Timed out waiting for response ", specifier_name( $rsvp ), "\n",
#        "start=$start stopon=$stopon now=", time;
    return;
}









#------------------------------------------------------------------------------
# Try to require one of the default freeze/thaw packages.
sub _default_freezer
{
  local $SIG{'__DIE__'} = 'DEFAULT';
  my $ret;

  foreach my $p (qw(Storable FreezeThaw POE::Component::IKC::Freezer)) {
    my $q=$p;
    $q=~s(::)(/)g;
    eval { require "$q.pm"; import $p ();};
    DEBUG and warn $@ if $@;
    return $p if $@ eq '';
  }
  die __PACKAGE__." requires Storable or FreezeThaw or POE::Component::IKC::Freezer\n";
}

sub _get_freezer
{
    my($freezer)=@_;
    unless(ref $freezer) {
    my $symtable=$::{"main::"};
    my $loaded=1;                       # find out of the package was loaded
    foreach my $p (split /::/, $freezer) {
        unless(exists $symtable->{"$p\::"}) {
            $loaded=0;
            last;
        }
        $symtable=$symtable->{"$p\::"};
    }

    unless($loaded) {        my $q=$freezer;
        $q=~s(::)(/)g;
        eval {require "$q.pm"; import $freezer ();};
        croak $@ if $@;
      }
    }

    # Now get the methodes we want
    my $freeze=$freezer->can('nfreeze') || $freezer->can('freeze');
    carp "$freezer doesn't have a freeze method" unless $freeze;
    my $thaw=$freezer->can('thaw');
    carp "$freezer doesn't have a thaw method" unless $thaw;

    # If it's an object, we use closures to create a $self->method()
    my $tf=$freeze;
    my $tt=$thaw;
    if(ref $freezer) {
        $tf=sub {  return $freeze->($freezer, @_) };
        $tt=sub {  return ($thaw->($freezer, @_))[0] };
    }
    else {
        # FreezeThaw::thaw returns an array now!  We only want the first
        # element.
        $tt=sub {  return ($thaw->( @_ ))[0] };
    }
    return($tf, $tt);
}

1;

__END__


=head1 NAME

POE::Component::IKC::ClientLite - Small client for IKC

=head1 SYNOPSIS

    use POE::Component::IKC::ClientLite;

    $poe = POE::Component::IKC::ClientLite->new(port=>1337);
    die POE::Component::IKC::ClientLite::error() unless $poe;

    $poe->post("Session/event", $param)
        or die $poe->error;
    
    # bad way of getting a return value
    my $foo=$poe->call("Session/other_event", $param)
        or die $poe->error;

    # better way of getting a return value
    my $ret=$poe->post_respond("Session/other_event", $param)
        or die $poe->error;

    # make sure connectin is aliave
    $poe->ping() 
        or $poe->disconnect;

=head1 DESCRIPTION

ClientLite is a small, pure-Perl IKC client implementation.  It is very basic
because it is intented to be used in places where POE wouldn't fit, like
mod_perl.

It handles automatic reconnection.  When you post an event, ClientLite will
try to send the packet over the wire.  If this fails, it tries to reconnect. 
If it can't it returns an error.  If it can, it will send he packet again.  If
*this* fails, well, tough luck.

=head1 METHODS

=head2 spawn

    my $poe = POE::Component::IKC::ClientLite->spawn( %params );

Creates a new PoCo::IKC::ClientLite object.  Parameters are supposedly
compatible with PoCo::IKC::Client, but unix sockets aren't
handled yet...  What's more, there are 3 additional parameters:

=over 4

=item block_size

Size, in octets (8 bit bytes), of each block that is read from the socket
at a time.  Defaults to C<65535>.

=item timeout

Time, in seconds, that C<call> and C<post_respond> will wait for a
response.  Defaults to 30 seconds.

=item connect_timeout

Time, in seconds, to wait for a phase of the connection negotiation to
complete.  Defaults to C<timeout>.  There are 4 phases of negotiation, so a
the default C<connect_timeout> of 30 seconds means it could potentialy take
2 minutes to connect.

=item protocol

Which IKC negociation protocol to use.  The original protocol (C<IKC>) was
synchronous and slow.  The new protocol (C<IKC0>) sends all information at
once.  IKC0 will degrade gracefully to IKC, if the client and server don't
match.

Default is IKC0.

=back

=head2 connect

    $poe->connect or die $poe->error;

Connects to the remote kernel if we aren't already. You can use this method
to make sure that the connection is open before trying anything.

Returns true if connection was successful, false if not.  You can check
L</error> to see what the problem was.


=head2 disconnect

Disconnects from remote IKC server.

=head2 error

    my $error=POE::Component::IKC::ClientLite::error();
    $error=$poe->error();

Returns last error.  Can be called as a object method, or as a global
function.

=head2 post

    $poe->post($specifier, $data);

Posts the event specified by C<$specifier> to the remote kernel.  C<$data>
is any parameters you want to send along with the event.  It will return 1
on success (ie, data could be sent... not that the event was received) and
undef() if we couldn't connect or reconnect to remote kernel.

=head2 post_respond

    my $ret=$poe->post_respond($specifier, $data);

Posts the event specified by C<$specifier> to the remote kernel.  C<$data>
is any parameters you want to send along with the event.  It waits until
the remote kernel sends a message back and returns it's payload.  Waiting
timesout after whatever you value you gave to 
L<POE::Component::IKC::Client>->spawn.

Events on the far side have to be aware of post_respond.  In particular,
ARG0 is not C<$data> as you would expect, but an arrayref that contains
C<$data> followed by a specifier that should be used to post back.

    sub my_event
    {
        my($kernel, $heap, $args)=@_[KERNEL, HEAP, ARG0];
        my $p=$args->[0];
        $heap->{rsvp}=$args->[1];
        # .... do lotsa stuff here
    }

    # eventually, we are finished
    sub finished
    {
        my($kernel, $heap, $return)=@_[KERNEL, HEAP, ARG0];
        $kernel->post(IKC=>'post', $heap->{rsvp}, $return);
    }

=head2 responded

    my $ret = $poe->responded( $state );
    my @ret = $poe->responded( $state );

Waits for $state from the remote kernel.  C<$state> must be a simple state
name.  Any requests from the remotre kernel for other states are rejected.
A remote handler would respond by using the 
L<proxy sender|POE::Component::IKC::Responder/"PROXY SENDER">.


=head2 call

    my $ret=$poe->call($specifier, $data);

This is the bad way to get information back from the a remote event. 
Follows the expected semantics from standard POE.  It works better then
post_respond, however, because it doesn't require you to change your
interface or write a wrapper.

=head2 ping

    unless($poe->ping) {
        # connection is down!  connection is down!
    }
    
Find out if we are still connected to the remote kernel.  This method will
NOT try to reconnect to the remote server

=head2 name

Returns our local name.  This is what the remote kernel thinks we are
called.  I can't really say this is the local kernel name, because, well,
this isn't really a kernel.  But hey.


=head1 FUNCTIONS

=head2 create_ikc_client

DEPRECATED.  Use L<POE::Compoent::IKC::ClientLite/spawn> instead.

=head1 AUTHOR

Philip Gwyn, <perl-ikc at pied.nu>

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2014 by Philip Gwyn.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<http://www.perl.com/language/misc/Artistic.html>

=head1 SEE ALSO

L<POE>, L<POE::Component::IKC>

=cut




