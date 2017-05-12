[![Build Status](https://secure.travis-ci.org/averyanov/pulse-meter-perl.png)](http://travis-ci.org/averyanov/pulse-meter-perl)

pulse-meter-perl
================

Pulse-meter minimal port to Perl

## Basic usage

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


## Description

This module is a minimal implementation of [pulse-meter gem](https://github.com/savonarola/pulse-meter) client.
You can read more about pulse-meter concepts and features in [gem documentation](https://github.com/savonarola/pulse-meter#features).

This module's main purpose is to allow send data to static or timelined 
sensors from perl client. Note that it just sends data, **nothing more**: 
no summarization and visualization is provided.

Basic usage is described in section above. Other sensors are initialized 
in the same way similar to their ruby counterparts.

