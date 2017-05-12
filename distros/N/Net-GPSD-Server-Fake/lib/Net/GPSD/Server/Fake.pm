package Net::GPSD::Server::Fake;

=pod

=head1 NAME

Net::GPSD::Server::Fake - Provides a Fake GPSD daemon server test harness. 

=head1 SYNOPSIS

 use Net::GPSD::Server::Fake;
 use Net::GPSD::Server::Fake::Stationary;
 my $server=Net::GPSD::Server::Fake->new();
 my $stationary=Net::GPSD::Server::Fake::Stationary->new(lat=>38.865826,
                                                         lon=>-77.108574);
 $server->start($stationary);

=head1 DESCRIPTION

=cut

use strict;
use vars qw($VERSION);
use IO::Socket::INET;
use Time::HiRes qw{time};
use Geo::Functions qw{dm_deg};

$VERSION = sprintf("%d.%02d", q{Revision: 0.16} =~ /(\d+)\.(\d+)/);

=head1 CONSTRUCTOR

=head2 new

Returns a new server

  my $server=Net::GPSD::Server::Fake->new(
               port=>'2947',
               name=>'GPSD',
               version=>Net::GPSD::Server::Fake->VERSION,
               debug=>1); 0=>none, 2=>default, 2+=>verbose

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=cut

sub initialize {
  my $self = shift();
  my %param = @_;
  $self->{'port'}    = $param{'port'}    || '2947';
  $self->{'version'} = $param{'version'} || $VERSION;
  $self->{'name'}    = $param{'name'}    || 'GPSD';
  $self->{'debug'}   = defined($param{'debug'}) ? $param{'debug'} : 2;
}

=head2 start

Binds provider to port and starts server.

 $server->start($provider);

=cut

sub start {
  my $self=shift();
  my $provider=shift();
  $SIG{CHLD} = 'IGNORE';
  my $listen_socket = IO::Socket::INET->new(LocalPort=>$self->port,
                                            Listen=>10,
                                            Proto=>'tcp',
                                            Reuse=>1);

  die "Can't create a listening socket: $@" unless $listen_socket;
  print "Debug Level: ", $self->{'debug'}, "\n" if ($self->{'debug'} > 2);

  while ($listen_socket->opened and my $connection=$listen_socket->accept) {
    my $child;
    die "Can't fork: $!" unless defined ($child = fork());
    if ($child == 0) {       #i'm the child!
      $listen_socket->close; #only parent needs listening socket
      my $chars="";
      my $w=0;
      my $r=0;
      my $pid_watcher=undef();
      my $pid_rmode=undef();
      my $name=$self->name;
      my $point=undef();
      my $sockhost=$connection->sockhost;
      my $sockport=$connection->sockport;
      my $peerhost=$connection->peerhost;
      my $peerport=$connection->peerport;
      print "Connected: ", $sockhost, ":", $sockport, " -> ", $peerhost,":",$peerport, "\n" if ($self->{'debug'} > 0);
      while (defined($_=$connection->getline)) {
        chomp;
        print "Command: ", $connection->peerhost,":",$connection->peerport, " -> ",$_ if ($self->{'debug'} > 1);
        next unless m/\S/;       # blank line
        my @output=($name);
        $point=$provider->get(time, $point);
        my @list=parseline($_);
        foreach (@list) {
          print " => $_" if ($self->{'debug'} > 2);
          if (m/l/i) {
            push @output, "L=0 ".$self->version." ailopstvwxy ".ref($self);
          } elsif (m/a/i) {
            push @output, "A=".u2q($point->alt);
            print ", A=".u2q($point->alt) if ($self->{'debug'} > 3);
          } elsif (m/v/i) {
            push @output, "V=".u2q($point->speed_knots);
            print ", V=".u2q($point->speed_knots) if ($self->{'debug'} > 3);
          } elsif (m/t/i) {
            push @output, "T=".u2q($point->heading);
            print ", T=".u2q($point->heading) if ($self->{'debug'} > 3);
          } elsif (m/s/i) {
            push @output, "S=".u2q($point->status);
            print ", S=".u2q($point->status) if ($self->{'debug'} > 3);
          } elsif (m/x/i) {
            push @output, "X=". $point->time||0;
          } elsif (m/i/i) {
            push @output, "I=".u2q(ref($provider));
          } elsif (m/m/i) {
            push @output, "M=".u2q($point->mode);
          } elsif (m/p/i) {
            push @output, "P=".join(" ", 
                                 u2q($point->lat),
                                 u2q($point->lon)
                               );
          } elsif (m/o/i) {
            push @output, $self->line_o($provider, $point);
          } elsif (m/y/i) {
            push @output, $self->line_y($provider, $point);
          } elsif (m/w/i) {
            $w=$w?0:1;
            push @output, "W=$w";
            if ($w) {
              $pid_watcher=$self->start_watcher($connection, $provider);
              print " => PID: $pid_watcher" if ($self->{'debug'} > 2);
            } else {
              $self->stop_child($pid_watcher);
            }
          } elsif (m/r/i) {
            $r=$r?0:1;
            push @output, "R=$r";
            if ($r) {
              $pid_rmode=$self->start_rmode($connection, $provider);
              print " => PID: $pid_rmode" if ($self->{'debug'} > 2);
            } else {
              $self->stop_child($pid_rmode);
            }
          } else {
          }
        } #end of foreach
        print $connection join(",", @output), "\n";
        print "\n" if ($self->{'debug'} > 0);
      } #end of while
      print "Disconnected: ", $sockhost, ":", $sockport, " -> ", $peerhost,":",$peerport, "\n" if ($self->{'debug'} > 0);
    } else { #i'm the parent
      $connection->close();
    }
  }
}

