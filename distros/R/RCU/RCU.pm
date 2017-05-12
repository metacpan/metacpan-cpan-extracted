=head1 NAME

RCU - Remote Control Unit Interface

=head1 SYNOPSIS

   use RCU;

=head1 DESCRIPTION

This module provides a generic interface to remote control units (only
receivers at the moment, as I cannot test more). It only provides an
abstract management interface, other modules are required for the hardware
access (RCU::Irman and RCU::Lirc are included, however).

=head2 GETTING STARTED

Please read L<RCU::Receipts> to get some idea on how to proceed after you
installed the module (testing & standard techniques).

=head1 THE RCU CLASS

The RCU class provides a general interface to anything you might want to
do to, it represents your application.

=over 4

=cut

package RCU;

$VERSION = 0.021;

use Carp;

=item $rcu = new RCU "interface-spec"

Creates a new RCU application. C<interface> must be an interface
specification similar to DBI's DSN:

 RCU:ifname:arg:arg...

Examples:
low-level interface (without C<RCU::> prefix) or an arrayref containing
name and constructor arguments. If the interface name has a C<::> prefix
it will be used as-is (without that prefix, of course).

For a much better interface, see L<RCU::Event>.

=cut

sub new {
   my $class = shift;
   my $if = shift;
   my $self = bless {}, $class;

   my ($rcu, $ifname, @ifargs) = split /:/, $if;
   $rcu eq "RCU" or croak "unknown interface name syntax";
   $ifname = "RCU::$ifname";
   do { eval "require $ifname"; die $@ if $@ } unless exists ${"$ifname\::"}{VERSION}; # best bet
   $self->{if} = $ifname->new(@ifargs);

   $self;
}

=item $rcu->interface

Return the RCU::Interface object used by this RCU object.

=cut

sub interface {
   $_[0]->{if};
}

=item ($keycode, $repeat) = $rcu->get

=item ($keycode, $repeat) = $rcu->poll

Simplified interface to the RCU (See also L<RCU::Event>), return a cooked
keycode and a repeat count (initial keypress = 0, increasing while the
key is pressed). If C<get> is called in scalar context it only returns
unrepeated keycodes.

This interface is problematic: no key-up events are generated, and
the repeat events occur pseudo-randomly and have no time relation
between each other, so better use the event-based interface provided by
L<RCU::Event|RCU::Event>.

=cut

$some_key;
$last_key;
$next_time;
$last_repeat;

sub _poll {
   my $self = shift;
   my @code = @_;
   return unless @code;
   my $now = shift @code;
   my $key = $RCU::Key::db{$code[0]}
             || ($RCU::Key::db{$code[1]} ||= new RCU::Key
                   $some_key->[0] || $RCU::Key::db{""}{"<default>"}[0] || {},
                   $code[1]);

   my $repeat_min  = $key->[0]{repeat_min} || 1;
   my $repeat_freq = $key->[0]{repeat_freq} || 0.2;
   if ($last_key == $key) {
      if ($now <= $next_time) {
         $last_repeat++;
      } else {
         $last_repeat = 0;
      }
   } else {
      $last_repeat = 0;
   }
   $some_key = $last_key = $key;
   $next_time = $now + $repeat_freq;
   if ($last_repeat && $last_repeat < $repeat_min) {
      return;
   } else {
      my $repeat = $last_repeat >= $repeat_min ? $last_repeat - $repeat_min + 1 : 0;
      return ($key->[2] || $key->[1], $repeat);
   }
}

sub poll {
   my $self = shift;
   $self->_poll($self->{if}->poll);
}

sub get {
   my $self = shift;
   while() {
     my @code = $self->_poll($self->{if}->get);
     if (@code) {
        return @code if wantarray;
        return $code[0] unless $code[0];
     }
   }
}


=back

=head1 THE RCU::Key CLASS

This class collects information about rcu keys.

=cut

package RCU::Key;

sub new {
   my $class = shift;
   my ($def, $cooked) = @_;
   bless [$def, $cooked], $class;
}

# RCU key database management

%db;

# $rcu{rcu_name}->{raw|cooked}->key;

# $def, $cooked

sub add_key {
   my ($def, $raw, $cooked) = @_;
   return $db{$def->{rcu_name}}{$raw} = new RCU::Key $def, $cooked;
}

package RCU::Config::Parser;

my $def;
my @def;

sub def(&) {
   my $sub = shift;
   push @def, $def;
   $def = $def ? {%$def} : {};
   &$sub;
}

sub rcu_name($) {
   $def->{rcu_name}    = shift;
}

sub repeat_freq($) {
   $def->{repeat_freq} = shift;
}

sub repeat_min($) {
   $def->{repeat_min}  = shift;
}

sub key($;$) {
   my ($raw, $cooked) = @_;
   RCU::Key::add_key($def, $raw, $cooked || $raw);
}

=head1 THE RCU::Interface CLASS

C<RCU::Interface> provides the base class for all rcu interfaces, it is rarely used directly.

=over 4

=cut

package RCU::Interface;

use Carp;

sub new {
   my $class = shift;
   my $self = bless {}, $class;
   $self;
}

=item fd

Return a unix filehandle that can be polled, or -1 if this is not
possible.

=item ($time, $raw, $cooked) = $if->get

=item ($time, $raw, $cooked) = $if->poll

Wait until a RCU event happens and return it. If the device can translate
raw keys events (e.g. hex key codes) into meaningful names ("cooked" keys)
it will return the cooked name as second value, otherwise both return
values are identical.

C<get> always returns an event, waiting if neccessary, while C<poll> only
checks for an event: If one is pending it is returned, otherwise C<poll>
returns nothing.

=cut

# do get emulation for interfaces that don't have get. slow but who cares, anyway

sub get {
   my $self = shift;
   my $fd = $self->fd;
   $fd >= 0 or croak ref($self)."::get cannot be emulated without an fd method";
   my @code;
   while (!(@code = $self->poll)) {
      my $in = ""; vec ($in, $fd, 1) = 1;
      select $in, undef, undef, undef;
   }
   wantarray ? @code : $code[1];
}

1;

=back

=head1 SEE ALSO

L<RCU::Irman>, L<RCU::Lirc>.

=head1 AUTHOR

This perl extension was written by Marc Lehmann <schmorp@schmorp.de>.

=head1 BUGS

No send interface.

=cut





