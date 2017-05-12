package Net::GPSD3;
use strict;
use warnings;
use base qw{Net::GPSD3::Base};
use JSON::XS qw{};
use IO::Socket::INET6 qw{};
use Net::GPSD3::Return::Unknown;
use Net::GPSD3::Cache;
use DateTime;

our $VERSION='0.19';
our $PACKAGE=__PACKAGE__;

=head1 NAME

Net::GPSD3 - Interface to the gpsd server daemon protocol versions 3 (JSON).

=head1 SYNOPSIS

=head2 Watch Interface

  use Net::GPSD3;
  my $gpsd=Net::GPSD3->new;
  $gpsd->watch;

One Liner

  perl -MNet::GPSD3 -e 'Net::GPSD3->new->watch'

=head2 Poll Interface

  use Net::GPSD3;
  use Data::Dumper qw{Dumper};
  my $gpsd=Net::GPSD3->new;
  my $poll=$gpsd->poll;
  print Dumper($poll);

One Liner

  perl -MNet::GPSD3 -e 'printf "Protocol: %s\n", Net::GPSD3->new->poll->parent->cache->VERSION->protocol;'

  Protocol: 3.4

=head2 POE Interface

See L<Net::GPSD3::POE>

=head1 DESCRIPTION

Net::GPSD3 provides an object client interface to the gpsd server daemon utilizing the version 3 protocol. gpsd is an open source GPS daemon from http://www.catb.org/gpsd/  Support for Version 3 of the protocol (JSON) was added to the daemon in version 2.90.  If your daemon is before 2.90 (protocol 2.X), please use the L<Net::GPSD> package.

=head1 CONSTRUCTOR

=head2 new

Returns a new Net::GPSD3 object.

  my $gpsd=Net::GPSD3->new;
  my $gpsd=Net::GPSD3->new(host=>"127.0.0.1", port=>2947); #defaults

=head1 METHODS

=head2 host

Sets or returns the current gpsd host.

 my $host=$obj->host;

=cut

sub host {
  my $self=shift;
  if (@_) {
    $self->{'host'}=shift;
    undef($self->{'socket'});
  }
  $self->{'host'}="127.0.0.1" unless defined $self->{'host'};
  return $self->{'host'};
}

=head2 port

Sets or returns the current gpsd TCP port.

 my $port=$obj->port;

=cut

sub port {
  my $self=shift;
  if (@_) {
    $self->{'port'}=shift;
    undef($self->{'socket'});
  }
  $self->{'port'}='2947' unless defined $self->{'port'};
  return $self->{'port'};
}

=head2 poll

Sends a Poll request to the gpsd server and returns a L<Net::GPSD3::Return::POLL> object. The method also populates the cache object with the L<Net::GPSD3::Return::VERISON> and L<Net::GPSD3::Return::DEVICES> objects.

  my $poll=$gpsd->poll; #isa Net::GPSD3::Return::POLL object

Note: In order to use the poll method consistently you should run the GPSD daemon as a service.  You may also need to run the daemon with the "-n" option.

=cut

sub poll {
  my $self=shift;
  $self->socket->send(qq(?DEVICES;\n)) unless $self->cache->DEVICES;
  $self->socket->send(qq(?POLL;\n));
  my $object;
  do { #Reads and caches VERSION and DEVICES
    local $/="\r\n";
    my $line=$self->socket->getline;
    chomp $line;
    $object=$self->constructor($self->decode($line), string=>$line);
    $self->cache->add($object) unless $object->class eq "POLL";
  } until $object->class eq "POLL"; #this needs more logic
  return $object;
}

=head2 watch

Calls all handlers that are registered in the handler method.

  $gpsd->watch;  #will not return unless something goes wrong.

=cut

sub watch {
  my $self=shift;
  my @handler=$self->handlers;
  push @handler, \&default_handler unless scalar(@handler);
  #$self->socket->send(qq(?DEVICES;\n)); #appears this is now done in the daemon
  $self->socket->send($self->_watch_string_on. "\n");
  my $object;
  #man 8 gpsd - Each request returns a line of response text ended by a CR/LF.
  local $/="\r\n";
  my $line;
  while (defined($line=$self->socket->getline)) { #Reads VERSION and DEVICES object too.
    #print "$line\n";
    chomp $line;
    my $object=$self->constructor($self->decode($line), string=>$line);
    $_->($object) foreach @handler;
    $self->cache($object); #cache after handler so that the last point is available to the handler.
  }
  return $self;
}

sub _watch_string_on {
  return q(?WATCH={"enable":true,"json":true};);
}

sub _watch_string_off {
  return q(?WATCH={"enable":false,"json":true};);
}

=head2 addHandler

Adds handlers to the handler list.

  $gpsd->addHandler(\&myHandler);
  $gpsd->addHandler(\&myHandler1, \&myHandler2);

A handler is a sub reference where the first argument is a Net::GPSD3::Return::* object.

=cut

sub addHandler {
  my $self=shift;
  my $array=$self->handlers;
  push @$array, @_ if @_;
  return $self;
}

=head2 handlers

List of handlers that are called in order to process objects from the gpsd wathcer stream.  

  my @handler=$gpsd->handlers; #()
  my $handler=$gpsd->handlers; #[]

=cut

sub handlers {
  my $self=shift;
  $self->{'handler'}=[] unless ref($self->{'handler'});
  return wantarray ? @{$self->{'handler'}} : $self->{'handler'};
}

=head2 cache

Returns the L<Net::GPSD3::Cache> caching object.

=cut

