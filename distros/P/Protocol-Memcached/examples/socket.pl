#!/usr/bin/perl 
use strict;
use warnings;

eval { require Socket; 1; } or die "This example needs Socket\n";

package Memcached::Example;
use parent qw(Protocol::Memcached);
use Socket;
use IO::Handle;
use POSIX;

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {
		server	=> $args{server} // 'localhost',
		port	=> $args{port} // 11211,
	}, $class;
	$self->Protocol::Memcached::init;
	return $self;
}

sub connect {
	my $self = shift;
	$self->{port} = getservbyname($self->{port}, 'tcp') if $self->{port} =~ /\D/;
	die "No port" unless $self->{port};

	my $iaddr   = inet_aton($self->{server}) or die "no host: " . $self->{server};
	my $paddr   = sockaddr_in($self->{port}, $iaddr);
	my $proto   = getprotobyname('tcp');
	socket(my $sock, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";

	connect($sock, $paddr) or die "connect: $!";
	$sock->autoflush(1);
	{
		my $flags = fcntl($sock, F_GETFL, 0) or die "Can't get flags for socket: $!\n";
		fcntl($sock, F_SETFL, $flags | O_NONBLOCK) or die "Can't make socket nonblocking: $!\n";
	}
	$self->debug('Connected to ' . $self->{server} . ':' . $self->{port});
	$self->{sock} = $sock;
}

sub write {
	my ($self, $data, %args) = @_;
	$self->debug('Writing ' . length($data) . ' bytes');
	$self->sock->write($data) or die $!;
	if(my $method = $args{on_flush}) {
		$self->$method();
	}
	return $self;
}

sub sock { shift->{sock} }
sub close { close shift->{sock} or die "$!"; }
sub debug { shift; warn "@_\n"; }

package main;

warn "Populating initial values\n";
my $mc = Memcached::Example->new(
	server	=> $ENV{PROTOCOL_MEMCACHED_SERVER},
	port	=> $ENV{PROTOCOL_MEMCACHED_PORT},
);
$mc->connect;
my ($k, $v) = qw(hello world);
my $done = 0;
$mc->set(
	$k => $v,
	on_complete	=> sub {
		print "Stored value for $k\n";
		$mc->get(
			$k,
			on_complete	=> sub {
				my %args = @_;
				print "Value stored was " . $args{value} . "\n";
				$mc->close;
				$done = 1;
			},
			on_error	=> sub { die "Failed because of @_\n" }
		);
	},
	on_error => sub {
		die "Failed due to @_\n";
	},
);
my $data = '';
warn "Starting loop\n";
use POSIX;
LOOP:
while(!$done) {
	warn "Read data\n";
	my $count = $mc->sock->read($data, 13, length($data));
	unless(defined $count) {
		next LOOP if $! == EWOULDBLOCK;
		die $!;
	}
	warn "Buffer now " . length($data) . " with count $count\n";
	warn "Successfully processed packet\n" while($mc->on_read(\$data));
}

exit;
