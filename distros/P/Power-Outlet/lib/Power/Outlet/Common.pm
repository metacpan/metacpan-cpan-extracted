package Power::Outlet::Common;
use strict;
use warnings;
use Time::HiRes qw{};
use base qw{Package::New};

our $VERSION = '0.46';
our $STATE   = 'OFF';

=head1 NAME

Power::Outlet::Common - Power::Outlet base class for all power outlets

=head1 SYNOPSIS

  use base qw{Power::Outlet::Common};

=head1 DESCRIPTION
 
Power::Outlet::Common is a base class for controlling and querying a power outlets.

=head1 USAGE

  use base qw{Power::Outlet::Common};

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 action

Smart case insensitive text-based wrapper around methods 0|ON => on, 1|OFF => off, SWITCH|TOGGLE => switch, CYCLE => cycle, QUERY => query

  my $state = $outlet->action("on");
  my $state = $outlet->action("1");
  my $state = $outlet->action("off");
  my $state = $outlet->action("0");
  my $state = $outlet->action("switch");
  my $state = $outlet->action("toggle");

=cut

sub action {
  my $self   = shift;
  my $action = shift;
  if ($action =~ m/\A(?:1|ON)\Z/i) {
    $self->on;
  } elsif ($action =~ m/\A(?:0|OFF)\Z/i) {
    $self->off;
  } elsif ($action =~ m/\A(?:SWITCH|TOGGLE)\Z/i) {
    $self->switch;
  } elsif ($action =~ m/\A(?:CYCLE)\Z/i) {
    $self->cycle;
  } elsif ($action =~ m/\A(?:QUERY)\Z/i) {
    $self->query;
  } else {
    die(qq{Error: action "$action" not supported});
  } 
}

=head2 query

The query method must be overridden in the sub class.

  my $state = $outlet->query;  #returns ON|OFF Note: may return other values for edge case

=cut

sub query {return $STATE};

=head2 on

The on method must be overridden in the sub class.

  my $state = $outlet->on;   #turns the outlet on reguardless of current state and returns ON.

Note: This should cancel any non-blocking cycle requests

=cut

sub on {return $STATE = 'ON'};

=head2 off

The off method must be overridden in the sub class.

  my $state = $outlet->off;   #turns the outlet off reguardless of current state and returns OFF.

Note: This should cancel any non-blocking cycle requests

=cut

sub off {return $STATE = 'OFF'};

=head2 switch

Only override the switch method if your hardware natively supports this capability.  However, it should still be documented.

  my $state = $outlet->switch; #turns the outlet off if on and on if off and returns the final state ON|OFF.

Note: The default implementations does not cancel non-blocking cycle requests

=cut

sub switch {
  my $self  = shift;
  my $query = $self->query;
  return $query eq 'OFF' ? $self->on  :
         $query eq 'ON'  ? $self->off :
         $query; #e.g. CYCLE, BUSY, etc.
}

=head2 cycle

Only override the cycle method if your hardware natively supports this capability.  However, it should still be documented.

  my $state = $outlet->cycle; #turns the outlet off-on-off or on-off-on with a delay and returns the final state ON|OFF.

Note: Implementations may be blocking or non-blocking.

=cut

sub cycle {
  my $self = shift;
  $self->switch;
  Time::HiRes::sleep $self->cycle_duration; #blocking. Maybe we should be non-blocking somehow.
  return $self->switch;
}

=head2 cycle_duration

Override the cycle_duration method if you want.

Default; 10 seconds (floating point number)

=cut

sub cycle_duration {
  my $self                  = shift;
  $self->{'cycle_duration'} = shift if @_;
  $self->{'cycle_duration'} = 10 unless defined $self->{'cycle_duration'};
  return $self->{'cycle_duration'};
}

=head2 name

User friendly name for an outlet.  

=cut

sub name {
  my $self        = shift;
  $self->{'name'} = shift if @_;
  $self->{'name'} = $self->_name_default unless defined $self->{'name'};
  return $self->{'name'};
}

sub _name_default {''};

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;
