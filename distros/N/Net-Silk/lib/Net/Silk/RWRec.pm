# Use of the Net-Silk library and related source code is subject to the
# terms of the following licenses:
# 
# GNU Public License (GPL) Rights pursuant to Version 2, June 1991
# Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013
# 
# NO WARRANTY
# 
# ANY INFORMATION, MATERIALS, SERVICES, INTELLECTUAL PROPERTY OR OTHER 
# PROPERTY OR RIGHTS GRANTED OR PROVIDED BY CARNEGIE MELLON UNIVERSITY 
# PURSUANT TO THIS LICENSE (HEREINAFTER THE "DELIVERABLES") ARE ON AN 
# "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY 
# KIND, EITHER EXPRESS OR IMPLIED AS TO ANY MATTER INCLUDING, BUT NOT 
# LIMITED TO, WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE, 
# MERCHANTABILITY, INFORMATIONAL CONTENT, NONINFRINGEMENT, OR ERROR-FREE 
# OPERATION. CARNEGIE MELLON UNIVERSITY SHALL NOT BE LIABLE FOR INDIRECT, 
# SPECIAL OR CONSEQUENTIAL DAMAGES, SUCH AS LOSS OF PROFITS OR INABILITY 
# TO USE SAID INTELLECTUAL PROPERTY, UNDER THIS LICENSE, REGARDLESS OF 
# WHETHER SUCH PARTY WAS AWARE OF THE POSSIBILITY OF SUCH DAMAGES. 
# LICENSEE AGREES THAT IT WILL NOT MAKE ANY WARRANTY ON BEHALF OF 
# CARNEGIE MELLON UNIVERSITY, EXPRESS OR IMPLIED, TO ANY PERSON 
# CONCERNING THE APPLICATION OF OR THE RESULTS TO BE OBTAINED WITH THE 
# DELIVERABLES UNDER THIS LICENSE.
# 
# Licensee hereby agrees to defend, indemnify, and hold harmless Carnegie 
# Mellon University, its trustees, officers, employees, and agents from 
# all claims or demands made against them (and any related losses, 
# expenses, or attorney's fees) arising out of, or relating to Licensee's 
# and/or its sub licensees' negligent use or willful misuse of or 
# negligent conduct or willful misconduct regarding the Software, 
# facilities, or other rights or assistance granted by Carnegie Mellon 
# University under this License, including, but not limited to, any 
# claims of product liability, personal injury, death, damage to 
# property, or violation of any laws or regulations.
# 
# Carnegie Mellon University Software Engineering Institute authored 
# documents are sponsored by the U.S. Department of Defense under 
# Contract FA8721-05-C-0003. Carnegie Mellon University retains 
# copyrights in all material produced under this contract. The U.S. 
# Government retains a non-exclusive, royalty-free license to publish or 
# reproduce these documents, or allow others to do so, for U.S. 
# Government purposes only pursuant to the copyright license under the 
# contract clause at 252.227.7013.

package Net::Silk::RWRec;

use strict;
use warnings;
use Carp;

use overload (
  'eq'   => \&eq,
  'ne'   => \&ne,
  '=='   => \&eq,
  '!='   => \&ne,
  '""'   => sub { shift },
);

use Net::Silk qw( :basic );
use Net::Silk::Site;

use DateTime;
use DateTime::Duration;
use Math::Int64 qw( uint64 );

use Scalar::Util qw( looks_like_number );

my %new_dispatch = (
    application      => sub { shift->application      (@_) },
    bytes            => sub { shift->bytes            (@_) },
    dip              => sub { shift->dip              (@_) },
    dport            => sub { shift->dport            (@_) },
    initial_tcpflags => sub { shift->initial_tcpflags (@_) },
    input            => sub { shift->input            (@_) },
    nhip             => sub { shift->nhip             (@_) },
    output           => sub { shift->output           (@_) },
    packets          => sub { shift->packets          (@_) },
    protocol         => sub { shift->protocol         (@_) },
    session_tcpflags => sub { shift->session_tcpflags (@_) },
    sip              => sub { shift->sip              (@_) },
    sport            => sub { shift->sport            (@_) },
    tcpflags         => sub { shift->tcpflags         (@_) },
    stime            => sub { shift->stime            (@_) },
    etime            => sub { shift->etime            (@_) },
    duration         => sub { shift->duration         (@_) },
    duration_ms      => sub { shift->duration_ms      (@_) },
    timeout_killed   => sub { shift->timeout_killed   (@_) },
    timeout_started  => sub { shift->timeout_started  (@_) },
    uniform_packets  => sub { shift->uniform_packets  (@_) },
);

