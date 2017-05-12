#!/usr/bin/perl 
use strict;
use warnings;

eval { require IO::Async::Loop; 1; } or die "This example needs IO::Async\n";

package Memcached::Example;
use parent qw(Protocol::Memcached);

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {
		stream	=> $args{stream},
	}, $class;
	$self->Protocol::Memcached::init;
	return $self;
}

sub write { shift->{stream}->write(@_) }

package main;
use IO::Async::Loop;
use Scalar::Util qw(weaken);

my $loop = IO::Async::Loop->new;
my $mc;

my $txt = "a" x 64;
my @queue = map { $txt++ } 0..1000;

$loop->connect(
	host		=> 'localhost',
	service 	=> 11211,
	socktype	=> 'stream',
	on_stream	=> sub {
		my $stream = shift;
		warn "Connected to memcached\n";
		$stream->configure(
			on_read => sub {
				my ($self, $buffref, $eof) = @_;
				return 1 if $mc->on_read($buffref);
				return undef;
			}
		);
		$loop->add($stream);
		$mc = Memcached::Example->new(
			stream	=> $stream
		);
		my $code;
		$code = $mc->sap(sub {
			my $mc = shift;
			my ($k, $v) = @_;
			$mc->set(
				$k => $v,
				on_complete	=> $mc->sap(sub {
					my $mc = shift;
					$mc->get(
						$k,
						on_complete	=> sub {
							my %args = @_;
#							print "Value stored was " . $args{value} . "\n";
							my $v = shift @queue
							 or return $loop->later(sub { $loop->loop_stop });
							$code->($v, $v);
						},
						on_error	=> sub { die "Failed because of @_\n" }
					);
				})
			);
		});
		my $v = shift @queue;
		$code->($v, $v);
	},
        on_resolve_error => sub { die "Cannot resolve - $_[-1]\n"; },
        on_connect_error => sub { die "Cannot connect - $_[0] failed $_[-1]\n"; },
);
$loop->loop_forever;

