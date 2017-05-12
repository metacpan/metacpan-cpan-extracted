package Net::PSYC::Event;
#
# Net::PSYC::Event - Event wrapper for different event systems.
#
# nur weil diese sachen im jahre 2003 aus Net::PSYC.pm ausgelagert
# wurden, und bis dahin nur mit IO::Select gearbeitet haben,
# haben sie dennoch und nach wie vor den originalcopyright... ;)
#
# aha, na dann sag mir auch mal, welche der zeilen aus net::psyc stammen. es ist
# mir auch irgendwie wurscht. oder nein, vielleicht: welches der konzepte...
#
# TODO: maybe extra arguments in add are much nicer.. also to avoid
# cyclic data structures.. we will see..

use strict;

use base qw(Exporter);

my (%unl2obj, %obj2unl, %unl2wrapper, %context2obj);
# context2obj is an approach to be able to route context. Clients use this too.
my (%PSYC_SOCKETS);

our $VERSION = '0.4';

our @EXPORT = qw();
our @EXPORT_OK = qw(register_uniform unregister_uniform watch forget init start_loop stop_loop add remove can_read can_write has_exception revoke);

import Net::PSYC qw(W sendmsg same_host send_mmp parse_uniform parse_psyc MERGEVAR FORK);

# dirty_wait hack!
sub PSYC_SOCKETS () { \%PSYC_SOCKETS }

# vielleicht sollte man psyc-state auf dauer mit register_uniform verknüpfen. 
# so wie ich es schonmal geplant hatte. Vor allem, was tut man mit den 
# register_uniform() calls. bekommen die _einen_ state oder nochmal getrennt 
# nach source und target mehrere. Sind user in der lage das selbst zu
# entscheiden/begreifen??
sub register_uniform {
    my ($unl, $obj) = @_;

    $unl ||= 'default';
    
    if (ref $obj) {
	$unl2obj{$unl} = $obj;
	$obj2unl{$obj} = $unl;
	unless ($obj->can('msg')) {
	    W0('%s does not have a msg()-method! Cannot deliver packet!',
		ref $obj);
	    return $obj;
	}
	unless ($obj->can('diminish') && $obj->can('augment') 
	&& $obj->can('assign') && $obj->can('reset')) {
	    my $o = $obj;
	    $obj = Net::PSYC::Event::Wrapper->new($o, $unl);
	}
    } else {
	$obj ||= caller; # just a class.. that sux.
	$unl2obj{$unl} = $obj;
	$obj2unl{$obj} = $unl;
	if (defined($unl) && exists $unl2wrapper{$unl} && $unl2wrapper{$unl}->{'obj'} eq $obj) {
	    return $unl2wrapper{$unl};
	}
	unless (eval "$obj->can('msg')") {
	    W0('%s does not have a msg() function! Cannot deliver packet!',
		scalar($obj));
	    return $obj;
	}
	$obj = Net::PSYC::Event::Wrapper->new($obj, $unl);
    }
    $unl2wrapper{$unl} = $obj;
    W1('register_uniform(%s, %s)', $unl, $obj->{'obj'});
    
    return $obj;
}

sub find_context {
    my ($context) = @_;
    return $context2obj{$context};
}

sub register_context {
    my ($context, $obj) = @_;
    unless (ref $obj) {
	W0('register_context needs an object to register for.');
	return 0;
    }
    $context2obj{$context} = $obj;
}

sub find_object {
    my $uni = shift;
    my $o = $unl2obj{$uni};
    unless ($o) {
	my $h = parse_uniform($uni);
	if (ref $h) {
	    $o = $unl2obj{$h->{'object'}};
	}
    }
    $o ||= $unl2obj{'default'};
    return $o;
}

sub find_uniform {
    return $obj2unl{$_[0]};  
}

sub unl2wrapper {
    my $unl = shift;
    my $o =  $unl2wrapper{$unl};
    unless ($o) {
	my $h = parse_uniform($unl);
	if (ref $h) {
            $o = $unl2wrapper{$h->{'object'}};
        }
    }
    $o ||= $unl2wrapper{'default'};
    return $o;
}

sub unregister_uniform {
    my $unl = shift;
    delete $obj2unl{$unl2obj{$unl}};
    delete $unl2wrapper{$unl};
    delete $unl2obj{$unl};
    return 1;
}

#   watch(psyc-socket-object)
sub watch {
    my $obj = shift;
    W2('watch(%s)', scalar($obj));
    $PSYC_SOCKETS{fileno($obj->{'SOCKET'})} = $obj;
    add($obj->{'SOCKET'}, 'r', \&deliver );
    #add($obj->{'SOCKET'}, 'w', sub { $obj->write() }, 0);
}

#   forget(psyc-socket-object)
sub forget {
    my $obj = shift;
    W2('forget(%s)', scalar($obj));
    delete $PSYC_SOCKETS{fileno($obj->{'SOCKET'})};
    remove($obj->{'SOCKET'});
}

