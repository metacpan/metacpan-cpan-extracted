use FindBin; use lib "${FindBin::RealBin}/..";
use t::lib::Test;

# traceparent version 00
{
    my $header = '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01';
    my $parsed = {
        version     => 0x00,
        trace_id    => '4bf92f3577b34da6a3ce929d0e0e4736',
        parent_id   => '00f067aa0ba902b7',
        trace_flags => 0x01,
    };

    eq_or_diff(parse_traceparent($header), $parsed, 'parse_traceparent - version 00');
    eq_or_diff(format_traceparent_v00($parsed), $header, 'format_traceparent - version 00');
}

# tracestate version 00
{
    my $header = 'rojo=00f067aa0ba902b7,congo=t61rcWkgMzE';
    my $parsed = { list_members => [
        { key => 'rojo', value => '00f067aa0ba902b7' },
        { key => 'congo', value => 't61rcWkgMzE' },
    ]};

    eq_or_diff(parse_tracestate($header), $parsed, 'parse_tracestate - version 00');
    eq_or_diff(format_tracestate_v00($parsed), $header, 'format_tracestate - version 00');
}

done_testing();
