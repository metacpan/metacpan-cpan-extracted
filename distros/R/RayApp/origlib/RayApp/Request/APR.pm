
package RayApp::Request::APR;
use strict;
use Apache::Filter ();
use Apache::Request ();
use Apache::RequestUtil ();
use Apache::Const qw(OK);
use Apache::Connection ();
use APR::SockAddr ();

sub new {
	my ($class, $r) = @_;
	$r->add_input_filter(\&_storage_filter);
	return bless {
		r => $r,
		request => Apache::Request->new($r),
	}, $class;
}

sub _storage_filter {
	my $filter = shift;
	my $store;
	while ($filter->read(my $buffer, 1024)) {
		$filter->print($buffer);
		$store .= $buffer;
	}
	my $orig = $filter->r->pnotes('rayapp_raw_body');
	$filter->r->pnotes('rayapp_raw_body', $orig . $store);
	return Apache::OK;
}

sub user {
	return shift->{'r'}->user;
}
sub remote_user {
	return shift->{'r'}->user;
}
sub _init_param {
	my $self = shift;
	if (not defined $self->{'param'}) {
		$self->{'param'} = {};
		if ($self->{'r'}->method eq 'POST') {
			for ($self->{'request'}->param) {
				# a hack for bug in Apache::Request which was giving
				# us each value twice
				my %u;
				$self->{'param'}{$_} = [
					grep { not $u{$_}++ }
					$self->{'request'}->body($_)
				];
			}
		} else {
			for ($self->{'request'}->args) {
				# a hack for bug in Apache::Request which was giving
				# us each value twice
				my %u;
				$self->{'param'}{$_} = [
					grep { not $u{$_}++ }
					$self->{'request'}->args($_)
				];
			}
		}
	}
}
sub param {
	my $self = shift;
	if (not defined $self->{'param'}) {
		$self->_init_param;
	}
	my $name = shift;
	if (not defined $name) {
		return keys %{ $self->{'param'} };
	}
	if (@_) {
		if (not defined $_[0]) {
			delete $self->{'param'}{$name};
			return;
		} elsif (ref $_[0] and ref $_[0] eq 'ARRAY') {
			$self->{'param'}{$name} = [ @{ $_[0] } ];
			return @{ $_[0] };
		} else {
			$self->{'param'}{$name} = [ @_ ];
			return @_;
		}
	}
	if (wantarray) {
		if (defined $self->{'param'}{$name}) {
			return @{ $self->{'param'}{$name} };
		}
		return;
	} else {
		if (defined $self->{'param'}{$name}
			and @{ $self->{'param'}{$name} }) {
			return $self->{'param'}{$name}[0];
		}
		return;
	}
}
sub delete {
	my $self = shift;
	if (not defined $self->{'param'}) {
		$self->_init_param;
	}
	my $param = shift;
	delete $self->{'param'}{$param};
}
sub request_method {
	shift->{'r'}->method;
}
sub referer {
	shift->{'r'}->headers_in->{'Referer'};
}
sub url {
	my $r = shift->{'r'};
	my %opts = @_;
	for (keys %opts) {
		if (/^-/) {
			my $updated = $_;
			$updated =~ s/^-//;
			$opts{$updated} = delete $opts{$_};
		}
	}

	my $uri = '';

	if (not keys %opts) {
		$opts{'full'} = 1;
	}
	my $protocol = 'http';
	my $c = $r->connection;
	my ($port) = $c->local_addr->port if defined $c;
	if ($port eq '443') {
		$protocol = 'https';
	}

	if ($opts{'full'} or $opts{'base'}) {
		$uri = $protocol . '://' .  $r->hostname;
		if ($protocol eq 'http' and $port ne 80) {
			$uri .= ':' . $port;
		}
		return $uri if $opts{'base'};
	}

	if ($opts{'full'} or $opts{'absolute'}) {
		$uri .= $r->uri;
	} elsif ($opts{'relative'}) {
		$uri = $r->uri;
		if ($uri =~ m!/$!) {
			$uri = './';
		} else {
			$uri =~ s!^.*/!!;
		}
	}
	if ($opts{'path'} or $opts{'path_info'}) {
		$uri .= $r->path_info;
	}

	if (defined $opts{'query'}) {
		my $query = $r->args;
		if (defined $query and $query ne '') {
			$uri .= '?' . $query;
		}
	}
	return $uri;
}
sub remote_host {
	my $c = shift->{'r'}->connection;
	return $c->remote_host();
}
sub remote_addr {
	my $c = shift->{'r'}->connection;
	my $sock_addr = $c->remote_addr();
	if (defined $sock_addr) {
		return $sock_addr->ip_get;
	}
	return;
}
sub body {
	shift->{r}->pnotes('rayapp_raw_body');
}

1;

