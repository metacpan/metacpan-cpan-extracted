# Netstring messages for RPC::Switch::Client::Tiny
#
package RPC::Switch::Client::Tiny::Netstring;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(netstring_read netstring_write);

our $VERSION = 1.14;

# Returns data in $buf and number of bytes read, or undef on EOF
# (see: https://www.perlmonks.org/?node_id=1173814)
#
sub sysreadfull {
	my ($file, $len) = ($_[0], $_[2]); # need ref on $buf here
	my $n = 0;
	while ($len - $n) {
		my $i = sysread($file, $_[1], $len - $n, $n);
		if (defined $i) {
			if ($i == 0) {
				return $n;
			} else {
				$n += $i;
			}
		} elsif ($!{EINTR}) {
			redo;
		} else {
			return $n ? $n : undef;
		}
	}
	return $n;
}

# Returns number of bytes written. Catches partial writes and
# interrupts but returns on file-errors like the print call.
#
sub syswritefull {
        my ($file, $buf) = @_;
        my $len = length($buf);
        my $n = 0;
        while ($len - $n) {
                my $i = syswrite($file, $buf, $len - $n, $n);
                if (defined($i)) {
                        $n += $i;
                } elsif ($!{EINTR}) {
                        redo;
                } else {
                        return $n ? $n : undef;
                }
        }
        return $n;
}

# netstring proto: http://cr.yp.to/proto/netstrings.txt
#
sub netstring_write {
	my ($s, $str) = @_;

	# A print call catches partial writes and interrupts,
	# but it will return on file-errors like 'Broken Pipe'.
	#
	# TODO: $client->stop() does not interrupt a blocking print
	#
	my $res = print $s '' . length($str) . ':' . $str . ',';
	$s->flush();
	return $res;
}

# returns received netstring, or empty string on EOF
# dies on error -> use eval {..}
#
sub netstring_read {
	my ($s) = @_;
	my ($c, $b, $n) = ('', '', '');

	# Break on EINTR only before start of message,
	# so that a partial message is never discarded.
	#
	my $res = sysread($s,$c,1);
	while ($res) {
		if ($c ne ':') {
			die "bad netstring: $c" unless ($c =~ /\d+/);
			$n .= $c;
		} else {
			die "bad netstring: $c" if ($n eq '');
			last;
		}
		$res = sysreadfull($s,$c,1);
	}
	if ($res && ($res = sysreadfull($s,$b,$n))) {
		die "bad netstring: $b" if ($res != $n);
		if ($res = sysreadfull($s,$c,1)) {
			die "bad netstring: $c" unless ($c eq ',');
			return $b;
		}
	}
	die "EINTR" if $!{EINTR};
	die "netstring read error: $!" unless defined $res;
	return ''; # EOF
}

1;

__END__

=head1 NAME

RPC::Switch::Client::Tiny::Netstring - send and receive atomic netstring messages

=head1 SYNOPSIS

  use RPC::Switch::Client::Tiny::Netstring;

  socketpair(my $out, my $in, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";

  my $msg = 'ping';
  my $res = netstring_write($out, $msg);
  my $req = eval { netstring_read($in) };

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=cut

