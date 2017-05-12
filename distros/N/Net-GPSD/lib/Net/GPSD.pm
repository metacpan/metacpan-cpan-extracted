package Net::GPSD;
use strict;
use warnings;
use IO::Socket::INET;
use Net::GPSD::Point;
use Net::GPSD::Satellite;

our $VERSION='0.39';

=head1 NAME

Net::GPSD - Provides an object client interface to the gpsd server daemon. 

=head1 SYNOPSIS

 use Net::GPSD;
 $obj=Net::GPSD->new;
 my $point=$obj->get;
 print $point->latlon. "\n";

or

 use Net::GPSD;
 $obj=Net::GPSD->new;
 $obj->subscribe();

=head1 DESCRIPTION

Note: This package supports the older version 2 protocol.  It works for gpsd versions less than 3.00.  However, for all versions of the gpsd deamon greater than 2.90 you should use the version 3 protocol supported by L<Net::GPSD3>.

Net::GPSD provides an object client interface to the gpsd server daemon.  gpsd is an open source GPS deamon from http://gpsd.berlios.de/.

For example the get method returns a blessed hash reference like

 {S=>[?|0|1|2],
  P=>[lat,lon]}

Fortunately, there are various methods that hide this hash from the user.

=head1 CONSTRUCTOR

=head2 new

Returns a new Net::GPSD object.

 my $obj=Net::GPSD->new(host=>"localhost", port=>"2947");

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

=head2 initialize

=cut

sub initialize {
  my $self = shift();
  my %param = @_;
  $self->{'host'}=$param{'host'} || 'localhost';
  $self->{'port'}=$param{'port'} || '2947';
  unless ($param{'do_not_init'}) { #for testing
    my $data=$self->retrieve('LKIFCB');
    foreach (keys %$data) {
      $self->{$_}=[@{$data->{$_}}]; #there has got to be a better way to do this...
    }
  }
}

=head2 get

Returns a current point object regardless if there is a fix or not.  Applications should test if $point->fix is true.

 my $point=$obj->get();

=cut

sub get {
  my $self=shift();
  my $data=$self->retrieve('SMDO');
  return Net::GPSD::Point->new($data);
}

=head2 subscribe

The subscribe method listens to gpsd server in watcher (W command)  mode and calls the handler for each point received.  The return for the handler will be sent back as the first argument to the handler on the next call.

 $obj->subscribe();
 $obj->subscribe(handler=>\&gpsd_handler, config=>$config);

=cut

sub subscribe {
  my $self = shift();
  my %param = @_;
  my $last=undef();
  my $handler=$param{'handler'} || \&default_point_handler;
  my $satlisthandler=$param{'satlisthandler'} || \&default_satellitelist_handler;
  my $config=$param{'config'} || {};
  my $sock = IO::Socket::INET->new(PeerAddr=>$self->host,
                                   PeerPort=>$self->port);
  $sock->send("W\n");
  my $data;
  my $point;
  while (defined($_=$sock->getline)) {
    if (m/,O=/) {
      $point=Net::GPSD::Point->new($self->parse($_));
      $point->mode(defined($point->tag) ? (defined($point->alt) ? 3 : 2) : 0);
      if ($point->fix) {
        my $return=&{$handler}($last, $point, $config);
        $last=$return if (defined($return));
      }
    } elsif (m/,W=/) {
    } elsif (m/,Y=/) {
    } elsif (m/,X=/) {
    } else {
      warn "Unknown: $_\n";
    }
  }
}

=head2 default_point_handler

=cut

sub default_point_handler {
  my $p1=shift(); #last return or undef if first
  my $p2=shift(); #current fix
  my $config=shift(); #configuration data
  print $p2->latlon. "\n";
  return $p2;
}

=head2 default_satellitelist_handler

=cut

sub default_satellitelist_handler {
  my $sl=shift();
  my $i=0;
  print join("\t", qw{Count PRN ELEV Azim SNR USED}), "\n";
  foreach (@$sl) {
    print join "\t", ++$i,
                     $_->prn,
                     $_->elev,
                     $_->azim,
                     $_->snr,
                     $_->used;
    print "\n";
  }
  return 1;
}

=head2 getsatellitelist

Returns a list of Net::GPSD::Satellite objects.  (maps to gpsd Y command)

 my @list=$obj->getsatellitelist;
 my $list=$obj->getsatellitelist;

=cut

sub getsatellitelist {
  my $self=shift();
  my $string='Y';
  my $data=$self->retrieve($string);
  my @data = @{$data->{'Y'}};
  shift(@data);             #Drop sentence tag
  my @list = ();
  foreach (@data) {
    #print "$_\n";
    push @list, Net::GPSD::Satellite->new(split " ", $_);
  }
  return wantarray ? @list : \@list;
}

=head2 retrieve

=cut

sub retrieve {
  my $self=shift();
  my $string=shift();
  my $sock=$self->open();
  if (defined($sock)) {
    $sock->send($string) or die("Error: $!");
    my $data=$sock->getline;
    chomp $data;
    return $self->parse($data);
  } else {
    warn "$0: Could not connect to gspd host.\n";
    return undef();
  }
}

=head2 open

=cut

sub open {
  my $self=shift();
  if (! defined($self->{'sock'}) || ! defined($self->{'sock'}->connected())) {
    $self->{'sock'} = IO::Socket::INET->new(PeerAddr => $self->host,
                                            PeerPort => $self->port);
  }
  return $self->{'sock'};
}

=head2 parse

=cut

sub parse {
  my $self=shift();
  my $line=shift();
  my %data=();
  my @line=split(/[,\n\r]/, $line);  
  foreach (@line) {
    if (m/(.*)=(.*)/) {
      if ($1 eq 'Y') {
        $data{$1}=[split(/:/, $2)]; #Y is : delimited
      } else {
        $data{$1}=[map {$_ eq '?' ? undef() : $_} split(/\s+/, $2)];
      }
    }
  }
  return \%data;
}

