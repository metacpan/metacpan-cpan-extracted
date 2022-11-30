use FindBin; use lib "${FindBin::RealBin}/..";
use t::lib::Test;

eq_or_diff(format_traceparent_v00({
    version     => 0x00,
    trace_id    => '4bf92f3577b34da6a3ce929d0e0e4736',
    parent_id   => '00f067aa0ba902b7',
    trace_flags => 0x01,
}), '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01', 'standard version 00');

eq_or_diff(format_traceparent_v00({
    version     => 0x00,
    trace_id    => '4bf92f3577b34da6a3ce929d0e0e4736',
    parent_id   => '00f067aa0ba902b7',
    trace_flags => 0x00,
}), '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-00', 'standard version 00');

eq_or_diff(format_traceparent_v00({
    version     => 0x01,
    trace_id    => '4bf92f3577b34da6a3ce929d0e0e4736',
    parent_id   => '00f067aa0ba902b7',
    trace_flags => 0xff,
}), '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01', 'downgraded version');

eq_or_diff(format_traceparent_v00({
    version     => 0x01,
    trace_id    => '4bf92f3577b34da6a3ce929d0e0e4736f',
    parent_id   => '00f067aa0ba902b7',
    trace_flags => 0xff,
}), undef, 'invalid trace id');

eq_or_diff(format_traceparent_v00({
    version     => 0x01,
    trace_id    => '4bf92f3577b34da6a3ce929d0e0e4736',
    parent_id   => '00f067aa0ba902b7f',
    trace_flags => 0xff,
}), undef, 'invalid parernt id');

done_testing();
