package Net::uwsgi;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT);

use IO::Socket::INET;
use IO::Socket::UNIX;
use IO::Select;

$VERSION     = 1.1;
@ISA         = qw(Exporter);
@EXPORT      = qw(uwsgi_pkt uwsgi_rpc uwsgi_signal uwsgi_spool uwsgi_cache_get uwsgi_cache_exists uwsgi_cache_del uwsgi_cache_set uwsgi_cache_update uwsgi_parse_header uwsgi_parse_body uwsgi_parse_hash uwsgi_parse_array);

sub u_consume_response {
	my ($socket) = @_;
	my $res = '';
	my $sel = IO::Select->new($socket);
        while(1) {
                unless($sel->can_read) {
                        die "Error: can't select() the uwsgi socket: $!";
                }
                $socket->recv(my $buf, 4096);
                last unless $buf;
                $res.=$buf;
        }
	return $res;
}

sub u_send_request {
	my ($addr, $pkt) = @_;
	my $socket = undef;
	if ($addr =~ /:/) {
                $socket = IO::Socket::INET->new(PeerAddr => $addr);
        }
        else {
                $socket = IO::Socket::UNIX->new(Peer => $addr);
        }
	$socket->send($pkt);
	return $socket;
}

sub uwsgi_pkt {
	my ($modifier1, $modifier2, $items) = @_;
	my $header = '';
	my $body = '';
	if (ref($items) eq 'ARRAY') {
		foreach(@{$items}) {
			$body .= pack('v', length($_)).$_;
		}
	}
	elsif (ref($items) eq 'HASH') {
		foreach(keys %{$items}) {
			$body .= pack('v', length($_)).$_.pack('v', length($items->{$_})).$items->{$_};
		}
	}
	elsif ($items) {
		$body .= pack('v', length($items)).$items;
	}

	return chr($modifier1).pack('v',length($body)).chr($modifier2).$body;
}

sub uwsgi_parse_header {
	my ($pkt) = @_;
	my ($modifier1, $pktsize, $modifier2) = unpack('CvC', substr($pkt, 0, 4));
	if ($pktsize > length($pkt)-4) {
                die "Error: invalid uwsgi packet size";
        }
	return ($modifier1, $pktsize, $modifier2);
};

sub uwsgi_parse_hash {
	my ($pkt) = @_;
	my $body = uwsgi_parse_body($pkt);
	my $h = {};
	while(length($body)) {
		my $header = substr($body, 0, 2);
		$body = substr($body, 2);
		my ($ksize) = unpack('v', $header);
		my $key = substr($body, 0, $ksize);
		$body = substr($body, $ksize);

		$header = substr($body, 0, 2);
		$body = substr($body, 2);
		my ($vsize) = unpack('v', $header);
		my $value = substr($body, 0, $vsize);
		$body = substr($body, $vsize);

		$h->{$key} = $value;
	}
	return $h;
}

sub uwsgi_parse_body {
	my ($pkt) = @_;
        my ($modifier1, $pktsize, $modifier2) = uwsgi_parse_header($pkt);
	return substr($pkt, 4, $pktsize);
}

sub uwsgi_rpc {
	my ($addr, @args) = @_;
	my $pkt = uwsgi_pkt(173, 0, \@args);
	my $socket = u_send_request($addr, $pkt);
	my $res = u_consume_response($socket);
	$socket->close;
	return uwsgi_parse_body($res);
}

sub uwsgi_signal {
	my ($addr, $signal) = @_;
        my $pkt = uwsgi_pkt(110, $signal);
	my $socket = u_send_request($addr, $pkt);
	$socket->close;
}

sub uwsgi_cache_get {
	my ($addr, $key) = @_;
	my $cache = undef;
	if ($addr =~ /@/) {
		($cache, $addr) = split /@/,$addr,2;
	} 
	
	my $req = { 'cmd' => 'get', 'key' => $key };
	if ($cache) {
		$req->{'cache'} = $cache;
	}

	my $pkt = uwsgi_pkt(111, 17, $req);
	my $socket = u_send_request($addr, $pkt);
	my $res = u_consume_response($socket);
        $socket->close;
        my $ures = uwsgi_parse_hash($res);
	if ($ures->{'status'} eq 'ok') {
		return substr($res, -$ures->{'size'});
	}
	return undef;
}

sub uwsgi_cache_exists {
        my ($addr, $key) = @_;
        my $cache = undef;
        if ($addr =~ /@/) {
                ($cache, $addr) = split /@/,$addr,2;
        }

        my $req = { 'cmd' => 'exists', 'key' => $key };
        if ($cache) {
                $req->{'cache'} = $cache;
        }

        my $pkt = uwsgi_pkt(111, 17, $req);
        my $socket = u_send_request($addr, $pkt);
        my $res = u_consume_response($socket);
        $socket->close;
        my $ures = uwsgi_parse_hash($res);
        if ($ures->{'status'} eq 'ok') {
                return 1;
        }
        return 0;
}

sub uwsgi_cache_del {
        my ($addr, $key) = @_;
        my $cache = undef;
        if ($addr =~ /@/) {
                ($cache, $addr) = split /@/,$addr,2;
        }

        my $req = { 'cmd' => 'del', 'key' => $key };
        if ($cache) {
                $req->{'cache'} = $cache;
        }

        my $pkt = uwsgi_pkt(111, 17, $req);
        my $socket = u_send_request($addr, $pkt);
        my $res = u_consume_response($socket);
        $socket->close;
        my $ures = uwsgi_parse_hash($res);
        if ($ures->{'status'} eq 'ok') {
                return 1;
        }
        return 0;
}

sub uwsgi_cache_set {
        my ($addr, $key, $value, $expires) = @_;
        my $cache = undef;
        if ($addr =~ /@/) {
                ($cache, $addr) = split /@/,$addr,2;
        }

        my $req = { 'cmd' => 'set', 'key' => $key, 'size' => ''.length($value) };
        if ($cache) {
                $req->{'cache'} = $cache;
        }
	if ($expires) {
                $req->{'expires'} = ''.$expires;
	}

        my $pkt = uwsgi_pkt(111, 17, $req);
        my $socket = u_send_request($addr, $pkt);
	$socket->send($value);
        my $res = u_consume_response($socket);
        $socket->close;
        my $ures = uwsgi_parse_hash($res);
        if ($ures->{'status'} eq 'ok') {
                return 1;
        }
        return 0;
}

sub uwsgi_cache_update {
        my ($addr, $key, $value, $expires) = @_;
        my $cache = undef;
        if ($addr =~ /@/) {
                ($cache, $addr) = split /@/,$addr,2;
        }

        my $req = { 'cmd' => 'update', 'key' => $key, 'size' => ''.length($value) };
        if ($cache) {
                $req->{'cache'} = $cache;
        }
        if ($expires) {
                $req->{'expires'} = ''.$expires;
        }

        my $pkt = uwsgi_pkt(111, 17, $req);
        my $socket = u_send_request($addr, $pkt);
        $socket->send($value);
        my $res = u_consume_response($socket);
        $socket->close;
        my $ures = uwsgi_parse_hash($res);
        if ($ures->{'status'} eq 'ok') {
                return 1;
        }
        return 0;
}


sub uwsgi_spool {
        my ($addr, $args) = @_;
        my $pkt = uwsgi_pkt(17, 0, $args);
        my $socket = u_send_request($addr, $pkt);
        my $res = u_consume_response($socket);
        $socket->close;
        my ($modifier1, $pktsize, $modifier2) = uwsgi_parse_header($res);
	if ($modifier1 != 255) { return 0; }
	return $modifier2;
}

1;
