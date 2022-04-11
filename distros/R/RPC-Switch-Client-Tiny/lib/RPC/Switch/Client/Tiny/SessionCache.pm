# Session cache for RPC::Switch::Client::Tiny
#
package RPC::Switch::Client::Tiny::SessionCache;

use strict;
use warnings;
use Time::HiRes qw(time);
use Time::Local;

our $VERSION = 1.15;

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		%args,
		active    => {}, # active async sessions
		lru       => {}, # lru list for sessions
		expiring  => [], # sorted session expire list
	}, $class;
	$self->{lru}{prev} = $self->{lru}{next} = $self->{lru};
	$self->{session_expire} = 60 unless $self->{session_expire};
	return $self;
}

sub bin_search {
	my ($array, $cmp, $key) = @_;
	my ($lo, $hi) = (0, $#{$array});
	my $found;

	# If more than one element matches, return index to last one.
	#
	while ($lo <= $hi) {
		my $mid = int(($lo + $hi) / 2);
		my $ret = $cmp->($key, $array->[$mid]);

		if ($ret == 0) {
			$found = $mid;
		}
		if ($ret < 0) {
			$hi = $mid - 1;
		} else {
			$lo = $mid + 1;
		}
	}
	if (defined $found) {
		return (1, $found);
	}
        return (0, $lo);
}

sub expire_insert {
	my ($self, $session) = @_;

	# Sort expire list in ascending order.
	# (mostly appends if all sessions have the same validity)
	#
	my ($found, $idx) = bin_search($self->{expiring}, sub { $_[0]->{expiretime} - $_[1]->{expiretime} }, $session);
	if ($found) {
		splice(@{$self->{expiring}}, $idx+1, 0, $session);
	} else {
		splice(@{$self->{expiring}}, $idx, 0, $session);
	}
}

sub expire_remove {
	my ($self, $session) = @_;

	# Remove can take a lot of processing if it is called
	# for long lists on every session drop.
	#
	my ($found, $idx) = bin_search($self->{expiring}, sub { $_[0]->{expiretime} - $_[1]->{expiretime} }, $session);
	if ($found) {
		do {
			if ($self->{expiring}[$idx]->{id} eq $session->{id}) {
				splice(@{$self->{expiring}}, $idx, 1);
				last;
			}
			last if (--$idx < 0);
		} while ($self->{expiring}[$idx]->{expiretime} eq $session->{expiretime});
	}
}

sub expire_regenerate {
	my ($self, $sessionlist) = @_;
	$self->{expiring} = [sort { $a->{expiretime} - $b->{expiretime} } @$sessionlist];
}

sub list_empty {
	my ($head) = @_;
        return $head->{next} == $head;
}

sub list_add {
	my ($prev, $elem) = @_;
	$prev->{next}{prev} = $elem;
	$elem->{next} = $prev->{next};
	$elem->{prev} = $prev;
	$prev->{next} = $elem;
}

sub list_del {
	my ($elem) = @_;
	$elem->{next}{prev} = $elem->{prev};
	$elem->{prev}{next} = $elem->{next};
	delete $elem->{prev};
	delete $elem->{next};
}

sub session_put {
	my ($self, $child) = @_;
	my $runtime = sprintf "%.02f", time() - $child->{start};

	return unless exists $child->{session};

	if (exists $self->{active}{$child->{session}{id}}) {
		return; # don't allow double sessions
	}
	my $diff = $child->{session}{expiretime} - time();
	if ($diff < 0) {
		return; # session expired
	}
	$self->{trace_cb}->('PUT', {pid => $child->{pid}, id => $child->{id}, session => $child->{session}{id}, runtime => $runtime}) if $self->{trace_cb};
	$self->{active}{$child->{session}{id}} = $child;
	list_add($self->{lru}{prev}, $child);
	return 1;
}

sub session_get {
	my ($self, $session_id, $msg_id) = @_;
	my %id = (defined $msg_id) ? (id => $msg_id) : ();

	if (exists $self->{active}{$session_id}) {
		my $child = delete $self->{active}{$session_id};
		list_del($child);

		my $stoptime = sprintf "%.02f", time() - $child->{start};
		$self->{trace_cb}->('GET', {pid => $child->{pid}, %id, session => $session_id, stoptime => $stoptime}) if $self->{trace_cb};
		return $child;
	}
	return;
}

sub parse_isotime {
	my ($isotime) = @_;
	my ($yy,$mm,$dd,$h,$m,$s,$msec) = $isotime =~
		/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?Z$/;
	return unless defined $s;

        my $time = timegm($s,$m,$h,$dd,$mm-1,$yy-1900);
        return $time;
}

sub session_new {
	my ($self, $set_session) = @_;
	my $expiretime;

	if (exists $set_session->{expires}) {
		$expiretime = parse_isotime($set_session->{expires});
	}
	# set default expire in seconds
	$expiretime = time() + $self->{session_expire} unless $expiretime;
	return {id => $set_session->{id}, expiretime => $expiretime};
}

sub lru_list {
	my ($self) = @_;
	my @list = ();

	for (my $elem = $self->{lru}{next}; $elem != $self->{lru}; $elem = $elem->{next}) {
		push(@list, $elem);
	}
	return \@list;
}

sub lru_dequeue {
	my ($self) = @_;

	unless (list_empty($self->{lru})) {
		my $child = $self->{lru}{next};
		return $self->session_get($child->{session}{id});
	}
	return;
}

sub expired_dequeue {
	my ($self) = @_;

	# Use sorted expire list to expire sessions.
	#
	if (scalar @{$self->{expiring}}) {
		my $session = $self->{expiring}[0];
		my $diff = $session->{expiretime} - time();
		return if ($diff >= 0);

		$session = shift @{$self->{expiring}};
		my $child = $self->session_get($session->{id});
		return $child;
	}
	return;
}

1;

__END__

=head1 NAME

RPC::Switch::Client::Tiny::SessionCache - Session tracking for async childs

=head1 SYNOPSIS

  use RPC::Switch::Client::Tiny::SessionCache;

  sub trace_cb {
	my ($type, $msg) = @_;
	printf "%s: %s\n", $type, to_json($msg, {pretty => 0, canonical => 1});
  }

  my $cache = RPC::Switch::Client::Tiny::SessionCache->new(trace_cb => \&trace_cb);

  my $expires = strftime('%Y-%m-%dT%H:%M:%SZ', gmtime(time()+1));
  my $session = $cache->session_new({id => '123', expires => $expires});
  my $child = {pid => $$, id => '1', start => time(), session => $session};

  if ($cache->session_put($child)) {
	$cache->expire_insert($child->{session});
  }

  if ($child = $cache->session_get($session->{id})) {
	$cache->expire_remove($child->{session});
  }

  while ($child = $cache->expired_dequeue()) {
	delete $child->{session};
  }

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=cut