sub new {
  my $class = shift;
  my $parms;
  if (@_ == 1 && ref $_[0]) {
    $parms = shift;
  }
  else {
    %{$parms = {}} = @_;
  }
  my $self;
  if (ref $class) {
    $self = $class->copy;
  }
  else {
    $self = $class->new_cleared();
  }
  if ($parms->{protocol}) {
    # needs to happen before setting any flags
    $new_dispatch{protocol}->($self => $parms->{protocol});
  }
  if ($parms->{etime} && $parms->{stime}) {
    # need to make sure stime is set first
    $new_dispatch{stime}->($self => $parms->{stime});
  }
  while (my($k, $v) = each %$parms) {
    my $sub = $new_dispatch{$k} or croak "unknown parameter '$k'";
    $sub->($self => $v);
  }
  $self;
}

sub as_hash {
  my $self = shift;
  my %r;
  for my $m (qw( application bytes dip duration stime
                 input nhip output packets protocol sip
                 finnoack timeout_killed timeout_started
                 uniform_packets )) {
    $r{$m} = $self->$m;
  }
  if (Net::Silk::Site::HAVE_SITE_CONFIG_SILENT()) {
    for my $m (qw( classtype_id classtype sensor_id sensor )) {
      $r{$m} = $self->$m;
    }
  }
  my $prot = $self->protocol;
  if ($prot == 6 || $prot == 17 || $prot == 132) {
    for my $m (qw( sport dport )) {
      $r{$m} = $self->$m;
    }
  }
  if ($self->is_icmp()) {
    for my $m (qw( icmptype icmpcode )) {
      $r{$m} = $self->$m;
    }
  }
  elsif ($prot == 6) {
    $r{tcpflags} = "" . $self->tcpflags;
  }
  if (defined $self->initial_tcpflags and $prot == 6) {
    for my $m (qw( initial_tcpflags session_tcpflags )) {
      $r{$m} = $self->$m;
    }
  }
  if ($self->uniform_packets) {
    $r{uniform_packets} = $self->uniform_packets;
  }
  wantarray ? %r : \%r;
}

sub application {
  my $self = shift;
  $self->set_application(shift) if @_;
  $self->get_application();
}

sub bytes {
  my $self = shift;
    $self->set_bytes(shift) if @_;
  $self->get_bytes();
}

sub finnoack {
  my $self = shift;
  $self->set_finnoack(shift) if @_;
  $self->get_finnoack();
}

sub icmpcode {
  my $self = shift;
  $self->set_icmpcode(shift) if @_;
  $self->get_icmpcode();
}

sub icmptype {
  my $self = shift;
  $self->set_icmptype(shift) if @_;
  $self->get_icmptype();
}

sub input {
  my $self = shift;
  $self->set_input(shift) if @_;
  $self->get_input();
}

sub output {
  my $self = shift;
  $self->set_output(shift) if @_;
  $self->get_output();
}

sub packets {
  my $self = shift;
  $self->set_packets(shift) if @_;
  $self->get_packets();
}

sub protocol {
  my $self = shift;
  $self->set_protocol(shift) if @_;
  $self->get_protocol();
}

sub sensor {
  my $self = shift;
  return unless Net::Silk::Site::HAVE_SITE_CONFIG_SILENT();
  if (@_) {
    my $sensor = shift;
    if (! looks_like_number($sensor)) {
      my $sensor_id = Net::Silk::Site::sensor_id($sensor);
      croak("Invalid sensor: $sensor") unless defined $sensor_id;
      $sensor = $sensor_id;
    }
    $self->set_sensor_id($sensor);
  }
  Net::Silk::Site::sensor_from_id($self->get_sensor_id());
}

