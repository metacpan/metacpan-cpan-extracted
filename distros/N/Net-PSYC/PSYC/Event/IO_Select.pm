package Net::PSYC::Event::IO_Select;

# TODO using fileno doesnt work for some funky file-handles ( perldoc -f fileno)
# but therefore select doesnt either. so.. who cares? In case someone knows a
# workaround for those, email me (I doubt that anybody is reading this anyway)

our $VERSION = '0.4';

use strict;

use base qw(Exporter);
use IO::Select;
use Net::PSYC qw(W);

sub BEGIN {
    if (eval { Time::HiRes::time() }) {
	eval qq {
	    sub mytime() { Time::HiRes::time() }
	};
    } else {
	eval qq {
	    sub mytime() { time() }
	};
    }
}

our @EXPORT_OK = qw(init can_read can_write has_exception add remove start_loop stop_loop revoke);

my (%S, %cb, $LOOP, @T);

%cb = (
	'r' => {},
	'w' => {},
	'e' => {},
    );

sub can_read {
    $S{'r'}->can_read(@_);
}

sub can_write {
    $S{'w'}->can_write(@_);
}

sub has_exception {
    $S{'e'}->has_exception(@_);
}

#   add (\*fd, flags, cb, repeat)
sub add {
    my ($fd, $flags, $cb, $repeat) = @_;

    unless ($cb && ref $cb eq 'CODE') {
	W0('You need a proper callback for add()! (has to be a code-ref)');
	return;
    }

    W2('add(%s, %s, %p, %d)', $fd, $flags, $cb, $repeat||0);

    foreach (split(//, $flags || 'r')) {
	if ($_ eq 'r' or $_ eq 'w' or $_ eq 'e') {
	    $S{$_} = new IO::Select() unless $S{$_};
	    $S{$_}->add($fd);
	    my $t =  $S{$_}->[0];
	    vec($S{$_}->[0], fileno($fd), 1) = 1;
	} elsif ($_ eq 't') {
	    my $i = 0;
	    my $t = mytime() + $fd;
	    while (exists $T[$i] && $T[$i]->[0] <= $t) {
		$i++;
	    }
	    splice(@T, $i, 0, [$t, $cb, ($repeat) ? 1 : 0, $fd]);
	    return scalar($cb).$fd;
	} else { next; }
	$cb{$_}->{fileno($fd)} = [ (!defined($repeat) || $repeat) ? -1 : 1, $cb ];
    }
    1;
}

sub revoke {
    my $id = shift;
    my $name = fileno($id);
    W2('revoke(%s)', $name);
    my @list;
    if (@_) {
	@list = @_;
    } else {
	@list = ('w', 'e', 'r');
    }
    foreach (@list) {
	if (exists $cb{$_}->{$name} and $cb{$_}->{$name}[0] == 0) {
	    vec($S{$_}->[0], $name, 1) = 1;
	    $cb{$_}->{$name}[0] = 1;
	    W2('revoked %s', $id);
	}
    }
}

#   remove (\*fd[, flags] )
sub remove {
    my $id = shift;
    W2('remove(%s)', $id);

    # this is actually 'not so' smart. i will do a better one on request.
    if (!ref $id) {
	my $i = 0;
	foreach (@T) {
	    if (scalar($T[$i]->[1]).$T[0]->[3] eq $id) {
		splice(@T, $i, 1);
		return 1;
	    }
	    $i++;
	}
    }

    my $name = fileno($id);
    foreach ('w', 'e', 'r') {
	if (exists $cb{$_}->{$name}) {
	    if (!$_[1] || $_[1] =~ /$_/) {
		vec($S{$_}->[0], $name, 1) = 0;
		$S{$_}->remove();
	    }
	}
    }
}

sub start_loop {
    my (@E, $sock, $name, @queue);
    
    # @queue
    
    $LOOP = 1;
    my $time = undef;
    LOOP: while ($LOOP) {
	if (scalar(@T) && !scalar(@queue)) {
	    $time = $T[0]->[0] - mytime();
	    if ($time < 0) {
		$time = 0;
		@E = ([],[],[]);
		goto TIME;
	    }
	    # we could do a goto here and leave out the select call. that
	    # however would keep rwe events from being called in case we have
	    # many many timers. As long as we dont have any means of handling
	    # different priorities we stay with this solution and try to be
	    # fair.
	    # TODO: think again
	} elsif (scalar(@queue)) { 
	   $time = 0;
	} else {
	    $time = undef; 
	}

	my ($rmask, $wmask, $emask) = ($S{'r'}->[0], $S{'w'}->[0], 
					$S{'e'}->[0]);

	@E = IO::Select::select(defined($rmask) && $rmask =~ /[^\0]/ 
				    ? $S{'r'} : undef, 
				defined($wmask) && $wmask =~ /[^\0]/ 
				    ? $S{'w'} : undef, 
				defined($emask) && $emask =~ /[^\0]/ 
				    ? $S{'e'} : undef, 
				$time);

	TIME:
	while (scalar(@T) && $T[0]->[0] <= mytime()) {
	    my $event = shift @T;
	    if ($event->[1]->() && $event->[2]) { # repeat!
		add($event->[3], 't', $event->[1], 1);
	    }
	    next LOOP unless ($time);
	}

	foreach $sock (@{$E[0]}) { # read    
	    $name = fileno($sock);
	    next unless (exists $cb{'r'}->{$name});
	    my $event = $cb{'r'}->{$name};
	    
	    if ($event->[0] != 0) {	 # repeat or not	
		if ($event->[0] > 0) {
		    $event->[0] = 0;
		    vec($S{'r'}->[0], $name, 1) = 0;
		}
		
		if ($event->[1]->($sock) == -1) {
		    push(@queue, [$event->[1], $sock, 1]);   
		}
	    }
	}

	foreach $sock (@{$E[1]}) { # write
	    $name = fileno($sock);
	    next unless (exists $cb{'w'}->{$name});
	    my $event = $cb{'w'}->{$name};
	    
	    if ($event->[0] != 0) {	 # repeat or not
		if ($event->[0] > 0) {
		    $event->[0] = 0; 
		    vec($S{'w'}->[0], $name, 1) = 0;
		}

		if ($event->[1]->($sock) == -1) {
		    push(@queue, [$event->[1], $sock, 1]);   
		}
	    }
	}

	foreach $sock (@{$E[2]}) { # error
	    $name = fileno($sock);
	    next unless (exists $cb{'e'}->{$name});
	    my $event = $cb{'e'}->{$name};

	    if ($event->[0] != 0) {	 # repeat or not
		if ($event->[0] > 0) {
		    $event->[0] = 0;
		    vec($S{'e'}->[0], $name, 1) = 0;
		}

		if ($event->[1]->($sock) == -1) {
		    push(@queue, [$event->[1], $sock, 1]);   
		}
	    }
	}

	foreach (0 .. $#queue) {
	    my $event = shift @queue;
	    if ($event->[0]->($event->[1], $event->[2]++) == -1) {
		push(@queue, $event);
	    }
	}
    }
    return 1;
}

sub stop_loop {
    $LOOP = 0;
    return 1;
}

1;
