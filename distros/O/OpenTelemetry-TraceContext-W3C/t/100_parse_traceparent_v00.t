use FindBin; use lib "${FindBin::RealBin}/..";
use t::lib::Test;

# values that can be parsed as v0

eq_or_diff(parse_traceparent('00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01'), {
    version     => 0x00,
    trace_id    => '4bf92f3577b34da6a3ce929d0e0e4736',
    parent_id   => '00f067aa0ba902b7',
    trace_flags => 0x01,
}, 'valid header, version 00');

eq_or_diff(parse_traceparent('01-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-f1'), {
    version     => 0x01,
    trace_id    => '4bf92f3577b34da6a3ce929d0e0e4736',
    parent_id   => '00f067aa0ba902b7',
    trace_flags => 0xf1,
}, 'valid header, higher version, no additional fields');

eq_or_diff(parse_traceparent('02-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01-something'), {
    version     => 0x02,
    trace_id    => '4bf92f3577b34da6a3ce929d0e0e4736',
    parent_id   => '00f067aa0ba902b7',
    trace_flags => 0x01,
}, 'valid header, higher version, additional fields');

# invalid values

eq_or_diff(parse_traceparent('00-4Bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01'), undef, 'invalid syntax (uppercase hex)');

eq_or_diff(parse_traceparent('ff-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01'), undef, 'invalid version ff');

eq_or_diff(parse_traceparent('00-00000000000000000000000000000000-00f067aa0ba902b7-01'), undef, 'invalid trace id');

eq_or_diff(parse_traceparent('00-4bf92f3577b34da6a3ce929d0e0e4736-0000000000000000-01'), undef, 'invalid parent id');

eq_or_diff(parse_traceparent('00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01-something'), undef, 'extra characters after value (for v0)');

done_testing();