sub sensor_id {
  my $self = shift;
  $self->set_sensor_id(shift) if @_;
  $self->get_sensor_id();
}

sub classname {
  my $self = shift;
  return unless Net::Silk::Site::HAVE_SITE_CONFIG_SILENT();
  $self->_classname();
}

sub typename {
  my $self = shift;
  return unless Net::Silk::Site::HAVE_SITE_CONFIG_SILENT();
  $self->_typename();
}

sub classtype {
  my $self = shift;
  return unless Net::Silk::Site::HAVE_SITE_CONFIG_SILENT();
  if (@_) {
    my $classtype;
    if (@_ > 1 || ref $_[0]) {
      my @ct;
      if (@_ > 1) {
        @ct = @_;
      }
      else {
        @ct = @{$_[0]};
      }
      my $classtype_id = Net::Silk::Site::classtype_id(@ct);
      croak("Invalid (class_name, type) pair: $classtype")
        unless defined $classtype_id;
      $classtype = $classtype_id;
    }
    else {
      $classtype = shift;
    }
    $self->set_classtype_id($classtype);
  }
  Net::Silk::Site::classtype_from_id($self->get_classtype_id());
}

sub classtype_id {
  my $self = shift;
  $self->set_classtype_id(shift) if @_;
  $self->get_classtype_id();
}

sub tcpflags {
  my $self = shift;
  $self->set_tcpflags(shift) if @_;
  $self->get_tcpflags();
}

sub initial_tcpflags {
  my $self = shift;
  $self->set_initial_tcpflags(shift) if @_;
  $self->get_initial_tcpflags();
}

sub session_tcpflags {
  my $self = shift;
  $self->set_session_tcpflags(shift) if @_;
  $self->get_session_tcpflags();
}

sub sip {
  my $self = shift;
  $self->set_sip(shift) if @_;
  $self->get_sip();
}

sub dip {
  my $self = shift;
  $self->set_dip(shift) if @_;
  $self->get_dip();
}

sub nhip {
  my $self = shift;
  $self->set_nhip(shift) if @_;
  $self->get_nhip();
}

sub sport {
  my $self = shift;
  $self->set_sport(shift) if @_;
  $self->get_sport();
}

sub dport {
  my $self = shift;
  $self->set_dport(shift) if @_;
  $self->get_dport();
}

sub timeout_killed {
  my $self = shift;
  $self->set_timeout_killed(shift) if @_;
  $self->get_timeout_killed();
}

sub timeout_started {
  my $self = shift;
  $self->set_timeout_started(shift) if @_;
  $self->get_timeout_started();
}

sub uniform_packets {
  my $self = shift;
  $self->set_uniform_packets(shift) if @_;
  $self->get_uniform_packets();
}

sub stime_epoch_ms {
  my $self = shift;
  $self->set_stime_epoch_ms(shift) if @_;
  $self->get_stime_epoch_ms();
}

sub stime {
  my $self = shift;
  if (@_) {
    my $t;
    if (@_ > 1) {
      $t = DateTime->new(@_);
    }
    else {
      $t = shift;
      if (! UNIVERSAL::isa($t, "DateTime")) {
        $t = DateTime->from_epoch(epoch => $t);
      }
    }
    # to milliseconds
    $self->set_stime_epoch_ms(uint64(($t->epoch*1000) + $t->millisecond));
  }
  # from milliseconds
  DateTime->from_epoch(epoch => $self->get_stime_epoch_ms()/1000);
}

sub etime_epoch_ms {
  my $self = shift;
  $self->set_etime_epoch_ms(shift) if @_;
  $self->get_etime_epoch_ms();
}

