use FindBin; use lib "${FindBin::RealBin}/..";
use t::lib::Test;

# values that can be parsed as v0

eq_or_diff(parse_tracestate('rojo=00f067aa0ba902b7,congo=t61rcWkgMzE'), { list_members => [
    { key => 'rojo', value => '00f067aa0ba902b7' },
    { key => 'congo', value => 't61rcWkgMzE' },
]}, 'valid header');

eq_or_diff(parse_tracestate('rojo=00f067aa0ba902b7  , congo=t61rcWkgMzE'), { list_members => [
    { key => 'rojo', value => '00f067aa0ba902b7' },
    { key => 'congo', value => 't61rcWkgMzE' },
]}, 'valid header, whitespace');

eq_or_diff(parse_tracestate('me@rojo=00f067aa0ba902b7,congo=t61rcWkgMzE'), { list_members => [
    { key => 'me@rojo', system_id => 'rojo', tenant_id => 'me', value => '00f067aa0ba902b7' },
    { key => 'congo', value => 't61rcWkgMzE' },
]}, 'valid header, multi-tenant');

eq_or_diff(parse_tracestate('rojo=the value X,congo=t61rcWkgMzE'), { list_members => [
    { key => 'rojo', value => 'the value X' },
    { key => 'congo', value => 't61rcWkgMzE' },
]}, 'valid header, values with sapces');

eq_or_diff(parse_tracestate(', rojo=00f067aa0ba902b7,, ,congo=t61rcWkgMzE, ,'), { list_members => [
    { key => 'rojo', value => '00f067aa0ba902b7' },
    { key => 'congo', value => 't61rcWkgMzE' },
]}, 'valid header, empty items');

done_testing();