sub deliver {
    my $socket = shift;
    my $repeat = shift;
    return 1 if (!exists $PSYC_SOCKETS{fileno($socket)});
    my $obj = $PSYC_SOCKETS{fileno($socket)};
    
    unless ( $repeat || $obj->read() ) { # connection lost
	Net::PSYC::shutdown($obj);
	W0('Lost connection to %s:%s', $obj->{'R_IP'}, $obj->{'R_PORT'});
	return 1;
    }

    my ($MMPvars, $MMPdata) = $obj->recv(); # get a packet
    
    return 1 if (!defined($MMPvars)); # incomplete .. stop
    
    return -1 if ($MMPvars == 0); # fragment .. keep on going
    
    if ($MMPvars == -1) { # shutdown
	Net::PSYC::shutdown($obj);
	W0('Someone is making trouble: %s', $MMPdata);
	W0('Closing connection to %s:%s.', $obj->{'R_IP'}, $obj->{'R_PORT'});
	return 1;
    }

    if ($MMPvars->{'_target'}) {
	my $t = parse_uniform($MMPvars->{'_target'});

	unless (ref $t) {
	    Net::PSYC::shutdown($obj);
	    W0('Could not parse that _target: %s.', $MMPvars->{'_target'});
	    W0('Closing connection to %s:%s.', $obj->{'R_IP'}, 
		$obj->{'R_PORT'});
	    return 1;
	}
	unless (same_host($t->{'host'}, '127.0.0.1')) {
	    # this is a remote uni
	    if ($obj->TRUST > 10) { # we relay
		send_mmp($MMPvars->{'_target'}, $MMPdata, $MMPvars);
		return -1;
	    } # we dont relay
	    sendmsg($MMPvars->{'_source'},
		    '_error_relay_denied',
		    "I won't deliver that!");
	    return -1;
	}
    }
    
    my $cb;
    unless (exists $MMPvars->{'_target'}) {
	$cb = unl2wrapper(0);
    } else {
	$cb = unl2wrapper($MMPvars->{'_target'});
    }
    
    unless ($cb) {
	W0('Found no recipient for %s. Dropping message.', 
	    $MMPvars->{'_target'});
	return -1;
    }

    my $iscontext = exists $MMPvars->{'_context'};
    my $t = $MMPvars->{'_context'} || $MMPvars->{'_source'};
    
    my ($mc, $data, $vars) = parse_psyc($MMPdata, $obj->{'LF'});
=state
    my ($mc, $data, $vars) = parse_psyc($MMPdata, $obj->{'LF'}, $cb, 
					$iscontext, $t);
=cut

    # means.. no mc but proper vars. its a state change.
    return -1 if ($mc eq '');

    if (!$mc && $mc == 0) {
	W0('Broken PSYC packet from %s. Parser says: %s', $obj->{'peeraddr'}, 
	    $data);
	W0('Closing connection to %s:%s.', $obj->{'R_IP'}, $obj->{'R_PORT'});
	Net::PSYC::shutdown($obj);
	return 1;
    }

    if (
	($mc eq '_notice_circuit_established' && Net::PSYC::FORK) ||
	($mc eq '_status_circuit' && !Net::PSYC::FORK)
	) {
	my @mods;
	if (exists $MMPvars->{'_understand_modules'}) {
	    if (ref $MMPvars->{'_understand_modules'} eq 'ARRAY') {
		# hm.. maybe it make sense to filter out the empty and
		# undef ones.. 
		@mods = map { $_ } @{$MMPvars->{'_understand_modules'}};
	    } elsif ($MMPvars->{'_understand_modules'}) { 
		@mods = ( $MMPvars->{'_understand_modules'} );
	    }
	}
	$obj->{'OK'} = 1;
	revoke($obj->{'SOCKET'});
	$obj->{'R'}->{'_understand_modules'} = { map { $_ => 1 } @mods };
	map { $obj->gotiate($_) } @mods;
    }

    foreach (keys %$MMPvars) {
	$vars->{$_} = $MMPvars->{$_} if (MERGEVAR($_));
    }
    
    $vars->{'_INTERNAL_origin'} = $obj;
    $cb->msg($MMPvars->{'_source'}, $mc, $data, $vars);
    return -1;
}

sub init {
    if ($_[0] eq 'Event') {
        require Net::PSYC::Event::Event;
        import Net::PSYC::Event::Event qw(can_read can_write has_exception add remove start_loop stop_loop revoke);
	return 1;
    } elsif ($_[0] eq 'IO::Select') {
        require Net::PSYC::Event::IO_Select;
        import Net::PSYC::Event::IO_Select qw(can_read can_write has_exception add remove start_loop stop_loop revoke);
	return 1;
    } elsif ($_[0] eq 'Gtk2') {
        require Net::PSYC::Event::Gtk2;
        import Net::PSYC::Event::Gtk2 qw(can_read can_write has_exception add remove start_loop stop_loop revoke);
	return 1;
    }
}

package Net::PSYC::Event::Wrapper;
# a wrapper-object to make classes work like objects in register_uniform

use strict;