sub etime {
  my $self = shift;
  if (@_) {
    my $t;
    if (@_ > 1) {
      $t = DateTime->new(@_);
    }
    else {
      $t = shift;
      if (! UNIVERSAL::isa($t, "DateTime")) {
        $t = DateTime->from_epoch(epoch => $t);
      }
    }
    # to milliseconds
    $self->set_etime_epoch_ms(uint64(($t->epoch * 1000) + $t->millisecond));
  }
  # from milliseconds
  DateTime->from_epoch(epoch => $self->get_etime_epoch_ms()/1000);
}

sub duration_ms {
  my $self = shift;
  $self->set_duration_ms(shift) if @_;
  $self->get_duration_ms();
}

sub duration {
  my $self = shift;
  if (@_) {
    my $d;
    if (@_ > 1) {
      $d = DateTime::Duration->new(@_);
    }
    else {
      $d = shift;
      if (! UNIVERSAL::isa($d, "DateTime::Duration")) {
        $d = DateTime::Duration->new(seconds => $d);
      }
    }
    # to milliseconds
    my $t = $d->days * 24 * 60 * 60 * 1000;
    $t += $d->hours * 60 * 60 * 1000;
    $t += $d->minutes * 60 * 1000;
    $t += $d->seconds * 1000;
    $t += $d->nanoseconds / 1_000_000;
    # uint32_t
    $self->set_duration_ms(int($t));
  }
  # from milliseconds
  DateTime::Duration->new(nanoseconds => $self->get_duration_ms()*1_000_000);
}

###

sub eq {
  my $self = shift;
  my $other = shift;
  if (! UNIVERSAL::isa($other, SILK_RWREC_CLASS)) {
    $other = SILK_RWREC_CLASS->new($other);
  }
  $self->_eq($other);
}

sub ne {
  my $self = shift;
  my $other = shift;
  if (! UNIVERSAL::isa($other, SILK_RWREC_CLASS)) {
    $other = SILK_RWREC_CLASS->new($other);
  }
  $self->_ne($other);
}

###

1;

__END__


=head1 NAME

Net::Silk::RWRec - SiLK Flow records

=head1 SYNOPSIS

  use Net::Silk::RWRec;

=head1 DESCRIPTION

C<Net::Silk::RWRec> objects SiLK flow records such as those produced by
L<rwfilter(1)>. C<Net::Silk::RWRec> objects are written and read from a
L<Net::Silk::File>.

=head1 METHODS

The following methods are available:

=head2 CONSTRUCTORS

=over

=item new(%params)

Returns a new C<Net::Silk::RWRec> object. Accepts the following keyword
parameters. See their corresponding accessor method names for
acceptable values and defaults:

=over

  application
  bytes
  classtype
  classtype_id
  dip
  dport
  duration
  duration_secs
  etime
  etime_epoch_secs
  initial_tcpflags
  icmpcode
  icmptype
  input
  nhip
  output
  packets
  protocol
  sensor
  sensor_id
  session_tcpflags
  sip
  sport
  stime
  stime_epoch_secs
  tcpflags
  timeout_killed
  timeout_started
  uniform_packets

=back

=item copy()

Returns a new RWRec that is a copy of this one.

=item to_ipv6()

Returns a new RWRec with the IP addresses (I<sip>, I<dip>, and I<nhip>)
converted to IPv6. Specifically, maps the IPv4 addresses into the
C<::ffff:0:0/96> prefix.

=item to_ipv4()

Returns a new RWRec with the IP addresses (I<sip>, I<dip>, and I<nhip>)
converted to IPv4. If any of these addresses cannot be converted to
IPv4 (that is, if any address is not in the C<::ffff:0:0/96> prefix),
returns C<undef>.

=back

=head2 ACCESSOR METHODS

With no arguments, all accessor methods return their current values.

=over

=item application($val)

Return or set the I<service> port of the flow, as set by the flow
meter if the meter supports it, a 16-bit integer. The L<yaf(1)> flow
meter refers to this value as the I<appLabel>. Defaults to 0.

=item bytes($val)

Return or set the number of bytes in the flow, a 32-bit integer.
Defaults to 0.

=item classname()

