package Net::Gnutella;
use Net::Gnutella::Client;
use Net::Gnutella::Server;
use Net::Gnutella::Event;
use IO::Socket;
use IO::Select;
use Carp;
use strict;
use vars qw/@ISA @EXPORT $VERSION $AUTOLOAD/;

$VERSION = $VERSION = "0.1";

use constant GNUTELLA_CONNECT => 1;
use constant GNUTELLA_REQUEST => 2;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(GNUTELLA_CONNECT GNUTELLA_REQUEST);

# Use AUTOHANDLER to supply generic attribute methods
#
sub AUTOLOAD {
	my $self = shift;
	my $attr = $AUTOLOAD;
	$attr =~ s/.*:://;
	return unless $attr =~ /[^A-Z]/; # skip DESTROY and all-cap methods
	croak sprintf "invalid attribute method: %s->%s()", ref($self), $attr unless exists $self->{_attr}->{lc $attr};
	$self->{_attr}->{lc $attr} = shift if @_;
	return $self->{_attr}->{lc $attr};
}

sub add_handler {
	my ($self, $event, $coderef, $replace, @args) = @_;

	return $self->_add_handler($event, $coderef, $replace, $self->{_handler}, @args);
}

sub dequeue {
	my ($self, $qid) = @_;

	return delete $self->{_queue}->{$qid};
}

