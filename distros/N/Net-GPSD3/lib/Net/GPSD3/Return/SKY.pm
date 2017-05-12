package Net::GPSD3::Return::SKY;
use strict;
use warnings;
use base qw{Net::GPSD3::Return::Unknown::Timestamp};
use DateTime;

our $VERSION='0.12';

=head1 NAME

Net::GPSD3::Return::SKY - Net::GPSD3 Return SKY Object

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides a Perl object interface to the SKY object returned by the GPSD daemon.

An example JSON object:

=head3 Protcol 3.1 versions

  {
    "class":"SKY",
    "tag":"MID4",
    "device":"/dev/ttyUSB0",
    "time":1253593665.430,
    "hdop":23.60,
    "reported":9,
    "satellites":
      [
        {"PRN":15,"el":77,"az":123,"ss":0, "used":false},
        {"PRN":18,"el":25,"az":268,"ss":0, "used":false},
        {"PRN":27,"el":13,"az":150,"ss":0, "used":false},
        {"PRN":29,"el":47,"az":228,"ss":0, "used":false},
        {"PRN":5, "el":39,"az":58, "ss":46,"used":true },
        {"PRN":21,"el":41,"az":309,"ss":33,"used":true },
        {"PRN":10,"el":32,"az":61, "ss":40,"used":true },
        {"PRN":8, "el":12,"az":48, "ss":40,"used":true },
        {"PRN":2, "el":9, "az":124,"ss":0, "used":false}
      ]
  }

=head3 Protcol 3.4 versions

  {
    "class":"SKY",
    "tag":"0x0120",
    "device":"/dev/cuaU0",
    "xdop":0.58,
    "ydop":0.96,
    "vdop":1.92,
    "tdop":1.14,
    "hdop":1.90,
    "gdop":2.93,
    "pdop":2.70,
    "satellites":[
      {"PRN":17,"el":76,"az":174,"ss":34,"used":true},
      {"PRN":28,"el":57,"az":38,"ss":30,"used":false},
      {"PRN":27,"el":22,"az":314,"ss":18,"used":true},
      {"PRN":7,"el":15,"az":127,"ss":29,"used":true},
      {"PRN":15,"el":31,"az":297,"ss":27,"used":true},
      {"PRN":11,"el":18,"az":54,"ss":28,"used":false},
      {"PRN":24,"el":18,"az":63,"ss":29,"used":false},
      {"PRN":9,"el":4,"az":313,"ss":18,"used":false},
      {"PRN":8,"el":45,"az":117,"ss":33,"used":true},
      {"PRN":26,"el":49,"az":245,"ss":37,"used":true},
      {"PRN":4,"el":5,"az":170,"ss":17,"used":false},
      {"PRN":138,"el":44,"az":157,"ss":40,"used":true}
    ]
  }

=head1 METHODS PROPERTIES

=head2 class

Returns the object class

=head2 string

Returns the JSON string

=head2 parent

Return the parent Net::GPSD object

=head2 device

=cut

sub device {shift->{"device"}};

=head2 tag

=cut

sub tag {shift->{"tag"}};

=head2 time

=head2 timestamp

=head2 datetime

=head2 reported

Count of satellites in view

=cut

sub reported {
  my $self=shift;
  $self->{"reported"}=scalar(@{$self->satellites})
    unless defined $self->{"reported"};
  return $self->{"reported"};
}

=head2 used

Count of satellites used in calculation

=cut

sub used {
  my $self=shift;
  $self->{"used"}=scalar(@{[grep {$_->{"used"}} $self->satellites]})
    unless defined $self->{"used"};
  return $self->{"used"};
}

=head2 satellites

Returns a list of satellite data structures.

  my $satellites=$sky->satellites(); #[{},...]
  my @satellites=$sky->satellites(); #({},...)

=cut

sub satellites {
  my $self=shift;
  unless (ref($self->{"satellites"}) eq "ARRAY") {
    $self->{"satellites"}=[];
  }
  return wantarray ? @{$self->{"satellites"}} : $self->{"satellites"};
}

=head2 Satellites

Returns a list of L<Net::GPSD3::Return::Satellite> objects.

  my @satellites=$sky->Satellites; #(bless{},...)
  my $satellites=$sky->Satellites; #[bless{},...]
  
=cut

sub Satellites {
  my $self=shift;
  unless (defined($self->{"Satellites"})) {
    $self->{"Satellites"}=[
      map {$self->parent->constructor(%$_,
                                      class=>"Satellite",
                                      string=>$self->parent->encode($_))} 
        grep {ref($_) eq "HASH"} $self->satellites];
  }
  return wantarray ? @{$self->{"Satellites"}} : $self->{"Satellites"};
}

=head1 BUGS

Log on RT and Send to gpsd-dev email list

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

L<Net::GPSD3>, L<DateTime>, L<Net::GPSD3::Return::Unknown>

=cut

1;