Return (not set) the class name string assigned to this flow record.
Initializes L<Net::Silk::Site> if it hasn't been already. Defaults to
'?'. In order to modify the classname, use C<classtype()> or
C<classtype_id()>.

=item classtype($class, $type)

=item classtype($classtype)

Return or set the classname and typename of this flow record. Can be
given as separate arguments or as an array ref containing the two
arguments. Returns a two-element list of classname and typename.
Initializes L<Net::Silk::Site> if it hasn't been already.

=item classtype_id($id)

Return or set the integer ID for the class and type of this flow record.
Defaults to 0.

=item dip($ip)

Return or set the destination IP of this flow record as a
L<Net::Silk::IPAddr>. The given IP can be a string or
L<Net::Silk::IPAddr>.

=item dport($port)

Return or set the destination port of this flow record as a 16-bit
integer. Defaults to 0. Since the destination port field is also used to
store the values for the ICMP type and code, setting this value may
modify I<icmptype> and I<icmpcode>.

=item duration($dt)

Return or set the duration of this flow record, either as a
L<DateTime::Duration> or an integer number of seconds. Defaults to 0.
Changing the I<duration> will modify I<etime> such that the difference
between I<etime> and I<stime> is the new duration. Returns a
L<DateTime::Duration>.

=item duration_ms($ms)

Return or set the duration of this flow record in milliseconds. Defaults
to 0. Changing the I<duration> will modify I<etime> as described for
C<duration()>.

=item etime(%dt_params)

=item etime($dt_or_secs)

Return or set the end time of this flow record, either as a L<DateTime>,
seconds since epoch, or as the keyword arguments that would be passed to
C<DateTime-E<gt>new()>. Defaults to the UNIX epoch time. Changing the
I<etime> will modify I<duration> of this record.

=item etime_epoch_ms($ms)

Return or set the end time of this flow record as a number of
milliseconds since the epoch time. Defaults to 0. Changing this will
modify the I<duration> of this record.

=item initial_tcpflags($flags)

Return or set the TCP flags on the first packet of this flow, as a
L<Net::Silk::TCPFlags> object or string or number acceptable to
C<Net::Silk::TCPFlags-E<gt>new()>. Setting I<initial_tcpflags> when
I<session_tcpflags> is undef will set the latter to an empty-string
L<Net::Silk::TCPFlags>. Setting I<initial_tcpflags> or
I<session_tcpflags> sets I<tcpflags> to the binary OR of their
values. Trying to set I<initial_tcpflags> when I<protocol> is not 6
(TCP) will croak.

=item icmpcode($val)

Return or set the ICMP code of this flow record, an 8-bit integer.
Defaults to 0. The value is only meaningful when I<protocol> is ICMP (1)
or when C<is_ipv6()> is true and I<protocol> is ICMPv6 (58). Since ICMP
type and code are stored in the I<dport> field, setting this value may
modify I<dport>.

=item icmptype($val)

Return or set the ICMP type of this flow record, an 8-bit integer.
Defaults to 0. The value is only meaningful when I<protocol> is ICMP (1)
or when C<is_ipv6()> is true and I<protocol> is ICMPv6 (58). Since ICMP
type and code are stored in the I<dport> field, setting this value may
modify I<dport>.

=item input($val)

The SNMP interface where this flow record entered the router or the
vlanId if the packing tools are configured to capture it (see
L<sensor.conf(5)>), as a 16-bit integer. Defaults to 0.

=item nhip($ip)

Return or set the next-hop IP of this flow record as a
L<Net::Silk::IPAddr>. The given IP can be a string or
L<Net::Silk::IPAddr>.

=item output($val)

The SNMP interface where this flow record exited the router or the
postVlanId if the packing tools are configured to capture it (see
L<sensor.conf(5)>), as a 16-bit integer. Defaults to 0.

=item packets($val)

Return or set the packet count for this flow record, a 32-bit integer.
Defaults to 0.

=item protocol($val)

Return or set the IP protocol of this flow record, an 8-bit integer.
Defaults to 0. Setting I<protocol> to anything other than 6 (TCP) causes
I<initial_tcpflags> and I<session_tcpflags> to be set to C<undef>.