sub do_one_loop {
	my $self = shift;

	my $timeout = $self->timeout;
	my $time = time();

	foreach my $key ($self->queue) {
		my $event = $self->queue($key);

		if ($event->[0] <= $time) {
			$event->[1]->( @{$event}[2..$#{$event}] );

			$self->dequeue($key);
		} else {
			my $nexttimeout = $event->[0] - $time;

			$timeout = $nexttimeout if $nexttimeout < $timeout or not $timeout;
		}
	}

	my ($rr, $wr, $er) = IO::Select->select(@{$self}{'_read', '_write', '_error'}, $timeout);

	foreach my $sock (@$rr) {
		my $conn = $self->{_connhash}->{read}->{$sock} or next;

		$conn->[0]->($conn->[1] ? ($conn->[1], $sock) : $sock, @{$conn}[2..$#{$conn}]);
	}

	foreach my $sock (@$wr) {
		my $conn = $self->{_connhash}->{write}->{$sock} or next;

		$conn->[0]->($conn->[1] ? ($conn->[1], $sock) : $sock, @{$conn}[2..$#{$conn}]);
	}
}

# Cache the latest 500 PONG hosts (host:port combinations)
#
sub _host_cache {
	my $self = shift;

	if (@_) {
		my $time = time();
		my $count = 500;
		my $cache = $self->{_host_cache};
		my $new = {};
		my $i = 0;

		# Add the specified entries
		#
		foreach (@_) {
			$cache->{$_} = $time;
		}

		# Build a new list containing the most recent n elements
		#
		foreach (grep { $i++ < $count } sort { $cache->{$b} <=> $cache->{$a} } keys %{$cache}) {
			$new->{$_} = $cache->{$_};
		}

		$self->{_host_cache} = $new;
	}

	return keys %{ $self->{_host_cache} };
}

sub connections {
	my $self = shift;
	my @ret;

	foreach my $key (keys %{ $self->{_connhash}->{all} }) {
		my $conn = $self->{_connhash}->{all}->{$key};

		next unless ref $conn eq "Net::Gnutella::Connection";
		next unless $conn->connected;

		push @ret, $conn;
	}

	return @ret;
}

sub new {
	my $class = shift;
	my %args = @_;

	my $self = {
		_connhash => {
			read  => {},
			write => {},
			all   => {},
		},
		_read  => new IO::Select,
		_write => new IO::Select,
		_attr  => {
			timeout => 10,
			debug   => 0,
			id      => [ map { rand(65535**2) } 0..4 ],
		},
		_handler => {},
		_host_cache => {},
		_msgid_source => {},
		_qid => 'a',
		_queue => {},
	};

	bless $self, $class;

	foreach my $key (keys %args) {
		my $lkey = lc $key;

		$self->$lkey($args{$key});
	}

	return $self;
}

sub new_client {
	my $self = shift;
	my $conn = Net::Gnutella::Client->new($self, @_);

	return if $conn->error;
	return $conn;
}

sub new_server {
	my $self = shift;
	my $conn = Net::Gnutella::Server->new($self, @_);

	return if $conn->error;
	return $conn;
}

sub queue {
	my $self = shift;

	if (@_) {
		return $self->{_queue}->{$_[0]};
	} else {
		return keys %{ $self->{_queue} };
	}
}

sub schedule {
	my ($self, $when, $coderef, @args) = @_;

	unless ($when =~ /^\d+[dhmst]$/i) {
		croak "First argument must be a number";
	}

	unless (defined $coderef && ref $coderef eq 'CODE') {
		croak "Second argument must be a coderef!";
	}

	my $time = time();

	$when *= 24*60*60 if $when =~ s/d$//i;
	$when *= 60*60    if $when =~ s/h$//i;
	$when *= 60       if $when =~ s/m$//i;
	                     $when =~ s/s$//i;

	if ($when =~ s/t$//i) {
		$time = $when;
	} else {
		$time += $when;
	}

	$self->{_qid} = 'a' if $self->{_qid} eq 'zzzzzzzz';

	my $id = $self->{_qid}++;
	$self->{_queue}->{$id} = [ $time, $coderef, @args ];
	return $id;
}

# Returns the connection a msgid originated from if it
# has been seen previously.
#
sub _msgid_source {
	my ($self, $msgid, $conn) = @_;

	unless ($msgid && ref($msgid) eq 'ARRAY') {
		carp "Invalid message ID: $msgid";
	}

	if ($conn) {
		my $i = 0;
		my $count = 5000;
		my $source = $self->{_msgid_source};

		$source->{join(":", @$msgid)} = [ $conn, time() ];

		foreach (grep { $i++ > $count } sort { $source->{$b}->[1] <=> $source->{$a}->[1] } keys %{$source}) {
			delete $source->{$_};
		}
	}

	return unless $self->{_msgid_source}->{join(":", @$msgid)};
	return $self->{_msgid_source}->{join(":", @$msgid)}->[0];
}

sub start {
	my $self = shift;

	$self->do_one_loop while 1;
}

sub _add_fh {
	my ($self, $fh, $coderef, $flags, $obj, @args) = @_;

	unless (ref $coderef eq "CODE") {
		croak "Second argument to ->_add_fh not a coderef";
	}

	$flags ||= 'r';

	if ($flags =~ /r/i) {
		$self->{_read}->add($fh);
		$self->{_connhash}->{read}->{$fh} = [ $coderef, $obj, @args ];
	}

	if ($flags =~ /w/i) {
		$self->{_write}->add($fh);
		$self->{_connhash}->{write}->{$fh} = [ $coderef, $obj, @args ];
	}

	$self->{_connhash}->{all}->{$fh} = $obj;
}

sub _add_handler {
	my ($self, $event, $coderef, $replace, $hashref, @args) = @_;

	unless (ref $coderef eq "CODE") {
		croak "Second argument to ->_add_handler not a coderef";
	}

	my %define = ( replace=>0, before=>1, after=>2 );

	if (not defined $replace) {
		$replace = 2;
	} elsif ($replace =~ /^\D/) {
		$replace = $define{lc $replace} || 2;
	}

	foreach my $ev (ref $event eq "ARRAY" ? @{$event} : $event) {
		if ($ev =~ /^\d/) {
			$ev = Net::Gnutella::Event->trans($ev);

			unless ($ev) {
				carp "Unknown event type in ->add_handler";
				return;
			}
		}

		$hashref->{lc $ev} = [ $coderef, $replace, @args ];
	}
}

sub _handler {
	my ($self, $event) = @_;
	my $handler;

	unless ($event) {
		confess "I messed up";
	}

	my $type = $event->type;
	my $conn = $event->from;
	my $default = $conn->can('_default') if $conn;

	if ($conn && exists $conn->{_handler}->{$type}) {
		printf STDERR " - Connection wide handler exists\n" if $self->debug >= 2;
		$handler = $conn->{_handler}->{$type};
	} elsif (exists $self->{_handler}->{$type}) {
		printf STDERR " - Global handler exists\n" if $self->debug >= 2;
		$handler = $self->{_handler}->{$type};
	} elsif ($default) {
		printf STDERR " - Calling default handler on connection\n" if $self->debug >= 2;
		return $conn->_default($event);
	} else {
		printf STDERR " - Calling default global handler\n" if $self->debug >= 2;
		return $self->_default($event);
	}

	my ($coderef, $replace, @args) = @$handler;

	if ($replace == 0) {      # REPLACE
		$coderef->($conn, $event, @args);
	} elsif ($replace == 1) { # BEFORE
		$coderef->($conn, $event, @args) or return;

		if ($default) {
			$conn->_default($event, @args);
		} else {
			$self->_default($event, @args);
		}
	} elsif ($replace == 2) { # AFTER
		if ($default) {
			$conn->_default($event, @args) or return;
		} else {
			$self->_default($event, @args) or return;
		}

		$coderef->($conn, $event, @args);
	}
}

sub _remove_fh {
	my ($self, $fh, $flags) = @_;

	$flags ||= 'r';

	if ($flags =~ /r/i) {
		$self->{_read}->remove($fh);
		delete $self->{_connhash}->{read}->{$fh};
	}

	if ($flags =~ /w/i) {
		$self->{_write}->remove($fh);
		delete $self->{_connhash}->{write}->{$fh};
	}
}

1;