sub cache {
  my $self=shift;
  $self->{"cache"}=Net::GPSD3::Cache->new(parent=>$self)
    unless defined $self->{"cache"};
  return $self->{"cache"};
}

=head1 METHODS Internal

=head2 default_handler

=cut

sub default_handler {
  my $object=shift;
  #use Data::Dumper qw{Dumper};
  #print Dumper($object);
  if ($object->class eq "TPV") {
    printf "%s: %s, Time: %s, Lat: %s, Lon: %s, Speed: %s, Heading: %s\n",
             DateTime->now,
             $object->class,
             $object->timestamp,
             $object->lat,
             $object->lon,
             $object->speed,
             $object->track;
  } elsif ($object->class eq "SKY") {
    printf "%s: %s, Satellites: %s, Used: %s, PRNs: %s\n",
             DateTime->now,
             $object->class,
             $object->reported,
             $object->used,
             join(",", map {$_->prn} grep {$_->used} $object->Satellites),
  } elsif ($object->class eq "SUBFRAME") {
    printf qq{%s: %s, Device: %s\n},
             DateTime->now,
             $object->class,
             $object->device;
  } elsif ($object->class eq "VERSION") {
    printf "%s: %s, GPSD: %s (%s), %s: %s\n",
             DateTime->now,
             $object->class,
             $object->release,
             $object->revision,
             ref($object->parent),
             $object->parent->VERSION;
  } elsif ($object->class eq "WATCH") {
    printf "%s: %s, Enabled: %s\n",
             DateTime->now,
             $object->class,
             $object->enabled;
  } elsif ($object->class eq "DEVICES") {
    my @device=$object->Devices;
    foreach my $device (@device) {
      if ($device->activated) {
        $device=sprintf("%s (%s bps %s-%s)", $device->path, $device->bps, $device->driver, $device->subtype);
      } else {
        $device=$device->path;
      }
    }
    printf "%s: %s, Devices: %s\n",
             DateTime->now,
             $object->class,
             join(", ", @device);
  } elsif ($object->class eq "DEVICE") {
    printf qq{%s: %s, Device: %s (%s bps %s-%s)\n},
             DateTime->now,
             $object->class,
             $object->path,
             $object->bps,
             $object->driver,
             $object->subtype;
  } elsif ($object->class eq "ERROR") {
    printf qq{%s: %s, Message: "%s"\n},
             DateTime->now,
             $object->class,
             $object->message;
  } else {
    warn(sprintf(qq{Warning: Unknown class "%s" for object "%s".}, $object->class, ref($object)));
    #print Dumper($object);
  }
  #print Dumper($object);
}

=head2 socket

Returns the cached L<IO::Socket::INET6> object

  my $socket=$gpsd->socket;  #try to reconnect on failure

=cut

sub socket {
  my $self=shift;
  unless (defined($self->{'socket'}) and
            defined($self->{'socket'}->connected)) { 
    $self->{"socket"}=IO::Socket::INET6->new(
                        PeerAddr => $self->host,
                        PeerPort => $self->port,
                      );
    die(sprintf("Error: Cannot connect to gpsd://%s:%s/.\n",
      $self->host, $self->port)) unless defined($self->{"socket"});
  }
  return $self->{'socket'};
}

=head2 json

Returns the cached L<JSON::XS> object

=cut

sub json {
  my $self=shift;
  #Do I need to support JSON::PP?
  $self->{"json"}=JSON::XS->new unless ref($self->{"json"}) eq "JSON::XS";
  return $self->{"json"};
}

=head2 decode

Returns a perl data structure given a JSON formated string.

  my %data=$gpsd->decode($string); #()
  my $data=$gpsd->decode($string); #{}

=cut

sub decode {
  my $self=shift;
  my $string=shift;
  my $data=eval {$self->json->decode($string)};
  if ($@) {
    $data={class=>"ERROR", message=>"Invalid JSON"};
  }
  return wantarray ? %$data : $data;
}

=head2 encode

Returns a JSON string from a perl data structure

=cut

sub encode {
  my $self=shift;
  my $data=shift;
  my $string=$self->json->encode($data);
  return $string;
}

=head2 constructor

Constructs a class object by lazy loading the classes.

  my $obj=$gpsd->constructor(%$data);
  my $obj=$gpsd->constructor(class=>"DEVICE",
                             string=>'{...}',
                             ...);

Returns and object in the Net::GPSD3::Return::* namespace.

=cut

sub constructor {
  my $self=shift;
  my %data=@_;
  $data{"class"}||="undef";
  my $class=join("::", $PACKAGE, "Return", $data{"class"});
  my $object;
  eval("use $class");
  if ($@) { #Failed to load class
    $object=Net::GPSD3::Return::Unknown->new(parent=>$self, %data);
  } else {
    $object=$class->new(parent=>$self, %data);
  }
  return $object;
}

=head1 BUGS

Log on RT and Send to gpsd-dev email list

There are no two GPS devices that are alike.  Each GPS device has a different GPSD signature as well. If your GPS device does not work out of the box with this package, please send me a log of your devices JSON sentences.

  echo '?POLL;' | nc 127.0.0.1 2947

  echo '?WATCH={"enable":true,"json":true};' | socat -t10 stdin stdout | nc 127.0.0.1 2947

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

Try gpsd-dev email list

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>michaelrdavis,tld=>com,account=>perl
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Net::GPSD>, L<Net::GPSD3::POE>, L<GPS::Point>, L<JSON::XS>, L<IO::Socket::INET6>, L<DateTime>

=cut

1;