=item sensor($name)

Return or set the name of the sensor where this flow record was
collected. Initializes L<Net::Silk::Site> if it hasn't been already.
Defaults to '?'.

=item sensor_id($id)

Return or set the sensor ID where this flow record was collected, a
16-bit integer. Defaults to 0.

=item session_tcpflags($flags)

Return or set the union of the flags of all but the first packet in this
flow record, as a L<Net::Silk::TCPFlags> or as a string or number
acceptable to C<Net::Silk::TCPFlags-E<gt>new()>. Setting
I<session_tcpflags> when I<initial_tcpflags> is C<undef> sets the latter
to an empty-string L<Net::Silk::TCPFlags>. Setting I<initial_tcpflags>
or I<session_tcpflags> sets I<tcpflags> to the binary OR of their
values. Trying to set I<session_tcpflags> when I<protocol> is not 6
(TCP) will croak.

=item sip($ip)

Return or set the source IP of this flow record as a
L<Net::Silk::IPAddr>. The given IP can be a string or
L<Net::Silk::IPAddr>.

=item sport($port)

Return or set the source port of this flow record. Defaults to 0.

=item stime(%dt_params)

=item stime($dt_or_secs)

Return or set the start time of this flow record, either as a
L<DateTime>, seconds since epoch, or as the keyword arguments that would
be passed to C<DateTime-E<gt>new()>. Defaults to the UNIX epoch time.
Changing the I<stime> will modify I<etime> such that I<duration> stays
constant. The maximum possible I<stime> is 2038-01-19 03:14:07 UTC.

=item stime_epoch_ms($ms)

Return or set the start time of this flow record as the number of
milliseconds since the epoch time. Defaults to 0. Changing this will
modify I<etime> such that I<duration> stays constant.

=item tcpflags($flags)

Return or set the union of the flags of all packets in this
flow record, as a L<Net::Silk::TCPFlags> or as a string or number
acceptable to C<Net::Silk::TCPFlags-E<gt>new()>. Setting I<tcpflags>
sets I<initial_tcpflags> and I<session_tcpflags> to undef. Setting
I<initial_tcpflags> or I<session_tcpflags> changes I<tcpflags> to the
binary OR of their values.

=item timeout_killed($bool)

Return or set whether this flow record was closed early due to timeout
by the collector. Defaults to 0.

=item timeout_started($bool)

Return or set whether this flow record is a continuation from a
timed-out flow. Defaults to 0.

=item typename()

Return (not set) the type name of this flow record. Initializes
L<Net::Silk::Site> if it hasn't been already. Defaults to 255. In order
to modify I<typename>, use the C<classtype()> or
C<classtype_id()> methods.

=item uniform_packets($bool)

Return or set whether this flow record contained only packets of the
same size. Defaults to 0.

=back

=head2 REGULAR METHODS

=over

=item as_hash()

Return a hash representing the contents of this RWRec. This will
implicitely initialize L<Net::Silk::Site> if it hasn't been already.

=item is_icmp()

Return whether or not the protocol of this flow record is 1 (ICMP) or if
the protocol is 58 (ICMPv6) while C<is_ipv6()> is true.

=item is_ipv6()

Return whether or not this flow record contains IPv6 addresses.

=item is_web()

Return whether or not this flow record can be represented as a web
record. A record can be represented as a web record if the protocol
is TCP (6) and either the source or destination port is one of 80,
443, or 8080.

=back

=head1 OPERATORS

The following operators are overloaded and work with
C<Net::Silk::RWRec> objects:

  eq
  ne
  ==
  !=
  ""

=head1 SEE ALSO

L<Net::Silk>, L<Net::Silk::IPSet>, L<Net::Silk::Bag>, L<Net::Silk::Pmap>, L<Net::Silk::IPWildcard>, L<Net::Silk::Range>, L<Net::Silk::CIDR>, L<Net::Silk::IPAddr>, L<Net::Silk::TCPFlags>, L<Net::Silk::ProtoPort>, L<Net::Silk::File>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