=head2 host

Sets or returns the current gpsd host.

 my $host=$obj->host;

=cut

sub host {
  my $self = shift();
  if (@_) {
    $self->{'host'} = shift();
  }
  return $self->{'host'};
}

=head2 port

Sets or returns the current gpsd TCP port.

 my $port=$obj->port;

=cut

sub port {
  my $self = shift();
  if (@_) {
    $self->{'port'} = shift();
  }
  return $self->{'port'};
}

=head2 baud

Returns the baud rate of the connect GPS receiver. (maps to gpsd B command first data element)

 my $baud=$obj->baud;

=cut

sub baud {
  my $self = shift();
  return q2u $self->{'B'}->[0];
}

=head2 rate

Returns the sampling rate of the GPS receiver. (maps to gpsd C command first data element)

 my $rate=$obj->rate;

=cut

sub rate {
  my $self = shift();
  return q2u $self->{'C'}->[0];
}

=head2 device

Returns the GPS device name. (maps to gpsd F command first data element)

 my $device=$obj->device;

=cut

sub device {
  my $self = shift();
  return q2u $self->{'F'}->[0];
}

=head2 identification (aka id)

Returns a text string identifying the GPS. (maps to gpsd I command first data element)

 my $identification=$obj->identification;
 my $identification=$obj->id;

=cut

sub identification {
  my $self = shift();
  return q2u $self->{'I'}->[0];
}

=head2 id

=cut

sub id {
  my $self = shift();
  return $self->identification;
}

=head2 protocol

Returns the GPSD protocol revision number. (maps to gpsd L command first data element)

 my $protocol=$obj->protocol;

=cut

sub protocol {
  my $self = shift();
  return q2u $self->{'L'}->[0];
}

=head2 daemon

Returns the gpsd daemon version. (maps to gpsd L command second data element)

 my $daemon=$obj->daemon;

=cut

sub daemon {
  my $self = shift();
  return q2u $self->{'L'}->[1];
}

=head2 commands

Returns a string of accepted command letters. (maps to gpsd L command third data element)

 my $commands=$obj->commands;

=cut

sub commands {
  my $self = shift();
  my $string=q2u $self->{'L'}->[2];
  return wantarray ? split(//, $string) : $string
}

=head1 FUNCTIONS

=head2 time

Returns the time difference between two point objects in seconds.

 my $seconds=$obj->time($p1, $p2);

=cut

sub time {
  #seconds between p1 and p2
  my $self=shift();
  my $p1=shift();
  my $p2=shift();
  return abs($p2->time - $p1->time);
}

=head2 distance

Returns the distance difference between two point objects in meters. (simple calculation)

 my $meters=$obj->distance($p1, $p2);

=cut

sub distance {
  #returns meters between p1 and p2
  my $self=shift();
  my $p1=shift();
  my $p2=shift();
  my $lat1=$p1->lat;
  my $lon1=$p1->lon;
  my $lon2=$p2->lon;
  my $lat2=$p2->lat;

  use Geo::Inverse;
  my $obj = Geo::Inverse->new();
  my ($faz, $baz, $dist)=$obj->inverse($lat1, $lon1, $lat2, $lon2);
  return $dist;
}

=head2 track

Returns a point object at the predicted location in time seconds assuming constant velocity. (Geo::Forward calculation)

 my $point=$obj->track($p1, $seconds);

=cut

sub track {
  #return calculated point of $p1 in time assuming constant velocity
  my $self=shift();
  my $p1=shift();
  my $time=shift();
  use Geo::Forward;
  my $object = Geo::Forward->new(); # default "WGS84"
  my $dist=($p1->speed||0) * $time;   #meters
  my ($lat1,$lon1,$faz)=($p1->lat, $p1->lon, $p1->heading||0);
  my ($lat2,$lon2,$baz) = $object->forward($lat1,$lon1,$faz,$dist);

  my $p2=Net::GPSD::Point->new($p1);
  $p2->lat($lat2);
  $p2->lon($lon2);
  $p2->time($p1->time + $time);
  $p2->heading($baz-180);
  return $p2;
}

=head2 q2u

=cut

sub q2u {
  my $a=shift();
  return $a eq '?' ? undef() : $a;
}

=head1 GETTING STARTED

Try the examples in the bin folder.  Most every method has a default which is most likely what you will want.

=head1 LIMITATIONS

The distance function is Geo::Inverse.

The track function uses Geo::Forward.

All units are degrees, meters, seconds.

=head1 BUGS

Email the author and log on RT.

=head1 EXAMPLES

=begin html

<ul>
<li><a href="../../bin/example-get.pl">example-get.pl</a></li>
<li><a href="../../bin/example-subscribe.pl">example-subscribe.pl</a></li>
<li><a href="../../bin/example-subscribe-handler.pl">example-subscribe-handler.pl</a></li>
<li><a href="../../bin/example-check.pl">example-check.pl</a></li>
<li><a href="../../bin/example-information.pl">example-information.pl</a></li>
<li><a href="../../bin/example-getsatellitelist.pl">example-getsatellitelist.pl</a></li>
<li><a href="../../bin/example-tracker.pl">example-tracker.pl</a></li>
<li><a href="../../bin/example-tracker-http.pl">example-tracker-http.pl</a></li>
<li><a href="../../bin/example-tracker-text.pl">example-tracker-text.pl</a></li>
</ul>

=end html

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

Michael R. Davis, qw/gpsd michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Geo::Inverse>, L<Geo::Forward>

=cut

1;
