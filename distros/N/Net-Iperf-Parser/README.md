# NAME

Net::Iperf::Parser - Parse a single iperf line result

[![Build Status](https://travis-ci.org/EmilianoBruni/net-iperf-parser.png?branch=master)](https://travis-ci.org/EmilianoBruni/net-iperf-parser)

# VERSION

version 0.04

# SYNOPSIS

    use Net::Iperf::Parser;

    my $p = new Net::Iperf::Parser;

    my @rows = `iperf -c iperf.volia.net -P 2`;

    foreach (@rows) {
      $p->parse($_);
      print $p->dump if ($p->is_valid && $p->is_global_avg);
    }

and result is something like this

    {
        is_valid          => 1,
        start             => 0,
        end               => 10,
        duration          => 10,
        speed             => 129024,
        speedk            => 126,
        speedm            => 0.123046875,
        is_process_avg    => 1,
        is_global_avg     => 1,
    }

# DESCRIPTION

Parse a single iperf line result in default or CSV mode

# METHODS

## start

Return the start time

## end

Return the end time

## is\_valid

Return if the parsed row is a valid iperf row

## is\_process\_avg

Return if the row is a process average value

## is\_global\_avg

Return if the row is the last summary value

## speed

Return the speed calculated in bps

## speedk

Return the speed calculated in Kbps

## speedm

Return the speed calculated in Mbps

## dump

Return a to\_string version of the object (like a Data::Dumper::dumper)

## parse($row)

Parse a single iperf line result

## parsecsv($row)

Parse a single iperf line result in CSV mode (-y C)

# SEE ALSO

[iperf](https://iperf.fr/)

# AUTHOR

Emiliano Bruni <info@ebruni.it>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
