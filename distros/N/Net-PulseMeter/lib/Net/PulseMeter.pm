package Net::PulseMeter;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.07';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


sub new
{
    my ($class, %parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);

    return $self;
}


#################### main pod documentation begin ###################

=head1 NAME

PulseMeter - Perl implementation of pulse-meter gem

=head1 SYNOPSIS

  use Redis;
  use Net::PulseMeter::Sensor::Base;
  use Net::PulseMeter::Sensor::Timelined::Counter;

  my $redis = Redis->new;
  Net::PulseMeter::Sensor::Base->redis($redis);

  my $sensor = Net::PulseMeter::Sensor::Timelined::Counter->new(
    "sensor_name",
    raw_data_ttl => 3600,
    interval => 10
  );
  $sensor->event(10);


=head1 DESCRIPTION

This module is a minimal implementation of L<pulse-meter gem|https://github.com/savonarola/pulse-meter> client.
You can read more about pulse-meter concepts and features in L<gem documentation|https://github.com/savonarola/pulse-meter#features>.

This module's main purpose is to allow send data to static or timelined 
sensors from perl client. Note that it just sends data, nothing more: 
no summarization and visualization is provided.

Basic usage is described in section above. Other sensors are initialized 
in the same way similar to their ruby counterparts.


=head1 AUTHOR

    Sergey Averyanov, Ilya Averyanov
    averyanov@gmail.com, ilya.averyanov@gmail.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=cut

#################### main pod documentation end ###################

1;