sub parseline {
  my $line=shift();
  my @list=();
  while ($line=~s/([a-z][^a-z]*)//i) {
    push(@list, $1) if $1;  
  }
  return @list;
}

sub start_watcher {
  my $self=shift();
  my $fh=shift();
  my $provider=shift();
  my $pid=fork();
  die("Error: Cannot fork.") unless defined $pid;
  if ($pid) {
    return $pid;
  } else {
    print ", starting watcher" if ($self->{'debug'} > 4);
    $self->watcher($fh, $provider);
  }
}

sub start_rmode {
  my $self=shift();
  my $fh=shift();
  my $provider=shift();
  my $pid=fork();
  die("Error: Cannot fork.") unless defined $pid;
  if ($pid) {
    return $pid;
  } else {
    $self->rmode($fh, $provider);
  }
}

sub stop_child {
  my $self=shift();
  my $pid=shift();
  print ", killing watcher" if ($self->{'debug'} > 4);
  kill "HUP", $pid;
}

sub line_o {
  my $self=shift();
  my $provider=shift();
  my $point=shift();
  if (ref($point) eq "Net::GPSD::Point") {
    #print $fh $self->name,",O=",
    return "O=".
      join(" ", $point->tag||"FAKE", $point->time||time,
                $point->errortime||0.001, u2q($point->lat), u2q($point->lon),
                u2q($point->alt), u2q($point->errorhorizontal),
                u2q($point->errorvertical), u2q($point->heading),
                u2q($point->speed), u2q($point->climb),
                u2q($point->errorheading), u2q($point->errorspeed),
                u2q($point->errorclimb), u2q($point->mode));
  } else {
    die("Error: provider->get must return Net::GPSD::Point\n");
  }
}

