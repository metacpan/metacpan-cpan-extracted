package Net::PSYC::Event::Event;

our $VERSION = '0.1';

use strict;
use Event qw(loop unloop);
use Net::PSYC qw(W);

use base qw(Exporter);
our @EXPORT_OK = qw(init can_read can_write has_exception add remove start_loop stop_loop revoke);

my (%s, %revoke);

sub can_read {
    croak('can_read() is not yet implemented by Net::PSYC::Event::Event');
}

sub can_write {
    croak('can_write() is not yet implemented by Net::PSYC::Event::Event');
}

sub has_exception {
    croak('has_exception() is not yet implemented by Net::PSYC::Event::Event');
}

#   add (\*fd, flags, cb, repeat)
sub add {
    my ($fd, $flags, $cb, $repeat) = @_;
    W2('add(%s, %s, %p, %d)', $fd, $flags, $cb, $repeat||0);
    if (!$flags || !$cb || !ref $cb eq 'CODE') {
	croak('Net::PSYC::Event::Event::add() requires flags and a callback!');
    }
    
    my $watcher;
    if ($flags eq 't') {
	$watcher = Event->timer( after => $fd,
				 repeat => defined($repeat) ? $repeat : 0,
				 cb => (!$repeat) 
		    ? sub { remove(($watcher)); $cb->() } 
		    : sub { remove(($watcher)) unless $cb->() });	
	$s{'t'}->{$watcher} = $watcher;
	return $watcher;
    } elsif ($flags !~ /[^rew]/) {
	my $temp = substr($flags, 0, 1);
	my $count;
	my $sub = sub { 
	    if ($cb->($fd, $count++) == -1) {
		$watcher->now();
	    } else {
		$count = 0;
	    }
	};
	$watcher = Event->io( fd => $fd,
			      cb => $sub,
			      poll => $flags,
			      repeat => defined($repeat) ? $repeat : 1);
	foreach ('r', 'w', 'e') {
	    next if ($flags !~ /$_/);
	    $s{$_}->{($fd)} = $watcher;
	    $revoke{$_}->{($fd)} = $watcher if (defined($repeat) && $repeat == 0);
	}
    } else {
	die "read the docu, you punk! '$flags' is _not_ a valid set of flags.";
    }

}
#   revoke( \*fd[, flags] )
sub revoke {
    my $sock = shift;
    my $name = ($sock);
    my $flags = shift;
    W2('revoked %s', $name);
    foreach ('r', 'w', 'e') {
	next if($flags && !$flags =~ /$_/);
	$s{$_}->{$name}->again() if(exists $s{$_}->{$name});
    }
}

#   remove ( \*fd[, flags] )
sub remove {
    my $sock = shift;
    my $name = ($sock);
    my $flags = shift;
    W2('removing %s', $name);
    foreach ('r', 'w', 'e', 't') {
	next if($flags && $flags !~ /$_/);
	next unless (exists $s{$_}->{$name});
	$s{$_}->{$name}->cancel();
	delete $s{$_}->{$name};
	delete $revoke{$_}->{$name};
    }
}

sub start_loop {
    !loop();
}

sub stop_loop {
    unloop();
}


1;
