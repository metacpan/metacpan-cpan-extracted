
package RayApp::Request::APR;
use strict;
use warnings FATAL => 'all';
use Apache2::Filter ();
use Apache2::Request ();
use Apache2::RequestRec ();
use APR::Request ();
use Apache2::RequestUtil ();
use Apache2::Const -compile => qw(MODE_READBYTES);
use Apache2::Connection ();
use APR::SockAddr ();
use APR::Const -compile => qw(SUCCESS BLOCK_READ);
use APR::Brigade ();
use APR::Bucket ();

use constant IOBUFSIZE => 8192;

use base 'RayApp::Request';

sub new {
	my ($class, $r) = @_;
	my $request = Apache2::Request->new($r);
	my $bb = APR::Brigade->new($r->pool, $r->connection->bucket_alloc);
	my @body;
	my $seen_eos = 0;
	do {
		$r->input_filters->get_brigade($bb,
			Apache2::Const::MODE_READBYTES,
			APR::Const::BLOCK_READ, IOBUFSIZE);
  
		for (my $b = $bb->first; $b; $b = $bb->next($b)) {
			if ($b->is_eos) {
				$seen_eos++;
				last;
			}
  
			if ($b->read(my $buf)) {
				push @body, $buf;
			}

			$b->remove; # optimization to reuse memory
		}
	} while (!$seen_eos);
  
	$bb->destroy;

	return bless {
		r => $r,
		request => $request,
		body => \@body,
	}, $class;
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
				$self->{'param'}{$_} = [
					$self->{'request'}->body($_)
				];
			}
		} else {
			for (APR::Request::args($self->{'request'})) {
				$self->{'param'}{$_} = [
					APR::Request::args($self->{'request'}, $_)
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
	my $self = shift;
	my $r = $self->{'r'};
	my $uri = $r->headers_in->{'X-RayApp-Frontend-URI'};
	if (not defined $uri) {
		$uri = $self->{r}->construct_url;
	}
	my %opts = @_;
	my $out = $self->parse_full_uri($uri, %opts);
	if ($opts{'query'} or $opts{'-query'}) {
		my $query = $self->{r}->args;
		if (defined $query and $query ne '') {
			$out .= "?$query";
		}
	}
	return $out;
}
sub url_orig {
	my $self = shift;
	my $uri = '';

	my $r = $self->{'r'};
	my %opts = @_;
	for (keys %opts) {
		if (/^-/) {
			my $updated = $_;
			$updated =~ s/^-//;
			$opts{$updated} = delete $opts{$_};
		}
	}

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
	my $self = shift;
	my $body = $self->{body};
	if (defined $body and @$body) {
		return join '', @$body;
	}
	return;
}

sub upload {
	my $self = shift;
	my $r = $self->{'r'};

	my @params = @_;
	if (not @params) {
	}

	require RayApp::Request::Upload;
	my @out;
	for my $param (@params) {
		if (defined $self->{uploads}{$param}) {
			push @out, @{ $self->{uploads}{$param} };
			next;
		}
		for my $u ($r->upload($param)) {
			my $filename = $u->filename;
			my $fh = $u->filehandle;
			my $content = join '', <$fh>;
			close $fh;
                        my $u = new RayApp::Request::Upload(
                                filename => $filename,
                                # filehandle => $_,
                                # content_type => $info->{'Content-Type'},
                                content => $content,
                                name => $param,
                        );
                        push @{ $self->{uploads}{$param} }, $u;
                        push @out, $u;
		}
	}
	if (wantarray) {
		@out;
	} else {
		$out[0];
	}
}

use Apache2::Cookie;
sub raw_cookie {
	my $self = shift;
	my $request = $self->{'request'};
	my $j = Apache2::Cookie::Jar->new($request);
	return $j->cookies($_[0]);
}
sub cookie {
	my $self = shift;
	my $request = $self->{'request'};
	my $j = Apache2::Cookie::Jar->new($request);
	if (wantarray) {
		return map { $_->value } $j->cookies($_[0]);
	} else {
		my $c = $j->cookies($_[0]);
		return ( defined $c ? $c->value : () );
	}
}

1;