sub line_y {
  my $self=shift();
  my $provider=shift();
  my $point=shift();
  my @satellite=$provider->getsatellitelist($point);
  if (ref($satellite[0]) eq "Net::GPSD::Satellite") {
    #print $fh $self->name,",Y=",
    return "Y=".
      join(":", 
                join(" ", "FAKE",$point->time, scalar(@satellite)),
                map {join(" ", $_->prn, round($_->elev,1), round($_->azim,1),
                               round($_->snr,1), $_->used)
                    } @satellite);
  } else {
    die("Error: provider->getsatellitelist must return a list of Net::GPSD::Satellite objects.\n");
  }
}

sub line_rmc {
  my $self=shift();
  my $provider=shift();
  my $point=shift();
  my ($nd, $nm, $nsign)=dm_deg($point->lat, qw{N S});
  my ($ed, $em, $esign)=dm_deg($point->lon, qw{E W});
  
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime($point->time);
  my $line=sprintf("GPRMC,%02d%02d%02d,%s,%02d%07.4f,%s,%03d%07.4f,%s,%.4f,%.3f,%02d%02d%02d,,",
                   $hour,
                   $min,
                   $sec,
                   $point->fix ? 'A' : 'V', 
                   $nd,
                   $nm,
                   $nsign,
                   $ed,
                   $em,
                   $esign,
                   $point->speed_knots,
                   $point->heading,
                   $mday,
                   $mon + 1,
                   $year % 100);
  return join('', '$', $line, '*', checksum($line));
}

sub watcher {
  my $self=shift();
  my $fh=shift();
  my $provider=shift();
  my $point=undef();
  my $count=0;

  while (1) {
    $point=$provider->get(time(), $point);
    print $fh join(",", $self->name, $self->line_o($provider, $point)), "\n";
    if ($count++ % 5 == 0) {
      print $fh join(",", $self->name, $self->line_y($provider, $point)), "\n";
    }
    sleep 1;
  }
}

sub rmode {
  my $self=shift();
  my $fh=shift();
  my $provider=shift();
  my $point=undef();
  my $count=0;

  while (1) {
    $point=$provider->get(time(), $point);
    print $fh $self->line_rmc($provider, $point), "\n";
#   if ($count++ % 5 == 0) {
#     print $fh join(",", $self->name, $self->line_y($provider, $point)), "\n";
#   }
    sleep 1;
  }
}

=head2 name

Gets or sets GPSD protocol name. This defaults to "GPSD" as some clients are picky.

  $obj->name('GPSD');
  my $name=$obj->name;

=cut

sub name {
  my $self = shift();
  if (@_) { $self->{'name'} = shift() } #sets value
  return $self->{'name'};
}

=head2 port

Returns the current TCP port.

  my $port=$obj->port;

=cut

sub port {
  my $self = shift();
  return $self->{'port'};
}

=head2 version

Returns the version that the GPSD deamon reports in the L command.  This default to the version of the Net::GPSD::Server::Fake->VERSION package.

  my $obj=Net$obj->version;
  my $version=$obj->version;

=cut

sub version {
  my $self = shift();
  return $self->{'version'};
}

sub u2q {
  my $value=shift();
  return (!defined($value)||($value eq "")) ? "?" : $value;
}

sub round {
  my $number=shift();
  my $round=shift()||0.01;
  return $round * int($number/$round);
}

sub checksum {
  #${line}*{chk}
  my $line=shift(); #GPRMC,053513,A,5331.6290,N,11331.8101,W,0.0000,0.000,150107,,
  my $csum = 0;
  $csum ^= unpack("C", $_) foreach (split("", $line));
  return sprintf("%2.2X",$csum);
}

1;

__END__

=head1 KNOWN LIMITATIONS

Only knows a few commands

Commands must be one per line.

Can't change providers mid stream.

Providers must remember state for watcher restarts.

Providers are queryed for a new point.  However, there needs to be a way for providers to be able to trigger new points.

=head1 BUGS

Send issues to gpsd-dev email list

=head1 AUTHOR

Michael R. Davis, qw/gpsd michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

gpsd L<http://gpsd.berlios.de/>

=cut
