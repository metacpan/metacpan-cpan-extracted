[![Actions Status](https://github.com/vague666/Quote-LineProtocol/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/vague666/Quote-LineProtocol/actions?workflow=test)
# NAME

Quote::LineProtocol - Helper module for Lineprotocol quoting

# SYNOPSIS

    use Quote::LineProtocol qw(measurement tags fields timestamp);
    my $measurement = 'Windows servers';
    my $tags = {Host => 'Server1', Address => 'server1.example.com', Description => 'Service backend'};
    my $fields = {MemoryMax => '4092000000', MemoryUsed => '367848234234', MemoryPrct => {type => 'f', value => 89.89}};

    say sprintf("%s,%s %s %s", measurement($measurement), tags(%$tags), fields(%$fields), timestamp('ns', 1));

    > Windows\ servers,Host=Server1,Address=server1.example.com,Description=Service\ backend MemoryMax=4092000000i,MemoryUsed=367848234234i,MemoryPrct=89.89 1768171443493651000

# DESCRIPTION

    This module provides helper functions to quote key/value pairs of datapoints
    meant to be sent over the InfluxDB lineprotocol following the rules specified
    on L<https://docs.influxdata.com/influxdb/v2/reference/syntax/line-protocol/>

# CONFIGURATION

Telegraf requires special consideration of spaces in strings. If using this module with telegraf set the env var QUOTE\_TELEGRAF before calling the script or use the following BEGIN block

    BEGIN {
      $ENV{QUOTE_TELEGRAF} = 1;
      require Quote::LineProtocol;
      Quote::LineProtocol->import(qw(measurement tags fields timestamp));
    }

With Strawberry perl you can set the env var in the portableshell.bat by adding

    set QUOTE_TELEGRAF=1

to the file

# METHODS

## measurement($str)

Returns a quoted string

## tags(key => value, key2 => value, ...)

Returns the input values quoted and joined with `,`

## fields(key => value, key2 => value, ...)

Returns the input values quoted and joined with `,`. The type of `value` is guessed based on regexps.
The `value` type can be specified with a hashref and must in that case consist of a `type` key and `value` key
where type can be one of:

- `f` for float
- `i` for integer
- `u` for unsigned integer
- `b` for boolean. In that case the value must be one of
    - -

        t, T, true, True, TRUE

    - -

        f, F, false, False, FALSE
- `s` for string

## timestamp(\[$str, \[$utc\]\])

$str specifies the precision of the timestamp, `ns`, `us`, or `ms`.
If no precision is specified `ns` is assumed.
$utc tells the function to use UTC time. Local timezone is assumed if not specified

# LICENSE

Copyright (C) Jari Matilainen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

vague <vague@cpan.org>
