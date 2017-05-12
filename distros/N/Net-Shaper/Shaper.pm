package Net::Shaper;

use 5.006;
use strict;
use warnings;

use IO::Socket;
use IO::Select;
use Time::HiRes;

our $VERSION = '0.3';

sub new {
  my($type, %args) = @_;
  $type = ref $type || $type;

  return bless \%args, $type;
}

sub LocalPort { @_ > 1 ? $_[0]->{LocalPort} = $_[1] : $_[0]->{LocalPort} }
sub LocalAddr { @_ > 1 ? $_[0]->{LocalAddr} = $_[1] : $_[0]->{LocalAddr} }
sub LocalHost { @_ > 1 ? $_[0]->{LocalHost} = $_[1] : $_[0]->{LocalHost} }
sub PeerPort  { @_ > 1 ? $_[0]->{PeerPort}  = $_[1] : $_[0]->{PeerPort}  }
sub PeerAddr  { @_ > 1 ? $_[0]->{PeerAddr}  = $_[1] : $_[0]->{PeerAddr}  }
sub PeerHost  { @_ > 1 ? $_[0]->{PeerHost}  = $_[1] : $_[0]->{PeerHost}  }
sub Bps       { @_ > 1 ? $_[0]->{Bps}       = $_[1] : $_[0]->{Bps}       }

sub run {
  my $this = shift;

  local $SIG{PIPE} = 'IGNORE';

  my @localArgs  = map { $_ => $this->$_() } grep defined($this->$_()), qw(LocalPort LocalAddr LocalHost);
  my @remoteArgs = map { $_ => $this->$_() } grep defined($this->$_()), qw(PeerPort  PeerAddr  PeerHost );

  my $src = IO::Socket::INET->new(@localArgs, Listen => SOMAXCONN, Reuse => 1, Proto => 'tcp');

  my $select = IO::Select->new($src);

  my $bps = $this->Bps();

  my(@dest, $done);

  $SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { @dest = (); $done = 1;};

  while (!$done) {
    if ($select->can_read(0)) {
      my $client = $src->accept();
      push @dest, [$client => IO::Socket::INET->new(@remoteArgs, Proto => 'tcp')];
    }

    my $start = Time::HiRes::time();
    my @recvBuf = my @sendBuf = ();
    my $bytes = 0;
    my $bytesToRead = $bps && @dest ? $bps / @dest : 32768;
    for (my $i = 0; $i < @dest; $i++) {
      my($client, $dest) = @{ $dest[$i] };
      $client->recv($recvBuf[$i], $bytesToRead, IO::Socket::MSG_DONTWAIT);
      $dest->recv  ($sendBuf[$i], $bytesToRead, IO::Socket::MSG_DONTWAIT);
      $bytes += length($recvBuf[$i]) + length($sendBuf[$i]);
    }
    my $now = Time::HiRes::time();

    unless ($bytes) {
      # wait for something to be ready to read
      my $sel = IO::Select->new();
      $sel->add($_) for $src, map @$_, @dest;
      my @ready = $sel->can_read();
      for my $fh (@ready) {
	$fh->recv(my $buf, 1, IO::Socket::MSG_PEEK);
	unless (length($buf)) {
	  @dest = grep { $_->[0] != $fh && $_->[1] != $fh } @dest;
	}
      }
      next;
    }

    if ($bps) {
      unless ($bytes / ($now - $start) < $bps) {
	Time::HiRes::sleep(($bytes - $bps * ($now - $start)) / $bps);
      }
    }

    for (my $i = 0; $i < @dest; $i++) {
      my($client, $dest) = @{ $dest[$i] };
      $dest->send($recvBuf[$i]);
      $client->send($sendBuf[$i]);
    }
  }
}

1;
__END__

=head1 NAME

Net::Shaper - Simple TCP Traffic Shaper

=head1 SYNOPSIS

  use Net::Shaper;

  my $shaper = Net::Shaper->new( LocalPort => 8000,
				 PeerAddr  => "my.site.com:80",
				 Bps       => 6000 ); # 6000 Bytes/sec. =~ 48,000 bits/sec.

  $shaper->run(); # does not return

=head1 DESCRIPTION

Net::Shaper can be used to implement a point-to-point TCP tunnel that limits bandwidth.

=head1 BUGS

This module only works for TCP connections.  It has only been tested on Linux.

=head1 AUTHOR

Benjamin Holzman, E<lt>bholzman@earthlink.netE<gt>

=cut
