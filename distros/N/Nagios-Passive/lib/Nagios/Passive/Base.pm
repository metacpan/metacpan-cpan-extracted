#vim: softtabstop-2 sw=2 :
package Nagios::Passive::Base;

use strict;
use Carp;
use Fcntl qw/:DEFAULT :flock/;
use Nagios::Plugin::Threshold;
use Nagios::Plugin::Performance;
Nagios::Plugin::Functions::_use_die(1);
use overload '""' => 'to_string';
use Moo;
use MooX::late;

my %RETURN_CODES = (
  0 => 'OK',
  1 => 'WARNING',
  2 => 'CRITICAL',
  3 => 'UNKNOWN',
);

has 'check_name'	  => ( is => 'rw', isa => 'Str', required => 1);
has 'host_name'           => ( is => 'rw', isa => 'Str', required => 1);
has 'service_description' => ( is => 'rw', isa => 'Str');
has 'time'                => ( is => 'rw', isa => 'Int', default => sub { time });
has 'return_code'         => ( is => 'rw', isa => 'Int', default => 0);
has 'output'              => (
  is => 'rw',
  isa => 'Str',
#  traits    => ['String'],
  default => '',
#  handles => {
#    add_output => 'append',
#  },
);

sub add_output {
    $_[0]->output( $_[0]->output . $_[1] );
}

has 'threshold'           => (
  is => 'ro',
  isa => 'Nagios::Plugin::Threshold',
  handles => [qw/set_thresholds/],
  lazy => 1,
  predicate => 'has_threshold',
  default => sub { Nagios::Plugin::Threshold->new },
);
has 'performance' => (
  traits => ['Array'],
  is => 'ro',
  isa => 'ArrayRef[Nagios::Plugin::Performance]',
  default => sub { [] },
  lazy => 1,
  predicate => 'has_performance',
  handles => {
     _performance_add => 'push',
  }
);

sub to_string {
  croak("override this");
}

sub submit {
  croak("override this");
}

sub add_perf {
  my $self = shift;
  my $perf = Nagios::Plugin::Performance->new(@_);
  $self->_performance_add($perf);
}

sub set_status {
  my $self = shift;
  my $value = shift;
  unless($self->has_threshold) {
    croak("you have to call set_thresholds before calling set_status");
  }
  $self->return_code($self->threshold->get_status($value))
}

sub _status_code {
  my $self = shift;
  my $r = $RETURN_CODES{$self->return_code};
  return defined($r) ? $r : 'UNKNOWN';
}

sub _quoted_output {
  my $self = shift;
  my $output = $self->output;
  # remove trailing newlines and quote the remaining ones
  $output =~ s/[\r\n]*$//o;
  $output =~ s/\n/\\n/go;
  if($self->has_performance) {
    return $output . " | ".$self->_perf_string;
  }
  return $output;
}

sub _perf_string {
  my $self = shift;
  return "" unless($self->has_performance);
  return join (" ", map { $_->perfoutput } @{ $self->performance });
}

1;
__END__

=head1 NAME

Nagios::Passive::Base - Base class for Nagios::Passive backends.

=head1 SYNOPSIS

This is an abstract class.

=head1 DESCRIPTION

This is just a base class for Nagios::Passive backends. Currently
known implementations:

=over 4

=item * Nagios::Passive::CommandFile

=item * Nagios::Passive::ResultPath

=back

=cut
