package Net::Async::Redis;
# ABSTRACT: redis support for IO::Async
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.003';

=head1 NAME

Net::Async::Redis - talk to Redis servers via IO::Async

=head1 VERSION

version 0.003

=head1 SYNOPSIS

=head1 DESCRIPTION

Redis functionality. Docs may arrive later.

Supports the basics - auth/get/set/pub/sub/del/keys - but not much else. Expect APIs to change over time.

Also note that L<Protocol::Redis> has a few issues to do with encoding (\r\n portability, quoting of
values), our handling for SET leaves much to be desired, and in general there's not much in the way
of error checking.

=cut

use curry::weak;
use IO::Async::Stream;
use Protocol::Redis;
use JSON::MaybeXS;
use List::Util qw(pairmap);
use Mixin::Event::Dispatch::Bus;

=head1 METHODS

=cut

sub bus { shift->{bus} //= Mixin::Event::Dispatch::Bus->new }

sub psubscribe {
	my ($self, $pattern) = @_;
	return $self->command(
		PSUBSCRIBE => $pattern
	)->then(sub {
		$self->{subscribed} = 1;
		Future->done
	})
}

sub attach_protocol {
	my ($self) = @_;
	$self->{protocol} = my $proto = Protocol::Redis->new(api => 1);
	$self->{json} = JSON::MaybeXS->new->pretty(1);
	$proto->on_message($self->curry::weak::on_message);
	$proto
}

sub on_message {
	my ($self, $redis, $data) = @_;
	# warn "got message: " . $self->json->encode($data);
	if($self->{subscribed}) {
		$self->bus->invoke_event(message => $data);
	} else {
		my $next = shift @{$self->{pending}} or die "No pending handler";
		$next->[1]->done($data);
	}
}

sub keys : method {
	my ($self, $match) = @_;
	$match //= '*';
	$self->debug_printf("Check for keys: %s", $match);
	return $self->command(
		KEYS => $match
	)->transform(
		done => sub {
			map $_->{data}, @{ shift->{data} }
		}
	)
}

sub del : method {
	my ($self, @keys) = @_;
	$self->debug_printf("Delete keys: %s", join ' ', @keys);
	return $self->command(
		DEL => @keys
	)->transform(
		done => sub {
			shift->{data}
		}
	)
}

sub get : method {
	my ($self, $key) = @_;
	$self->debug_printf('GET key: %s', $key);
	return $self->command(
		GET => $key
	)->transform(
		done => sub {
			shift->{data}
		}
	)
}

sub exists : method {
	my ($self, $key) = @_;
	$self->debug_printf('EXISTS key: %s', $key);
	return $self->command(
		EXISTS => $key
	)->transform(
		done => sub {
			shift->{data}
		}
	)
}

sub set : method {
	my ($self, $k, $v, @opt) = @_;
	$self->debug_printf('SET key %s, options %s', $k, join ', ', pairmap { "$a=$b" } @opt);
	$v =~ s/"/\\"/g;
	$v = '"' . $v . '"';
	return $self->command(
		SET => $k, $v,
		@opt
	)->transform(
		done => sub {
			shift->{data}
		}
	)
}

sub config_set : method {
	my ($self, $k, $v) = @_;
	$self->debug_printf('CONFIG SET %s = %s', $k, $v);
	return $self->command(
		'CONFIG SET' => $k, $v,
	)->transform(
		done => sub {
			shift->{data}
		}
	)
}

sub watch_keyspace {
	my ($self, $pattern, $code) = @_;
	$pattern //= '*';
	my $sub = '__keyspace@*__:' . $pattern;
	my $f;
	if($self->{have_notify}) {
		$f = Future->done;
	} else {
		$self->{have_notify} = 1;
		$f = $self->config_set(
			'notify-keyspace-events', 'Kg$xe'
		)
	}
	$f->then(sub {
		$self->bus->subscribe_to_event(
			message => sub {
				my ($ev, $data) = @_;
				return unless $data->{data}[1]{data} eq $sub;
				my ($k, $op) = map $_->{data}, @{$data->{data}}[2, 3];
				$k =~ s/^[^:]+://;
				$code->($op => $k);
			}
		);
		$self->psubscribe($sub)
	})
}

sub stream { shift->{stream} }

sub scan {
	my ($self, %args) = @_;
	my $code = $args{each};
	$args{batch} //= $args{count};
}

sub connect {
	my ($self, %args) = @_;
	my $auth = delete $args{auth};
	$args{host} //= 'localhost';
	$args{port} //= 6379;
	$self->{connection} //= $self->loop->connect(
		service => $args{port},
		host    => $args{host},
		socktype => 'stream',
	)->then(sub {
		my ($sock) = @_;
		# warn "connected\n";
		my $stream = IO::Async::Stream->new(
			handle => $sock,
			on_closed => $self->curry::weak::notify_close,
			on_read => sub {
				my ($stream, $buffref, $eof) = @_;
				my $len = length($$buffref);
				$self->debug_printf("have %d bytes of data from redis", $len);
				$self->protocol->parse(substr $$buffref, 0, $len, '');
				0
			}
		);
		Scalar::Util::weaken(
			$self->{stream} = $stream
		);
		$self->attach_protocol;
		$self->add_child($stream);
		if(defined $auth) {
			return $self->command('AUTH', $auth)
		} else {
			return Future->done
		}
	})
}

=head1 METHODS - Internal

=cut

sub notify_close {
	my ($self) = @_;
	$self->configure(on_read => sub { 0 });
	$_->[1]->fail('disconnected') for @{$self->{pending}};
	$self->maybe_invoke_event(disconnect => );
}

sub command_label {
	my ($self, @cmd) = @_;
	return join ' ', @cmd if $cmd[0] eq 'KEYS';
	return $cmd[0];
}

sub command {
	my ($self, @cmd) = @_;
	my $cmd = join ' ', @cmd;
	my $f = $self->loop->new_future;
	$f->label($self->command_label(@cmd));
	push @{$self->{pending}}, [ $cmd, $f ];
	# warn "Writing $cmd\n";
	return $self->stream->write("$cmd\x0D\x0A")->then(sub {
		$f
	});
}

sub protocol {
	my ($self) = @_;
	$self->attach_protocol unless exists $self->{protocol};
	$self->{protocol}
}

sub json { shift->{json} }

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2015. Licensed under the same terms as Perl itself.