# this is beta since it does not allow anyone to handle several psyc-objects at
# once. remember: register_uniform() allows wildcards
=state
use base 'Net::PSYC::State';
=cut

sub new {
    my $class = shift;
    my $o = shift;
    my $unl = shift;

    my $self = {};
    if (ref $o) {
	$self->{'msg'} = sub{ $o->msg(@_) };
=state
	$self->{'assign'} = sub{ $o->assign(@_) } if ($o->can('assign'));
	$self->{'augment'} = sub{ $o->augment(@_) } if ($o->can('augment'));
	$self->{'diminish'} = sub{ $o->diminish(@_) } if ($o->can('diminish'));
	$self->{'reset'} = sub{ $o->reset(@_) } if ($o->can('reset'));
=cut
    } else {
	$self->{'msg'} = eval "\\&$o\::msg";
=state
	foreach ('assign','augment','diminish','restet') {
	    $self->{$_} = eval "\\&$o\::$_" if (eval "$o->can('$_')");
	}
=cut
    }
    $self->{'unl'} = $unl;
    $self->{'obj'} = $o;
    return bless $self, $class;
}

sub msg {
    my $self = shift;
=cut
    $self->SUPER::msg(@_);
=cut
    &{$self->{'msg'}};
}
=state

sub assign {
    my $self = shift;
    return if ($self->{'assign'} && $self->{'assign'}->(@_));
    $self->SUPER::assign(@_);
}

sub augment {
    my $self = shift;
    return if ($self->{'augment'} && $self->{'augment'}->(@_));
    $self->SUPER::augment(@_);
}

sub diminish {
    my $self = shift;
    return if ($self->{'diminish'} && $self->{'diminish'}->(@_));
    $self->SUPER::diminish(@_);
}

sub reset {
    my $self = shift;
    return if ($self->{'reset'} && $self->{'reset'}->(@_));
    $self->SUPER::reset(@_);
}
=cut


1;

__END__

=head1 NAME

Net::PSYC::Event - Event wrapper for various event systems.

=head1 DESCRIPTION

Net::PSYC::Event offers an interface to easily use L<Net::PSYC> with different Event systems. It currently offers support for Event.pm, IO::Select and Gtk2.

=head1 SYNOPSIS

    # load Net::PSYC::Event for Gtk2 eventing.
    use Net::PSYC qw(Event=Gtk2);
    use Net::PSYC::Event qw(register_uniform unregister_uniform start_loop);

    bind_uniform('psyc://example.org/');
    register_uniform('psyc://example.org/@chatroom');
 
    sub msg {
	my ($source, $mc, $data, $vars) = @_;
	# lets do some conferencing
    }

    start_loop() # start the event-loop
 
=head1 PERL API

=over 4

=item register_uniform( B<$unl>[, B<$object> ] )
	
Registers B<$object> or the calling package for all incoming messages targeted at B<$unl>. Calls 

B<$object>->msg( $source, $mc, $data, $vars ) or

caller()::msg( $source, $mc, $data, $vars )

for every incoming PSYC packet.

=item unregister_uniform( B<$unl> )
	
Unregister an B<$unl>. No more packages will be delivered for that B<$unl> thenceforward.

=item start_loop()

Start the Event loop. 

=item stop_loop()

Stop the Event loop.

=item add( B<$fd>, B<$flags>, B<$callback>[, B<$repeat>])
 
Start watching for events on B<$fd>. B<$fd> may be a GLOB or an IO::Handle object. B<$flags> may be B<r>, B<w> or B<e> (data to be read, written or pending exceptions) or any combination. 
 
If B<$repeat> is set to 0 the callback will only be called once (revoke() may be used to reactivate it). If you don't want one-shot events either leave B<$repeat> out or set it to 1.

=item $id = add( B<$time>, 't', B<$callback>[, B<$repeat>])

Add a timer event. The event will be triggered after B<$time> seconds. This is a one-shot event by default. However, if B<$repeat> is set to 1, B<$callback> will be called every B<$time> seconds until the event is removed.

One-shot timer events are removed automatically and B<revoke> is not possible for them.

Remember: You are not using a real-time system. The accuracy of timer events depends heavily on other events pending, io-operations and system load in general. 

=item remove( B<$fd>[, B<$flags>] )

Stop watching for events on B<$fd>. Different types can not be removed seperately if they have been add()ed together!

=item remove( B<$id> )

Removed the timer event associated with the given B<$id>. 

=item revoke( B<$fd> )

Revokes the eventing for B<$fd>. ( one-shot events ) 


=back
 
=head1 SEE ALSO

L<Net::PSYC>, L<Net::PSYC::Client>, L<Net::PSYC::Event::Event>, L<Net::PSYC::Event::IO_Select>, L<Net::PSYC::Event::Gtk2>, L<http://psyc.pages.de/>

=head1 AUTHORS

Arne GE<ouml>deke <el@goodavice.pages.de>

=head1 COPYRIGHT

Copyright (c) 1998-2005 Arne GE<ouml>deke and Carlo v. Loesch.
All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


